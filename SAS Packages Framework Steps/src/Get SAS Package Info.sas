%if &spf_init_debug %then %do;
    %let spf_init_orig_symbolgen = %sysfunc(getoption(symbolgen));
    %let spf_init_orig_mlogic = %sysfunc(getoption(mlogic));
    %let spf_init_orig_mprint = %sysfunc(getoption(mprint));
    %let spf_init_orig_mlogicnest = %sysfunc(getoption(mlogicnest));
    %let spf_init_orig_mprintnest = %sysfunc(getoption(mprintnest));
    options symbolgen mlogic mprint mlogicnest mprintnest;
%end;

%macro spf_init_step;
    %local spf_init_sascontent 
           spf_package_file_sascontent
           spf_init_file 
           spf_init_path
           spf_repo_arg
           spf_install_args
           spf_init_fileref
           re_valid_package_name
           spf_package_file
           spf_package_file_path
           spf_package_file_fileref
           s
    ;
    
    %global spf_package_path
            spf_package_path_sascontent
            spf_package_path_is_sascontent
    ;

    /* Remove case-sensitivity */
    %let spf_init_type          = %upcase(&spf_init_type);
    %let spf_package_list_type  = %upcase(&spf_package_list_type);
    %let spf_repo               = %upcase(&spf_repo);
    %let spf_package_path_sascontent =;

    /******* Error checking *******/

    /* Must include a URL or file (this will fail later if the URL does not exist) */
    %if (&spf_init_type = URL  AND %superq(spf_init_url) =) OR
        (&spf_init_type = FILE AND %superq(spf_init_fqp) =)   
    %then %do;
        %put ERROR: You must include a URL or file for SPFInit.sas.;
        %abort;
    %end;

    /* Place to save SAS packages */
    %if %bquote(&spf_package_folder) = %then %do;
        %put ERROR: You must include a location to save SAS packages.;
        %abort;
    %end;

    /* Things to check when installing or loading */
    %if (&spf_package_install OR &spf_package_load) %then %do;

        /* Must include a list of packages or a file if installing/loading */
        %if (&spf_package_list_type = LIST AND &spf_package_list =) OR
            (&spf_package_list_type = FILE AND &spf_package_file_fqp=)
        %then %do;
            %put ERROR: You must include a list or file of packages when the Install or Load option is selected.;
            %abort;
        %end;

        /* Things to check only when installing */
        %if &spf_package_install %then %do;

            /* GitHub but no text added */
            %if &spf_repo = GITHUB AND &spf_github_name = %then %do;
                %put ERROR: You must include a GitHub username when the GitHub repo option is selected.;
                %abort;
            %end;

            /* Custom but no text added (note: installPackage will already check if the URL is valid) */
            %else %if &spf_repo = CUSTOM AND &spf_custom_url = %then %do;
                %put ERROR: You must include a URL when the Custom repo option is selected.;
                %abort;
            %end;
       %end;
    %end;

    /* Flags / path name cleanup */
    %let spf_init_sascontent            = %sysevalf(%qscan(%qupcase(&spf_init_fqp), 1, /) = SASCONTENT:, boolean);
    %let spf_package_path_is_sascontent = %sysevalf(%qscan(%qupcase(&spf_package_folder), 1, /) = SASCONTENT:, boolean);
    %let spf_package_path               = %qsubstr(&spf_package_folder, %index(&spf_package_folder, /)); /* Remove sascontent or sasserver from the start */

    /* Randomize filename statement to init packages framework */
    %let spf_init_fileref = spf_%upcase(%substr(%sysfunc(tranwrd(%sysfunc(uuidgen()),-,%str())), 1, 4));

    /******* SPF Package Location *******/

    /* If the package path is in SAS content, we need to:
        1. Keep track of the original package path  in SAS Content
        2. Reset the SPF package path to WORK */    
    %if &spf_package_path_is_sascontent %then %do;
        %let spf_package_path_sascontent = %superq(spf_package_path);
        %let spf_package_path            = %qsysfunc(pathname(work));
    %end;

    filename packages "&spf_package_path";

    /******* SPF Initialization File Location *******/

    /* Create a filename statement for either a URL, SAS Content, or a physical path */
    %if &spf_init_type = URL %then %do;
        filename &spf_init_fileref url "&spf_init_url";
    %end;

        %else %if &spf_init_type = FILE %then %do;

            /* sasserver:/foo/bar --> /foo/bar
               sascontent:/foo/bar --> /foo/bar */
            %let spf_init_fqp  = %qsubstr(&spf_init_fqp, %index(&spf_init_fqp, /));
            %let spf_init_file = %qscan(&spf_init_fqp, -1, /);
            %let spf_init_path = %qsubstr(&spf_init_fqp, 1, %eval(%length(&spf_init_fqp)-%length(&spf_init_file)-1));

            %if &spf_init_sascontent %then %do;   
                filename &spf_init_fileref filesrvc
                    folderpath=%sysfunc(quote(&spf_init_path))
                    filename=%sysfunc(quote(&spf_init_file))
                ;
            %end;

                /* Otherwise, use the physical path on the filesystem */
                %else %do;
                    filename &spf_init_fileref %sysfunc(quote(&spf_init_fqp)); 
                %end;
        %end;

    /******* Run SPFInit.sas *******/
    %include &spf_init_fileref;
    
    %if &syserr LE 6 %then %do;

        %if &spf_package_path_is_sascontent %then %do;
            %put NOTE: SAS packages are being stored in &spf_package_folder, but SAS packages must be on disk. It is highly recommended to use a physical location for best performance.;
            %put NOTE: PACKAGES fileref has been reassigned to the WORK directory.;
            %put NOTE: SPF Tools steps will automatically copy packages to/from SAS Content and WORK. Use %nrstr(%%)relocatePackage to manually transfer packages.;
        %end;

        %put NOTE: SAS Packages Framework initialized in &spf_package_path;
    %end;
        %else %do;
            filename &spf_init_fileref clear;
            %abort cancel;
        %end;

    filename &spf_init_fileref clear;

    /******* Install or load *******/
    %if &spf_package_install OR &spf_package_load %then %do;

        %if &spf_package_list_type = FILE %then %do;
        
            /* Get filename and path:
                - packages.txt
                - /location/to/file 
            */
            %let spf_package_file_sascontent = %sysevalf(%qscan(%qupcase(&spf_package_file_fqp), 1, /) = SASCONTENT:, boolean);
            %let spf_package_file_fqp        = %qsubstr(&spf_package_file_fqp, %index(&spf_package_file_fqp, /));
            %let spf_package_file            = %qscan(&spf_package_file_fqp, -1, /);
            %let spf_package_file_path       = %qsubstr(&spf_package_file_fqp, 1, %eval(%length(&spf_package_file_fqp)-%length(&spf_package_file)-1));
            %let spf_package_file_fileref    = pkg_%upcase(%substr(%sysfunc(tranwrd(%sysfunc(uuidgen()),-,%str())), 1, 4));

            %if &spf_package_file_sascontent %then %do;
                filename &spf_package_file_fileref filesrvc
                    filename=%sysfunc(quote(&spf_package_file))
                    folderpath=%sysfunc(quote(&spf_package_file_path))
                ;
            %end;
                %else %do;
                    filename &spf_package_file_fileref %sysfunc(quote(&spf_package_file_fqp));
                %end;
        %end;

        /* Sets valid package names:
            package
            package(version)
            package[version]
            package{version}
            package==version

            Version formats that are passed to the SPF use the brackets shown above. == is for convenience and is converted.
        */
        %let re_valid_package_name = ^[a-z0-9_]+(?:\([0-9.]+\)|\{[0-9.]+\}|\[[0-9.]+\]|==[0-9.]+)?$;

       /* Creates a dataset of packages and versions, and creates macro variables for:
          - A space and comma-separated list of packages with normalized versions: package1(version) package2(version) ...
          - A space-separated list of packages without versions: package1 package2 ...

          Code that runs depends on the method of input.
       */  
        data _null_;
            length package_raw 
                   package 
                   version      $256 
                   package_list $32767
            ;

            retain invalid_name_msg 0
                package_list
            ;
                
            /* Either loop through all the values in the manual list, or read from a file */
            %if &spf_package_list_type = LIST %then %do;

            do i = 1 to countw("&spf_package_list", ,'S');
                package_raw = strip(scan("&spf_package_list", i, ,'S'));

            %end;

            /* Or read from a file */
            %else %do;

            infile &spf_package_file_fileref end=eof;        
            input package_raw$;
            package_raw = strip(package_raw);

            %end;

            /* Detect invalid patterns and ignore */
            invalid_name = ( NOT prxmatch("/&re_valid_package_name/i", strip(package_raw)) );

            if invalid_name then do;
                put 'WARNING: ' package_raw 'is an invalid package name format and will be ignored.';
                invalid_name_msg = 1;
            end;

            else do;
                    
                ver_delim = findc(package_raw, '([{=');
                package   = substr(package_raw, 1, ifn(ver_delim > 0, ver_delim-1, length(package_raw)) );
                version   = compress(substr(package_raw, ver_delim+1), '.' ,'KD');

                /* package1 package2(version) package3 ... */
                package_list = catx(
                    ' ', 
                    package_list, 
                    ifc(
                        missing(version), 
                        package, 
                        cats(package, '(', version, ')') 
                    ) 
                );

            end;

            if NOT invalid_name then output;

            /* End the do loop if reading from a list */
            %if &spf_package_list_type = LIST %then %do;
                
            end;

            %end;

            /* Output the list at the end. EOF if reading from file, end of loop if not */ 
            %if &spf_package_list_type = FILE %then %do;

            if eof then do;

            %end;

                /* Create valid formats for installPackage and loadPackages:
                    - Space-separated list
                    - Comma-separated list
                    - Comma-separated list that removes versions: 
                        package1(6.7.0) package2(6.9.0) package3(4.2.0) --> package1 package2 package3
                */
                call symputx('spf_package_list_clean',     package_list, 'L');
                call symputx('spf_package_list_clean_cs',  tranwrd(package_list, ' ', ','));
                call symputx('spf_package_list_nover',     prxchange("s/\([^)]*\)//", -1, package_list), 'L');
                call symputx('n_packages', countw(package_list, ' '), 'L');

                if invalid_name_msg  then put 'WARNING: Expected package name formats: ' /
                    'package' /
                    'package(version)' /
                    'package[version]' /
                    'package{version}' /
                    'package==version' /
                ;

            %if &spf_package_list_type = FILE %then %do;

            end;
                    
            %end;

            keep package version;
        run;

        %if &n_packages > 1 %then %let s = s;
            %else %let s =;

        /******* Install *******/
        %if &spf_package_install %then %do;
    
            /* Set installPackage options depending on the repo selected */
            %if &spf_repo = PHARMAFOREST %then
                %let spf_repo_arg = mirror=3
            ;

            %else %if &spf_repo = GITHUB %then
                %let spf_repo_arg = github=&spf_github_name
            ;

            %else %if &spf_repo = CUSTOM %then %do;

                /* Add an ending / if the user forgot - requirement for this option */
                %if %qsubstr(&spf_custom_url, %length(&spf_custom_url), 1) NE %str(/) %then
                    %let spf_custom_url = %superq(spf_custom_url)/
                ;

                %let spf_repo_arg = sourcePath=%superq(spf_custom_url);
            %end;

            %else %let spf_repo_arg=;

            %let spf_install_args = replace=&spf_package_update;

            /* Add future arguments here */
            %if %length(&spf_repo_arg) > 0 %then 
                %let spf_install_args = &spf_install_args, &spf_repo_arg
            ;

            options spool;
            
            /* Install packages. Must be a space-separated list. */
            %installPackage(&spf_package_list_clean, &spf_install_args);

            /* Copy from WORK to SAS Content if SAS Content was specified */
            %if &spf_package_path_is_sascontent %then %do;

                %put NOTE: Copying package&s from WORK to sascontent:&spf_package_path_sascontent;
                
                %relocatePackage(
                    &spf_package_list_nover, 
                    target=&spf_package_path_sascontent, 
                    tDevice=FILESRVC,
                    ignorePackagesFilerefCheck=1,
                    checksum=%sysevalf(NOT &spf_package_update, boolean) /* Do not check hashes if spf_package_update is true */
                );
            %end;
        %end;

        /******* Load *******/
        %if(&spf_package_load) %then %do;

            /* If we have not run an install and a user is using SAS Content, then we 
               need to copy from SAS Content to WORK. Only copy the file over if it is newer. */
            %if(NOT &spf_package_install AND &spf_init_sascontent) %then %do;
            
                %put NOTE: Copying &n_packages package&s to WORK from sascontent:&spf_package_path_sascontent;

                %relocatePackage(
                    &spf_package_list_nover, 
                    source=&spf_package_path_sascontent,
                    sDevice=FILESRVC,
                    checksum=1
                );
            %end;

            %loadPackages(&spf_package_list_clean_cs);
        %end;

    %end;

%mend spf_init_step;
%spf_init_step;

%if &spf_init_debug %then %do;
    options &spf_init_orig_symbolgen 
            &spf_init_orig_mlogic 
            &spf_init_orig_mlogicnest 
            &spf_init_orig_mprint 
            &spf_init_orig_mprintnest
    ;
%end;

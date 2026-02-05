%if &spf_install_debug %then %do;
    %let spf_install_orig_symbolgen = %sysfunc(getoption(symbolgen));
    %let spf_install_orig_mlogic = %sysfunc(getoption(mlogic));
    %let spf_install_orig_mprint = %sysfunc(getoption(mprint));
    %let spf_install_orig_mlogicnest = %sysfunc(getoption(mlogicnest));
    %let spf_install_orig_mprintnest = %sysfunc(getoption(mprintnest));
    options symbolgen mlogic mprint mlogicnest mprintnest;
%end;

%macro spf_install_step;
    %local spf_repo_arg
           spf_install_args
           spf_package_file_sascontent
           spf_package_file
           spf_package_file_path
           spf_package_file_fileref
           s
    ;

    /* Remove case-sensitivity */
    %let spf_package_list_type = %upcase(&spf_package_list_type);

    /******* Error checking *******/
    %if NOT %sysmacexist(installPackage) %then %do;
        %put ERROR: You must initialize the SAS Packages Framework before running the Install Package step.;
        %abort cancel;
    %end;

    /* Must include a list of packages or a file if installing/loading */
    %if (&spf_package_list_type = LIST AND %bquote(&spf_package_list) =) OR
        (&spf_package_list_type = FILE AND %bquote(&spf_package_file_fqp)=)
    %then %do;
        %put ERROR: You must include a list or file of packages to install.;
        %abort;
    %end;

    /* GitHub but no text added */
    %if &spf_repo = GITHUB AND %bquote(&spf_github_name) = %then %do;
        %put ERROR: You must include a GitHub username when the GitHub repo option is selected.;
        %abort;
    %end;

    /* Custom but no text added (Note: installPackage will already check if the URL is valid) */
    %else %if &spf_repo = CUSTOM AND %bquote(&spf_custom_url) = %then %do;
        %put ERROR: You must include a URL when the Custom repo option is selected.;
        %abort;
    %end;

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
                filename="&spf_package_file"
                folderpath="&spf_package_file_path"
            ;
        %end;
            %else %do;
                filename &spf_package_file_fileref "&spf_package_file_fqp";
            %end;
    %end;

    /* Sets valid package names:
        package
        package(version)
        package[version]
        package{version}
        package==version
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

    %let spf_repo = %upcase(&spf_repo);
    
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

    /* Install packages. Must be a space-separated list. */
    %installPackage(&spf_package_list_clean, &spf_install_args);

    /* Copy from WORK to SAS Content if SAS Content was specified */
    %if %symexist(spf_package_path_is_sascontent) %then %do;
        %if &spf_package_path_is_sascontent %then %do;

            %put NOTE: Copying packages from WORK to sascontent:&spf_package_path_sascontent;
                
            %relocatePackage(
                &spf_package_list_nover, 
                target=&spf_package_path_sascontent, 
                tDevice=FILESRVC,
                ignorePackagesFilerefCheck=1,
                checksum=%sysevalf(NOT &spf_package_update, boolean) /* Do not check hashes if spf_package_update is true */
            );
        %end;
    %end;

%mend spf_install_step;

%spf_install_step;

%if &spf_install_debug %then %do;
    options &spf_install_orig_symbolgen 
            &spf_install_orig_mlogic 
            &spf_install_orig_mlogicnest 
            &spf_install_orig_mprint 
            &spf_install_orig_mprintnest
    ;
%end;
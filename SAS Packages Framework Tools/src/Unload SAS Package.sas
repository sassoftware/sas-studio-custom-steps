%if &spf_unload_debug %then %do;
    %let spf_unload_orig_symbolgen  = %sysfunc(getoption(symbolgen));
    %let spf_unload_orig_mlogic     = %sysfunc(getoption(mlogic));
    %let spf_unload_orig_mprint     = %sysfunc(getoption(mprint));
    %let spf_unload_orig_mlogicnext = %sysfunc(getoption(mlogicnest));
    %let spf_unload_orig_mprintnest = %sysfunc(getoption(mprintnest));
    options symbolgen mlogic mprint mlogicnest mprintnest;
%end;

%macro spf_unload_step;
    %local spf_package
           spf_package_file_sascontent
           spf_package_file
           spf_package_file_path
           spf_package_file_fileref
           i
    ;

    %if NOT %sysmacexist(unloadPackage) %then %do;
        %put ERROR: You must initialize the SAS Packages Framework before running the Unload Package step.;
        %abort cancel;
    %end;

    /* Remove case-sensitivity */
    %let spf_package_list_type = %upcase(&spf_package_list_type);
    
    /* Must include a list of packages or a file if installing/loading */
    %if (&spf_package_list_type = LIST AND %bquote(&spf_package_list) =) OR
        (&spf_package_list_type = FILE AND %bquote(&spf_package_file_fqp)=)
    %then %do;
        %put ERROR: You must include a list or file of packages to unload.;
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
                filename=%sysfunc(quote(&spf_package_file))
                folderpath=%sysfunc(quote(&spf_package_file_path))
            ;
        %end;
            %else %do;
                filename &spf_package_file_fileref %sysfunc(quote(&spf_package_file_fqp));
            %end;
    %end;

    /* Creates a dataset of packages and versions, and creates macro variables for:
           - A space and comma-separated list of packages with normalized versions: package1(version) package2(version) ...
           - A space-separated list of packages without versions: package1 package2 ...

       Code that runs depends on the method of input.
    */
    data _null_;
       length package_raw 
              package 
              package_list_nover $32767
       ;

       retain package_list_nover;
                
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

       ver_delim = findc(package_raw, '([{=');
       package   = substr(package_raw, 1, ifn(ver_delim > 0, ver_delim-1, length(package_raw)) );

       /* package1 package2 package3 ... */
       package_list_nover    = catx(' ', package_list_nover, package);

       /* End the do loop if reading from a list */
       %if &spf_package_list_type = LIST %then %do;
                
       end;

       %end;

       /* Output the list at the end. EOF if reading from file, end of loop if not */ 
       %if &spf_package_list_type = FILE %then %do;

       if eof then do;

       %end;

       /* Create valid formats for unloadPackage:
              - package1(6.7.0) package2(6.9.0) package3(4.2.0) --> package1 package2 package3
       */
           call symputx('spf_package_list_nover', package_list_nover, 'L');

        %if &spf_package_list_type = FILE %then %do;

        end;
                    
        %end;

        keep package version;
    run;

    %if &spf_package_list_nover = %then %do;
        %put ERROR: You must specify at least one package to unload.;
        %abort;
    %end;   

    %do i = 1 %to %sysfunc(countw(&spf_package_list_nover));
        %let spf_package = %scan(&spf_package_list_nover, &i);
        %unloadPackage(&spf_package);
    %end;
    
%mend spf_unload_step;
%spf_unload_step;

%if &spf_unload_debug %then %do;
    options &spf_unload_orig_symbolgen 
            &spf_unload_orig_mlogic 
            &spf_unload_orig_mlogicnest 
            &spf_unload_orig_mprint 
            &spf_unload_orig_mprintnest
    ;
%end;
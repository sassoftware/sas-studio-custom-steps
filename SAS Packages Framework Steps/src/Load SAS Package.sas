%if &spf_load_debug %then %do;
    %let spf_load_orig_symbolgen  = %sysfunc(getoption(symbolgen));
    %let spf_load_orig_mlogic     = %sysfunc(getoption(mlogic));
    %let spf_load_orig_mprint     = %sysfunc(getoption(mprint));
    %let spf_load_orig_mlogicnest = %sysfunc(getoption(mlogicnest));
    %let spf_load_orig_mprintnest = %sysfunc(getoption(mprintnest));
    options symbolgen mlogic mprint mlogicnest mprintnest;
%end;

%macro spf_load_step;
    %local spf_package_file_sascontent
           spf_package_file
           spf_package_file_path
           spf_package_file_fileref
           s
    ;   

    %if NOT %sysmacexist(loadPackage) %then %do;
        %put ERROR: You must initialize the SAS Packages Framework before running the Load Package step.;
        %abort cancel;
    %end;

    %let spf_package_list_type = %upcase(&spf_package_list_type);

    /* Load one package */
    %if &spf_package_list_type = ONE PACKAGE %then %do;

        /* Remove versions if the user accidentally adds them since they do nothing on load */
        data _null_;
            package = strip(translate("&spf_package", ' ', '0D0A'x));
            package = prxchange("s/[({\[\]=].*//", -1, package);
            
            call symputx('spf_package', package, 'L');
            call symputx('n_packages', countw(package, ' '), 'L');
        run;

        %if &n_packages = 0 %then %do;
            %put ERROR: You must specify one package to load.;
            %abort;
        %end;

        %else %if &n_packages > 1 %then %do;
            %put ERROR: &n_packages packages were specified but expected 1. Specify only one package when using the One package option.;
            %abort;
        %end;

        /* Should let someone still run this if they initialize it outside of the step */
        %if %symexist(spf_package_path_is_sascontent) %then %do;
            %if &spf_package_path_is_sascontent %then %do;
                %put NOTE: Copying package %upcase(&spf_package) to WORK from sascontent:&spf_package_path_sascontent;

                %relocatePackage(
                    &spf_package, 
                    source=&spf_package_path_sascontent,
                    sDevice=FILESRVC,
                    checksum=1
                );
            %end;
        %end;

        /* The default value of lazyData in loadPackage is missing, so reset the lazy data list to be missing 
           if the user does not enable load_lazy_data */
        %if NOT &spf_load_lazy_data %then %let spf_lazy_data_list = %str( );

        /* The default value of cherryPick in loadPackage is *, so reset the package element list to be * 
           if the user does not enable cherryPick */
        %if NOT &spf_load_package_elements %then %let spf_package_elements_list = *;

        /* Create space and comma-separated lists / remove carriage returns */
        data _null_;
            call symputx('spf_lazy_data_list_clean', translate("&spf_lazy_data_list", ' ', '0D0A'x), 'L');
            call symputx('spf_package_elements_list_clean', translate("&spf_package_elements_list", ' ', '0D0A'x), 'L');
        run;

        %loadPackage(
            &spf_package,
            lazyData     = &spf_lazy_data_list_clean,
            cherryPick   = &spf_package_elements_list_clean,
            DS2Force     = &spf_ds2_force,
            suppressExec = &spf_suppress_exec
        );
    %end;

        /* Load multiple packages */
        %else %do;

            /* Must include a list of packages or a file if installing/loading */
            %if ( (&spf_package_list_type = LIST AND &spf_package_list =) OR 
                  (&spf_package_list_type = FILE AND &spf_package_file_fqp=)
                ) %then %do;
                %put ERROR: You must include a list or file of packages to install.;
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

                    /* Create valid formats for installPackage and loadPackages:
                        - Space and comma-separated lists that removes versions: 
                            package1(6.7.0) package2(6.9.0) package3(4.2.0) --> package1 package2 package3
                    */
                    call symputx('spf_package_list_nover',     package_list_nover, 'L');
                    call symputx('spf_package_list_nover_cs',  translate(package_list_nover, ',', ' '), 'L');
                    call symputx('n_packages', countw(package_list_nover, ' '), 'L');

                %if &spf_package_list_type = FILE %then %do;

                end;
                    
                %end;

                keep package;
            run;

            %if &spf_package_list_nover = %then %do;
                %put ERROR: You must specify at least one package to load.;
                %abort;
            %end;

            %if %symexist(spf_package_path_is_sascontent) %then %do;
                %if &spf_package_path_is_sascontent %then %do;
                    %if &n_packages > 1 %then %let s = s;
                        %else %let s =;
                        
                    %put NOTE: Copying &n_packages package&s to WORK from sascontent:&spf_package_path_sascontent;

                    %relocatePackage(
                        &spf_package_list_nover, 
                        source=&spf_package_path_sascontent,
                        sDevice=FILESRVC,
                        checksum=1
                    );
                %end;
            %end;

            %loadPackages(&spf_package_list_nover_cs);
        %end;
%mend spf_load_step;
%spf_load_step;

%if &spf_load_debug %then %do;
    options &spf_load_orig_symbolgen 
            &spf_load_orig_mlogic 
            &spf_load_orig_mlogicnest 
            &spf_load_orig_mprint 
            &spf_load_orig_mprintnest
    ;
%end;
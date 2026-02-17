/* Program based on SAS KB 51626: How to write the contents of the SAS log or other text output to an HTML, RTF, or PDF file 
   https://support.sas.com/kb/51/626.html
*/
%macro spf_package_info / minoperator mindelimiter = ' ';
    %local log_loc spf_package_list_dsn spf_result_ds;

    %let spf_package_info_option = %upcase(&spf_package_info_option);
    %let spf_package_list_dsn    =;
    %let spf_result_ds           = %sysevalf(&spf_result_ds_content OR &spf_result_ds_list, boolean);

    %if (&spf_package_info_option = HELP    AND NOT %sysmacexist(helpPackage) ) OR
        (&spf_package_info_option = PREVIEW AND NOT %sysmacexist(previewPackage) ) OR
        (&spf_package_info_option = LIST    AND NOT %sysmacexist(listPackages) )
    %then %do;
        %put ERROR: You must initialize the SAS Packages Framework before running the Package Info step.;
        %abort;
    %end;

    %if &spf_package_info_option IN (HELP PREVIEW) %then %do;

        /* Remove versions if user added them */
        data _null_;
            package = prxchange("s/[({\[\]=].*//", -1, strip("&spf_package"));
            call symputx('spf_package', package, 'L');
            call symputx('n_packages', countw(package, ' ') );
        run;

        %if &n_packages = 0 %then %do;
            %put ERROR: You must include a package to get help.;
            %abort;
        %end;

        %else %if &n_packages > 1 %then %do;
            %put ERROR: &n_packages packages were specified but expected 1. Specify only one package when using the One package option.;
            %abort;
        %end;
        
        /* Copy from WORK to SAS Content if SAS Content was specified during initialization */
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
    %end;

    /* Get original log location and save an spf_package_help.log file to WORK */
    %let log_loc      = %superq(SYSPRINTTOLOG);
    %let spf_info_log = %qsysfunc(pathname(work))/spf_package_help.log;
    %let spf_info_output_type = %upcase(&spf_info_output_type);

    %if &spf_info_output_type NE LOG %then %do;
        proc printto log="&spf_info_log" new; 
        run;
    %end;

    /* Either get help, preview, or list packages */
    %if &spf_package_info_option = HELP  %then %do;
        %helpPackage(&spf_package, &spf_info_keyword, packageContentDS=&spf_result_ds);
    %end;

    %else %if &spf_package_info_option = PREVIEW %then %do;
        %previewPackage(&spf_package, &spf_info_keyword);
    %end;

    %else %do;
        %if &spf_result_ds %then %let spf_package_list_dsn = spf_package_list;

        %listPackages(&spf_package_list_dsn)
    %end;

    %if &spf_info_output_type NE LOG %then %do;

        /* Reset log location */
        %if &log_loc = %then %do;
            proc printto; run;
        %end;
            %else %do;
                proc printto file="&log_loc"; run;
            %end;

        proc document name=spf_info(write);
            import textfile="&spf_info_log" to logfile;
            replay;
        quit;
    %end;

%mend spf_package_info;
%spf_package_info;

%sysmacdelete spf_package_info / NOWARN;
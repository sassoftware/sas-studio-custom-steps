* sprc is short for submit Python and R code;
* Macro to check if the connected tables are in CAS;
%macro _sprc_check_for_engine(_sprc_current_table_engine, _sprc_current_table, _sprc_cfe_rc, _sprc_expected_engine=CAS);
    %local _sprc_current_table_engine
        _sprc_current_table
        _sprc_expected_engine
        _sprc_cfe_rc;

    %if &_sprc_current_table_engine. NE &_sprc_expected_engine. %then %do;
        %let &_sprc_cfe_rc. = 0;

        data _null_;
            putlog "ERROR: The table &_sprc_current_table. is not a &_sprc_expected_engine. table.";
            putlog "ERROR: In order for this step to run your data needs to be loaded in &_sprc_expected_engine.";
            abort 42;
        run;
    %end;
%mend _sprc_check_for_engine;

* Macro to get the caslib name of the libname;
%macro _sprc_get_caslib_name(_sprc_libref, _sprc_caslib_variable);
    %local _sprc_libref
        _sprc_caslib_variable;
    
    proc sql noprint;
        select sysvalue into :&_sprc_caslib_variable. trimmed from dictionary.libnames
        where libname = upcase("&_sprc_libref.") and upcase(sysname)="CASLIB";
    quit;
%mend _sprc_get_caslib_name;


%macro _sprc_check();
    %local _sprc_ERROR_CODE
        _sprcFile
        _sprcIsContent
        _sprcFirstArg
        _sprc_i;

    * Detector for the script language based on the scripts file extension;
    * Counter for the number of in and output tables;
    %global _sprcLang
        _sprcInCounter
        _sprcOutCounter;

    %let _sprc_ERROR_CODE = 1;
    %let _sprcIsContent = 0;
    %let _sprcFirstArg = 1;
    %let _sprcInCounter = 0;
    %let _sprcOutCounter = 0;

    * Iterate overall then input and output table;
    * First step is checking if the variable contains anything;
    * If a table was connected engine check for CAS is done and the acutal CASLIB name is retrieved;
    * Then the table is turned into an argument for the gateway.runLang action;
    %do _sprc_i = 1 %to 10;
        * Check all 10 potential input tables;
        %if %symexist(inputtable&_sprc_i.) %then %do;
            %if &&inputtable&_sprc_i. eq %then %do;
                %if &_sprc_i. eq 1 %then %do;
                    %put NOTE: No input table connected.;
                %end;
                %let inputtable&_sprc_i. =;
            %end;
            %else %do;
                %_sprc_check_for_engine(&&inputtable&_sprc_i._engine., &&inputtable&_sprc_i., _sprc_ERROR_CODE);
                %_sprc_get_caslib_name(&&inputtable&_sprc_i._lib., &&inputtable&_sprc_i._lib.);

                %let _sprcInCounter = %eval(&_sprcInCounter. + 1);
                %if &_sprcFirstArg. %then %do;
                    %let inputtable&_sprc_i. = inputtable&_sprc_i. = {name = "&&inputtable&_sprc_i._name", caslib="&&inputtable&_sprc_i._lib"};
                    %let _sprcFirstArg = 0;
                %end;
                %else %do;
                    %let inputtable&_sprc_i. = ,inputtable&_sprc_i. = {name = "&&inputtable&_sprc_i._name", caslib="&&inputtable&_sprc_i._lib"};
                %end;
            %end;
        %end;
        %else %do;
            %global inputtable&_sprc_i.;
            %let inputtable&_sprc_i. =;
        %end;

        * Check all 10 potential output tables;
        %if %symexist(outputtable&_sprc_i) %then %do;
            %if &&outputtable&_sprc_i. eq %then %do;
                %if &_sprc_i. eq 1 %then %do;
                    %put NOTE: No output table connected.;
                %end;
                %let outputtable&_sprc_i. =;
            %end;
            %else %do;
                %_sprc_check_for_engine(&&outputtable&_sprc_i._engine., &&outputtable&_sprc_i., _sprc_ERROR_CODE);
                %_sprc_get_caslib_name(&&outputtable&_sprc_i._lib., &&outputtable&_sprc_i._lib.);

                %let _sprcOutCounter = %eval(&_sprcOutCounter. + 1);
                %if &_sprcFirstArg. %then %do;
                    %let outputtable&_sprc_i. = outputtable&_sprc_i. = {name = "&&outputtable&_sprc_i._name", caslib="&&outputtable&_sprc_i._lib"};
                    %let _sprcFirstArg = 0;
                %end;
                %else %do;
                    %let outputtable&_sprc_i. = ,outputtable&_sprc_i. = {name = "&&outputtable&_sprc_i._name", caslib="&&outputtable&_sprc_i._lib"};
                %end;
            %end;
        %end;
        %else %do;
            %global outputtable&_sprc_i.;
            %let outputtable&_sprc_i. =;
        %end;
    %end;

    %if &_sprcFirstArg. eq 0 %then %do;
        %let outputtable10 = &outputtable10., inputTableCounter = &_sprcInCounter., outputTableCounter = &_sprcOutCounter.;
    %end;
    %else %do;
        %let outputtable10 = inputTableCounter = &_sprcInCounter., outputTableCounter = &_sprcOutCounter.;
    %end;

    %if &_sprc_ERROR_CODE. %then %do;
        * Extract the script language and create the filename statement for the script;
        data _null_;
            justFileName = scan("&scriptFileSelector.", -1, '/', 'MO');
            folderPath1 = scan("&scriptFileSelector.", 2, ':', 'MO');
            folderPath2 = substr(folderPath1, 1, length(folderPath1) - length(justFileName) - 1);
            mode = scan("&scriptFileSelector.", 1, ':', 'MO');
            
            * Handle the different required filename for SAS Content and SAS Server;
            if mode = 'sascontent' then do;
                call symput('_sprcIsContent', 1);
                call symput('_sprcFile', "filename sprcTMP filesrvc folderPath='" || strip(folderPath2) || "' filename='" || strip(justFileName) || "'");
            end;
            else do;
                call symput('_sprcFile', "filename sprcScpt '" || strip(folderPath1) || "'");
            end;
        
            * Check the file extension and set the code parameter accordingly;
            lang = reverse(scan(reverse("&scriptFileSelector."), 1, '.'));
            if lowcase(lang) = 'py' then do;
                call symput('_sprcLang', 'PYTHON');
            end;
            else if lowcase(lang) = 'r' then do;
                call symput('_sprcLang', 'R');
            end;
            else do;
                putlog 'ERROR: Unsupported file extension detected - Execution aborted';
                abort 42;
            end;
        run;

        * SAS Content file needs to be copied to a temp file;
        %if &_sprcIsContent. %then %do;
            &_sprcFile.;
            filename sprcScpt temp;

            data _null_;
                infile sprcTMP;
                file sprcScpt;
                input;
            
                put _infile_;
            run;

            filename sprcTMP clear;
        %end;
        %else %do;
            &_sprcFile.;
        %end;
    %end;
%mend _sprc_check;

%_sprc_check();

* Run the actual code - as it uses submit/endsubmit it needs to be outside of a macro;
proc cas;
    code = readfile('sprcScpt');

    gateway.runLang / args={&inputtable1. &outputtable1. &inputtable2. &outputtable2. &inputtable3. &outputtable3. &inputtable4. &outputtable4. &inputtable5. &outputtable5. &inputtable6. &outputtable6. &inputtable7. &outputtable7. &inputtable8. &outputtable8. &inputtable9. &outputtable9. &inputtable10. &outputtable10.},
        code = code,
        jitter_timeout_millis = &jitterTimeoutMillis.,
        lang = "&_sprcLang.",
        log_level = "&logLevel.",
        %if &nthreads. ne 0 %then %do; %put nthreads = &nthreads.,; %end;
        single = %if &runSingleThread. %then %do; true %end; %else %do; false %end;,
        timeout_millis = &timeoutMillis.;
run; quit;

* Remove all macro in- and outputtable variables as they could be created by this step;
%macro _sprc_var_clean_up();
    %local _sprc_i;
    
    %do _sprc_i = 1 %to 10;
        %symdel inputtable&_sprc_i. outputtable&_sprc_i.;
    %end;
%mend _sprc_var_clean_up;

%_sprc_var_clean_up();

filename sprcScpt clear;
%symdel _sprcLang _sprcInCounter _sprcOutCounter;
%sysmacdelete _sprc_check_for_engine;
%sysmacdelete _sprc_get_caslib_name;
%sysmacdelete _sprc_check;
%sysmacdelete _sprc_var_clean_up;
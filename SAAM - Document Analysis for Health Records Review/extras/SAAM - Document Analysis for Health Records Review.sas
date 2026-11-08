/***************************************************************************************************************

   SCRIPT:       SAAM - Document Analysis for Health Records Review.step

   PURPOSE:
   Custom Step driver for the Health Records Review (HRR) medical information extraction pipeline. 
   Validates UI-provided server paths, assigns the compiled MRR macro catalog, builds a JSON 
   `userConfig` payload, writes it to a temporary file, and executes `%mrr_information_extraction`. 
   After execution, assigns an output libref (or imports flat files) so results are accessible in SAS.

   KEY FEATURES:
   -------------
   - Validates that UI selections are SAS Server–based (rejects SAS Content selections)
   - Derives `_hrr_src_filepath`, `_hrr_export_dirpath`, `_hrr_astore_dirpath`,
     `_hrr_macro_catalog_dirpath` from `sasserver:`-prefixed parameters
   - Gracefully assigns/refreshes compiled macro catalog (MSTORED/SASMSTORE)
   - Dynamically constructs the MRR `userConfig` JSON (import/global/std sections)
   - Normalizes and defaults optional settings:
       * SDA vs SAS input mode routing
       * `flag_invalid_dates` and `enable_bookmarking` to JSON booleans
       * `min_valid_date` defaults to 1930-01-01
       * `max_valid_date` defaults to CURRENTDATE
       * converts ISO dates to SAS DATE9. strings for config
   - Writes `userConfig` JSON to a temp fileref and passes its resolved path to MRR
   - Post-processes exports by assigning an output libref based on export type:
       * sas7bdat → direct libname to export directory
       * sashdat  → CASLIB + libname CAS (if session exists)
       * json     → JSON libname to nested results file
       * csv/xls/xlsx → PROC IMPORT of expected flat files into a temp libref

   REQUIRED MACRO VARIABLES (UI-provided):
   ---------------------------------------
   - _hrr_input_source_type            [SDA:MAPPINGFILE or SAS:SASDATASET]
   - _hrr_source_data_file             [sasserver:<path>]
   - _hrr_output_export_directory      [sasserver:<path>]
   - _hrr_output_export_file_type      [csv | json | xls | xlsx | sas7bdat | sashdat]
   - _hrr_astore_directory             [sasserver:<path>]
   - _hrr_macro_catalog_directory      [sasserver:<path>]
   - _hrr_colnames_sas_r1_c1           [document_id column (SAS input mode)]
   - _hrr_colnames_sas_r1_c2           [document_text column (SAS input mode)]
   - _hrr_colnames_sas_r1_c3           [document_page_number column (SAS input mode)]
   - _hrr_debug_level                  [DEBUG | INFO]

   OPTIONAL FLAGS & FORMATTERS (UI-provided):
   ------------------------------------------
   - _hrr_standardize_casing           [Lowcase | Upcase | Propcase]
   - _hrr_enable_bookmarking           [YES | NO]  -> converted to true/false for JSON
   - _hrr_flag_invalid_dates           [YES | NO]  -> converted to true/false for JSON
   - _hrr_min_valid_date               [ISO8601 date; defaults to 1930-01-01]
   - _hrr_max_valid_date               [ISO8601 date; defaults to CURRENTDATE]
   - _hrr_date_format                  [SAS date format, e.g., DATE9.]

   DERIVED / INTERNAL MACRO VARIABLES:
   -----------------------------------
   - _hrr_input_source                 [SDA or SAS]
   - _hrr_src_filepath                 [resolved source file path]
   - _hrr_export_dirpath               [resolved export directory path]
   - _hrr_astore_dirpath               [resolved astore directory path]
   - _hrr_macro_catalog_dirpath        [resolved macro catalog directory path]
   - _hrr_sda_fpath                    [populated when input source is SDA]
   - _hrr_sas_fpath                    [populated when input source is SAS]
   - _hrr_user_config_json             [full JSON config string]
   - _hrr_usercfg_fpath                [resolved temp config filepath]
   - _hrr_output_libref                [_HRROUT_]
   - _hrr_catalog_libref               [_HRRCAT_]

   OUTPUTS:
   --------
   - Temp `userConfig` file (FILEREF: usercfg) containing JSON payload
   - `%mrr_information_extraction(userConfig=<tempfile>, astoreDirpath=<dir>, loglevel=<level>)`
   - Exported results written to `_hrr_export_dirpath` in the selected format
   - Output made available via libref `_HRROUT_` (direct libname / CAS / JSON / PROC IMPORT)

   DEPENDENCIES:
   -------------
   - Compiled MRR macro catalog accessible from `_hrr_macro_catalog_directory`
     (loaded via MSTORED/SASMSTORE)
   - `%mrr_information_extraction` (MRR pipeline macro)
   - `%mrr_cleanup_global_mvars` (cleanup utility)
   - CAS session availability required for `sashdat` post-processing path

   HISTORY:
   --------
   - 2025-10-01 | mupago |              | Initial creation
   - 2025-11-25 | winado | AAIMDEV-5070 | Added logic to gracefully assign SAS macro catalog
   - 2025-11-25 | winado | AAIMDEV-5069 | Refactored to use astoreDirpath instead of rootDirpath
   - 2025-12-03 | mupago | AAIMDEV-5070 | Updated parameters for astore dirpath and macro catalog
   - 2025-12-19 | winado | AAIMDEV-5071 | Updates to design layout and code modifications for consistency
   - 2026-01-12 | mupago | AAIMDEV-5070 | Updated to use kscan function in reset_assign_exportLibref macro  
   - 2026-01-14 | mupago | AAIMDEV-5070 | Added clean up code from _template to delete user defined macro 
                                          variables and functions  
   - 2026-01-21 | mupago | AAIMDEV-5071 | Used _hrr_export_dirpath as parameter value for reset_assign_exportLibref macro
   - 2026-01-21 | mupago | AAIMDEV-5071 | Modified %sysmacdelete splitting into multiple statements to avoid extraneous text warning
   - 2026-01-21 | mupago | AAIMDEV-5071 | Fixed a bug for cas_sess_exist evaluation to use %let instead of %put
   - 2026-01-21 | mupago | AAIMDEV-5071 | Used sysevalf function to perform numerical comparison for cas session macro variable
   - 2026-01-21 | mupago | AAIMDEV-5071 | Added code to explicitly remove MRR_OUT from CAS to avoid conflict with output libref
   - 2026-01-21 | mupago | AAIMDEV-5071 | Added code for lifting sashdat tables into memory for sashdat output file type
   - 2026-01-22 | mupago | AAIMDEV-5071 | Fixed code for proc import to use guessingrows only when dbms is csv
   - 2026-01-23 | winado | AAIMDEV-5071 | Code fix for setting boolean values
********************************************************************************************************************/

cas;
cas casauto;
caslib _all_ assign;
/* options casdatalimit=8G; */
/* options mprint mprintnest mlogic symbolgen mautosource mlogicnest; */

/* Uncomment to debug */
/* %put "_hrr_input_source_type selected is:" &_hrr_input_source_type; */
/* %put "_hrr_colnames_sas_r1_c1 selected is:" &_hrr_colnames_sas_r1_c1; */
/* %put "_hrr_colnames_sas_r1_c2 selected is:" &_hrr_colnames_sas_r1_c2; */
/* %put "_hrr_colnames_sas_r1_c3 selected is:" &_hrr_colnames_sas_r1_c3; */
/* %put "_hrr_source_data_file selected is:" &_hrr_source_data_file; */
/* %put "_hrr_output_export_directory selected is:" &_hrr_output_export_directory; */
/* %put "_hrr_output_export_file_type selected is:" &_hrr_output_export_file_type; */
/* %put "_hrr_astore_directory selected is:" &_hrr_astore_directory; */
/* %put "_hrr_macro_catalog_directory selected is:" &_hrr_macro_catalog_directory; */
/* %put "_hrr_standardize_casing selected is:" &_hrr_standardize_casing; */
/* %put "_hrr_flag_invalid_dates selected is:" &_hrr_flag_invalid_dates; */
/* %put "_hrr_enable_bookmarking selected is:" &_hrr_enable_bookmarking; */
/* %put "_hrr_min_valid_date selected is:" &_hrr_min_valid_date; */
/* %put "_hrr_max_valid_date selected is:" &_hrr_max_valid_date; */
/* %put "_hrr_date_format selected is:" &_hrr_date_format; */
/* %put "_hrr_debug_level selected is:" &_hrr_debug_level; */

/* Specify where to make output accessible from after processing completes */
%let _hrr_output_libref = _HRROUT_;
%let _hrr_catalog_libref = _HRRCAT_;

/* Check that macro catalog and model directory exist and are accessible */
data _null_;

    * Check that the user provided Astore file directory is on the SAS server and not in SAS Content;
    mode_1 = kscan("&_hrr_astore_directory.", 1, ':');

    if mode_1 EQ 'sasserver' then do;
        call symputx('_hrr_astore_dirpath', kscan("&_hrr_astore_directory.", -1, ':'));
    end;
    else do;
        putLog 'ERROR: Please ensure that the selected source directory is on the SAS server.';
        abort 40;
    end;

    * Check that the user provided macro catalog directory is on the SAS server and not in SAS Content;
    mode_2 = kscan("&_hrr_macro_catalog_directory.", 1, ':');
    
    if mode_2 EQ 'sasserver' then do;
        call symputx('_hrr_macro_catalog_dirpath', kscan("&_hrr_macro_catalog_directory.", -1, ':'));
    end;
    else do;
        putLog 'ERROR: Please ensure that the selected export directory is on the SAS server.';
        abort 41;
    end;

run;

/* Logic to gracefully establish SAS macro catalog accessibility */
%macro mrr_assign_sasmacro_catalog(catalogLibref=, dirpath=);

    %put NOTE: &=catalogLibref;
    %put NOTE: &=dirpath;    

    /* Ensure catalogLibref meets length requirement */
    %if %klength(&catalogLibref.) > 8 %then %do;
        %put ERROR: SAS macro catalog catalogLibref <&catalogLibref> supplied to mrr_assign_sasmacro_catalog must be <= 8 characters long!;
        %return;
    %end;

    /* Determine if SAS macro catalog already exists from prior execution */
    proc sql noprint; 
        select count(distinct libname) 
        into: mrr_sasmacro_catalog_exists 
        from dictionary.libnames 
        where kupcase(kstrip(libname)) = kupcase(kstrip("&catalogLibref"));
    quit;

    /* If it exists then clear it to avoid error */
    %if &mrr_sasmacro_catalog_exists. = 1 %then %do;
        %sysmstoreclear;
    %end;

    /* Now assign and load compiled macro catalog */
    libname &catalogLibref. &dirpath.;
    options mstored sasmstore="&catalogLibref";

    /* Check if it exists now after assignment */
    proc sql; 
        select count(distinct libname) 
        into: mrr_sasmacro_catalog_exists 
        from dictionary.libnames 
        where kupcase(kstrip(libname)) = kupcase(kstrip("&catalogLibref"));
    quit;

    %put NOTE: &=mrr_sasmacro_catalog_exists;

%mend mrr_assign_sasmacro_catalog;

/* Assign and load compiled macro catalog */
%mrr_assign_sasmacro_catalog(catalogLibref=&_hrr_catalog_libref., dirpath="&_hrr_macro_catalog_dirpath.");

/* Validate input file exists and is accessible */
data _null_;

    * Extract the first argument from the Input Source Type parameter to be passed on to the json config file;
    call symputx('_hrr_input_source', kscan("&_hrr_input_source_type.", 1, ':'));

    * Check that the user provided a source (input) directory on the SAS server and not in SAS Content;
    mode_1 = kscan("&_hrr_source_data_file.", 1, ':');
    if mode_1 EQ 'sasserver' then do;
        call symputx('_hrr_src_filepath', kscan("&_hrr_source_data_file.", -1, ':'));
    end;
    else do;
        putLog 'ERROR: Please ensure that the selected source directory is on the SAS server.';
        abort 42;
    end;

    * Check that the user provided a export (output) directory on the SAS server and not in SAS Content;
    mode_2 = kscan("&_hrr_output_export_directory.", 1, ':');

    if mode_2 EQ 'sasserver' then do;
        call symputx('_hrr_export_dirpath', kscan("&_hrr_output_export_directory.", -1, ':'));
    end;
    else do;
        putLog 'ERROR: Please ensure that the selected export directory is on the SAS server.';
        abort 43;
    end;
run;

%put NOTE: &=_hrr_src_filepath;
%put NOTE: &=_hrr_export_dirpath;

/* Conditionally populate the filepath for either the SAS or SDA specific input data mode */

%if %kupcase(&_hrr_input_source) = SDA %then %do;
    %let _hrr_sda_fpath = &_hrr_src_filepath;
    %let _hrr_sas_fpath =;
%end;

%if %kupcase(&_hrr_input_source) = SAS %then %do;
    %let _hrr_sas_fpath = &_hrr_src_filepath;
    %let _hrr_sda_fpath=;
%end;

%if %kupcase(&_hrr_flag_invalid_dates) = YES %then %do;
    %let _hrr_flag_invalid_dates = true;
%end;
%else %do;
    %let _hrr_flag_invalid_dates = false;
%end;

%if %kupcase(&_hrr_enable_bookmarking) = YES %then %do;
    %let _hrr_enable_bookmarking = true;
%end;
%else %do;
    %let _hrr_enable_bookmarking = false;
%end;

%if &_hrr_min_valid_date = %then %do; 
    %let _hrr_min_valid_date = 1930-01-01; 
%end;

%if &_hrr_max_valid_date = %then %do; 
    %let _hrr_max_valid_date = CURRENTDATE;
%end;

/* Convert character ISO date to SAS date and reformat */
data _null_;
    minValidDate_num = input("&_hrr_min_valid_date", yymmdd10.);
    formatted_MinValidDate = put(minValidDate_num, date9.);
    call symputx('_hrr_min_valid_date', formatted_MinValidDate);
run;

/* Convert character ISO date to SAS date and reformat */
%if &_hrr_max_valid_date ne CURRENTDATE %then %do;
    data _null_;
        maxValidDate_num = input("&_hrr_max_valid_date", yymmdd10.);
        formatted_MaxValidDate = put(maxValidDate_num, date9.);
        call symputx('_hrr_max_valid_date', formatted_MaxValidDate);
    run;
%end;

/* Print out mvar values for debugging */
%put NOTE: &=_hrr_sda_fpath;
%put NOTE: &=_hrr_sas_fpath;
%put NOTE: &=_hrr_flag_invalid_dates;
%put NOTE: &=_hrr_enable_bookmarking;
%put NOTE: &=_hrr_min_valid_date;
%put NOTE: &=_hrr_max_valid_date;

/* Dynamically create the user config json string in a sas macro using the parameters passed on from the Custom Step */

%let _hrr_user_config_json=
{
    "global": [
        {
            "main": [
                {
                    "id": "1000",
	                "datamode": "ECE",
                    "persist_scoring_data": "true"
                }
            ],
            "parms": [
                {
                    "sub": [
                        {
                            "id": "1001",
                            "name": "output_flat_files",
                            "type": "flag",
                            "value": "true"
                        },
                        {
                            "id": "1002",
                            "name": "flat_file_dirpath",
                            "type": "directory_path",
                            "value": "%superq(_hrr_export_dirpath)"
                        },
                        {
                            "id": "1003",
                            "name": "flat_file_format",
                            "type": "file_format",
                            "value": "%superq(_hrr_output_export_file_type)"
                        }
                    ]
                }
            ]
        }
    ],
    "import": [
        {
            "main": [
                {
                    "id": "2000",
                    "import_source": "%superq(_hrr_input_source)"
                }
            ],
            "parms": [
                {
                    "id": "2010",
                    "source": "SDA",
                    "datatype": "OCRFILE",
                    "method": "MAPPINGFILE",
                    "description": "Loads OCR output produced by the SAS Document Analysis (SDA) process",
                    "sda_filepath": "%superq(_hrr_sda_fpath)"
                },
                {
                    "id": "2020",
                    "source": "SAS",
                    "datatype": "DATASET",
                    "method": "DATAFILE",
                    "description": "Loads input dataset from a SAS datafile",
                    "sas_filepath": "%superq(_hrr_sas_fpath)",
                    "sub": [
                        {
                            "id": "2021",
                            "name": "document_id",
                            "type": "column_name",
                            "value": "%superq(_hrr_colnames_sas_r1_c1)"
                        },
                        {
                            "id": "2022",
                            "name": "document_text",
                            "type": "column_name",
                            "value": "%superq(_hrr_colnames_sas_r1_c2)"
                        },
                        {
                            "id": "2023",
                            "name": "document_page_number",
                            "type": "column_name",
                            "value": "%superq(_hrr_colnames_sas_r1_c3)"
                        }
                    ]
                }
            ]
        }
    ],
    "std": [
        {
            "main": [
                {
                    "id": "3000",
                    "standardized_casing": "%superq(_hrr_standardize_casing)",
                    "enable_bookmarking": "%superq(_hrr_enable_bookmarking)"
                }
            ],
            "parms": [
                {
                    "sub": [
                        {
                            "id": "3001",
                            "name": "date_format",
                            "type": "sas_format",
                            "value": "%superq(_hrr_date_format)"
                        },
                        {
                            "id": "3002",
                            "name": "flag_invalid_dates",
                            "type": "flag",
                            "value": "%superq(_hrr_flag_invalid_dates)"
                        },
                        {
                            "id": "3003",
                            "name": "min_valid_date",
                            "type": "string",
                            "value": "%superq(_hrr_min_valid_date)"
                        },
                        {
                            "id": "3004",
                            "name": "max_valid_date",
                            "type": "string",
                            "value": "%superq(_hrr_max_valid_date)"
                        }
                    ]
                }
            ]
        }
    ]
}
;

/* Assign a temporary fileref named 'usercfg' */
filename usercfg temp;

/* Write json content to the target directory location */ 
data _null_ ;
    file usercfg ;
    length jsonstring $32767 ;
    jsonstring = symget('_hrr_user_config_json') ;
    jsonlen = klength(ktrim(kleft(jsonstring))) ;
    put jsonstring $varying. jsonlen ;
run ;

/* Write out the temp file to the log just to verify the contents */
data _null_;
    infile usercfg;
	input ;
    put "Start of the user config file in the log";
	put _infile_;
    put "End of the user config file in the log";
run;

/* Extract the fullpath of the temp file to a macro variable to pass as a parameter to the macro function */
%let _hrr_usercfg_fpath = %sysfunc(pathname(usercfg));
%put NOTE: &=_hrr_usercfg_fpath;

/* Execute MRR end-to-end information extraction */
%mrr_information_extraction(userConfig=&_hrr_usercfg_fpath, astoreDirpath=&_hrr_astore_dirpath., loglevel=&_hrr_debug_level.); 

/* Clear the temporary fileref - usercfg */
filename usercfg clear;

/* Proc import macro for xls and xlsx extensions */
%macro proc_import(exportFileType=, exportDirpath=, exportLibref=, tableName=);
        proc import
            datafile="&exportDirpath./&tableName..&exportFileType"
            out=&exportLibref..&tableName.
            dbms=&exportFileType.
            replace;
            getnames=YES;
            %if %kupcase(&exportFileType)=CSV %then %do;
                %put NOTE: Using guessingrows option to determine column types with exportFileType as: &exportFileType;
                guessingrows=5000;
            %end;
        run;
%mend;

/* Reset / Clear exportLibref if it already exists and assign using params */
%macro reset_assign_exportLibref(exportFileType=, exportDirpath=, exportLibref=);

    %local saslib_exists cas_sess_exist jsonlib_exists;

    /* Remove 'sasserver:' prefix from macrovar if it exists */
        /* %let exportDirpath = %sysfunc(scan(&_hrr_output_export_directory., -1, ':'));  */

    %put &=exportFileType;
    %put &=exportDirpath;
    %put &=exportLibref;

    /* Check if the exportLibref is currently assigned and unassign it, if needed */
    proc sql noprint;
        select count(distinct libname) 
            into: libref_exists 
            from dictionary.libnames 
            where kupcase(kstrip(libname))=kupcase(kstrip("&exportLibref"))
        ;
    quit;

    %if &libref_exists. > 0 %then %do;
        %put NOTE: Clearing existing exportLibref=&exportLibref.;
        libname &exportLibref. clear;
    %end;

    /* Assign libref based on export file type */

    %if &exportFileType.=sas7bdat %then %do;
        libname &exportLibref. "&exportDirpath";
        %put NOTE: sas7bdat output library created with libref - &exportLibref.;
    %end;

    %else %if &exportFileType.=sashdat %then %do;
        
        %let cas_sess_exist = %sysfunc(sessfound(&_SESSREF_));

        /* Use function to perform numerical comparison */
        %if %sysevalf(&cas_sess_exist. > 0) %then %do;

            %put CAS session already exists with a return code: &cas_sess_exist.;

            /* Explicitly drop cas library by name - MRR_OUT to avoid conflict with path based caslib _HRROUT_ */
            proc cas;
                table.dropCaslib / caslib="MRR_OUT";
            quit;

            caslib mycaslib sessref=&_SESSREF_ datasource=(srctype="path") path="&exportDirpath.";

            libname &exportLibref. cas caslib=mycaslib;
            
            /* Lift all the sashdat output tables in the caslib into memory */
            /* CAUTION: sashdat files names in casdata= option are case-sensitive and needs
            to be specified with exact case with which they are located on the server */

            proc casutil incaslib="mycaslib" outcaslib="mycaslib";
                load casdata="mrr_final_keyvalues.sashdat" casout="MRR_FINAL_KEYVALUES" replace;
                load casdata="mrr_final_docsummary.sashdat" casout="MRR_FINAL_DOCSUMMARY" replace;
                load casdata="mrr_final_pagesummary.sashdat" casout="MRR_FINAL_PAGESUMMARY" replace;
                load casdata="mrr_source_data_mapping.sashdat" casout="MRR_SOURCE_DATA_MAPPING" replace;
                load casdata="mrr_final_classification.sashdat" casout="MRR_FINAL_CLASSIFICATION" replace;
            quit;

            %put NOTE: sashdat output library created with libref - &exportLibref.;
        %end;
    %end;

    %else %if &exportFileType.=json %then %do;
        libname &exportLibref. json "&exportDirpath./MRR_NESTED_RESULTS.json";
        %put NOTE: json output library created with libref - &exportLibref.;
    %end;

    %else %if &exportFileType.=csv or &exportFileType.=xls or &exportFileType.=xlsx %then %do;

        libname &exportLibref. "/tmp";
        %proc_import(exportFileType=&exportFileType., exportDirpath=&exportDirpath., exportLibref=&exportLibref., tableName=MRR_FINAL_KEYVALUES);
        %proc_import(exportFileType=&exportFileType., exportDirpath=&exportDirpath., exportLibref=&exportLibref., tableName=MRR_FINAL_DOCSUMMARY);
        %proc_import(exportFileType=&exportFileType., exportDirpath=&exportDirpath., exportLibref=&exportLibref., tableName=MRR_FINAL_PAGESUMMARY);
        %proc_import(exportFileType=&exportFileType., exportDirpath=&exportDirpath., exportLibref=&exportLibref., tableName=MRR_SOURCE_DATA_MAPPING);
        %proc_import(exportFileType=&exportFileType., exportDirpath=&exportDirpath., exportLibref=&exportLibref., tableName=MRR_FINAL_CLASSIFICATION);

    %end;

%mend reset_assign_exportLibref;

%reset_assign_exportLibref(exportFileType=&_hrr_output_export_file_type., exportDirpath=&_hrr_export_dirpath., exportLibref=&_hrr_output_libref.);

/* Clean up global macro variables with common prefix */

%let _mrr_debug_flag_ = N;
%mrr_cleanup_global_mvars(mvarPrefix=_hrr);
%symdel _mrr_debug_flag_;

/* Need to assign _mrr_debug_flag_ to avoid error within mrr_cleanup_global_mvars macro */

/* Clear macro catalog libref - not working for some reason */

/* %sysmstoreclear; */

%put NOTE: The SDA-HRR medical information extraction process has completed successfully - output can be accessed from the _HRROUT_ libref.;

/* Delete user-defined SAS macros and SAS macro variables using nowarn option.  */

%symdel _hrr_astore_dirpath _hrr_macro_catalog_dirpath _hrr_input_source _hrr_src_filepath _hrr_export_dirpath _hrr_min_valid_date _hrr_max_valid_date / NOWARN;

%sysmacdelete proc_import;
%sysmacdelete reset_assign_exportLibref; 
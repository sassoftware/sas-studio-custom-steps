/* SAS templated code goes here */

/* -------------------------------------------------------------------------------------------*
   DuckDB - Introspect Parquet Metadata - Version 0.5.1

   This custom step extracts and outputs metadata from input parquet files. 
   A future plan is that, based on user parameters, the step modifies parquet reflecting in 
   changed metadata, particularly partitioning information and rowgroups to optimise query 
   performance.  
   
   It takes advantage of the SAS/ACCESS Interface to DuckDB and inbuilt functions to work 
   with parquet files.

   Author: Sundaresh Sankaran (original)
   Refactor: Polished after AI-assisted automation
   Version: 0.5.1 (16FEB2026)
*-------------------------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------------------------*
    User Parameters
    
    The parameters below allow customization of the aggregation operation,
    including the input file path, aggregation functions, columns to aggregate,
    grouping columns, and output table.
    
    Users can modify these parameters to suit their specific data and analysis needs.
* -------------------------------------------------------------------------------------------- */

/* Input option: 'single' for a single parquet file, 'multiple' for all parquet files in a folder */
/* %let input_option=single; */

/*  Directory or prefix containing parquet files  */
/* %let parquet_file_path=sasserver:/mnt/viya-share/data/parquet-test/ss-new/parquet-test/HMEQ_WITH_CUST.parquet; */

 
/* %let parquet_path=sasserver:/mnt/viya-share/data/parquet-test/ss-new/parquet-test; */


/*  Output table assigned to the Duck DB engine. Provide libname-qualified name if desired.  */
/* %let output_table=dukonce.TABLE_NUM_AGGS_DD; */




/* -----------------------------------------------------------------------------------------*
   Macros

   The macros below follow the structural conventions used in prior custom steps by author:

   - small utility macros for runtime triggers and error flags
   - a focused macro to build SQL strings and one to execute the Duck DB query
*------------------------------------------------------------------------------------------*/

/* -------------------------------------------------------------------------------------------* 
   Macro to initialize a run-time trigger global macro variable to run SAS Studio Custom Steps. 
   A value of 1 (the default) enables this custom step to run.  A value of 0 (provided by 
   upstream code) sets this to disabled.

   Input:
   1. triggerName: The name of the runtime trigger you wish to create. Ensure you provide a 
      unique value to this parameter since it will be declared as a global variable.

   Output:
   2. &triggerName : A global variable which takes the name provided to triggerName.
*-------------------------------------------------------------------------------------------- */

%macro _create_runtime_trigger(triggerName);
   %global &triggerName.;
   %if %sysevalf(%superq(&triggerName.)=, boolean)  %then %do;
      %put NOTE: Trigger macro variable &triggerName. does not exist. Creating it now.;
      %let &triggerName.=1;
   %end;
%mend _create_runtime_trigger;


/* -----------------------------------------------------------------------------------------* 
   Macro to create an error flag for capture during code execution.

   Input:
      1. errorFlagName: The name of the error flag you wish to create. Ensure you provide a 
         unique value to this parameter since it will be declared as a global variable.
      2. errorFlagDesc: A description to add to the error flag.

    Output:
      1. &errorFlagName : A global variable which takes the name provided to errorFlagName.
      2. &errorFlagDesc : A global variable which takes the name provided to errorFlagDesc.
*------------------------------------------------------------------------------------------ */

%macro _create_error_flag(errorFlagName, errorFlagDesc);

   %global &errorFlagName.;
   %let &errorFlagName.=0;
   %global &errorFlagDesc.;

%mend _create_error_flag;


/* -----------------------------------------------------------------------------------------* 
   Macro to identify whether a given folder location provided from a 
   SAS Studio Custom Step folder selector happens to be a SAS Content folder
   or a folder on the filesystem (SAS Server).

   Input:
   1. pathReference: A path reference provided by the file or folder selector control in 
      a SAS Studio Custom step.

   Output:
   1. _path_identifier: Set inside macro, a global variable indicating the prefix of the 
      path provided.

   Also available at: https://raw.githubusercontent.com/SundareshSankaran/sas_utility_programs/main/code/Identify%20SAS%20Content%20or%20Server/macro_identify_sas_content_server.sas

*------------------------------------------------------------------------------------------ */

%macro _identify_content_or_server(pathReference);
   %global _path_identifier;
   data _null_;
      call symput("_path_identifier", scan(%str(&pathReference.),1,":","MO"));
   run;
   %put NOTE: _path_identifier is &_path_identifier. ;
%mend _identify_content_or_server;

/* -----------------------------------------------------------------------------------------* 
   Macro to extract the path provided from a SAS Studio Custom Step file or folder selector.

   Input:
   1. pathReference: A path reference provided by the file or folder selector control in 
      a SAS Studio Custom step.

   Output:
   1. _sas_folder_path: Set inside macro, a global variable containing the path.

   Also available at: https://raw.githubusercontent.com/SundareshSankaran/sas_utility_programs/main/code/Extract%20SAS%20Folder%20Path/macro_extract_sas_folder_path.sas

*------------------------------------------------------------------------------------------ */

%macro _extract_sas_folder_path(pathReference);

   %global _sas_folder_path;

   data _null_;
      call symput("_sas_folder_path", scan(%str(&pathReference.),2,":","MO"));
   run;

%mend _extract_sas_folder_path;

/* -----------------------------------------------------------------------------------------* 
  Macro: _assign_input_file_path
  Purpose: Based on the type of input selected, assign either the value of a path to a single
           parquet file or a glob pointing to all parquet files in a folder.
   Output:
      1. &_input_file_path : A global variable which contains the resolved input file path.
*------------------------------------------------------------------------------------------ */

%macro _assign_input_file_path;
    %global _input_file_path;

    %if "&input_option."="single" %then %do;
        %let _input_file_path=&parquet_file_path.;
    %end;
    %if "&input_option."="multiple" %then %do;
        data _null_;
            call symput("_input_file_path",%str("&parquet_path./*.parquet"));
        run;
    %end;

    %put NOTE: The input file path has been set as "&_input_file_path.";

%mend _assign_input_file_path;



/* -----------------------------------------------------------------------------------------* 
  EXECUTION Macro: _dpm_execution_macro
  Purpose: Extract metadata and write to output table.
   Behavior: Connects to DuckDB, extracts metadata, creates output table.
*------------------------------------------------------------------------------------------ */

%macro _dpm_execution_macro;
    
   %put NOTE: Step 1 - Assign in-memory DuckDB libname.;

   %if &_duckdb_error_flag. = 0 %then %do;
      libname dukonce duckdb;
   %end;

   %put NOTE: Step 2 - Assign input file path macro variable.;

   %if &_duckdb_error_flag.=0 %then %do;
      %_assign_input_file_path;
   %end;

   
   %put NOTE: Step 3 - Identify if this file reference is on Server or Content.;

   %if &_duckdb_error_flag. = 0 %then %do;
      %_identify_content_or_server("&_input_file_path.");

      %if "&_path_identifier."="sasserver" %then %do;
         %put NOTE: Folder location prefixed with &_path_identifier. is on the SAS Server.;
      %end;

      %else %do;

         %let _duckdb_error_flag=1;
         %put ERROR: Please select a valid file on the SAS Server (filesystem). ;
         data _null_;
            call symputx("_duckdb_error_desc", "&_duckdb_error_desc. <-> Please select a valid file on the SAS Server (filesystem).");
         run;
      
      %end;

   %end;

   %put NOTE: Step 4 - Extract the path from the input_file_path macro variable.;

   %if &_duckdb_error_flag. = 0 %then %do;

      %_extract_sas_folder_path("&_input_file_path.");

      %if "&_sas_folder_path." = "" %then %do;

         %let _duckdb_error_flag = 1;
         %let _duckdb_error_desc = &_duckdb_error_desc. <-> The field is empty, please select a valid path  ;
         %put ERROR: &_duckdb_error_desc. ;

      %end;
      %else %do;
         %let file_path=&_sas_folder_path.;
         %put NOTE: Extracted file path is &file_path.;
      %end;
   %end;


    %if &_duckdb_error_flag. = 0 %then %do;
         %if "&input_option."="single" %then %do;
            %let file_path=&file_path.;
        %end;
        %if "&input_option."="multiple" %then %do;
            data _null_;
                call symput("file_path",%str("&file_path./*.parquet"));
            run;
        %end;
   %end;


   %put NOTE: Step 5 - Execute DuckDB metadata extraction and create output table.;

   %if &_duckdb_error_flag. = 0 %then %do;
        %put NOTE: Executing DuckDB metadata extraction query...;
        proc sql;
            connect using dukonce;
            create table &output_table. (replace=yes) as
            select * from connection to dukonce(
                select 
                * from parquet_metadata("&file_path.")
                
            );
        run;
        quit;
   %end;
   %else %do;
        %let _duckdb_error_desc = &_duckdb_error_desc. <-> Cannot execute DuckDB aggregation query; 
        %put ERROR: &_duckdb_error_desc.;
        %put NOTE: &_duckdb_error_flag.;
   %end;

   %if &_duckdb_error_flag. = 0 %then %do;
        %if &load_cas. = 1 %then %do;
            %put NOTE: Loading output table into CAS...;
            cas mySession sessopts=(caslib=public timeout=1800);

            /* === Use PROC CASUTIL to load and promote in one step === */
            proc casutil;
               droptable casdata="&target_tblname." incaslib="&target_caslib." quiet;
               droptable casdata="&target_tblname." incaslib="&target_caslib." quiet;
               load data=&output_table. casout="&target_tblname." outcaslib="&target_caslib." promote;
               run;
            quit;

            cas mySession terminate;
            %put NOTE: DuckDB metadata extraction and output table creation completed successfully.;
         %end;
   %end;
   %if "&input_option."="single" %then %do;
        %if &write_parquet.=1 %then %do;
            %if &_duckdb_error_flag.=0 %then %do;
                %put NOTE: Writing Parquet file ;
                %if "&order_by_cols."="" %then %do;
                    %let order_by_string=;
                %end;
                %else %do;
                    %let order_by_string=ORDER BY &order_by_cols.;
                %end;
                      
                %_identify_content_or_server("&output_parquet_folder.");

                %if "&_path_identifier."="sasserver" %then %do;
                    %put NOTE: Folder location prefixed with &_path_identifier. is on the SAS Server.;
                %end;

                %else %do;

                    %let _duckdb_error_flag=1;
                    %put ERROR: Please select a valid file on the SAS Server (filesystem). ;
                    data _null_;
                        call symputx("_duckdb_error_desc", "&_duckdb_error_desc. <-> Please select a valid output file on the SAS Server (filesystem).");
                    run;
                %end;

            %end;
            %if &_duckdb_error_flag. = 0 %then %do;
                %if "&output_parquet_name."="" %then %do;
                    %let _duckdb_error_flag = 1;
                    %let _duckdb_error_desc = &_duckdb_error_desc. <-> No parquet file name provided;
                    %put ERROR: &_duckdb_error_desc.;
                %end;
            %end;
            %if &_duckdb_error_flag.=0 %then %do;
                %_extract_sas_folder_path("&output_parquet_folder.");
                %if "&_sas_folder_path." = "" %then %do;

                    %let _duckdb_error_flag = 1;
                    %let _duckdb_error_desc = &_duckdb_error_desc. <-> The field is empty, please select a valid path  ;
                    %put ERROR: &_duckdb_error_desc. ;

                %end;
                %else %do;
                    %let output_file_path=&_sas_folder_path./&output_parquet_name.;
                    %put NOTE: Extracted file path for output file is &output_file_path.;
                %end;
            %end;
            %if &_duckdb_error_flag.=0 %then %do;
                proc sql;
                    connect using dukonce;
                    execute(
                        SET preserve_insertion_order=false;
                        COPY (SELECT * FROM "&file_path." &order_by_string.)
                            TO "&output_file_path." (
                                FORMAT PARQUET,
                                OVERWRITE,
                                &METADATA_OPTION_TBL_COL_1. &METADATA_OPTION_TBL_R1_C1.,
                                &METADATA_OPTION_TBL_COL_2. &METADATA_OPTION_TBL_R1_C2.,
                                &METADATA_OPTION_TBL_COL_3. &METADATA_OPTION_TBL_R1_C3.,
                                &METADATA_OPTION_TBL_COL_4. &METADATA_OPTION_TBL_R1_C4.,
                                STRING_DICTIONARY_PAGE_SIZE_LIMIT &METADATA_OPTION_TBL_R1_C5. 
                        
                                );
                    ) by dukonce;
            
                quit;
                %put NOTE: Output parquet file created succesfully;
            %end;
        %end;
   %end;
   %if &_duckdb_error_flag. = 1 %then %do;
        %let _duckdb_error_desc = &_duckdb_error_desc. <-> Cannot execute DuckDB aggregation query.; 
        %put ERROR: &_duckdb_error_desc.;
   %end;   

%mend _dpm_execution_macro;

/* -----------------------------------------------------------------------------------------* 
  END MACROS
*------------------------------------------------------------------------------------------ */

/* -----------------------------------------------------------------------------------------* 
  Execution Code
*------------------------------------------------------------------------------------------ */
%put NOTE: Starting duckdb metadata introspection program (v0.5.1)...;
%_create_error_flag(_duckdb_error_flag, _duckdb_error_desc);

%put NOTE: Step 0 - 0.1 - Error Flag & Desc variable created.;

%_create_runtime_trigger(_duckdb_run_trigger);

%put NOTE: Step 0 - 0.2 - Runtime trigger value is &_duckdb_run_trigger.;

%if &_duckdb_run_trigger. = 1 %then %do;
   %_dpm_execution_macro;
%end;

%if &_duckdb_run_trigger. = 0 %then %do;
   %put NOTE: This step has been disabled. Nothing to do.;
%end;

%if &_duckdb_error_flag. = 1 %then %do;
   %put ERROR: DuckDB metadata introspection program ended with errors. Description: &_duckdb_error_desc.;
%end;

/* ----------------------------------------------------------------------------------* 
    Cleanup 
*------------------------------------------------------------------------------------------ */
%put NOTE: Step CLEANUP - CLEANUP.1 - Clean up global macro variables created during execution;



%if %symexist(_input_file_path) %then %do;
   %symdel _input_file_path;
%end;

%if %symexist(_SAS_FOLDER_PATH) %then %do;
   %symdel _SAS_FOLDER_PATH;
%end;

%if %symexist(_PATH_IDENTIFIER) %then %do;
   %symdel _PATH_IDENTIFIER;
%end;


%if %symexist(_duckdb_run_trigger) %then %do;
   %symdel _duckdb_run_trigger;
%end;

%if %symexist(_duckdb_run_trigger) %then %do;
   %symdel _duckdb_run_trigger;
%end;

%if %symexist(_duckdb_run_trigger) %then %do;
   %symdel _duckdb_run_trigger;
%end;

%if %symexist(_duckdb_error_flag) %then %do;
   %symdel _duckdb_error_flag;
%end;

%if %symexist(_duckdb_error_desc) %then %do;
   %symdel _duckdb_error_desc;
%end;


/* Remove helper macros from global symbol table */
%put NOTE: Step CLEANUP - CLEANUP.2 - Delete helper macros from global symbol table.;

%sysmacdelete _create_runtime_trigger;
%sysmacdelete _create_error_flag;

%sysmacdelete _identify_content_or_server;
%sysmacdelete _assign_input_file_path;
%sysmacdelete _dpm_execution_macro;
%sysmacdelete _extract_sas_folder_path;

%put NOTE: duckdb metadata introspection program (v0.5.1) completed.;
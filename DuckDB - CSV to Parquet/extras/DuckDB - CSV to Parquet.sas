/************************************************************************
DuckDB - CSV to Parquet Conversion

Purpose: This SAS program utilizes SAS/ACCESS to DuckDB to ingest a CSV file 
         and convert it into a Parquet file.
Input Parameters:
- csv_file_path: Full path to the source CSV file (macro variable)
- has_headers: Boolean (TRUE/FALSE) indicating if the CSV has a header row (macro variable)
- parquet_output_path: Folder location for the output Parquet file (macro variable)
- parquet_file_name: Name/prefix for the output Parquet file (macro variable)

Created: Sundaresh Sankaran
Version: 0.1.0 (21OCT2026)
************************************************************************/;

/* Define macro variables for input parameters */
%let csv_file_path = &csv_file_path.;                /* e.g., '/data/input.csv' */
%let has_headers = &has_headers.;                    /* TRUE or FALSE */
%let parquet_output_path = &parquet_output_path.;    /* e.g., '/data/output/' */
%let parquet_file_name = &parquet_file_name. ;       /* e.g., 'output_data WITHOUT the .parquet' */


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
  EXECUTION Macro: _dcp_execution_macro
  Purpose: Extract metadata and write to output table.
   Behavior: Connects to DuckDB, extracts metadata, creates output table.
*------------------------------------------------------------------------------------------ */

%macro _dcp_execution_macro;
    
   %put NOTE: Step 1 - Assign in-memory DuckDB libname.;

   %if &_duckdb_error_flag. = 0 %then %do;
      libname dukonce duckdb database=":memory::mydb";;
   %end;
   
   %put NOTE: Step 2 - Identify if input file reference is on Server or Content.;

   %if &_duckdb_error_flag. = 0 %then %do;
      %_identify_content_or_server("&csv_file_path.");

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

   %put NOTE: Step 3 - Extract the path from the csv_file_path macro variable.;

   %if &_duckdb_error_flag. = 0 %then %do;

      %_extract_sas_folder_path("&csv_file_path.");

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

   %put NOTE: Step 4 -  Check if parquet_output_path is on Server or Content;

   %if &_duckdb_error_flag. = 0 %then %do;
      %_identify_content_or_server("&parquet_output_path.");

      %if "&_path_identifier."="sasserver" %then %do;
         %put NOTE: Folder location prefixed with &_path_identifier. is on the SAS Server.;
      %end;

      %else %do;

         %let _duckdb_error_flag=1;
         %put ERROR: Please select a valid location on the SAS Server (filesystem). ;
         data _null_;
            call symputx("_duckdb_error_desc", "&_duckdb_error_desc. <-> Please select a valid file on the SAS Server (filesystem).");
         run;
      
      %end;

   %end;

   %put NOTE: Step 5 - Extract the path from the parquet_output_path macro variable.;

   %if &_duckdb_error_flag. = 0 %then %do;

      %_extract_sas_folder_path("&parquet_output_path.");

      %if "&_sas_folder_path." = "" %then %do;

         %let _duckdb_error_flag = 1;
         %let _duckdb_error_desc = &_duckdb_error_desc. <-> The field is empty, please select a valid path  ;
         %put ERROR: &_duckdb_error_desc. ;

      %end;
      %else %do;
         %let parquet_file_path=&_sas_folder_path.;
         %put NOTE: Extracted file path is &parquet_file_path.;
      %end;
   %end;

   %put NOTE: Step 6 - Extract and Load.;

   %if &_duckdb_error_flag. = 0 %then %do;
        %put NOTE: Executing DuckDB-based ELT...;
        /* Connect to DuckDB */
        proc sql;
            connect using dukonce;
            
            execute(
                /* 
                Using DuckDB's read_csv_auto and COPY command to export to Parquet.
                header=&has_headers handles the column detection.
                */
                COPY (
                    SELECT * FROM read_csv_auto("&file_path.", 
                                                header=&has_headers, 
                                                union_by_name=true)
                ) TO "&parquet_file_path./&parquet_file_name..parquet" 
                (FORMAT PARQUET, OVERWRITE TRUE);
            ) by dukonce;

            disconnect from dukonce;
        quit;
   %end;
   %else %do;
        %let _duckdb_error_desc = &_duckdb_error_desc. <-> Cannot execute DuckDB ELT query; 
        %put ERROR: &_duckdb_error_desc.;
        %put NOTE: &_duckdb_error_flag.;
   %end;

   

%mend _dcp_execution_macro;


/************************************************************************
EXECUTION CODE
************************************************************************/;


%put NOTE: Starting DuckDB-controlled ELT ...;
%_create_error_flag(_duckdb_error_flag, _duckdb_error_desc);

%put NOTE: Step 0 - 0.1 - Error Flag & Desc variable created.;

%_create_runtime_trigger(_duckdb_run_trigger);

%put NOTE: Step 0 - 0.2 - Runtime trigger value is &_duckdb_run_trigger.;

%if &_duckdb_run_trigger. = 1 %then %do;
   %_dcp_execution_macro;
%end;

%if &_duckdb_run_trigger. = 0 %then %do;
   %put NOTE: This step has been disabled. Nothing to do.;
%end;

%if &_duckdb_error_flag. = 1 %then %do;
   %put ERROR: DuckDB ELT program ended with errors. Description: &_duckdb_error_desc.;
%end;

/* ----------------------------------------------------------------------------------* 
    Cleanup 
*------------------------------------------------------------------------------------------ */
%put NOTE: Step CLEANUP - CLEANUP.1 - Clean up global macro variables created during execution;

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
%sysmacdelete _dcp_execution_macro;
%sysmacdelete _extract_sas_folder_path;

%put NOTE: CSV to Parquet step completed.;

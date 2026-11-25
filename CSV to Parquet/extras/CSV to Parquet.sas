/************************************************************************
DuckDB - CSV to Parquet Conversion

Purpose: This SAS program utilizes SAS/ACCESS Interface to DuckDB to ingest a CSV file 
         and convert it into a Parquet file.
Input Parameters:
- input_file_location: Option (folder,s3,web) indicating where the input CSV file(s) are located (macro variable)
- csv_folder_path: if input_file_location is "folder", full path to the folder containing source CSV files (macro variable)
- csv_file_pattern: A glob pattern which may include wildcards describing source CSV files (macro variable)
- s3_path: If input_file_location is "s3", full path to the S3 bucket containing source CSV files (macro variable)
- url_path: If input_file_location is "web", full URL path to the source CSV file (macro variable)
- has_headers: Boolean (TRUE/FALSE) indicating if the CSV has a header row (macro variable)

Prerequisites for S3 ingestion:
- Ensure you have set the following environmental variables to hold S3 bucket credentials.  These are identified by 
  the credential_chain provider in DuckDB automatically.  At a minimum,
  - AWS_ACCESS_KEY_ID
  - AWS_SECRET_ACCESS_KEY
  and if you're using short-term tokens for the session, 
  - AWS_SESSION_TOKEN

  (A standard way is to set options through option set=VAR=VALUE; SAS statements)

Output specification:
- parquet_output_path: Folder location for the output Parquet file (macro variable)
- parquet_file_name: Name/prefix for the output Parquet file (macro variable)
- save_rejects: Whether to save rejects or not (macro variable)
- ignore_errors: Whether to skip rows that cause parsing or casting errors (macro variable)
- union_by_name: Whether to combine multiple schemas based on column names (default false) (macro variable)
If you do choose to save rejects,
- rejects_data_table: Table containing rejected record details at a line and scan level
- rejects_scan_table: Table containing metadata about the rejected records.

Created: Sundaresh Sankaran
Version: 1.0.0 (23NOV2026)
************************************************************************/;

/* -----------------------------------------------------------------------------------------*
   Set parameter values (edit below block only if testing)

   to test the program, edit the macro variables below to point to your specfied values.
   For example, if you wish to specify a folder on the SAS Server, set input_file_location to folder
   and provide the csv_folder_path and csv_file_pattern accordingly.

   %let input_file_location = folder;  

   and in the dependent_macrovars_setting macro, 
   %let csv_folder_path=sasserver:/your_foldder_path 
   %let csv_file_pattern=an_example.csv;
*------------------------------------------------------------------------------------------*/


/* Define macro variables (including nested in macros wherre necessary) for input parameters */

%let input_file_location = &input_file_location.;  /* e.g., 'folder', 's3', 'web' */

%macro dependent_macrovars_setting;
    %if "&input_file_location."="folder" %then %do;
        %let csv_folder_path = &csv_folder_path.;                /* e.g., '/data/' */
        %let csv_file_pattern = &csv_file_pattern.;              /* e.g., 'input.csv' / '*.csv' */
    %end;
    %else %if "&input_file_location."="s3" %then %do;
        %let s3_path = &s3_path.;      
        %let csv_file_pattern = &csv_file_pattern.;               /* e.g., 's3://bucket-name/path/' */
    %end;
    %else %if "&input_file_location."="web" %then %do;
        %let url_path = &url_path.;                              /* e.g., 'https://example.com/data/input.csv' */
    %end;
    %else %do;
        %put ERROR: Invalid input_file_location specified. Please choose 'folder', 's3', or 'web'.;
    %end;
%mend dependent_macrovars_setting;

%dependent_macrovars_setting;

%let has_headers = &has_headers.;                    /* TRUE or FALSE */
%let parquet_output_path = &parquet_output_path.;    /* e.g., '/data/output/' */
%let parquet_file_name = &parquet_file_name. ;       /* e.g., 'output_data WITHOUT the .parquet' */
%let ignore_errors = &ignore_errors.;                  /* TRUE or FALSE */;
%let union_by_name = &union_by_name.;                  /* TRUE or FALSE */;

%macro set_union_rejects_relationship;
    %if "&union_by_name."="0" %then %do;
        %let save_rejects = &save_rejects.;                  /* TRUE or FALSE */;
        %if "&save_rejects."="1" %then %do;
            %let rejects_data_table=&rejects_data_table.;
            %let rejects_scan_table=&rejects_scan_table.;
            %put NOTE: The Rejects table is &rejects_data_table.;
            %put NOTE: The Rejects table is &rejects_scan_table.;
        %end;
    %end;
%mend set_union_rejects_relationship;

%set_union_rejects_relationship;



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
    

    %if "&save_rejects."="1" %then %do;

        %let rejects_data_table=&rejects_data_table.;
        %let rejects_scan_table=&rejects_scan_table.;
        %put NOTE: The Rejects table is &rejects_data_table.;
        %put NOTE: The Rejects table is &rejects_scan_table.;
        
    %end;


   %put NOTE: Step 1 - Assign in-memory DuckDB libname.;

   %if &_duckdb_error_flag. = 0 %then %do;
      libname dukonce duckdb database=":memory::mydb";;
   %end;

   %put NOTE: Step 2 - Additional settings based on input file location.;

   %if &_duckdb_error_flag. = 0 %then %do;
   
      %if "&input_file_location."="folder" %then %do;
         %put NOTE: Input file location is a folder on the SAS Server.;
         %put NOTE: Step 2.1.1 - Identify if input folder reference is on Server or Content.;
         %_identify_content_or_server("&csv_folder_path.");

         %if "&_path_identifier."="sasserver" %then %do;
            %put NOTE: Folder location prefixed with &_path_identifier. is on the SAS Server.;
         %end;

         %else %do;

            %let _duckdb_error_flag=1;
            %put ERROR: Please select a valid folder on the SAS Server (filesystem). ;
            data _null_;
               call symputx("_duckdb_error_desc", "&_duckdb_error_desc. <-> Please select a valid file on the SAS Server (filesystem).");
            run;
         
         %end;
         
         %put NOTE: Step 2.1.2 - Extract the path from the csv_folder_path macro variable.;
         %if &_duckdb_error_flag. = 0 %then %do;

            %_extract_sas_folder_path("&csv_folder_path.");

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
      %end;

      %else %if "&input_file_location."="s3" %then %do;
         %put NOTE: Input file location is an S3 bucket.;
         %put NOTE: Step 2.2.1 - Load credentials  FOR S3 environment.;
         %put NOTE: AWS region is &s3_aws_region.;
         proc sql;
            connect using dukonce;
            execute(
               INSTALL httpfs;
               LOAD httpfs;
               INSTALL aws;
               LOAD aws;


               CREATE OR REPLACE SECRET s3_read (
                  TYPE s3,
                  PROVIDER credential_chain,
                  CHAIN 'env;config',
                  REGION "&s3_aws_region."
               );

            ) by dukonce;
            disconnect from dukonce;
         quit;
         %let file_path=&s3_path.;
         %put NOTE: Extracted file path is &file_path.;

      %end;

      %else %if "&input_file_location."="web" %then %do;
         %put NOTE: Input file location is a web URL.;
         %put NOTE: Step 2.3.1 - Load extensions to readd from http file systems.;
         proc sql;
            connect using dukonce;
            execute(
               INSTALL httpfs;
               LOAD httpfs;
            ) by dukonce;
            disconnect from dukonce;
         quit;
      %end;

      %else %do;
         %let _duckdb_error_flag=1;
         %put ERROR: Please select a valid input file location (folder, s3, or web). ;
         data _null_;
            call symputx("_duckdb_error_desc", "&_duckdb_error_desc. <-> Please select a valid input file location (folder, s3, or web).");
         run;
      
      %end;
   %end;




   %put NOTE: Step 3 -  Check if parquet_output_path is on Server or Content;

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

   %put NOTE: Step 4 - Extract the path from the parquet_output_path macro variable.;

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

   %put NOTE: Step 5 - Construct input file path based on parameters provided;

   %if &_duckdb_error_flag. = 0 %then %do;
      %let slash=%str(/);
      %if "&input_file_location."="folder" %then %do;
         %if "&csv_file_pattern." = "" %then %do;
            %let csv_file_pattern = %str(*.csv);
         %end;
      %end;
      %if "&input_file_location."="s3" %then %do;
         %if "&csv_file_pattern." = "" %then %do;
            %let csv_file_pattern = %str(*.csv);
         %end;
         %let htap = %sysfunc(reverse(&s3_path.));
         /* Adjust the S3 path to remove a trailing slash */;
         %if "%substr(&htap.,1,1)"="/" %then %do;
            %let s3_path=%substr(&s3_path.,1,%length(&s3_path.)-1);
            %let htap=%sysfunc(reverse(&s3_path.));
            %put NOTE: The trailing slash in the S3 path has been removed to facilitate proper path formation.;
         %end;
         %let possible_extension = %sysfunc(scan("&htap.",1,"."));
         %put %length(&possible_extension.);
         %put %length(&htap.);
         %if %length(&possible_extension.) = %length(&htap.) %then %do;
            /* kept blank for a do-nothing, but can change later*/;
         %end;
         %else %do;
         /* This condition is a strong (but not comprehensive) indication of an extension used in the file path */;
            %let slash=;
            %let csv_file_pattern=;
            %put NOTE: The CSV file pattern and artificial trailing forward slash have been removed due to a strong indication of an extension used in the file path.;
         %end;

         %let file_path=&s3_path.;
      %end;
      
      %if "&input_file_location."="web" %then %do;
         %let slash=;
         %let csv_file_pattern=;
         %let file_path=&url_path.;
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
                    SELECT * FROM read_csv_auto("&file_path.&slash.&csv_file_pattern.", 
                                                %if "&ignore_errors."="1" %then %do;
                                                    ignore_errors=&ignore_errors.::BOOLEAN,
                                                %end;
                                                header=&has_headers.::BOOLEAN, 
                                                union_by_name=&union_by_name.::BOOLEAN
                                                %if "&union_by_name."="0" %then %do;
                                                    , store_rejects=&save_rejects.::BOOLEAN 
                                                %end;
                                                )
                ) TO "&parquet_file_path./&parquet_file_name..parquet" 
                (FORMAT PARQUET, OVERWRITE TRUE);

                %if "&union_by_name."="0" %then %do;    
                    %if "&save_rejects."="1" %then %do;
                        COPY reject_errors TO "&parquet_file_path./&rejects_data_table..parquet"  (FORMAT PARQUET, OVERWRITE TRUE);
                        COPY reject_scans TO "&parquet_file_path./&rejects_scan_table..parquet"  (FORMAT PARQUET, OVERWRITE TRUE);
                    %end;
                %end;

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

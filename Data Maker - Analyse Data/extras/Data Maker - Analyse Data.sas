/* SAS templated code goes here */

/* -------------------------------------------------------------------------------------------*
   Data Maker - Analyse Data

   This SAS program analyses Parquet input files using DuckDB, a typical (but by NO means limiting)
   use case being analysis prior to ingestion into SAS Data Maker for synthetic data generation.
   The analysis job informs data configuration decisions made during synthetic data generation.

   Author: [Sundaresh Sankaran](sundaresh.sankaran@sas.com)
   Version: 0.2.0 (2026-01-23)
*-------------------------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------------------------*
    User Parameters
    
    The parameters below allow customization, debugging and testing of the program.
    
    Users can modify these parameters to run standalone and debug the program.
    Uncomment and modify the parameters as needed.
    
    When running as part of a SAS Studio Custom Step, these parameters will be
    provided by upstream code and should remain commented out.
* -------------------------------------------------------------------------------------------- */;

/* Input option: single or multiple */
/* %let input_option=multiple;  */

/*  Directory or prefix containing parquet files  */;
/* data _null_;  */
/*   call symput("parquet_path","sasserver:/mnt/viya-share/data/parquet-test/ss-new/parquet-test" );; */
/* run;  */

/* %let parquet_file_path=sasserver:/mnt/viya-share/data/parquet-test/ss-new/parquet-test/HMEQ_WITH_CUST.parquet;  */

/* Output table assigned to the DuckDB engine. Provide libname-qualified name if desired. */
/* %let output_table = WORK.TEMP_RESULTS;  */

/* -----------------------------------------------------------------------------------------*
   Macros

   The macros below follow the structural conventions used in prior custom steps by author:

   - small utility macros for runtime triggers and error flags
   
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
 Execution Macro:
 Main macro called by execution control to analyse parquet files using DuckDB.
*------------------------------------------------------------------------------------------ */

%macro _dm_analysis_parquet(output_table=);

   /* -----------------------------------------------------------------------------------------* 
   Create a libname backed by the DuckDB engine
   *------------------------------------------------------------------------------------------ */
   
   %put NOTE: Step 1 - Assign in-memory DuckDB libname.;

   %if &_dm_analysis_error_flag. = 0 %then %do;
      libname DUKINHEL duckdb;;
   %end;

   %put NOTE: Step 2 - Assign input file path macro variable.;

    %if &_dm_analysis_error_flag.=0 %then %do;
      %_assign_input_file_path;
   %end;
   

   %put NOTE: Step 3 - Identify if this file reference is on Server or Content.;

   %if &_dm_analysis_error_flag. = 0 %then %do;
      %_identify_content_or_server("&_input_file_path.");

      %if "&_path_identifier."="sasserver" %then %do;
         %put NOTE: Folder location prefixed with &_path_identifier. is on the SAS Server.;
      %end;

      %else %do;

         %let _dm_analysis_error_flag=1;
         %put ERROR: Please select a valid file on the SAS Server (filesystem). ;
         data _null_;
            call symputx("_dm_analysis_error_desc", "Please select a valid file on the SAS Server (filesystem).");
         run;
      
      %end;
   %end;  

   %put NOTE: Step 4 - Extract the path from the input_file_path macro variable.;

   %if &_dm_analysis_error_flag. = 0 %then %do;

      %_extract_sas_folder_path("&_input_file_path.");

      %if "&_sas_folder_path." = "" %then %do;

         %let _dm_analysis_error_flag = 1;
         %let _dm_analysis_error_desc = The field is empty, please select a valid path  ;
         %put ERROR: &_dm_analysis_error_desc. ;

      %end;
      %else %do;
         %let file_path=&_sas_folder_path.;
         %put NOTE: Extracted file path is &file_path.;
      %end;
   %end;   

   %if &_dm_analysis_error_flag. = 0 %then %do;
         %if "&input_option."="single" %then %do;
            %let file_path=&file_path.;
        %end;
        %if "&input_option."="multiple" %then %do;
            data _null_;
                call symput("file_path",%str("&file_path./*.parquet"));
            run;
        %end;
   %end;

   /* -----------------------------------------------------------------------------------------* 
   Extract columns from parquet metadata and schema
   *------------------------------------------------------------------------------------------ */
   %if &_dm_analysis_error_flag. = 0 %then %do;
      %put NOTE: Step 5 - Extract parquet metadata and schema from files in &file_path..;
      proc sql;
         connect using DUKINHEL;
         create table DUKINHEL.metadata_schema_table (replace=yes) as 
            select * from
               connection to DUKINHEL(
                  SELECT
                     a.*,b.* 
                  FROM
                     (
                        SELECT 
                           *
                        FROM 
                           parquet_metadata("&file_path.") 
                     ) a 

                     JOIN

                     (
                        SELECT 
                           *
                        FROM 
                           parquet_schema("&file_path.") 
                     ) b
                  ON 
                     a.file_name=b.file_name 
                     AND 
                     a.path_in_schema = b.name 
                     AND
                     a.type = b.type
               );
      quit;
   %end;

   /* -----------------------------------------------------------------------------------------* 
   Build SQL aggregation strings
   *------------------------------------------------------------------------------------------ */
   %if &_dm_analysis_error_flag. = 0 %then %do;
      %put NOTE: Step 6 - Build SQL aggregation strings for each column in parquet files.;

      data DUKINHEL.metadata_table_sql (keep = sql_full_string replace=yes);
         set DUKINHEL.metadata_schema_table;
         length sql_full_string VARCHAR(*);
         sql_leader_string = "SELECT '"||trim(file_name)||"' as file_path, parse_filename('"||trim(file_name)||"') as filename, '"||trim(path_in_schema)||"' as column_name";
         sql_query_num =  " COUNT(*) as total_count";
         sql_query_cardinality = "COUNT(DISTINCT "||'"'||trim(path_in_schema)||'"'||") as cardinality";
         sql_query_missing = "COUNT(CASE WHEN "||'"'||trim(path_in_schema)||'"'||" IS NULL THEN 1 END) as null_values";
         sql_query_max = "MAX("||'"'||trim(path_in_schema)||'"'||") as max_value";
         sql_query_min = "MIN("||'"'||trim(path_in_schema)||'"'||") as min_value";
         sql_query_median = "MEDIAN("||'"'||trim(path_in_schema)||'"'||") as median_value";
         if converted_type = "DATE" then do;
            sql_query_avg = "AVG(date_diff('day', DATE '1970-01-01', CAST("||'"'||trim(path_in_schema)||'"'||" AS DATE))) as avg_value";
         end;
         else if converted_type = "TIMESTAMP" then do;
            sql_query_avg = "AVG(date_diff('millisecond', TIMESTAMP '1970-01-01 00:00:00',"||'"'||trim(path_in_schema)||'"'||")::DOUBLE) as avg_value";
         end;
         else if converted_type = "TIMESTAMP_MICROS" then do;
            sql_query_avg = "AVG(date_diff('microsecond', TIMESTAMP '1970-01-01 00:00:00',"||'"'||trim(path_in_schema)||'"'||")::DOUBLE) as avg_value";
         end;
         else if type ne "BYTE_ARRAY" then do;
            sql_query_avg = "AVG("||'"'||trim(path_in_schema)||'"'||") as avg_value";
         end; 
         else do;
            sql_query_avg = "SUM(NULL) as avg_value";
         end;
         sql_trailer_string = " from '"||trim(file_name)||"'";
         ARRAY sql_strings(8) sql_leader_string sql_query_num sql_query_cardinality sql_query_missing sql_query_min sql_query_median sql_query_avg sql_query_max ;
         do i = 1 to 8;
            if i = 1 then sql_full_string = trim(sql_strings(i));
            else sql_full_string = trim(sql_full_string)||", "||trim(sql_strings(i));
         end;
         sql_full_string = trim(sql_full_string)||" "||trim(sql_trailer_string);
      run;
   %end;

   /* -----------------------------------------------------------------------------------------* 
   Generate final SQL string to execute
   *------------------------------------------------------------------------------------------ */
   %if &_dm_analysis_error_flag. = 0 %then %do;
      %put NOTE: Step 7 - Generate final SQL string to execute. ;

      proc sql;
         connect using DUKINHEL;
         execute(
            CREATE OR REPLACE TABLE METADATA_TABLE_SQL AS
               SELECT DISTINCT sql_full_string FROM METADATA_TABLE_SQL;
         ) by DUKINHEL;
      quit;

      data _null_;
        set DUKINHEL.metadata_table_sql end = EOF;
        call symput("sql_string_"||compress(put(_n_,8.)),sql_full_string);
        if EOF then call symputx("nbr_queries",_n_);
      run;

   %end;

   /* -----------------------------------------------------------------------------------------*
   Symbolgen option turned on to transparently show the final SQL string being executed
   *------------------------------------------------------------------------------------------ */
   %if &_dm_analysis_error_flag. = 0 %then %do;
      %put NOTE: Step 8 - Execute final SQL string to generate output table. ;
      options symbolgen;

   /* -----------------------------------------------------------------------------------------*
   Execute final SQL string to generate output table
   *------------------------------------------------------------------------------------------ */

      proc sql;
         connect using DUKINHEL;
         execute(
            CREATE TABLE IF NOT EXISTS RESULT_ANALYSIS (
                file_path	VARCHAR	,	 	 	 
                filename	VARCHAR	,	 	 	 
                column_name	VARCHAR	,	 	 	 
                total_count	BIGINT	,	 	 	 
                cardinality	BIGINT	,	 	 	 
                null_values	BIGINT	,	 	 	 
                min_value	VARCHAR	,	 	 	 
                median_value	VARCHAR	,	 	 	 
                avg_value	DOUBLE	,	 	 	 
                max_value	VARCHAR		
            );

            %do i = 1 %to &nbr_queries.;
            INSERT INTO RESULT_ANALYSIS 
                &&sql_string_&i. ;
            %end;

         ) by DUKINHEL;

      quit;

    %end;

    /* -----------------------------------------------------------------------------------------*
    Print final output table to results window
    *------------------------------------------------------------------------------------------ */

   %if &_dm_analysis_error_flag. = 0 %then %do;
 
     %put NOTE: Step 9 - Create output table ;
     
     data &output_table.;
        set DUKINHEL.RESULT_ANALYSIS;
      run;
      
      options nosymbolgen;

   %end;
   /* -----------------------------------------------------------------------------------------*
   Print final output table to results window
   *------------------------------------------------------------------------------------------ */
   %if &_dm_analysis_error_flag. = 0 %then %do;

      %put NOTE: Step 10 - Print final output table to results window. ;

      proc print data=&output_table.;
      run;

      libname DUKINHEL clear;

   %end;
    
%mend _dm_analysis_parquet;



/* -----------------------------------------------------------------------------------------* 
  Execution Code
*------------------------------------------------------------------------------------------ */
%put NOTE: Starting Data Maker Analysis program (v0.2.0)...;
%_create_error_flag(_dm_analysis_error_flag, _dm_analysis_error_desc);

%put NOTE: Step 0 - 0.1 - Error Flag & Desc variable created.;

%_create_runtime_trigger(_dm_analysis_run_trigger);

%put NOTE: Step 0 - 0.2 - Runtime trigger value is &_dm_analysis_run_trigger.;

%if &_dm_analysis_run_trigger. = 1 %then %do;
   %put NOTE: Step EXECUTION - Running Data Maker Analysis program...;

    %_dm_analysis_parquet(output_table=&output_table.);
   
%end;

%if &_dm_analysis_run_trigger. = 0 %then %do;
   %put NOTE: This step has been disabled. Nothing to do.;
%end;

%put NOTE:Error &_dm_analysis_error_flag.:&_dm_analysis_error_desc.;
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



%if %symexist(group_by_clause) %then %do;
   %symdel group_by_clause;
%end;

%if %symexist(_dm_analysis_run_trigger) %then %do;
   %symdel _dm_analysis_run_trigger;
%end;

%if %symexist(_dm_analysis_error_flag) %then %do;
   %symdel _dm_analysis_error_flag;
%end;

%if %symexist(_dm_analysis_error_desc) %then %do;
   %symdel _dm_analysis_error_desc;
%end;


/* Remove helper macros from global symbol table */
%put NOTE: Step CLEANUP - CLEANUP.2 - Delete helper macros from global symbol table.;

%sysmacdelete _create_runtime_trigger;
%sysmacdelete _create_error_flag;
%sysmacdelete _identify_content_or_server;
%sysmacdelete _assign_input_file_path;
%sysmacdelete _dm_analysis_parquet;
%sysmacdelete _extract_sas_folder_path;

%put NOTE: Data Maker analysis program (v0.2.0) completed.;

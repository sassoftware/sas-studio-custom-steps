/* SAS templated code goes here */

/* -------------------------------------------------------------------------------------------*
   DuckDB - Aggregate Parquets - Version 1.1.4

   This program dynamically builds a DuckDB SQL aggregation query and
   pushes it down to Duck DB through the SAS/ACCESS Interface to Duck DB.
   
   This version refactored to follow the structural patterns, macro usage and
   verbose commenting style used by the "LLM - Azure OpenAI In-context Learning.sas"
   program while preserving the original purpose and logic.

   Author: Sundaresh Sankaran (original)
   Refactor: Polished after AI-assisted automation
   Version: 1.1.4 (2025-12-15)
*-------------------------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------------------------*
    User Parameters
    
    The parameters below allow customization of the aggregation operation,
    including the input file path, aggregation functions, columns to aggregate,
    grouping columns, and output table.
    
    Users can modify these parameters to suit their specific data and analysis needs.
* -------------------------------------------------------------------------------------------- */

/*  Directory or prefix containing parquet files  */
/* %let parquet_file_path=sasserver:/mnt/viya-share/data/parquet-test/ss-new/parquet-test/HMEQ_WITH_CUST.parquet; */

 

/* Aggregation function list: define count then each function name macro */
/* %let function_name_count=4; */
/* %let function_name_1=AVG; */
/* %let function_name_2=SUM; */
/* %let function_name_3=STDDEV; */
/* %let function_name_4=COUNT; */

/* Comma-separated list of columns to aggregate and group-by columns (space or comma separated OK)  */
/* %let agg_columns=DELINQ DEBTINC;                    */
/* %let group_by_columns= ;                  */

/*  Output table assigned to the Duck DB engine. Provide libname-qualified name if desired.  */
/* %let output_table=dukonce.TABLE_NUM_AGGS_DD; */


/* -----------------------------------------------------------------------------------------*
   Macros

   The macros below follow the structural conventions used in the LLM-Azure example:

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
  Macro: _create_sql_string
  Purpose: Build the comma-separated list of aggregate expressions and the
           group-by column list suitable for injection into the DuckDB SQL.
  Behavior: Does not execute SQL; only constructs macro variables:
            - &final_agg_columns.  (aggregations with aliases)
            - &final_group_by_columns. (comma-separated grouping columns)
*------------------------------------------------------------------------------------------ */

%macro _create_sql_string;

    %global final_agg_columns final_group_by_columns group_by_clause;
    %local i function_name;
    %let final_agg_columns=;

    %do i = 1 %to &function_name_count.;

        %let function_name = &&function_name_&i.;

        data _null_;
        length new $32767.;
        /* Surrounding double-quotes let the macro variable &function_name insert into the pattern */
        new = prxchange('s/\s+/,/i', -1, trim("&agg_columns."));
        new = prxchange("s/\b\w+\b/&function_name.($0) AS &function_name._$0/i", -1, new );       
        call symput("new_agg_columns_&i.", trim(new));
        run;

        %if &i = 1 %then %do;
            %let final_agg_columns=&&new_agg_columns_&i..;
        %end;
        %else %do;
            %let final_agg_columns=&final_agg_columns., &&new_agg_columns_&i..;
        %end;

    %end;



/* Create GROUP BY clause only if group-by columns are provided */
    %if "&group_by_columns." = "" %then %do;
      %let final_group_by_columns=;
      %let group_by_clause=;
    %end;
    %else %do;
    /* Convert whitespace-separated group-by columns to comma-separated list */
         data _null_;
            new = prxchange('s/\s+/,/i', -1, "&group_by_columns.");
            call symput('final_group_by_columns', new);
         run;
        %let group_by_clause=group by &final_group_by_columns.;
        %let final_group_by_columns=&final_group_by_columns.,;
    %end;
    
%mend _create_sql_string;


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
      call symput("_path_identifier", scan("&pathReference.",1,":","MO"));
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
      call symput("_sas_folder_path", scan("&pathReference.",2,":","MO"));
   run;

%mend _extract_sas_folder_path;


/* -----------------------------------------------------------------------------------------* 
  Macro: _duckdb_execute_aggregations
  Purpose: Build the SQL (via create_sql_string) and run a direct connection
           to the Duck DB engine, executing the aggregation and returning
           the results from the pushed-down query.
*------------------------------------------------------------------------------------------ */

%macro _duckdb_execute_aggregations;

   %if &_duckdb_error_flag. = 0 %then %do;
      libname dukonce sasioduk;
   %end;

   %if &_duckdb_error_flag. = 0 %then %do;
      %_identify_content_or_server(&parquet_file_path.);

      %if "&_path_identifier."="sasserver" %then %do;
         %put NOTE: Folder location prefixed with &_path_identifier. is on the SAS Server.;
      %end;

      %else %do;

         %let _duckdb_error_flag=1;
         %put ERROR: Please select a valid file on the SAS Server (filesystem) containing your Azure OpenAI key.  Key should be in a secure location within filesystem. ;
         data _null_;
            call symputx("_duckdb_error_desc", "Please select a valid file on the SAS Server (filesystem) containing your Azure OpenAI key.  Key should be in a secure location within filesystem.");
         run;
      
      %end;
   %end;

   %if &_duckdb_error_flag. = 0 %then %do;

      %_extract_sas_folder_path(&parquet_file_path.);

      %if "&_sas_folder_path." = "" %then %do;

         %let _duckdb_error_flag = 1;
         %let _duckdb_error_desc = The field is empty, please select a valid path  ;
         %put ERROR: &_duckdb_error_desc. ;

      %end;
      %else %do;
         %let file_path=&_sas_folder_path.;
         %put NOTE: Extracted file path is &file_path.;
      %end;
   %end;


   %if &_duckdb_error_flag. = 0 %then %do;
        %put NOTE: Building SQL aggregation strings...;
        %_create_sql_string;
   %end;

   %put NOTE: Final string resolves to &final_agg_columns.;
   %put NOTE: Final group by columns resolve to &final_group_by_columns.;

   %if &_duckdb_error_flag. = 0 %then %do;
        %put NOTE: Executing DuckDB aggregation query...;
        proc sql;
            connect using dukonce;
            select * from connection to dukonce(
                select 
                &final_group_by_columns.
                &final_agg_columns.
                from read_parquet("&file_path.")
                &group_by_clause.
            );
        quit;
   %end;
   %else %do;
        %let _duckdb_error_desc = Cannot execute DuckDB aggregation query.; 
        %put ERROR: &_duckdb_error_desc.;
   %end;

%mend _duckdb_execute_aggregations;


/* -----------------------------------------------------------------------------------------* 
  Execution Control
*------------------------------------------------------------------------------------------ */

%_create_error_flag(_duckdb_error_flag, _duckdb_error_desc);
%_create_runtime_trigger(_duckdb_run_trigger);

%put NOTE: Starting duckdb aggregations program (v1.1.4)...;
%put NOTE: Run trigger value is &_duckdb_run_trigger.;

%if &_duckdb_run_trigger. = 1 %then %do;
   %_duckdb_execute_aggregations;
%end;

%if &_duckdb_run_trigger. = 0 %then %do;
   %put NOTE: This step has been disabled. Nothing to do.;
%end;


/* ----------------------------------------------------------------------------------* 
    Cleanup 
*------------------------------------------------------------------------------------------ */

%if %symexist(final_agg_columns) %then %do;
   %symdel final_agg_columns;
%end;

%if %symexist(final_group_by_columns) %then %do;
   %symdel final_group_by_columns;
%end;

%if %symexist(group_by_clause) %then %do;
   %symdel group_by_clause;
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
%sysmacdelete _create_runtime_trigger;
%sysmacdelete _create_error_flag;
%sysmacdelete _create_sql_string;
%sysmacdelete _duckdb_execute_aggregations;

%put NOTE: duckdb aggregations program (v1.1.4) completed.;
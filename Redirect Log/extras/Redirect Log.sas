/* SAS templated code goes here */

/*-----------------------------------------------------------------------------------------*
   START MACRO DEFINITIONS.
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

   Also at: https://github.com/SundareshSankaran/sas_utility_programs/blob/main/code/Create_Run_Time_Trigger/macro_create_runtime_trigger.sas
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
      2. errorFlagDesc: The name of an error flag description variable to hold the error 
         description.

    Output:
      1. &errorFlagName : A global variable which takes the name provided to errorFlagName.
      2. &errorFlagDesc : A global variable which takes the name provided to errorFlagDesc.

   Also available at: 
   https://github.com/SundareshSankaran/sas_utility_programs/blob/main/code/Error%20Flag%20Creation/macro_create_error_flag.sas
*------------------------------------------------------------------------------------------ */

%macro _create_error_flag(errorFlagName, errorFlagDesc);

   %global &errorFlagName.;
   %global &errorFlagDesc.;
   %let &errorFlagName.=0;
   %let &errorFlagDesc. = No errors reported so far;
   
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
   Macro to handle the redirection of a log file.
*------------------------------------------------------------------------------------------ */
%macro _rl_redirect_log;
   %_identify_content_or_server(&logLocationPath.);
   %if "&_path_identifier." = "sascontent" %then %do;
      data _null_;
         call symputx("_rl_error_flag",1);
         call symput("_rl_error_desc","Provide a log file path located on the file system.");
      run;
   %end;
   %else %do;
      data _null_;
         call symput("_rl_error_desc","Redirected log file is located on the file system.");
       run;
   %end;
   %if &_rl_error_flag.=0 %then %do;
      %_extract_sas_folder_path(&logLocationPath.);
      %put NOTE: SAS Folder path is &_sas_folder_path.;
      data _null_;
         call symput("logLocation",'"'||"&_sas_folder_path."||'"');
      run;
      %let _sas_folder_path=;
   %end;

%mend _rl_redirect_log;

/* -----------------------------------------------------------------------------------------* 
   Macro to handle the redirection of an output file.
*------------------------------------------------------------------------------------------ */
%macro _rl_redirect_output;
   %_identify_content_or_server(&outputLocationPath.);
   %if "&_path_identifier." = "sascontent" %then %do;
      data _null_;
         call symputx("_rl_error_flag",1);
         call symput("_rl_error_desc","Provide an output file path located on the file system.");
      run;
   %end;
   %else %do;
      data _null_;
         call symput("_rl_error_desc","Redirected output file is located on the file system.");
       run;
   %end;
   %if &_rl_error_flag.=0 %then %do;
      %_extract_sas_folder_path(&outputLocationPath.);
      %put NOTE: SAS Folder path is &_sas_folder_path.;
      data _null_;
         call symput("outputLocation",'"'||"&_sas_folder_path."||'"');
      run;
      %let _sas_folder_path=;
   %end;

%mend _rl_redirect_output;

/* -----------------------------------------------------------------------------------------* 
   Macro to write redirection events to an output dataset.
*------------------------------------------------------------------------------------------ */
%macro _rl_write_output_dataset(operation, location);
   %put &location.;

   %if %sysfunc(exist(&outputTable.)) %then %do;
      %put NOTE: Output dataset exists;
   %end;
   %else %do;
      data &outputTable.;
         length operation $8. location $1024. update_dttm 8.;
         format update_dttm datetime20.;
         informat update_dttm datetime20.;
      run;
   %end;


   data WORK.__temp_location;
      length operation $8. location $1024. update_dttm 8.;
      format update_dttm datetime20.;
      informat update_dttm datetime20.;

      operation = "&operation.";
      location = "&location.";
      update_dttm = datetime() ;
   run;

   proc append data=work.__temp_location base=&outputTable. force;
   quit;

   proc datasets lib= work;
   delete __temp_location;
   quit;

%mend _rl_write_output_dataset;


/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE MACRO 

   _rl prefix stands for Redirect Log

   Note: This code block is a variation from the normal way the run-time control's used in 
         other custom steps. A redirection of log leads to the program exiting the %do-%end
         block in an unclean manner.  To avoid this, we use a %goto statement, usually 
         considered undesirable, but appropriate for situations such as these (to exit a
         function cleanly).
*------------------------------------------------------------------------------------------*/

%macro _rl_execution_code;

   %if &_rl_run_trigger. = 0 %then %do;
      %put NOTE: This step has been disabled.  Nothing to do.;
      %goto exit;
   %end;
   

   %put NOTE: Starting main execution code;

/*-----------------------------------------------------------------------------------------*
   Create an error flag. 
*------------------------------------------------------------------------------------------*/

   %_create_error_flag(_rl_error_flag, _rl_error_desc);

   %put NOTE: Error flag created;


   %global logLocation;
   %global outputLocation;
   %let logLocation=LOG;
   %let outputLocation=PRINT;

/*-----------------------------------------------------------------------------------------*
   If the redirect macro already exists, then check status and perform operation accordingly.
   Else, inform user to run the reassignment (default) operation. 
*------------------------------------------------------------------------------------------*/

   %if "&redirectOperation." = "log" %then %do;
      %_rl_redirect_log;
      %if &_rl_error_flag.=0 %then %do;
         %_rl_write_output_dataset(&redirectOperation., "&logLocation.");
      %end;
   %end;
   %else %if "&redirectOperation." = "output" %then %do;
      %_rl_redirect_output;
      %if &_rl_error_flag.=0 %then %do;
         %_rl_write_output_dataset(&redirectOperation., "&outputLocation.");
      %end;
   %end;
   %else %if "&redirectOperation." = "both" %then %do;
      %_rl_redirect_log;
      %_rl_redirect_output;
      %if &_rl_error_flag.=0 %then %do;
         %_rl_write_output_dataset(&redirectOperation._log, "&logLocation.");
         %_rl_write_output_dataset(&redirectOperation._output, "&outputLocation.");
      %end;
   %end;
   %else %if "&redirectOperation." = "default" %then %do;
      %_rl_write_output_dataset(&redirectOperation., default_location);
   %end;

   proc printto LOG=&logLocation. PRINT=&outputLocation. ;
   run;


%exit: %mend _rl_execution_code;

/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE
   The execution code is controlled by the trigger variable defined in this custom step. This
   trigger variable is in an "enabled" (value of 1) state by default, but in some cases, as 
   dictated by logic, could be set to a "disabled" (value of 0) state.

   The execution below is a variation from the normal use of a run-time trigger.  Refer note for 
   %_rl_execution_code.
*------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------*
   Create run-time trigger. 
*------------------------------------------------------------------------------------------*/

%_create_runtime_trigger(_rl_run_trigger);

/*-----------------------------------------------------------------------------------------*
   Execute 
*------------------------------------------------------------------------------------------*/
   
%_rl_execution_code;

%put NOTE: Final summary;
%put NOTE: Status of error flag - &_rl_error_flag. ;
%put NOTE: Error desc - &_rl_error_desc. ;

/*-----------------------------------------------------------------------------------------*
   Clean up existing macro variables and macro definitions.
*------------------------------------------------------------------------------------------*/

%if %symexist(_sas_folder_path) %then %do;
   %symdel _sas_folder_path;
%end;
%if %symexist(_path_identifier) %then %do;
   %symdel _path_identifier;
%end;
%if %symexist(_rl_error_flag) %then %do;
   %symdel _rl_error_flag;
%end;
%if %symexist(_rl_error_desc) %then %do;
   %symdel _rl_error_desc;
%end;
%if %symexist(_rl_run_trigger) %then %do;
   %symdel _rl_run_trigger;
%end;

%sysmacdelete _rl_redirect_log;
%sysmacdelete _rl_redirect_output;
%sysmacdelete _rl_execution_code;
%sysmacdelete _create_runtime_trigger;
%sysmacdelete _identify_content_or_server;
%sysmacdelete _extract_sas_folder_path;
%sysmacdelete _create_error_flag;


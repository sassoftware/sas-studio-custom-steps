/* SAS templated code goes here */

/* -------------------------------------------------------------------------------------------* 
   Python - Switch Environments

   v 1.0.0 (29AUG2025)

   This program helps you switch between different Python environments from within a SAS session.
   It is also meant as a mechanism for a user to revert to the base environment from an active 
   virtual environment.

   Sundaresh Sankaran (sundaresh.sankaran@sas.com|sundaresh.sankaran@gmail.com)
*-------------------------------------------------------------------------------------------- */

/*-----------------------------------------------------------------------------------------*
   Debug Section

   The following code block (to be commented out or deleted in production) is meant to 
   help you debug the custom step. It sets values for the macro variables that would 
   normally be set through the custom step interface.

   Uncomment and modify the values as needed to test the custom step outside of SAS Studio.
   
   Here's the requirement from the project:

   Receives input from user regarding folder location of venv (include venv)
   Changes options to point to same
   If user wants to revert to original, check for presence of ORIGINAL_PYPATH
   Revert to Original_PYPATH if so
   SAS log message to indicate success
   sys.executable to specify the interpreter and remove confusion
   All the useful macro and wiring

*------------------------------------------------------------------------------------------*/

/* === User Input Macro Variables (in logical order) === */


/* 1. Option to revert to original Python environment (1 = Revert, 0 = Use specified venv)*/;
* %let revert_to_original = 1; /* Set to 1 to revert to ORIGINAL_PYPATH, 0 to use a specified venv */

/* 2. If not reverting, specify the folder location of the virtual environment (venv) */
* %let venv = ; /* Provide the full path including 'venv' folder if revert_to_original=0 */

*/; 

/*-----------------------------------------------------------------------------------------*
   Python Block Definition
*------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------*
   The following block of code has been created for the purpose of allowing proc python 
   to execute within a macro. Execution within a macro allows for other checks to be carried 
   out through SAS prior to handing off to the Python step.

   In this example, a temporary file is created containing the requisite Python commands, which 
   are then executed through infile reference.

   Note that Python code is pasted as-is and may be out of line with the SAS indentation followed.

*------------------------------------------------------------------------------------------*/

filename printint temp;

data _null_;

   length line $32767;               * max SAS character size ;
   infile datalines4 truncover pad;
   input ;   
   file printint;
   line = strip(_infile_);           * line without leading and trailing blanks ;
   l1 = length(trimn(_infile_));     * length of line without trailing blanks ;
   l2 = length(line);                * length of line without leading and trailing blanks ;
   first_position=l1-l2+1;           * position where the line should start (alignment) ;
   if (line eq ' ') then put @1;     * empty line ;
   else put @first_position line;    * line without leading and trailing blanks correctly aligned ;

   datalines4;

# Import necessary libraries
import sys

SAS.logMessage(f"Current Python Path: {sys.executable}")


;;;;
run;   

/*-----------------------------------------------------------------------------------------*
   MACROS
*------------------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------------*
   The following macro variable is defined as global because it will help in cases
   involving repeated use of this step. 
*------------------------------------------------------------------------------------------*/

%global ORIGINAL_PYPATH;

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
   %let  &errorFlagName.=0;
   %global &errorFlagDesc.;

%mend _create_error_flag;

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


/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE MACRO 

   _switchenv prefix stands for Switch Environments
*------------------------------------------------------------------------------------------*/
%macro _switchenv_execution_code;

   %let revertt=&REVERT_TO_ORIGINAL;

   %_create_error_flag(_switchenv_error_flag, _switchenv_error_desc);

/*-----------------------------------------------------------------------------------------*
    Check if user wants to revert to original environment
*------------------------------------------------------------------------------------------*/
   %if &_switchenv_error_flag. = 0 %then %do;
      %put NOTE: This is the current state of revertt - &revertt. ;
      %if "&revertt." = "1" %then %do;
         %if %symexist(ORIGINAL_PYPATH) %then %do;
            options set=PROC_PYPATH="&ORIGINAL_PYPATH.";
            %let _switchenv_error_flag=0;
            %let _switchenv_error_desc=NOTE: Set Python path to original Python environment at &ORIGINAL_PYPATH..;
         %end;
         %else %do;
/*-----------------------------------------------------------------------------------------*
    Insert code to check if default path exists at /opt/sas/viya/home/sas-pyconfig
*------------------------------------------------------------------------------------------*/
            %if "%str(%sysfunc(fileexist(/opt/sas/viya/home/sas-pyconfig/default_py/bin/python3)))" = "1" %then %do;
               options set=PROC_PYPATH="/opt/sas/viya/home/sas-pyconfig/default_py/bin/python3";
               %let _switchenv_error_flag=0;
               %let _switchenv_error_desc=NOTE: Set Python path to default Python profile environment at /opt/sas/viya/home/sas-pyconfig/default_py/bin/python3.;
 /*-----------------------------------------------------------------------------------------*
    Retain ORIGINAL_PYPATH for any future repeated use
*------------------------------------------------------------------------------------------*/
                %let ORIGINAL_PYPATH = %sysget(PROC_PYPATH);              
            %end;
            %else %do;
               %let _switchenv_error_flag=1;
               %let _switchenv_error_desc=ERROR: Neither an ORIGINAL_PYPATH variable or default Python path exists. Cannot revert to original environment.;
/*-----------------------------------------------------------------------------------------*
    Record current path as ORIGINAL_PYPATH for any future repeated use
*------------------------------------------------------------------------------------------*/
                %let ORIGINAL_PYPATH = %sysget(PROC_PYPATH);              
            %end;
         %end;
      %end;
      %else %if "&revertt." = "0" %then %do;
/*-----------------------------------------------------------------------------------------*
    Record ORIGINAL_PYPATH in order to roll back if needed
    Note: Original means the current path before the following code runs.
*------------------------------------------------------------------------------------------*/
         %let ORIGINAL_PYPATH = %sysget(PROC_PYPATH);     
         %_extract_sas_folder_path(&venv.);
         %let venv_input=&_sas_folder_path.;
         %if "&venv_input." = "" %then %do;
            %let _switchenv_error_flag=1;
            %let _switchenv_error_desc=ERROR: No virtual environment path specified. Please provide a valid path.;
         %end;
         %else %do;
            %if %str(%sysfunc(fileexist(&venv_input./bin/python3))) = "0" %then %do;
               %let _switchenv_error_flag=1;
               %let _switchenv_error_desc=ERROR: The specified virtual environment path &venv_input. does not exist or is invalid. Please provide a valid path.;
            %end;
            %else %do;
               options set=PROC_PYPATH="&venv_input./bin/python3";
               %let _switchenv_error_flag=0;
               %let _switchenv_error_desc=NOTE: Set Python path to virtual environment at &venv_input./bin/python3.;
         
            %end;
         %end;
      %end;
   %end;

/*-----------------------------------------------------------------------------------------*
    Reset interpreter to new virtual environment
*------------------------------------------------------------------------------------------*/
   %if &_SWITCHENV_ERROR_FLAG. = 0 %then %do;
        proc python terminate;
        quit;

        proc python infile=printint; 
        run;

   %end;   


   

%mend _switchenv_execution_code;

/*-----------------------------------------------------------------------------------------*
   END MACROS
*------------------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE
*------------------------------------------------------------------------------------------*/
   
/*-----------------------------------------------------------------------------------------*
   Create Runtime Trigger
*------------------------------------------------------------------------------------------*/
%_create_runtime_trigger(_switchenv_run_trigger);

/*-----------------------------------------------------------------------------------------*
   Execute 
*------------------------------------------------------------------------------------------*/

%if &_switchenv_run_trigger. = 1 %then %do;

   %_switchenv_execution_code;

%end;

%if &_switchenv_run_trigger. = 0 %then %do;

   %put NOTE: This step has been disabled.  Nothing to do.;

%end;


%put NOTE: Final summary;
%put NOTE: Status of error flag - &_switchenv_error_flag. ;
%put &_switchenv_error_desc.;
%put NOTE: Error desc if any - &_switchenv_error_desc. ;

/*-----------------------------------------------------------------------------------------*
   END EXECUTION CODE
*------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------*
   Clean up existing macro variables and macro definitions.
*------------------------------------------------------------------------------------------*/

%if %symexist(_switchenv_run_trigger) %then %do;
   %symdel _switchenv_run_trigger;
%end;
%if %symexist(_switchenv_error_flag) %then %do;
   %symdel _switchenv_error_flag;
%end;
%if %symexist(_switchenv_error_desc) %then %do;
   %symdel _switchenv_error_desc;
%end;


%sysmacdelete _create_runtime_trigger;
%sysmacdelete _create_error_flag;
%sysmacdelete _extract_sas_folder_path;
%sysmacdelete _switchenv_execution_code;


filename printint clear;


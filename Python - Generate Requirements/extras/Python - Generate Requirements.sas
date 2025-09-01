/* SAS templated code goes here */

/* -------------------------------------------------------------------------------------------* 
   Python - Generate Requirements

   v 1.1.0 (31AUG2025)

   This program helps you generate a requirements.txt file for your Python project or environment.
   You can either freeze all packages in a given Python environment, or generate requirements
   based on the imports used in a folder of Python scripts.

   Sundaresh Sankaran (sundaresh.sankaran@sas.com| sundaresh.sankaran@gmail.com)
*-------------------------------------------------------------------------------------------- */

/*-----------------------------------------------------------------------------------------*
   Debug Section
   Uncomment and modify the values as needed to test the custom step outside of SAS Studio.
*------------------------------------------------------------------------------------------*/

%let req_task = project;

%let env_folder = %str(sasserver:/opt/sas/viya/home/sas-pyconfig/base_py);

%let project_folder = %str(sasserver:/mnt/viya-share/data/sinsrn/);

%let req_file = %str(sasserver:/mnt/viya-share/data/sinsrn/requirements.txt);

/*-----------------------------------------------------------------------------------------*
   Python Block Definitions
*------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------*
   The following block of code has been created for the purpose of allowing proc python 
   to execute within a macro. Execution within a macro allows for other checks to be carried 
   out through SAS prior to handing off to the Python step.

   In this example, a temporary file is created containing the requisite Python commands, which 
   are then executed through infile reference.

   Note that Python code is pasted as-is and may be out of line with the SAS indentation followed.

*------------------------------------------------------------------------------------------*/;

filename pipfreez temp;
data _null_;
   length line $32767;
   infile datalines4 truncover pad;
   input ;   
   file pipfreez;
   line = strip(_infile_);
   l1 = length(trimn(_infile_));
   l2 = length(line);
   first_position=l1-l2+1;
   if (line eq ' ') then put @1;
   else put @first_position line;
   datalines4;

import subprocess
req = SAS.symget("req_file")
pyt = SAS.symget("python_exec")
command = f"{pyt} -m pip freeze > {req}"
ret = subprocess.run(command, shell=True, capture_output=True)

if ret.returncode == 0:
    print(f"Requirements file saved at {req}")
else:
    print(f"Error occurred while generating requirements file: {ret.stderr.decode()}")

;;;;
run;

filename projreq temp;
data _null_;
   length line $32767;
   infile datalines4 truncover pad;
   input ;   
   file projreq;
   line = strip(_infile_);
   l1 = length(trimn(_infile_));
   l2 = length(line);
   first_position=l1-l2+1;
   if (line eq ' ') then put @1;
   else put @first_position line;
   datalines4;

import os
import subprocess

pyt = os.environ['PROC_PYPATH']
projectarea = SAS.symget("project_folder")
resultloc = SAS.symget("req_file")

command = f"{pyt} -m pipreqs.pipreqs --save {resultloc} --force {projectarea}"

ret = subprocess.run(command, shell=True, capture_output=True)

if ret.returncode == 0:
    print(f"Requirements file saved at {resultloc}")
else:
    print(f"Error occurred while generating requirements file: {ret.stderr.decode()}")

;;;;
run;

/*-----------------------------------------------------------------------------------------*
   MACROS
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
*------------------------------------------------------------------------------------------*/
%macro _genreq_execution_code;

/*-----------------------------------------------------------------------------------------*
   Create an error flag
*------------------------------------------------------------------------------------------*/
   %_create_error_flag(_genreq_error_flag, _genreq_error_desc);

/*-----------------------------------------------------------------------------------------*
    Extract value from file selector for requirements
*------------------------------------------------------------------------------------------*/
   %if &_genreq_error_flag. = 0 %then %do;
/*-----------------------------------------------------------------------------------------*
    Provide error if req file is empty
*------------------------------------------------------------------------------------------*/
        %if "&req_file" = "" %then %do;
          %let _genreq_error_flag=1;
          %let _genreq_error_desc=ERROR: Please specify requirements file.;
        %end;
        %else %do;
           %_extract_sas_folder_path(&req_file.);
           %let req_file=&_sas_folder_path.;
        %end;
   %end;

/*-----------------------------------------------------------------------------------------*
    For "freeze" task, extract value from folder selector for env folder
*------------------------------------------------------------------------------------------*/

   %if &_genreq_error_flag. = 0 %then %do;
        %if "%upcase(&req_task.)" = "FREEZE" %then %do;
/*-----------------------------------------------------------------------------------------*
    Provide error if env folder is empty
*------------------------------------------------------------------------------------------*/
            %if "&env_folder." = "" %then %do;
                %let _genreq_error_flag=1;
                %let _genreq_error_desc=ERROR: Please specify env_folder.;
            %end;
            %else %do;
                %_extract_sas_folder_path(&env_folder.);
                %let env_folder=&_sas_folder_path.;
                %put NOTE: Environment folder resolved to &env_folder.;

/*-----------------------------------------------------------------------------------------*
    Run Python code for "freeze" task
*------------------------------------------------------------------------------------------*/
                %if &_genreq_error_flag. = 0 %then %do;
                        %let python_exec = &env_folder./bin/python3;
                        proc python infile=pipfreez;
                        run;
                        %let _genreq_error_desc=NOTE: Requirements frozen from environment &env_folder. available in folder &req_file. ;
                %end;
            %end;
        %end;
        %else %if "%upcase(&req_task.)" = "PROJECT" %then %do;
            %if "&project_folder" = "" %then %do;
                %let _genreq_error_flag=1;
                %let _genreq_error_desc=ERROR: Please specify project folder.;
            %end;
            %else %do;
/*-----------------------------------------------------------------------------------------*
    For "project" task, extract value from folder selector for project folder
*------------------------------------------------------------------------------------------*/

                %_extract_sas_folder_path(&project_folder.);
                %let project_folder=&_sas_folder_path.;
/*-----------------------------------------------------------------------------------------*
    Run Python code for "project" task
*------------------------------------------------------------------------------------------*/
                %if &_genreq_error_flag. = 0 %then %do;
                    proc python infile=projreq;
                    run;
                    %let _genreq_error_desc=NOTE: Requirements generated from project folder &project_folder. available in folder &req_file.;
                %end;
            %end;
        %end;
   %end;
%mend _genreq_execution_code;

/*-----------------------------------------------------------------------------------------*
   END MACROS
*------------------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE
*------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------*
   Create Runtime Trigger
*------------------------------------------------------------------------------------------*/
%_create_runtime_trigger(_genreq_run_trigger);

/*-----------------------------------------------------------------------------------------*
   Execute 
*------------------------------------------------------------------------------------------*/

%if &_genreq_run_trigger. = 1 %then %do;
    %put NOTE: Execution trigger is set to 1. Proceeding with execution of Python - Generate Requirements custom step.;
    %_genreq_execution_code;
%end;

%if &_genreq_run_trigger. = 0 %then %do;

   %put NOTE: This step has been disabled.  Nothing to do.;

%end;

%put NOTE: Final summary;
%put NOTE: Status of error flag - &_genreq_error_flag.;
%put &_genreq_error_desc.;
%put NOTE: Error desc - &_genreq_error_desc.;

/*-----------------------------------------------------------------------------------------*
   Clean up existing macro variables and macro definitions.
*------------------------------------------------------------------------------------------*/

%if %symexist(_genreq_error_flag) %then %do;
   %symdel _genreq_error_flag;
%end;
%if %symexist(_genreq_error_desc) %then %do;
   %symdel _genreq_error_desc;
%end;

%sysmacdelete _create_error_flag;
%sysmacdelete _extract_sas_folder_path;
%sysmacdelete _genreq_execution_code;

filename pipfreez clear;
filename projreq clear;

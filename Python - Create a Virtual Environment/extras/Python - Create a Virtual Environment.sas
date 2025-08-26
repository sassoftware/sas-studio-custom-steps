/* SAS templated code goes here */

/* -------------------------------------------------------------------------------------------* 
   Python - Create a Virtual Environment

   v 2.0.0 (26AUG2025)

   This program helps you create a Python virtual environment from within a SAS session.
   It captures the current Python executable path and creates a virtual environment in the
   specified location (or current working directory if not specified). It also allows you to
   install packages either from a requirements.txt file or a space-separated list of packages.

   Sundaresh Sankaran (sundaresh.sankaran@sas.com|sundaresh.sankaran@gmail.com)
*-------------------------------------------------------------------------------------------- */

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

filename cvirenv temp;

data _null_;

   length line $32767;               * max SAS character size ;
   infile datalines4 truncover pad;
   input ;   
   file cvirenv;
   line = strip(_infile_);           * line without leading and trailing blanks ;
   l1 = length(trimn(_infile_));     * length of line without trailing blanks ;
   l2 = length(line);                * length of line without leading and trailing blanks ;
   first_position=l1-l2+1;           * position where the line should start (alignment) ;
   if (line eq ' ') then put @1;     * empty line ;
   else put @first_position line;    * line without leading and trailing blanks correctly aligned ;

   datalines4;

# Import necessary libraries
import os
import subprocess
from pathlib import Path

# Capture current Python executable and save in a macro variable called  ORIGINAL_PYPATH for reference
pyt=os.environ["PROC_PYPATH"]
SAS.symput("ORIGINAL_PYPATH",str(pyt))

# Create a virtual environment in the directory specified.
venv_input=SAS.symget("venv_input")
path = Path(venv_input)
if path.exists():
    venv=os.path.join(venv_input,"venv")
else:
    venv=os.path.join(os.getcwd(),"venv")

install_system_site_packages=int(SAS.symget("install_system_site_packages"))

if install_system_site_packages==1:
    command = f"{pyt} -m venv {venv} --system-site-packages"
else:
    command = f"{pyt} -m venv {venv}"


ret = subprocess.run(command, capture_output=True, shell=True)

if ret.__dict__["returncode"]==0: 
    SAS.symput("TEMP_PYPATH",str(os.path.join(venv,"bin","python3")))
    SAS.logMessage("Virtual environment created successfully.")
else:
    SAS.logMessage("Error creating virtual environment. Return code: " + str(ret.__dict__["returncode"]) + ". Error message: " + str(ret.__dict__["stderr"]),"error")
    SAS.symput("_cvirenv_error_flag",1)  # if error, retain original Python path ;
    SAS.symput("_cvirenv_error_desc","Error creating virtual environment. Return code: " + str(ret.__dict__["returncode"]) + ". Error message: " + str(ret.__dict__["stderr"]))


;;;;
run;   

filename instpack temp;

data _null_;

   length line $32767;               * max SAS character size ;
   infile datalines4 truncover pad;
   input ;   
   file instpack;
   line = strip(_infile_);           * line without leading and trailing blanks ;
   l1 = length(trimn(_infile_));     * length of line without trailing blanks ;
   l2 = length(line);                * length of line without leading and trailing blanks ;
   first_position=l1-l2+1;           * position where the line should start (alignment) ;
   if (line eq ' ') then put @1;     * empty line ;
   else put @first_position line;    * line without leading and trailing blanks correctly aligned ;

   datalines4;

# Import necessary libraries
import os
import subprocess
import sys

SAS.logMessage(f"Current Python Path: {sys.executable}")
pyt=SAS.symget("TEMP_PYPATH")
SAS.logMessage("Starting Requirements install")
req=SAS.symget("req")

# Error prevention: check for empty requirements file or no package provided
if not req or req.strip() == "":
   SAS.logMessage("No requirements file or package list provided. Skipping pip install.")
else:
   if os.path.isfile(req):
      # Check if file is empty
      if os.path.getsize(req) == 0:
         SAS.logMessage(f"Requirements file '{req}' is empty. Skipping pip install.")
      else:
         print("File provided")
         command = "{pyt} -m pip install -r {req}".format(pyt=pyt,req=req)
         ret = subprocess.run(command, capture_output=True, shell=True)
         if ret.__dict__["returncode"]==0: 
            SAS.logMessage("Requirements installed successfully.")
         else:
            SAS.logMessage("Error installing requirements. Return code: " + str(ret.__dict__["returncode"]) + ". Error message: " + str(ret.__dict__["stderr"]),"error")
            SAS.symput("_cvirenv_error_flag",1)  # if error, retain original Python path ;
            SAS.symput("_cvirenv_error_desc","Error installing requirements. Return code: " + str(ret.__dict__["returncode"]) + ". Error message: " + str(ret.__dict__["stderr"]))
   else:
      # Check if req is just whitespace
      if req.strip() == "":
         SAS.logMessage("No packages specified in the list. Skipping pip install.")
      else:
         print("List provided")
         command = "{pyt} -m pip install {req}".format(pyt=pyt,req=req)
         ret = subprocess.run(command, capture_output=True, shell=True)
         if ret.__dict__["returncode"]==0: 
            SAS.logMessage("Requirements installed successfully.")
         else:
            SAS.logMessage("Error installing requirements. Return code: " + str(ret.__dict__["returncode"]) + ". Error message: " + str(ret.__dict__["stderr"]),"error")
            SAS.symput("_cvirenv_error_flag",1)  # if error, retain original Python path ;
            SAS.symput("_cvirenv_error_desc","Error installing requirements. Return code: " + str(ret.__dict__["returncode"]) + ". Error message: " + str(ret.__dict__["stderr"]))


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

   _cvirenv prefix stands for Create Virtual Environment
*------------------------------------------------------------------------------------------*/
%macro _cvirenv_execution_code;

   %_create_error_flag(_cvirenv_error_flag, _cvirenv_error_desc);

/*-----------------------------------------------------------------------------------------*
    Extract value from folder selector
*------------------------------------------------------------------------------------------*/
   %if &_cvirenv_error_flag. = 0 %then %do;
      %_extract_sas_folder_path(&venv.);
      %let venv_input=&_sas_folder_path.;
   %end;   

/*-----------------------------------------------------------------------------------------*
    Create a virtual environment in the specified location
*------------------------------------------------------------------------------------------*/
   %if &_cvirenv_error_flag. = 0 %then %do;
      proc python infile=cvirenv;
      run;
   %end;   
/*-----------------------------------------------------------------------------------------*
    Change interpreter to new virtual environment
*------------------------------------------------------------------------------------------*/
   %if &_cvirenv_error_flag. = 0 %then %do;
        proc python terminate;
        quit;
        
        options set=PROC_PYPATH="&TEMP_PYPATH.";
        
   %end;   
   
/*-----------------------------------------------------------------------------------------*
    Install Packages
*------------------------------------------------------------------------------------------*/
   %if &_cvirenv_error_flag. = 0 %then %do;
      proc python infile=instpack;
      run;
   %end;   

%mend _cvirenv_execution_code;

/*-----------------------------------------------------------------------------------------*
   END MACROS
*------------------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE
*------------------------------------------------------------------------------------------*/
   
/*-----------------------------------------------------------------------------------------*
   Create Runtime Trigger
*------------------------------------------------------------------------------------------*/
%_create_runtime_trigger(_cvirenv_run_trigger);

/*-----------------------------------------------------------------------------------------*
   Execute 
*------------------------------------------------------------------------------------------*/

%if &_cvirenv_run_trigger. = 1 %then %do;

   %_cvirenv_execution_code;

%end;

%if &_cvirenv_run_trigger. = 0 %then %do;

   %put NOTE: This step has been disabled.  Nothing to do.;

%end;


%put NOTE: Final summary;
%put NOTE: Status of error flag - &_cvirenv_error_flag. ;
%put &_cvirenv_error_desc.;
%put NOTE: Error desc - &_cvirenv_error_desc. ;

/*-----------------------------------------------------------------------------------------*
   END EXECUTION CODE
*------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------*
   Clean up existing macro variables and macro definitions.
*------------------------------------------------------------------------------------------*/

%if %symexist(_cvirenv_run_trigger) %then %do;
   %symdel _cvirenv_run_trigger;
%end;
%if %symexist(_cvirenv_error_flag) %then %do;
   %symdel _cvirenv_error_flag;
%end;
%if %symexist(_cvirenv_error_desc) %then %do;
   %symdel _cvirenv_error_desc;
%end;


%sysmacdelete _create_runtime_trigger;
%sysmacdelete _create_error_flag;
%sysmacdelete _extract_sas_folder_path;
%sysmacdelete _cvirenv_execution_code;

filename instpack clear;
filename cvirenv clear;




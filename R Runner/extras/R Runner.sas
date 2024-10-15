/* SAS templated code goes here */

/*-----------------------------------------------------------------------------------------*
   START MACRO DEFINITIONS.
*------------------------------------------------------------------------------------------*/

/* -----------------------------------------------------------------------------------------* 
   Error flag for capture during code execution.
*------------------------------------------------------------------------------------------ */

%global _rr_error_flag;
%let _rr_error_flag=0;

/* -----------------------------------------------------------------------------------------* 
   Create a global variable to contain the path of the R filename (either temp or specified)
*------------------------------------------------------------------------------------------ */
%global _rr_rfile_location;

/* -----------------------------------------------------------------------------------------* 
   Create a global variable to mention whether the text area count exists or not (indicating)
   whether single or multi-line.
*------------------------------------------------------------------------------------------ */
%global _rr_rarea_multiline_exist;
%let _rr_rarea_multiline_exist=%symexist(rrrarea_count);


%put NOTE: Multiple Lines exist in snippet indicator - &_rr_rarea_multiline_exist.;

/* -----------------------------------------------------------------------------------------* 
   This macro creates a temporary file to hold the R script from the snippet.  
*------------------------------------------------------------------------------------------ */

%macro createTempRFile;
filename rfile temp;

%if &_rr_rarea_multiline_exist.=0 %then %do;

   data _null_;
      file rfile;
      put "&rrrarea.";
   run;

%end;

%else %do;

   data _null_;
      length text $32767.;
      file rfile;
      do i = 1 to &rrrarea_COUNT. ;
         if symget("rrrarea_" || strip(put(i,12.))) eq '' then do ;
            text="";
         end ;
         else do ;
		     text=cats(symget("rrrarea_" || strip(put(i,12.)))) ;
             put text;
		 end ;
	  end ;
   run;

%end;


%mend createTempRFile;

/* -----------------------------------------------------------------------------------------* 
   This macro checks if the file provided is on the filesystem and not SAS Content, or if a  
   file is provided at all.  Currently, only files on the filesystem or snippets through the
   UI are supported.  
*------------------------------------------------------------------------------------------ */

%macro treatRFileInput(fileName);

      %let fileType = %sysfunc(scan("&fileName.",1,":"));
      %let filePath = %sysfunc(scan("&fileName.",2,":"));

      %put NOTE: The file path is &filePath.;

      %if %sysfunc(upcase("&fileType."))="SASCONTENT" %then %do;
         %put ERROR: Provide a R program located on the filesystem.;
         %let _rr_error_flag=1;
      %end;

      %else %if %sysfunc(upcase("&fileType."))="SASSERVER" %then %do;
         %put NOTE: Filesystem file provided;
         filename rfile "&filePath.";
         %let _rr_rfile_location=%sysfunc(pathname(rfile));
      %end;

      %else %do;
         %put NOTE: Empty file location. Use of R snippet area assumed.;
         %createTempRFile;
         %let _rr_rfile_location=%sysfunc(pathname(rfile));
      %end;

%mend treatRFileInput;



/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE MACRO 
   Driven by user choice from UI. 
   NOTE: Execution code needs (proc python) submit blocks to be written to a file prior to
         running.  This shall be undertaken in future.
*------------------------------------------------------------------------------------------*/
%macro main_execution_code;
%mend main_execution_code;


/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE 
   Note: Python code blocks follow different indentation logic and are currently not
   indented within the SAS proc python blocks below. Workaround (lower priority) in progress.
*------------------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------------*
   Check the type of R file input provided and treat accordingly.
*------------------------------------------------------------------------------------------*/

%treatRFileInput("&inputRScript.");

%if &_rr_error_flag.=0 %then %do;

/*-----------------------------------------------------------------------------------------*
   Initial imports which set up the R HOME connection.
*------------------------------------------------------------------------------------------*/

   proc python;

      submit;

import os
import gc

r_home_path=SAS.symget("rHomePath")

os.environ['R_HOME']=r_home_path
import rpy2.robjects as robjects
from rpy2.robjects import r

      endsubmit;

   quit;

/*-----------------------------------------------------------------------------------------*
   Create a Pandas dataframe from any input table / dataset provided. For ease of reference,
   this dataframe will be called input_table within Pandas (Python).

   Correspondingly, the R data frame can be referred to as "r_input_table" within R script.
   Notice the controlled manner in which the r_input_table data frame is passed to a global
   environment.
*------------------------------------------------------------------------------------------*/



   proc python;
      submit;

inputtable=SAS.symget("inputtable")

if len(inputtable) > 1 : 

   import pandas as pd
   input_table = pd.DataFrame
   input_table = SAS.sd2df(inputtable)

   import rpy2.robjects as ro
   from rpy2.robjects.packages import importr
   from rpy2.robjects import pandas2ri
   from rpy2.robjects import globalenv

   with (ro.default_converter + pandas2ri.converter).context():
     r_input_table = ro.conversion.get_conversion().py2rpy(input_table)

   globalenv['r_input_table'] = r_input_table
   SAS.logMessage("Input dataset has been transferred to an R dataframe.")
   
   del input_table
   gc.collect()

      endsubmit;
   quit;

/*-----------------------------------------------------------------------------------------*
   Obtain input R file and execute with rpy2's robjects.r object. Write env variables and 
   values to a Pandas dataframe and subsequently to a SAS dataset. 
*------------------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------------*
   NOTE: In this ** early ** release, the values of the R environment variables (globalenv)
         are written as-is, i.e. they are considered rpy2 objects of different class types
         in Python. The values are only meant for informational purposes. Their presence 
         within a Pandas dataframe should not make you assume that you can treat them 
         natively as Python objects (further manipulation as guided by rPy2 documentation
         is needed).
*------------------------------------------------------------------------------------------*/


   proc python;

      submit;

# Obtain values from the UI
rScriptPath=SAS.symget("_rr_rfile_location")
envData=SAS.symget("envData")
print(envData)

with open(rScriptPath,"r",encoding="utf-8") as f:
   rsnippet=f.read()
   r(rsnippet) 


if len(envData) > 1:
   outputDict=[]
   for eachObject in robjects.globalenv:
      outputDict.append({"R_Variable":eachObject})
   outputDataFrame = pd.DataFrame.from_dict(outputDict)
   SAS.df2sd(outputDataFrame, dataset=envData)
   SAS.logMessage("Output variable information table.")
   
   del outputDataFrame
   gc.collect()

      endsubmit;

   quit;




%put NOTE: RR FILE LOCATION is &_rr_rfile_location.;



/*-----------------------------------------------------------------------------------------*
   Create a Pandas dataframe from an existing R data frame and output to a SAS dataset. 
   Ensure that this R data frame does exist.
*------------------------------------------------------------------------------------------*/


   proc python;
      submit;
outputtable    = SAS.symget("outputtable")

if len(outputtable) > 1:

   import pandas as pd
   output_r_df = SAS.symget("output_rdf_name")
   output_pdf     = pd.DataFrame


   import rpy2.robjects as ro
   from rpy2.robjects import pandas2ri
   from rpy2.robjects import globalenv

   print(output_r_df)

   r_table = globalenv[output_r_df]

   with (ro.default_converter + pandas2ri.converter).context():
     output_pdf = ro.conversion.get_conversion().rpy2py(r_table)

   SAS.df2sd(output_pdf, dataset=outputtable)
   SAS.logMessage("Transferred dataframe to SAS")

   del output_pdf
   gc.collect()


      endsubmit;
   quit;


%end;
/*-----------------------------------------------------------------------------------------*
   Remove execution-time macro variables.
*------------------------------------------------------------------------------------------*/

%symdel _rr_rfile_location;
%symdel _rr_rarea_multiline_exist;
%symdel _rr_error_flag;


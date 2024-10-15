/* SAS templated code goes here */

/*--------------------------------------------------------------------------------------*
   This macro creates a global macro variable called _usr_nameCaslib
   that contains the caslib name (aka. caslib-reference-name) associated with the libname 
   and assumes that the libname is using the CAS engine.

   As sysvalue has a length of 1024 chars, we use the trimmed option in proc sql
   to remove leading and trailing blanks in the caslib name.
*---------------------------------------------------------------------------------------*/

%macro _usr_getNameCaslib(_usr_LibrefUsingCasEngine); 

   %global _usr_nameCaslib;
   %let _usr_nameCaslib=;

   proc sql noprint;
      select sysvalue into :_usr_nameCaslib trimmed from dictionary.libnames
      where libname=upcase("&_usr_LibrefUsingCasEngine.") and upcase(sysname)="CASLIB";
   quit;

%mend _usr_getNameCaslib;


/*--------------------------------------------------------------------------------------*
   Macro to execute string substitution for "GPU Devices" in case the user enables GPU & 
   specifies a GPU device ID. 

   Note : For those interested, a little dated but insightful SAS Global Forum paper on 
   the best way to evaluate if a macro variable is blank (as used below), provided here:
   http://support.sas.com/resources/papers/proceedings09/022-2009.pdf 
*---------------------------------------------------------------------------------------*/

%macro gpu_status_string_substitute;
   %global deviceArgumentString;
   %if &gpuEnabled.=0 %then %do;
      %let deviceArgumentString=;
   %end;
   %else %do;
      %if %sysevalf(%superq(numDevices)=,boolean) %then %do;
         %let deviceArgumentString=;
      %end;
      %else %do;
         data _null_;
            call symput("deviceArgumentString",",device=&numDevices.");
         run;
      %end;
   %end;

%mend gpu_status_string_substitute;


/*--------------------------------------------------------------------------------------*
  Call the above "caslib check" macro 3 times for each of the tables (and their libnames)
  presently connected to this step.
*---------------------------------------------------------------------------------------*/

%_usr_getNameCaslib(&inputTable_lib.);
%let input_table_lib=&_usr_nameCaslib.;

%if "&input_table_lib."="" %then %do;
   %put NOTE: Please provide a valid table and libref using the CAS engine.;
   data _null_;
      abort exit 4322;
   run;
%end;

%_usr_getNameCaslib(&modelTable_lib.);
%let model_table_lib=&_usr_nameCaslib.;

%_usr_getNameCaslib(&casOut_lib.);
%let output_table_lib=&_usr_nameCaslib.;

/* Blank out the _usr_nameCaslib macro variable so as to not leave things dangling. */
%let _usr_nameCaslib=;


/* Execute the gpu_status_string_substitute macro. */

%gpu_status_string_substitute;


/* Main Processing occurs in the below section through a CAS action call.  */

proc cas;

/* Obtain values from the UI */
   input_table_name=symget("inputTable_name_base");
   input_table_lib=symget("input_table_lib");
   output_table_name=symget("casOut_name_base");
   output_table_lib=symget("output_table_lib");
   model_table_name=symget("modelTable_name_base");
   model_table_lib=symget("model_table_lib");
   document_id=symget("docId_1_name_base");
   text_variable=symget("textVar_1_name_base");

/* Score table with a given text classifier model */
   textClassifier.scoreTextClassifier /               
      table={name=input_table_name, caslib=input_table_lib}
      model={name=model_table_name, caslib=model_table_lib}
      text=text_variable
      docId=document_id
      gpu={enable=&gpuEnabled. &deviceArgumentString.}
      includeAllScores=&includeAllScores.
      batchSize=&batchSize.
      casOut={name=output_table_name, caslib=output_table_lib, replace=True}
;

quit; 
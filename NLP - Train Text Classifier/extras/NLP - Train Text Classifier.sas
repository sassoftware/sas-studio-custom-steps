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
  Call the above "caslib check" macro 4 times for each of the tables (and their libnames) 
  presently connected to this step.
*---------------------------------------------------------------------------------------*/

%_usr_getNameCaslib(&trainingTable_lib.);
%let training_table_lib=&_usr_nameCaslib.;

%if "&training_table_lib."="" %then %do;
   %put NOTE: Please provide a valid table and libref using the CAS engine.;
   data _null_;
      abort exit 4321;
   run;
%end;

%_usr_getNameCaslib(&validationTable_lib.);
%let validation_table_lib=&_usr_nameCaslib.;

%_usr_getNameCaslib(&testTable_lib.);
%let test_table_lib=&_usr_nameCaslib.;

%_usr_getNameCaslib(&modelOut_lib.);
%let model_table_lib=&_usr_nameCaslib.;

/* Blank out the _usr_nameCaslib macro variable so as to not leave things dangling. */
%let _usr_nameCaslib=;


/* Execute the gpu_status_string_substitute macro. */

%gpu_status_string_substitute;


/* Main Processing occurs in the below section through a CAS action call.  */

proc cas;

/* Obtain values from the UI */
   training_table_name=symget("trainingTable_name_base");
   training_table_lib=symget("training_table_lib");
   model_table_name=symget("modelOut_name_base");
   model_table_lib=symget("model_table_lib");
   target_variable=symget("targetVar_1_name_base");
   text_variable=symget("textVar_1_name_base");
   validation_table_name=symget("validationTable_name_base");
   validation_table_lib=symget("validation_table_lib");
   test_table_name=symget("testTable_name_base");
   test_table_lib=symget("test_table_lib");

   print("Your model will be written to "||model_table_lib||"."||model_table_name);
   print("Your training table is "||training_table_lib||"."||training_table_name);

/* Repurpose training table as validation, if validation table not provided */
   if validation_table_name="" then do; 
      print("No validation table specified.  Using training table for validation.");
      validation_table_name=training_table_name;
      validation_table_lib=training_table_lib;
   end;

/* Repurpose training table as test, if test table not provided. */
   if test_table_name="" then do; 
      print("No test table specified.  Using training table for test.");
      test_table_name=training_table_name;
      test_table_lib=training_table_lib;
   end;    

/* Train a text classifier for the given target variable */
   textClassifier.trainTextClassifier /               
      table={name=training_table_name, caslib=training_table_lib}
      modelOut={name=model_table_name, caslib=model_table_lib, replace=True}
      target=target_variable
      text=text_variable
      gpu={enable=&gpuEnabled. &deviceArgumentString.}
      batchSize=&batchSize.
      chunkSize=&chunkSize.
      maxEpochs=&maxEpochs.
      seed=&seedNumber.
      testTable={name=test_table_name, caslib=test_table_lib}
      validationPartitionFraction=&validationPartitionFraction.
      validTable={name=validation_table_name, caslib=validation_table_lib}
;

/* Future placeholder : Persist Model Table */

quit;  
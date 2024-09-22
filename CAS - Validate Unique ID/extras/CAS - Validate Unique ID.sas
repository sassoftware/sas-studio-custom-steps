/* SAS templated code goes here */

/*-----------------------------------------------------------------------------------------*
   Macro definition
*------------------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------------*
   This macro creates a global macro variable called _usr_nameCaslib
   that contains the caslib name (aka. caslib-reference-name) associated with the libname 
   and assumes that the libname is using the CAS engine.

   As sysvalue has a length of 1024 chars, we use the trimmed option in proc sql
   to remove leading and trailing blanks in the caslib name.
*------------------------------------------------------------------------------------------*/

%macro _usr_getNameCaslib(_usr_LibrefUsingCasEngine); 

   %global _usr_nameCaslib;
   %let _usr_nameCaslib=;

   proc sql noprint;
      select sysvalue into :_usr_nameCaslib trimmed from dictionary.libnames
      where libname = upcase("&_usr_LibrefUsingCasEngine.") and upcase(sysname)="CASLIB";
   quit;

%mend _usr_getNameCaslib;


/*-----------------------------------------------------------------------------------------*
   Execution code
*------------------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------------*
   Run caslib check macro to obtain the name of the caslib, given the libname using CAS engine.
*------------------------------------------------------------------------------------------*/

%_usr_getNameCaslib(&inputtable_lib.);
%let inputTableLib=&_usr_nameCaslib.;

%_usr_getNameCaslib(&validationtable_lib.);
%let validationTableLib=&_usr_nameCaslib.;


/*-----------------------------------------------------------------------------------------*
   Run CAS procedure
*------------------------------------------------------------------------------------------*/

proc cas;

/*-----------------------------------------------------------------------------------------*
   Obtain values from the UI
*------------------------------------------------------------------------------------------*/

   inputTable=symget("inputtable_name_base");
   inputTableLib=symget("inputTableLib");
   docId=symget("docId_1_name_base");
   validationTable=symget("validationtable_name_base");
   validationTableLib=symget("validationTableLib");


/*-----------------------------------------------------------------------------------------*
   Run CAS action to validate the specified user id
*------------------------------------------------------------------------------------------*/

   textManagement.validateIds /
      table={name=inputTable, caslib=inputTableLib}
      id=docId
      casout={name=validationTable, caslib=validationTableLib, replace=True}
;

quit;


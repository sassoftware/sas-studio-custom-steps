/*----------------------------------------------------------------------------------------*
   This code assumes the name of the table control is inputtable1 
*-----------------------------------------------------------------------------------------*/

%if "%upcase(&inputtable1_engine)"="CAS" %then %do; 
   %let _usr_inputtable1_caslib=%sysfunc(getlcaslib(&inputtable1_lib)); 
%end;
%else %do;
   data _null_;
      putlog "ERROR: The selected input library does not point to a CASlib";
      abort;
   run;
%end;

/*-----------------------------------------------------------------------------------------*
   START MACRO DEFINITIONS.
*------------------------------------------------------------------------------------------*/

/* -----------------------------------------------------------------------------------------* 
   Create a global macro variable for the trigger to run this custom step. A value of 1 
   (the default) enables this custom step to run.  A value of 0 (provided by upstream code)
   sets this to disabled.
*------------------------------------------------------------------------------------------ */

%global _gsd_run_trigger;

%if %sysevalf(%superq(_gsd_run_trigger)=, boolean)  %then %do;
	%put NOTE: Trigger macro variable _gsd_run_trigger does not exist. Creating it now.;
    %let _gsd_run_trigger=1;
%end;

/* -----------------------------------------------------------------------------------------* 
   This macro creates a global macro variable called _usr_nameCaslib
   that contains the caslib name (aka. caslib-reference-name) associated with the libname 
   and assumes that the libname is using the CAS engine.

   As sysvalue has a length of 1024 chars, we use the trimmed option in proc sql
   to remove leading and trailing blanks in the caslib name.
*------------------------------------------------------------------------------------------ */

%macro _usr_getNameCaslib(_usr_LibrefUsingCasEngine); 

   %global _usr_nameCaslib;
   %let _usr_nameCaslib=;

   proc sql noprint;
      select sysvalue into :_usr_nameCaslib trimmed from dictionary.libnames
      where libname = upcase("&_usr_LibrefUsingCasEngine.") and upcase(sysname)="CASLIB";
   quit;

%mend _usr_getNameCaslib;

/*-----------------------------------------------------------------------------------------*
   This macro creates a dataset of IDs on the fly as per number provided by user.
*------------------------------------------------------------------------------------------*/

%macro _gsd_createData;

   data PUBLIC.IDONLY;
	  length ID 8.;
	  %do i=1 %to &numobs.;
	     ID = &i.;
	     output;
	  %end;
   run;

%mend _gsd_createData;


/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE MACRO 
*------------------------------------------------------------------------------------------*/

%macro main_execution_code;

   /*--------------------------------------------------------------------------------------*
      Run the libref check macro in order to obtain the correct Caslib for desired tables.
   *---------------------------------------------------------------------------------------*/
   %global inputCaslib;
   %global outputCaslib;
   
   %_usr_getNameCaslib(&inputtable1_lib.);
   %let inputCaslib=&_usr_nameCaslib.;
   %put NOTE: &inputCaslib. is the input caslib.;
   %let _usr_nameCaslib=;

   %_usr_getNameCaslib(&outputtable1_lib.);
   %let outputCaslib=&_usr_nameCaslib.;
   %let _usr_nameCaslib=;

   /*--------------------------------------------------------------------------------------*
      Generate a dataset of IDs. 
   *---------------------------------------------------------------------------------------*/

   %_gsd_createData;

   proc cas;

      /*-----------------------------------------------------------------------------------*
         Capture inputs from the UI 
      *------------------------------------------------------------------------------------*/

      input_table_lib   = symget("inputCaslib");
      input_table_name  = symget("inputtable1_name_base");
      output_table_lib  = symget("outputCaslib");
      output_table_name = symget("outputtable1_name_base");
	
      /*-----------------------------------------------------------------------------------*
         Load astore to memory. 
      *------------------------------------------------------------------------------------*/

      table.loadTable /
         caslib = input_table_lib,
         path   = input_table_name||".sashdat",
         casout = {name = input_table_name, caslib=input_table_lib, replace=True}
      ;

      /*-----------------------------------------------------------------------------------*
         Load astore to memory. 
      *------------------------------------------------------------------------------------*/

      astore.score /
         table={name = "IDONLY", caslib="PUBLIC"},
         casOut={name = output_table_name, caslib=output_table_lib, replace=True},
         rstore={name = input_table_name, caslib=input_table_lib};

   quit;

   /*--------------------------------------------------------------------------------------*
      Generate a dataset of IDs. 
   *---------------------------------------------------------------------------------------*/

   data &outputtable1.;
	  set &outputtable1.;
	  SYNTHETIC_DATA_FLAG=0;
   run;

%mend main_execution_code;

/*-----------------------------------------------------------------------------------------*
   END OF MACROS
*------------------------------------------------------------------------------------------*/


/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE
   The execution code is controlled by the trigger variable defined in this custom step. This
   trigger variable is in an "enabled" (value of 1) state by default, but in some cases, as 
   dictated by logic, could be set to a "disabled" (value of 0) state.
*------------------------------------------------------------------------------------------*/

%if &_gsd_run_trigger. = 1 %then %do;
   %main_execution_code;
%end;
%if &_gsd_run_trigger. = 0 %then %do;
   %put NOTE: This step has been disabled.  Nothing to do.;
%end;


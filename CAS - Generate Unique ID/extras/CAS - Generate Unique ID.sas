/* SAS templated code goes here */

/*-----------------------------------------------------------------------------------------*
   START MACRO DEFINITIONS.
*------------------------------------------------------------------------------------------*/

/* -----------------------------------------------------------------------------------------* 
   Create a global macro variable for the trigger to run this custom step. A value of 1 
   (the default) enables this custom step to run.  A value of 0 (provided by upstream code)
   sets this to disabled.
   
   Albeit a little unnecessary, to avoid any confusion, the "gui" in the macro variable 
   is a reference to "Generate Unique ID" (the name of this step).
*------------------------------------------------------------------------------------------ */

%global _gui_run_trigger;

%if %sysevalf(%superq(_gui_run_trigger)=, boolean)  %then %do;
	%put NOTE: Trigger macro variable _gui_run_trigger does not exist. Creating it now.;
    %let _gui_run_trigger=1;
%end;


/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE MACRO 
   Driven by user choice from UI. 
*------------------------------------------------------------------------------------------*/

%macro main_execution_code;

/* A common use-case is that the analytics developer desires all variables to be copied over to the output table.   */
/* A trait of the CAS action (textmanagement.generateIds) used below is to automatically copy all variables, if NO variables are selected in the copyVars option. */
/* This current version of the custom step does not specify the copyVars option, therefore implying that all columns get copied over.  Users may edit this custom step to include the copyVars option if they desire. */

   %put "Blank list provided. All Columns will be copied.";


/* Call the CAS action contained within the Text Management action set (which is available within all Viya offerings) */
   proc cas;
      textManagement.generateIds /                            
         casOut={name="&casout_name_base.", caslib="&casout_lib.", replace=TRUE },
         id="&uid_name_base.",
         table={name="&inputtable1_name_base.", caslib="&inputtable1_lib."}
         ;

   quit;

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


%if &_gui_run_trigger. = 1 %then %do;
   %main_execution_code;
%end;
%if &_gui_run_trigger. = 0 %then %do;
   %put NOTE: This step has been disabled.  Nothing to do.;
%end;

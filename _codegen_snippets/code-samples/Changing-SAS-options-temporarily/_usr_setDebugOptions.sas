/*-----------------------------------------------------------------------------*
 This macro remembers the current settings for SAS options symbolgen and mprint 
 before switching them on. It creates global macro variables for all options
 that are being changed.

 This allows for resetting them back to their current settings at the end of
 your custom step.
 *-----------------------------------------------------------------------------*/

%macro _usr_setDebugOptions(debugMode);

%if %qupcase(%bquote(&debugMode))=1 %then %do;
   %* Switch debug mode ON. Custom Step framework always returns 1 for checkbox that is selected;
   %global _usr_defaultSymbolgen _usr_defaultMprint;
   %let _usr_defaultSymbolgen = %sysfunc(getoption(symbolgen));
   %let _usr_defaultMprint = %sysfunc(getoption(mprint));
   options symbolgen mprint;
%end;

%else %if %qupcase(%bquote(&debugMode))=0 %then %do;
   %* Switch debug mode OFF. Custom Step framework always returns 0 for checkbox that is unselected;
   options &_usr_defaultSymbolgen &_usr_defaultMprint;
%end;

%else %do;
   %put ERROR: %bquote(&debugMode) is an unsupported value for the debugMode parameter. Specify 1 or 0 to switch it ON or OFF.;
%end;
 
%mend _usr_setDebugOptions;

/*******************/
/* Some test cases */
/*******************/
%let debugModeCheckbox=1; /* Checkbox in custom step framework always returns the following values 1: selected, 0: unselected */

%_usr_setDebugOptions(&debugModeCheckbox); 
%_usr_setDebugOptions(AND); /% bquote() macro function prevents such a parameter value to cause a macro error */
%_usr_setDebugOptions("1");
%_usr_setDebugOptions(1);
%_usr_setDebugOptions(0);

/* At the end of your custom step codegen remove this SAS macro */
/* using the following code                                     */
%sysmacdelete _usr_setDebugOptions;

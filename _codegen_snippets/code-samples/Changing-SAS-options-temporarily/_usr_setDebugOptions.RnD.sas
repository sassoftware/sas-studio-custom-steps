/***
   Macro that sets certain SAS options and stores the original option
   settings in user-defined global macro variables using a naming
   convention. This so they can be set back to their original value at
   the end of your custom step.
 
   This example uses options related to SAS macros, more specifically
   options that print more detailed macro runtime information to the
   log for debug purposes. But this approach can be used to change
   any SAS option setting that is supported at SAS session level.
 
   This example assumes that the custom step UI has a checkbox
   named _usr_debugCheckbox to activate this special behaviour.
***/
 
%macro _usr_setDebugOptions;
   %global _usr_defaultSymbolgen _usr_defaultMprint;
   %let _usr_defaultSymbolgen = %sysfunc(getoption(symbolgen));
   %let _usr_defaultMprint = %sysfunc(getoption(mprint));
 
   %if &_usr_debugCheckbox. eq 1 %then %do;
      options symbolgen mprint;
      /* Set the flag for resetting overwritten options, so it can be picked up */
      /* by another macro, _usr_restoreOptionSettings, at the end of your step  */
      %let _usr_restoreDebugOptions = 1;
   %end;
%mend _usr_setDebugOptions;
%_usr_setDebugOptions;

/* At the end of your custom step codegen remove this SAS macro */
/* using the following code                                     */
%sysmacdelete _usr_setDebugOptions;
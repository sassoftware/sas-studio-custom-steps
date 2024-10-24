/***
   Macro that restores option settings to their original values and
   relies on the user-defined global macro variables that were
   set by macro usr_setDebugOptions.
***/
 
%macro _usr_restoreOptionSettings;
 
   %if &_usr_restoreDebugOptions. eq 1 %then %do;
      options &_usr_defaultSymbolgen. &_usr_defaultMprint;
   %end;
 
%mend _usr_restoreOptionSettings;
%_usr_restoreOptionSettings;

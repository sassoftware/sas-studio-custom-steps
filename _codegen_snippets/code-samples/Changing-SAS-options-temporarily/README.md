# Changing SAS Options temporarily

## Background

Sometimes you want to change the values of a SAS option in your custom step, so the step exposes certain behaviour.

Best practice is to only change those setting for the duration of your custom step and then restore the option settings to their original values at the end of your custom step.

A common example would be where your step supports a "debug" option. The custom step UI would have a checkbox "Run in debug mode", that might change SAS options settings. Or perhaps such a debug option would not delete intermediate tables created by your custom step that you would normally delete at the end of your custom step. There are many other scenarios possible.

Here is an example that changes SAS options that specify how much detail is shown in the SAS log when you execute SAS macros. It retrieves and stores the current values of specific settings before overwriting them. The macro supports a parameter to switch specific debug options on or off. 

```SAS
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
```

The code shown in the example above can can be found in [_usr_setDebugOptions.sas](_usr_setDebugOptions.sas)

Or you could use two separate macros,one for setting options to a specific value and one for restoring the original settings. Examples can be found in [_usr_setDebugOptions.RnD.sas](./_usr_setDebugOptions.RnD.sas) and [_usr_restoreOptionSettings.RnD.sas](./_usr_restoreOptionSettings.RnD.sas)

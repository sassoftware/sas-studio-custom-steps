# Changing SAS Options temporarily

## Background

Sometimes you want to change the values of a SAS option in your custom step, so the step exposes certain behaviour.

Best practice is to only change those setting for the duration of your custom step and then restore the option settings to their original values at the end of your custom step.

A common example would be where your step supports a "debug" option, eg. by having a checkbox in your UI "Run in debug mode", that might change SAS options so it prints generated macro statements and values for macro variables in the SAS log independent of what the configuration settings are for the SAS Compute Context that is in use. Or perhaps such a debug option would not delete intermediate tables created by your custom step that you would normally delete at the end of your custom step. There are many other scenarios possible.

An example of how you could do this is in a single SAS macro that has an option to switch options on or off can be found in [_usr_setDebugOptions.sas](_usr_setDebugOptions.sas)

Or you could use two separate macros,one for setting options to a specific value and one for restoring the original settings. The can be found in [_usr_setDebugOptions.RnD.sas](./_usr_setDebugOptions.RnD.sas) and [_usr_restoreOptionSettings.RnD.sas](./_usr_restoreOptionSettings.RnD.sas)

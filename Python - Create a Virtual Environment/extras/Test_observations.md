# Testing Bugs encountered

The following is more an internal focussed activity (and perhaps won't / needn't be included).  To illustrate bugs or errors that came about during a test of this custom step (in the hope that it promotes awareness / learning)

1. Testing of [Python - Switch Environments](../../Python%20-%20Switch%20Environments/) raised this error, which gives us the lesson that ORIGINAL_PYPATH should be made global.

```sas
399  %put &_switchenv_error_desc.;
ERROR: ORIGINAL_PYPATH does not exist. Cannot revert to original environment.
400  %put NOTE: Error desc if any - &_switchenv_error_desc. ;
NOTE: Error desc if any - ERROR: ORIGINAL_PYPATH does not exist. Cannot revert to original environment.
401  

```


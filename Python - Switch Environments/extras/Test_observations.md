# Testing Bugs encountered

The following is more an internal focussed activity (and perhaps won't / needn't be included).  To illustrate bugs or errors that came about during a test of this custom step (in the hope that it promotes awareness / learning)

1. Check environment variables (also happens if you base your code on existing code)

```sas
WARNING: Apparent symbolic reference _CVIRENV_ERROR_FLAG not resolved.
ERROR: A character operand was found in the %EVAL function or %IF condition where a numeric operand is required. The condition was: 
       &_cvirenv_error_flag. = 0 
ERROR: The macro _SWITCHENV_EXECUTION_CODE will stop executing.
```

2. Debug section variables need to be commented out prior to any production code test.
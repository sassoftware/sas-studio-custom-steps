# Programmatically Stop Flow Execution

## Background
Sometimes there is a need to stop the execution of SAS code at runtime, as you might not be able to capture all restrictions in the
custom step UI itself. Therefore the generated code needs to perform validation at runtime and then programmatically stop flow execution
when required pre-conditions are not met. 

One example would be where the custom step requires both the input and output table to reside in a libref that points to a caslib.
The custom step UI doesn't provide an option to the step author to check this as usage time, so this can only be done at runtime.

SAS supports the **abort** statement in a data step, and the **%abort** macro statement inside a macro to stop SAS code execution. Both have very similar capabilities.

**Note**: Using **abort abend** is discouraged, as the abend option would remove the current SAS session from underneath SAS Studio and
cause the user to have to reset the current SAS session. 

### Example - Using abort statement in data step
To programmatically stop code execution use the **abort** statement in a data step. Then precede it with a put or putlog statement that explains the reason why. More details about that the abort statement can be found here: [SAS Documentation for the abort statement](https://go.documentation.sas.com/doc/en/pgmsascdc/default/lestmtsref/p0hp2evpgqvfsfn1u223hh9ubv3g.htm).

Here is a simple code sample and a screenshot to show how this presents itself in SAS Studio
```SAS
data _null_;
    putlog "ERROR: aborting this step because ...";
    abort cancel;
run;
```
 ![](abort%20in%20SAS%20Studio%20after%20put%20error%20statement%20-%20screenshot.png)

### Example - Using %abort macro statement
This statement cannot be used in open code, so it needs to be inside a macro. It provides capabilities similar to the abort statement. [SAS Documentation for the %abort macro statement](https://go.documentation.sas.com/doc/en/pgmsascdc/default/mcrolref/p0f7j2zr6z71nqn1fpefnmulzazf.htm)

Note: When using the %abort macro statement, the popup message on the step in the flow that was aborted does not show the line number where processing stopped. But the Submitted Code and Results tab in the Flow, allows you to click on the error message and will then navigate to the line that generated that error.

Here is a simple code sample and a screenshot to show how this presents itself in SAS Studio
```SAS
%macro test;
   %put ERROR: aborting this step because ...;
   %abort;
%mend test;
%test;
```
 ![](%25abort%20in%20SAS%20Studio%20after%20put%20error%20statement%20-%20screenshot.png)

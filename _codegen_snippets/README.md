# SAS code snippets for common tasks in code generator of a SAS Studio Custom Step

## Background

Collection of code snippets to make it easy/easier for contributors of SAS Studio Custom Steps to implement common "tasks" in the code generator part of a custom step. This should not only make things easier for contributors, but also allow for more standardized and more robust code generators.

| Topic | Notes |
| --- | --- |
| [Changing SAS options temporarily](./code-samples/Changing-SAS-options-temporarily) | Typically used to switch debugging options on/off |
| [Check SAS Server or SAS Content location](./code-samples/Check-SASServer-SASContent) | If your SAS code only supports a file/folder location on the SAS Server, or only supports a file/folder location in SAS Content, then have your SAS code check what has been selected and issue an error when needed.
| [Programmatically stop Flow execution](./code-samples/Programmatically-Stop-Flow-Execution) | Sometimes there is a need to stop the execution of SAS code at runtime, as you might not be able to capture all restrictions in the custom step UI itself. |
| [Retrieving list of selected columns from a Column Selector control for use in Base SAS, SQL, CASL](./code-samples/Get-Column-Selector-items) | Lists of columns have slighly different syntax in Base SAS, SQL, and CASL |
| [Retrieving caslib associated with libname that is using cas engine](./code-samples/Get-CAS-Library-Name) | The SAS Studio UI surfaces SAS library definitions and some of those libraries could point to a caslib. If your SAS code wants to execute a CAS action when the selected table is a CAS table, your code generator needs to know which caslib is being used by the libname. This because the **caslib=** parameter of a CAS action only understands about caslib names and not about libnames. |
| [Reuse existing CAS session when using SWAT](./code-samples/Reuse-CAS-session-from-SWAT) | There are situations where you have Python logic that uses SWAT that you would want to use in a custom step. It's strongly recommended that if the existing Compute session has started a CAS session, that CAS session is reused by SWAT. |


## Ideas for enhancements 
* drop CAS table 
* check if table exists in libname
* ...
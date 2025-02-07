# SAS Coding Best Practices

We will only list some basic guidelines here, promoting readability, comprehension and appearance.  
Btw. also check out [sasjs/lint](https://github.com/sasjs/lint).
 1. Code should not produce Errors, Warnings or Concerning Notes in SAS log. Code snippets to check user input for some common scenarios that cannot be performed in the custom step UI itself, can be found in [SAS code snippets for common tasks in code generator of a SAS Studio Custom Step](https://github.com/sassoftware/sas-studio-custom-steps/blob/main/_codegen_snippets/README.md). 
 2. Indent using spaces instead of tabs
 3. Be consistent with indentation increments
 4. Indent conditional blocks and DO groups, and do it consistently, the logic will be easier to follow
 5. Avoid mixing symbol and mnemonic versions of comparison operators and use one style consistently
 6. End DATA-steps and PROC-steps with a RUN statement. End interactive procedures, such as proc sql and proc datasets, with a QUIT statement.
 7. Group non-executable statements (length, attrib, retain, format, informat, etc.) at the top of a data step before executable statements
 8. Two level data set names should always be used, which includes specifying WORK library
 9. When available, use string functions that support UTF-8 data. For example, use kfind(...) rather than find(...).  
    See [Internationalization Compatibility for SAS String Functions](https://documentation.sas.com/?cdcId=pgmsascdc&cdcVersion=default&docsetId=nlsref&docsetTarget=p1pca7vwjjwucin178l8qddjn0gi.htm)
    for more details
10. When changing SAS option settings, return the setting to the original value after you are done with them. An example is shown below:

    ```SAS
    %local etls_syntaxcheck;  
    %let etls_syntaxcheck = %sysfunc(getoption(syntaxcheck));
    
    /* Turn off syntaxcheck option to perform following steps*/
    options nosyntaxcheck;
    %local etls_obs;
    %let etls_obs = %sysfunc(getoption(obs));
    
    /* Set obs option to max to perform following steps  */
    options obs = max;
    
    /* Code that does the actual work (data processing) goes here */
    
    /* Reset obs option to previous setting  */
    options obs = &etls_obs;
    
    /* Reset syntaxcheck option to previous setting  */
    options &etls_syntaxcheck;
    ```
11. Remove all items created after you are done with them
    * Remove all temporary datasets (typically created in work and/or casuser) after you are done with them and they are not part of the output
    * Reset all titles, footnotes after you are done with them

12. Use a naming prefix for temporary tables consider that is specific to your custom step
    * It allows to more easily identify those tables in the Explorer panel. Even though these tables would automatically be deleted (see #11 above), when
      the step runs into issues, it allows the user to more easily identy those steps and inspect their content for debugging purposes.
    * A common approach is to start with an underscore, followed by the first character of each word of your custom step, followed by an underscore.
      So if your step is named Great Data Transformation, then the prefix would be \_GDP\_
    * For steps with very complex processing logic, consider providing a "Run in debug mode" option in the custom step UI that will skip deleting the
      temporary tables at the end of the step.

 13. Use the macro name on the %mend statement. It makes the code easier to read, especially when you have many macros and/or nested macros.
     
 14. Remove SAS macro variables and SAS macros at the end of step when they are not needed anymore.
     ```SAS
     /* Example SAS macro variable definition */
     %let myUserDefinedMacroVariable=The answer is 42;
     
     /* Example SAS macrodefinition */
     %macro myUserDefinedMacro;
         %put Hello World;
     %mend myUserDefinedMacro */
     ```
     
     ```SAS
     /* Removing user-defined SAS macro variables */
     %symdel myUserDefinedMacroVariable /nowarn;
     
     /* Removing user-defined SAS macros */
     %sysmacdelete myUserDefinedMacro / nowarn; 
     ```

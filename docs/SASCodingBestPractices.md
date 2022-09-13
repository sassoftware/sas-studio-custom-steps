# SAS Coding Best Practices

We will only list some basic guidelines here, promoting readability, comprehension and appearance.  
Btw. also check out [sasjs/lint](https://github.com/sasjs/lint).
 1. Code should not produce Errors, Warnings or Concerning Notes in SAS log
 2. Indent using spaces instead of tabs
 3. Be consistent with indentation increments
 4. Indent conditional blocks and DO groups, and do it consistently, the logic will be easier to follow
 5. Avoid mixing symbol and mnemonic versions of comparison operators and use one style consistently
 6. End DATA-steps and PROC-steps with a RUN statement. End interactive procedures such as proc sql and proc datasets with a QUIT statement.
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
    * Remove all datasets created in work and casuser after you are done with them and they are not part of the output
    * Reset all titles, footnotes after you are done with them

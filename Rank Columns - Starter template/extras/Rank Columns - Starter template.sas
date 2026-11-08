/*************************************************************
PROC RANK for multiple columns and additional option.
*************************************************************/

/* Example of using a macro to loop through a variable set of
   values from a control to build a list of values. */

%let columnsToRankList=;
%let newColumnsList=;

/* Name of the UI control that shows the list of selected columns
   is: rankColumns */
%macro columnSelectorToSingleMacrovar; 
     %do i = 1 %to &rankColumns_count;
         %let columnsToRankList= &columnsToRankList &&rankColumns_&i._name;
         %if &createNewVariables=1 %then %do;
             %let newColumnsList=&newColumnsList rank_&&rankColumns_&i._name;
         %end;
     %end;
%mend columnSelectorToSingleMacrovar;

%columnSelectorToSingleMacrovar;

/* Take all of the input and put together the final code */
proc rank data=&inTable out=&outTable ties=&ties;
    var &columnsToRankList;
    %if &createNewVariables=1 %then %do;
        ranks &newColumnsList;
     %end;
run;

/* Cleanup macros and macro variables that were created in this
   user-defined code generator, using standard macros that are generated
   by the SAS Studio Flow framework. 
   The definition of these macros can be seen in the generated code when
   a custom step is run in Flow mode or run in Standalone mode. */
%_flw_del_macro_vars(columnsToRankList newColumnsList);
%_flw_del_macros(columnSelectorToSingleMacrovar);

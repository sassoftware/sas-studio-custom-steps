/* Dummy entry, named _template, used in sample readme file */
/* SAS templated code goes here */

/*-----------------------------------------------------------------------------------------*
   START Macro definitions.
*------------------------------------------------------------------------------------------*/
%let _myMacroVariable=456;

%macro _doIt;
   %if &_myMacroVariable=123 %then %do;
      data work._myIntermediate;
         var1="&_myMacroVariable";
      run;
   %end;
   %else %do;
      /*-----------------------------------------------------------------------------------------*
         Writing ERROR: to the SAS log results in the custom step be set in Error mode,
         and hovering over the node will show that error message.
      *------------------------------------------------------------------------------------------*/
      %put ERROR: _myMacroVariable needs to have value 123;
   %end;
%mend _doIt; 

/*-----------------------------------------------------------------------------------------*
   END Macro definitions.
*------------------------------------------------------------------------------------------*/

%_doIt;

/*-----------------------------------------------------------------------------------------*
   Clean up intermediate tables, macro variables and macro definitions.
*------------------------------------------------------------------------------------------*/
proc datasets lib=work noprint nowarn;
   delete _myIntermediate;
run; quit;

/*-----------------------------------------------------------------------------------------*
  Delete user-defined SAS macros and SAS macro variables using nowarn option. This to 
  prevent warning messages in SAS log in case the item does not exist because it is only
  created conditionally depending on user selections. A valid use case. 
  Using nowarn avoids the need for the step author to add additional logic that first checks whether
  the item exists before trying to delete it.
*------------------------------------------------------------------------------------------*/
%symdel _myMacroVariable / NOWARN;
%sysmacdelete _doIt / NOWARN;
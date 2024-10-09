/* SAS templated code goes here */

/* Make use of utility macro to obtain a list of selected variables, separated by spaces */
%let blankSeparatedList = %_flw_get_column_list(_flw_prefix=copyVarColumns);

/* Create a table of the columns to be copied, which can be merged with the output table. */
data work._temp_table_ (keep= &docId. &blankSeparatedList.);
   set &inputtable.;
run;

/* Call the CAS action contained within the Text Management action set (which is available within all Viya offerings) */
proc cas;

/* Note: Even though the identifyLanguage action already has a copyVars parameter, this is deliberately not being used, due to some known issues with copyVars under investigation */

/* Run the identifyLanguage action */
textManagement.identifyLanguage /
   table = {name="&inputtable_name_base.", caslib="&inputtable_lib."}
   text="&TEXTVAR_1_NAME_BASE."
   docId = "&DOCID_1_NAME_BASE."
   casout={name="&casout_name_base.", caslib="&casout_lib.", replace=True}
;

/* Future placeholder:  Add an option to filter for specific languages */

quit;

/* The following test is to check if additional copyVars columns are blank.  If so, then nothing happens. Otherwise, an additional step is carried out to merge the output data with the set of additional columns. */

%if %sysevalf(%superq(blankSeparatedList)=,boolean)  %then %do;
   %put "Blank list provided. No other columns will be copied.";
%end;
%else %do;

   data &casout.;
      merge &casout.(in=a) work._temp_table_ (in=b);
      by &docId.;
      if a;
   run;
   

%end;


/* Clean up - remove temp table */
proc datasets lib=work;
   delete _temp_table_;
quit;
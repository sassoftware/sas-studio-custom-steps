/* SAS templated code goes here */

/* Extract name of folder from user interface */
data _null_;
   call symput("folderName",scan("&folderName.",2,":","MO"));
run;

/* If a status table has not been specified, assign output_status_table macro variable as "_NULL_"; */
%if %symexist(output_status_table) = 0 %then %do;
   %let output_status_table=_NULL_;
%end;

/* Delete the Repo */
data &output_status_table.;
/* rc stands for return code which captures any errors or messages that occur during the git cloning process. */
   rc = GIT_DELETE_REPO("&folderName.");
/* The return code for deletes is (currently) very simple - 0 for successful and -1 for not successful */

run;
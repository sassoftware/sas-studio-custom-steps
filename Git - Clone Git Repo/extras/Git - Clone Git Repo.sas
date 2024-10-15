/* SAS templated code goes here */

/* Extract values from user interface */
data _null_;
   call symput("folderName",scan("&folderName.",2,":","MO"));
   call symput("publicKeyFile",scan("&publicKeyFile.",2,":","MO"));
   call symput("privateKeyFile",scan("&privateKeyFile.",2,":","MO"));
run;

/* If a status table has not been specified, assign output_status_table macro variable as "_NULL_"; */
%if %symexist(output_status_table) = 0 %then %do;
   %let output_status_table=_NULL_;
%end;

/* If a details table has not been specified, assign git_folder_table macro variable as "_NULL_"; */
%if %symexist(git_folder_table) = 0 %then %do;
   %let git_folder_table=_NULL_;
%end;

/* Clone the Repo */
data &output_status_table.;
/* rc stands for return code which captures any errors or messages that occur during the git cloning process. */
   rc = GIT_CLONE("&gitrepo.","&folderName.","&sshUser.","&sshKeyPassword.","&publicKeyFile.","&privateKeyFile.");
/* Save the return code inside a macro variable */
   call symput("gcrc",rc);
run;

/* Create Output Status Table based on Return Code */
%if &gcrc=0 %then %do;

   data &git_folder_table.;
   length folder_name $200. type $6. level 8.;
   folder_name="&folderName.";
   type="Folder";
   level=0;
   output;
   run;

/* FUTURE PLACEHOLDER: This above dataset will be enriched with many more details such as a listing of all assets within itself and subdirectories, as well as codifying the same within macro variables. */

%end;
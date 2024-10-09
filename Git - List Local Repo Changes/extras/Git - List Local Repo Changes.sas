/* SAS templated code goes here */

/* The below macro deals with cases when the user decides to promote their table to CAS */

%macro promTable;

/* Check if table needs to be promoted to CAS */
   %if "&promote_table." = "1" %then %do;

/* Create a temporary CAS session */
      cas temp_session;
      caslib _all_ assign;


/* Create a temporary session-scope CAS table to hold the table of changes */
      data PUBLIC.TEMP_GIT_CHANGE_TABLE;
         set &git_change_table.;
      run;


      proc cas;

         /* Helper functions */

         /* To check if an in-memory table exists in a caslib */
         function doesTableExist(casLib, casTable);
            table.tableExists result=tableExistsResultTable status=rc / caslib=casLib, table=casTable;
            tableExists = dictionary(tableExistsResultTable, "exists");
            return tableExists;
         end;

         /* To drop an in-memory table if it already exists */
         function dropTableIfExists(casLib,casTable);
            tableExists = doesTableExist(casLib, casTable);
            if tableExists != 0 then do;
               print "Dropping table: "||casLib||"."||casTable;
               table.dropTable status=rc / caslib=casLib, table=casTable, quiet=True;
               if rc.statusCode != 0 then do;
                  exit();
               end;
            end;
         end;

/* End Helper Functions */

         /* As the table needs to be promoted, both session and global table need to be removed (if they exist).   */
         /* Therefore dropTableIfExist is called twice:                                                            */
         /*  - If both session and global table exist, the first call will remove the session table,               */
         /*      the second call will remote the global (promoted) table                                           */
         /*  - If only session or global table exist, the first call will delete it, the second call is a no-op    */
         /*  - If neither session or global table exist, both calls are no-op                                      */

         dropTableIfExists("PUBLIC","&gitChangeTableName.");
         dropTableIfExists("PUBLIC","&gitChangeTableName.");
         print "Trying run code";
         
         /* Create a session-scope table based on the temporary table of changes */ 
         
         dataStep.runCode /
            code="data PUBLIC.&gitChangeTableName.; set PUBLIC.TEMP_GIT_CHANGE_TABLE;run;";

         /* Promote table to global scope within Public (ensure you can write to shared Public caslib) */
         table.promote /
            caslib= "PUBLIC"
            name="&gitChangeTableName."
            drop=True
            targetlib= "PUBLIC"
          ;
      quit;

/* Terminate temporary CAS session */
      cas temp_session terminate;
      
   %end;

%mend promTable;


/* Check Folder provided */
data _null_;
call symput("serverType",scan("&folderName.",1,":","MO"));
run;

/* Carry out further activities only if folder is within filesystem */

%if "&serverType."="sasserver" %then %do;

/* Extract values from user interface */
   data _null_;
      call symput("folderName",scan("&folderName.",2,":","MO"));
      call symput("gitChangeTableName", scan("&git_change_table.",2,".","MO"));
   run;

/* Obtain status and create dataset of changed files */
   data &git_change_table.;
      length path $2000. status $20. staged $10. folderName $100.;

      folderName="&folderName.";

/* n contains the total number of files with a changed status */
      n = git_status("&folderName.");

/* For each n, obtain status , path of file, and staged status */
      do n = 1 to n;
         rc1=git_status_get(n,"&folderName.", "path", path);
         rc2=git_status_get(n,"&folderName.", "status", status);
         rc3=git_status_get(n,"&folderName.","staged", staged);
         output;
      end;
   run;

   %promTable;

%end;
%else %do;

   %put "Not a filesystem folder. Exiting";

%end;



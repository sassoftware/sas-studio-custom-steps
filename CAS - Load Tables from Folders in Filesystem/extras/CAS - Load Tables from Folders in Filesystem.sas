proc cas;

   /* Retrieve all relevant macro variable values that represent selections in the UI */
   folderName=symget("folderName");
   folderPath=scan(folderName,2,":","MO");
   fileType=symget("fileType");
   fileNamePattern=symget("fileNamePattern");
   outputCaslib=symget("outputCaslib");
   promoteFlag=symget("promoteFlag");

   if fileType="ALL" then fileType='%';
   /* FUTURE PLACEHOLDER: Accommodate multiple filetypes (i.e. between 1 single file type and ALL) */


   /* START - Define helper functions */

   function doesTableExist(casLib, casTable);
      table.tableExists result=tableExistsResultTable status=rc / caslib=casLib, table=casTable;
      tableExists = dictionary(tableExistsResultTable, "exists");
      return tableExists;
   end;

   function whichCaslibUsesThisPath(folderPath);
      table.caslibInfo result=result / showHidden=TRUE, srcType="ALL", verbose=TRUE;

      /* We check if the given path is already part of a list of caslibs,*/
      /* and therefore already assigned                                  */
      /* Note that the folder path may sometimes have a "/" appended ,   */
      /* therefore checking for both cases.                              */


      if dim(result.CasLibInfo.where(Path=folderPath or Path=folderPath||"/"))>0 then do;
         /* If the path already exists within a caslib, we assign the caslib name to the caslibname variable. */

         caslibName=result.CasLibInfo.where(Path=folderPath or Path=folderPath||"/")[1]["Name"];
         return caslibName;
      end;

      else do;
         /* Otherwise, we return  false to the calling code, indicating that they could make a decision for the new path */
         return(false);
      end;
   end;

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

   function isServerFolder(folderName);
      folderType = scan(folderName,1,":");
      /* In CASL checks for boolean values are case-insensitive */
      /* so True/TRUE/true/tRuE are equivalent                  */
      select(upcase(folderType));
         when('SASSERVER') return(true);
         otherwise return(false);
      end;
   end;

   function loadTableFromFileName(fileName,inputCaslib,OutputCaslib);
      /* Function parameters:                                                                                      */
      /*    - fileName     : name of a file including file extension, without directory info                       */
      /*    - inputCaslib  : name of caslib containing the file                                                    */
      /*    - outputCaslib : name of target caslib where file will be loaded into                                  */

      tableName=scan(fileName,1,".","MO");
      /* Warning: When not specifying the file extension during load, CAS will apply a preference and might not    */
      /*          load the file with the extension you intended. Eg. sashdat before csv/txt/...                    */

      if promoteFlag='0' then do;
         /* Load the table without promote                                                                         */

         /* As the table will not be promoted, simply use replace=True to overwrite existing session table         */
         /* Using result= to suppress extra lines in SAS log                                                       */
         /* Using path= and specifying file name including extension, incase file exist mulitple times with        */
         /*   different extensions. This to ensure that the intended file extension is used.                       */
         table.loadTable result=resultTable status=rc /
            caslib=inputCaslib,
            path=fileName,
            casOut={caslib=outputCaslib, replace=True}
            ;
      end;
      else do;
         /* Load and promote the table.                                                                            */

         /* As the table needs to be promoted, both session and global table need to be removed (if they exist).   */
         /* Therefore dropTableIfExist is called twice:                                                            */
         /*  - If both session and global table exist, the first call will remove the session table,               */
         /*      the second call will remote the global (promoted) table                                           */
         /*  - If only session or global table exist, the first call will delete it, the second call is a no-op    */
         /*  - If neither session or global table exist, both calls are no-op                                      */
         dropTableIfExists(outputCaslib,tableName);
         dropTableIfExists(outputCaslib,tableName);

         /* Using result= to suppress extra lines in SAS log                                                       */
         table.loadTable result=resultTable status=rc / /* Using result= to suppress extra lines in output */
            caslib=inputCaslib,
            path=fileName,
            casout={caslib=outputCaslib, promote=True}
            ;
      end;

      return(rc.statusCode);

      end;

      /* END - Define helper functions */

      /* We will assume the user has selected a directory that is not mapped by an existing caslib.   */
      /* Therefore, a caslib will be created temporarily, to be used by table.loadTable and the       */
      /* caslib will be deleted after all requested files have been processed.                        */

      if isServerFolder(folderName)!=true then do;
         print "Folder: "!!folderName!!"is not a SAS Server folder";
         print "Exiting now ...";
         /* This exists current run-group in proc cas, subsequent run-groups are stil going to be run */
         exit;
      end; 
      else print "Valid folder";

      /* We will check if a path (and a corresponding caslib) already exists.                 */
      /* If it exists, we don't create the caslib;  Otherwise, we create the temporary caslib */
      tmpSourceCaslib = whichCaslibUsesThisPath(folderPath);

      if tmpSourceCaslib then do;
         mainLoadOfFiles(tmpSourceCaslib);
      end;
      else do;
         tmpSourceCaslib="LoadCASFSTemp";
         table.addCaslib result=result /
            name=tmpSourceCaslib,
            dataSource={srcType="path"},
            path=folderPath
            ;

         mainLoadOfFiles(tmpSourceCaslib);

         table.dropCaslib / 
            caslib=tmpSourceCaslib
            ;
      end;

   /* Hoisting Main Processing Function here */

   function mainLoadOfFiles(tmpSourceCaslib);
      /* FUTURE PLACEHOLDER: Need better explanation of pattern definitions in UI                                                               */
      /* Patterns are tricky as table.fileInfo action has its own syntax for wildcard characters                                                */
      /* Doc URL: https://go.documentation.sas.com/doc/en/pgmsascdc/default/caspg/p1xt9526uq5etwn1vmnk8koh0k6y.htm#n0y2zj2e81x5y5n1onqq4tibcn5h */

      table.fileInfo result = result /
         caslib=tmpSourceCaslib,
         path='%'||fileNamePattern||'%'||fileType,
         wildsensitive=false /* Ignore casing specified in pattern */
         ;

      /* FUTURE PLACEHOLDER - Idea: Perhaps create an output table that lists all the files that were found and their load status */
      nFiles = dim(result.FileInfo);
      do i = 1 to nFiles;
         print "Loading file "!!i!!"of "!!nFiles!!": "!!result.FileInfo[i,"Name"];
         fileStatus=loadTableFromFileName(result.FileInfo[i,"Name"], tmpSourceCaslib, outputCaslib);
         print "Return Code: "!!fileStatus;
         print " ";
      end;
   end;

quit;


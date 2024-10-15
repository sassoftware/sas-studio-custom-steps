/* SAS templated code goes here */

/*-----------------------------------------------------------------------------------------*
   This macro creates a global macro variable called _usr_nameCaslib
   that contains the caslib name (aka. caslib-reference-name) associated with the libname 
   and assumes that the libname is using the CAS engine.

   As sysvalue has a length of 1024 chars, we use the trimmed option in proc sql
   to remove leading and trailing blanks in the caslib name.
*------------------------------------------------------------------------------------------*/

%macro _usr_getNameCaslib(_usr_LibrefUsingCasEngine); 

   %global _usr_nameCaslib;
   %let _usr_nameCaslib=;

   proc sql noprint;
      select sysvalue into :_usr_nameCaslib trimmed from dictionary.libnames
      where libname = upcase("&_usr_LibrefUsingCasEngine.") and upcase(sysname)="CASLIB";
   quit;

%mend _usr_getNameCaslib;

/*-----------------------------------------------------------------------------------------*
  Call the above "caslib check" macro for each of the required tables (and their libnames)
  presently connected to this step.
*------------------------------------------------------------------------------------------*/

%_usr_getNameCaslib(&inputTable_lib.);
%let input_table_lib=&_usr_nameCaslib.;

%if "&input_table_lib."="" %then %do;
   %put ERROR: Please provide a valid input table and libref using the CAS engine.;
   data _null_;
      abort exit 4321;
   run;
%end;

/* Blank out the _usr_nameCaslib macro variable so as to not leave things dangling.       */
%let _usr_nameCaslib=;

%_usr_getNameCaslib(&outputTable_lib.);
%let output_table_lib=&_usr_nameCaslib.;

%if "&output_table_lib."="" %then %do;
   %put ERROR: Please provide a valid output table and libref using the CAS engine.;
   data _null_;
      abort exit 4321;
   run;
%end;

/* Blank out the _usr_nameCaslib macro variable so as to not leave things dangling.       */
%let _usr_nameCaslib=;

%_usr_getNameCaslib(&matchOut_lib.);
%let matchout_table_lib=&_usr_nameCaslib.;

%if "&matchout_table_lib."="" %then %do;
   %put ERROR: Please provide a valid output matches table and libref using the CAS engine.;
   data _null_;
      abort exit 4321;
   run;
%end;

/* Blank out the _usr_nameCaslib macro variable so as to not leave things dangling.       */
%let _usr_nameCaslib=;

/*-----------------------------------------------------------------------------------------*
   This block of code handles the copy of specified input table columns to the output 
   table. For this purpose, we make use of a utility macro to obtain a list of selected
   variables, separated by spaces. 

   We then handle two possible scenarios - one in which no additional columns were selected,
   and the other in which one of more columns were selected - within an %IF block in open
   code. If no columnns are selected, then a string (representing the copyVars option of 
   the CAS action) is set to blank. Otherwise, a string containing the copyVars code 
   block (e.g. copyVars={"a..",".."}) is created with selected columns populated.

   Note : For those interested, a little dated but insightful SAS Global Forum paper on 
   the best way to evaluate if a macro variable is blank (as used below), provided here:
   http://support.sas.com/resources/papers/proceedings09/022-2009.pdf

   CAS requires a quoted list of comma-separated values within its action calls, therefore
   we carry out some string substitution to convert the space-separated list into a quoted,
   comma-separated list.
*------------------------------------------------------------------------------------------*/

%let blankSeparatedList = %_flw_get_column_list(_flw_prefix=outputTableColumns);

%if %sysevalf(%superq(blankSeparatedList)=,boolean)  %then %do;
   %put "Blank list provided. All Columns will be copied.";
   %let commaSeparatedList=;
   %let copyVarStringPre=;
   %let copyVarStringPost=;
%end;
%else %do;
/* The following utility macro creates a comma-separated list from the space separated list */
   %let commaSeparatedList = %_flw_get_column_list(_flw_prefix=outputTableColumns, _delim=%str(,));
/* Create quoted, comma-separated lists for use inside a CAS action                         */
   data _null_;
      call symput("commaSeparatedList",'"'||tranwrd("&commaSeparatedList.",",",'","')||'"');
   run;
/* Additional values for preceding and succeeding text, yielding copyVars={"a","b","c"}    */
   data _null_;
      call symput("copyVarStringPre","copyVars={");
      call symput("copyVarStringPost","}");
   run;
%end;



/*-----------------------------------------------------------------------------------------*
   This is the main block of code which calls the applySentimentConcepts action. 
   Prior to calling the action, we obtain necessary inputs from the UI, associate the 
   desired language with a language-specific sentiment model, and load the model for use
   within the action. Some helper functions facilitate the same
*------------------------------------------------------------------------------------------*/
proc cas;

/*-----------------------------------------------------------------------------------------*
   Helper functions
*------------------------------------------------------------------------------------------*/

/* langToSentFile - function to provide a corresponding sent file for a given language     */

   function langToSentFile(language);
      if language = "Arabic" then return "ar_sentiment_liti.sashdat";
      else if language = "Chinese" then return "zh_sentiment_liti.sashdat";
      else if language = "Danish" then return "da_sentiment_liti.sashdat";
      else if language = "Dutch" then return "nl_sentiment_liti.sashdat";
      else if language = "English" then return "en_sentiment_liti.sashdat";
      else if language = "Farsi" then return "fa_sentiment_liti.sashdat";
      else if language = "French" then return "fr_sentiment_liti.sashdat";
      else if language = "German" then return "de_sentiment_liti.sashdat";
      else if language = "Hungarian" then return "hu_sentiment_liti.sashdat";
      else if language = "Italian" then return "it_sentiment_liti.sashdat";
      else if language = "Japanese" then return "ja_sentiment_liti.sashdat";
      else if language = "Korean" then return "ko_sentiment_liti.sashdat";
      else if language = "Norwegian" then return "no_sentiment_liti.sashdat";
      else if language = "Portuguese" then return "pt_sentiment_liti.sashdat";
      else if language = "Spanish" then return "es_sentiment_liti.sashdat";
      else if language = "Swedish" then return "sv_sentiment_liti.sashdat";
      else if language = "Turkish" then return "tr_sentiment_liti.sashdat";
   end;

/* doesTableExist - provides an indicator whether a CAS table is loaded in memory or not  */

   function doesTableExist(casLib, casTable);
      table.tableExists result = tableExistsResultTable status = rc / caslib = casLib, table = casTable;
      tableExists = dictionary(tableExistsResultTable, "exists");
      return tableExists;
   end;
   
/* loadSentFile - Loads a predefined sentiment analysis file if needed                    */

   function loadSentTable(sentTable,sentfile);
      sentTableExists = doesTableExist("referenceData",sentTable);
      if sentTableExists = 0 then do;
         table.loadTable /
            casout = {name=sentTable,caslib="referenceData"}
            caslib ="referenceData"
            path = sentfile
         ;
      end;
   end;
/*  End - Helper Functions.                                                                */


/*  Read in variables from the UI                                                          */
   language = symget("language");
   input_table_name = symget("inputTable_name_base");
   input_table_lib = symget("input_table_lib");
   output_table_name = symget("outputTable_name_base");
   output_table_lib = symget("output_table_lib");
   matchout_table_name = symget("matchOut_name_base");
   matchout_table_lib = symget("matchout_table_lib");

/*-----------------------------------------------------------------------------------------*
   Load Sentiment model and call action.
   Note: The predefined sentiment analysis tables are available in the referenceData caslib
   and may not all be loaded to memory by default
*------------------------------------------------------------------------------------------*/

   sentfile = langToSentFile(language);
   sentTable = scan(sentfile,1,".","MO");
   loadSentTable(sentTable,sentfile);

/* Run Sentiment Analysis on the given input data                                          */

   sentimentAnalysis.applySentimentConcepts / 
      casout = {name = output_table_name, 
                caslib = output_table_lib, 
                replace = True}
      &copyVarStringPre.&commaSeparatedList.&copyVarStringPost.
      docId = "&docId_1_name."
      table = {name = input_table_name, 
               caslib = input_table_lib, 
               where = "&textVar_1_name_base. ne ''"}
      model = {name = sentTable, caslib = "referenceData"}
      text = "&textVar_1_name."
      conceptMatchesOut = {name = matchout_table_name, 
                           caslib = matchout_table_lib, 
                           replace = True}
   ;


quit;
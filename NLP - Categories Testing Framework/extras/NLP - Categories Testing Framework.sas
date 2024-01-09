cas ss;
caslib _ALL_ assign;


/*-----------------------------------------------------------------------------------------*
   Values provided are for illustrative purposes only.
   Provide your own values in the section below.  
*------------------------------------------------------------------------------------------*/


%let analyticsProjectLocation=as-shared-default/Analytics_Project_2e99a5cb-7793-488b-8165-95199bd951cb;
%let outputTable_lib=PUBLIC;
%let inputTable_lib=PUBLIC;
%let inputTable_name_base=PHONEREVIEWS;
%let inputTable_name=PHONEREVIEWS;
%let inputCaslib=PUBLIC;
%let modelBinary=9fae58b0-a0e8-4925-9b59-977f5fc85a9a_CATEGORY_BINARY;
%let docId=ID_Review;
%let textVar=Text_Review;
%let outputCaslib=PUBLIC;
%let outputTable_name=NEWTRAN;
%let outputTable_name_base=NEWTRAN;
%let actualVar=Target_Rating;



/* templated code goes here*/;
/*-----------------------------------------------------------------------------------------*
   START MACRO DEFINITIONS.
*------------------------------------------------------------------------------------------*/

/* -----------------------------------------------------------------------------------------* 
   Macro to create an error flag for capture during code execution.

   Input:
      1. errorFlagName: The name of the error flag you wish to create. Ensure you provide a 
         unique value to this parameter since it will be declared as a global variable.

    Output:
      2. &errorFlagName : A global variable which takes the name provided to errorFlagName.

   Also available at: 
   https://github.com/SundareshSankaran/sas_utility_programs/blob/main/code/Error%20Flag%20Creation/macro_create_error_flag.sas
*------------------------------------------------------------------------------------------ */


%macro _create_error_flag(errorFlagName);

   %global &errorFlagName.;
   %let  &errorFlagName.=0;

%mend _create_error_flag;

/* -------------------------------------------------------------------------------------------* 
   Macro to initialize a run-time trigger global macro variable to run SAS Studio Custom Steps. 
   A value of 1 (the default) enables this custom step to run.  A value of 0 (provided by 
   upstream code) sets this to disabled.

   Input:
   1. triggerName: The name of the runtime trigger you wish to create. Ensure you provide a 
      unique value to this parameter since it will be declared as a global variable.

   Output:
   2. &triggerName : A global variable which takes the name provided to triggerName.
   
   Also available at:
   https://github.com/SundareshSankaran/sas_utility_programs/blob/main/code/Create_Run_Time_Trigger/macro_create_runtime_trigger.sas
*-------------------------------------------------------------------------------------------- */

%macro _create_runtime_trigger(triggerName);

   %global &triggerName.;

   %if %sysevalf(%superq(&triggerName.)=, boolean)  %then %do;
  
      %put NOTE: Trigger macro variable &triggerName. does not exist. Creating it now.;
      %let &triggerName.=1;

   %end;

%mend _create_runtime_trigger;

/*-----------------------------------------------------------------------------------------*
   Macro variable to capture indicator of a currently active CAS session
*------------------------------------------------------------------------------------------*/

%global casSessionExists;
%global _current_uuid_;

/*-----------------------------------------------------------------------------------------*
   Macro to capture indicator and UUIDof any currently active CAS session.
   UUID is not expensive and can be used in future to consider graceful reconnect.
*------------------------------------------------------------------------------------------*/

%macro _nctf_checkSession;
   %if %sysfunc(symexist(_SESSREF_)) %then %do;
      %let casSessionExists= %sysfunc(sessfound(&_SESSREF_.));
      %if &casSessionExists.=1 %then %do;
         proc cas;
            session.sessionId result = sessresults;
            call symputx("_current_uuid_", sessresults[1]);
            %put NOTE: A CAS session &_SESSREF_. is currently active with UUID &_current_uuid_. ;
         quit;
      %end;
   %end;
%mend _nctf_checkSession;

/*-----------------------------------------------------------------------------------------*
   This macro creates a global macro variable called _usr_nameCaslib
   that contains the caslib name (aka. caslib-reference-name) associated with the libname 
   and assumes that the libname is using the CAS engine.

   As sysvalue has a length of 1024 chars, we use the trimmed option in proc sql
   to remove leading and trailing blanks in the caslib name.
   From macro provided by Wilbram Hazejager
*------------------------------------------------------------------------------------------*/

%macro _usr_getNameCaslib(_usr_LibrefUsingCasEngine); 

   %global _usr_nameCaslib;
   %let _usr_nameCaslib=;

   proc sql noprint;
      select sysvalue into :_usr_nameCaslib trimmed from dictionary.libnames
      where libname = upcase("&_usr_LibrefUsingCasEngine.") and upcase(sysname)="CASLIB";
   quit;

%mend _usr_getNameCaslib;

/* -----------------------------------------------------------------------------------------* 
   Macro to split the Model Studio Project location and obtain the caslib portion for 
   downstream use.

   Input:
   1. projectLocation: A string provided by a text field in  a SAS Studio Custom step.
     

   Output:
   1. analyticsProjectCaslib: Set inside macro, a global variable indicating the caslib portion
      of the model studio path.
   also available at: https://raw.githubusercontent.com/SundareshSankaran/sas_utility_programs/main/code/Project_Caslib_from_Model_Studio_Location/project_caslib_from_model_studio.sas
*------------------------------------------------------------------------------------------ */

%macro _extract_caslib_from_ms_location(projectLocation);

   %global analyticsProjectCaslib;

   data _null_;
      if index("&projectLocation.","/") > 0 then do;
         call symput("analyticsProjectCaslib",scan("&projectLocation.",2,"/","MO"));
      end;
      else do;
         call symput("analyticsProjectCaslib","&projectLocation.");
      end;
   run;

   %put NOTE: The macro variable analyticsProjectCaslib resolves to: &analyticsProjectCaslib.;

%mend _extract_caslib_from_ms_location;

/* -----------------------------------------------------------------------------------------* 
   Macro to promote a CAS table.

   FUTURE PLACEHOLDER: The following functions will be converted to user defined functions
   instead of being called within the same proc cas block.

   Inputs:
   1. casLib: A valid caslib.
   2. casTable: A name of a CAS table.
     
   also available at: https://raw.githubusercontent.com/SundareshSankaran/sas_utility_programs/main/code/Promote%20a%20CAS%20Table/promote_cas_table.sas
*------------------------------------------------------------------------------------------ */

%macro _promote_cas_table(casLib, casTable, targetCaslib, targetTable);
   
   proc cas;

      function doesTableExist(_casLib, _casTable);
         table.tableExists result=tableExistsResultTable status=rc / 
            caslib = _casLib, 
            table  = _casTable;
         tableExists = dictionary(tableExistsResultTable, "exists");
         print tableExists;
         return tableExists;
      end;

      function dropTableIfExists(casLib,casTable);
         print "Entering dropTableIfExists";
         print casLib;
         tableExists = doesTableExist(casLib, casTable);
         if tableExists != 0 then do;
            print "Dropping table: "||casLib||"."||casTable;
            table.dropTable status=rc / caslib=casLib, table=casTable, quiet=True;
            if rc.statusCode != 0 then do;
               exit();
            end;
            dropTableIfExists(casLib, casTable);
         end;
      end;

      function promoteTable(casLib, casTable, targetCaslib, targetTable);         
         table.promote /
            target       = targetTable,
            targetcaslib = targetCaslib,
            name         = casTable,
            caslib       = casLib
          ; 
      end;

      dropTableIfExists("&targetCaslib.", "&targetTable.");
      promoteTable("&casLib.","&casTable.", "&targetCaslib.", "&targetTable.");

   quit;

%mend _promote_cas_table;



/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE MACRO 
*------------------------------------------------------------------------------------------*/

%macro _nctf_main_execution_code;

/*-----------------------------------------------------------------------------------------*
   Create an error flag. 
*------------------------------------------------------------------------------------------*/

   %_create_error_flag(_nctf_error_flag);

/*-----------------------------------------------------------------------------------------*
   Check if an active CAS session exists. 
*------------------------------------------------------------------------------------------*/

   %_nctf_checkSession;

   %if &casSessionExists. = 0 %then %do;
      %put ERROR: A CAS session does not exist. Connect to a CAS session upstream. ;
      %let _nctf_error_flag = 1;
   %end;
   %else %do;

/*-----------------------------------------------------------------------------------------*
   Check Input table libref to ensure it points to a valid caslib.
*------------------------------------------------------------------------------------------*/

      %if &_nctf_error_flag. = 0 %then %do;

         %global inputCaslib;
   
         %_usr_getNameCaslib(&inputTable_lib.);
         %let inputCaslib=&_usr_nameCaslib.;
         %put NOTE: &inputCaslib. is the caslib for the input table.;
         %let _usr_nameCaslib=;

         %if "&inputCaslib." = "" %then %do;
            %put ERROR: Input table caslib is blank. Check if Base table is a valid CAS table. ;
            %let _nctf_error_flag=1;
         %end;

      %end;

/*-----------------------------------------------------------------------------------------*
   Check Output table libref to ensure it points to a valid caslib.
*------------------------------------------------------------------------------------------*/

      %if &_nctf_error_flag. = 0 %then %do;

         %global outputCaslib;
   
         %_usr_getNameCaslib(&outputTable_lib.);
         %let outputCaslib=&_usr_nameCaslib.;
         %put NOTE: &outputCaslib. is the output caslib.;
         %let _usr_nameCaslib=;

         %if "&outputCaslib." = "" %then %do;
            %put ERROR: Output table caslib is blank. Check if Output table is a valid CAS table. ;
            %let _nctf_error_flag=1;
         %end;

      %end;


      %if &_nctf_error_flag. = 0 %then %do;

   /*-----------------------------------------------------------------------------------------*
      Extract caslib  from the Model Studio project location.
   *------------------------------------------------------------------------------------------*/

         %_extract_caslib_from_ms_location(&analyticsProjectLocation.);

   /*-----------------------------------------------------------------------------------------*
      Run CAS statements.
   *------------------------------------------------------------------------------------------*/

         proc cas;

         /*------------------------------------------------------------------------------------*
            Helper functions.  As mentioned in previous note, a future placeholder is to convert
            these to user-defined functions and avoid having to declare them within every 
            proc cas block.
         *------------------------------- -----------------------------------------------------*/

            function doesTableExist(_casLib, _casTable);
               table.tableExists result=tableExistsResultTable status=rc / 
                  caslib = _casLib, 
                  table  = _casTable;
               tableExists = dictionary(tableExistsResultTable, "exists");
               print tableExists;
               return tableExists;
            end;

            function dropTableIfExists(casLib,casTable);
               print "Entering dropTableIfExists";
               print casLib;
               tableExists = doesTableExist(casLib, casTable);
               if tableExists != 0 then do;
                  print "Dropping table: "||casLib||"."||casTable;
                  table.dropTable status=rc / caslib=casLib, table=casTable, quiet=True;
                  if rc.statusCode != 0 then do;
                     exit();
                  end;
                  dropTableIfExists(casLib, casTable);
               end;
            end;

         /*------------------------------------------------------------------------------------*
            Obtain parameters from the UI
         *------------------------------- -----------------------------------------------------*/
            inputTableName          = symget("inputTable_name_base");
            inputCaslib             = symget("inputCaslib");
            analyticsProjectCaslib  = symget("analyticsProjectCaslib");
            modelBinary             = symget("modelBinary");
            docId                   = symget("docId");
            textVar                 = symget("textVar");
            outputCaslib            = symget("outputCaslib");
            outputTableName         = symget("outputTable_name_base");

         /*------------------------------------------------------------------------------------*
            Apply the NLP model (currently supports only categories)
         *------------------------------- -----------------------------------------------------*/
            textRuleScore.applyCategory/
               model    = {caslib=analyticsProjectCaslib, name=modelBinary},
               table    = {caslib=inputCaslib, name=inputTableName},
               docId    = docId,
               text     = textVar,
               casOut   = {caslib=outputCaslib, name="__TEMP_CAT", replace=TRUE},
               matchOut = {caslib=outputCaslib, name="__TEMP_MAT", replace=TRUE}
            ;


            /*------------------------------------------------------------------------------------*
               note this query text string is depicted in separate strings to reduce chances of 
               error (due to unbalanced quotation marks) which affects readability.
            *------------------------------- -----------------------------------------------------*/

           
            queryText_1 = "create table &outputCaslib.._&outputTable_name. {options replace = True} as select a.*, b._category_, b._score_, b._match_text_, b._start_, b._end_ from (select &docId., &textVar., &actualVar. from &inputCaslib..&inputTable_name.) a ";
            queryText_2 = " left join (select __TEMP_CAT.&docId., __TEMP_CAT._category_, __TEMP_CAT._score_, __TEMP_MAT._match_text_, __TEMP_MAT._start_, __TEMP_MAT._end_ from &outputCaslib..__TEMP_CAT" ;
            queryText_3 = " left join &outputCaslib..__TEMP_MAT on __TEMP_CAT.&docId. = __TEMP_MAT.&docId.) b on a.&docId. = b.&docId.";

            /*------------------------------------------------------------------------------------*
               The following section on the use of the dynamic cardinality feature within
               fed sql is a very useful reference.  Note that this is suitable for situations
               involving joins of 3+ tables (the case here) and also taking the size of table
               into consideration.  Considering use / disuse of this flag based on any 
               prior knowledge you might have about your category output tables.

               FUTURE PLACEHOLDER: Provide an option in the UI.

               https://go.documentation.sas.com/doc/en/pgmsascdc/default/casfedsql/p0lrihvbn5xnfdn1a86poyhemp9f.htm 
            *------------------------------- -----------------------------------------------------*/

            fedsql.execDirect /
               cntl  = {dynamicCardinality=TRUE},
               query = queryText_1||queryText_2||queryText_3
            ;

          /*------------------------------------------------------------------------------------*
               Create candidate category tables for assessment.
          *------------------------------- -----------------------------------------------------*/

            fedsql.execDirect / 
               query = "create table &outputCaslib..__TEMPCAT_1 {options replace = True} as select distinct &actualVar. as Category_Level from &inputCaslib..&inputTable_name. ";

            fedsql.execDirect / 
               query = "create table &outputCaslib..__TEMPCAT_2 {options replace = True} as select distinct scan(_category_,-1,'/') as Category_Level from &outputCaslib.._&outputTable_name.";

            datastep.runCode /
               code = "data &outputCaslib..__TEMPCAT_3 (replace = Yes) ; length Category_Level varchar(*); Category_Level = ''; if _threadid_ = 1;run;";

          /*------------------------------------------------------------------------------------*
               For practical purposes, the number of records in the following temp tables
               allow us to append (and then subsequently select distinct records).  A merge
               data step is preferred but may emit a warning about multiple lengths.
          *------------------------------- -----------------------------------------------------*/

            datastep.runCode /
               code = "data &outputCaslib..__TEMPCAT (replace = Yes) ; set &outputCaslib..__TEMPCAT_1 &outputCaslib..__TEMPCAT_2 &outputCaslib..__TEMPCAT_3 ; run;";

          /*------------------------------------------------------------------------------------*
               Create a 'candidate' dataset.  Text categorization differs from other 
               "classification" problems in that it may allow for multiple labels 
               and even multiple truths in some rare cases. Every record is assessed as if it 
               were a candidate for all possible categories. 

               It's tempting to consider a nice single FedSQL query to output the final table,
               but we'll prioritise functionality over form and put in a 
               FUTURE PLACEHOLDER: consider optimizing all FedSQL queries below.

          *------------------------------- -----------------------------------------------------*/

            fedsql.execDirect / 
               query = "select distinct Category_Level from &outputCaslib..__TEMPCAT";


            fedsql.execDirect / 
               query = "create table &outputCaslib..__TEMP1 {options replace = True} as select a.*, b.* from (select distinct &docId. from &inputCaslib..&inputTable_name.) a, (select distinct Category_Level from &outputCaslib..__TEMPCAT) b  ";
             
            fedsql.execDirect /
               query = "create table &outputCaslib..__TEMP2 {options replace = True} as select a.*, b.nbr_predictions from (select * from &outputCaslib..__TEMP1) a left join (select &docId., scan(_category_,-1,'/') as Category_Level, count(*) as nbr_predictions from &outputCaslib.._&outputTable_name. group by &docId., _category_) b on a.&docId. = b.&docId. and a.Category_Level = b.Category_Level";

            fedsql.execDirect /
               query = "create table &outputCaslib..__TEMP3 {options replace = True} as select a.*, b.nbr_actuals from (select * from &outputCaslib..__TEMP1) a left join (select &docId., &actualVar. as Category_Level, count(*) as nbr_actuals from &outputCaslib.._&outputTable_name. group by &docId., &actualVar.) b on a.&docId. = b.&docId. and a.Category_Level = b.Category_Level";

            fedsql.execDirect /
               query = "create table &outputCaslib..__TEMP4 {options replace = True} as select a.*, b.nbr_actuals from (select * from &outputCaslib..__TEMP2) a inner join (select * from &outputCaslib..__TEMP3) b on a.&docId. = b.&docId. and a.Category_Level = b.Category_Level";

          /*------------------------------------------------------------------------------------*
               Delete intermediate tables.
          *------------------------------- -----------------------------------------------------*/

            dropTableIfExists("&outputCaslib.", "__TEMP_CAT");
            dropTableIfExists("&outputCaslib.", "__TEMP_MAT");
            dropTableIfExists("&outputCaslib.", "__TEMPCAT_1");
            dropTableIfExists("&outputCaslib.", "__TEMPCAT_2");
            dropTableIfExists("&outputCaslib.", "__TEMPCAT_3");
            dropTableIfExists("&outputCaslib.", "__TEMPCAT");
            dropTableIfExists("&outputCaslib.", "__TEMP1");
            dropTableIfExists("&outputCaslib.", "__TEMP2");
            dropTableIfExists("&outputCaslib.", "__TEMP3");


         quit;
         
         data &outputCaslib..__TEMP4;
         length Record_Type $15.;
         set &outputCaslib..__TEMP4;
            /*------------------------------------------------------------------------------------*
               Calculation of True Positives
               "Win the lottery."
            *------------------------------- -----------------------------------------------------*/
            if nbr_predictions > 0 and nbr_actuals > 0 then do;
               Record_Type = "True Positive";
               naive_true_positives = nbr_predictions;
            end;
            /*------------------------------------------------------------------------------------*
               Calculation of False Positives
               "Make a wrong call."
            *------------------------------- -----------------------------------------------------*/
            if nbr_predictions > nbr_actuals then do;
               Record_Type = "False Positive";
               naive_false_positives = max(0,nbr_predictions) - max(0,nbr_actuals);
            end;
            /*------------------------------------------------------------------------------------*
               Calculation of True Negatives
               "Don't consider the unlikely."
            *------------------------------- -----------------------------------------------------*/
            if nbr_predictions = . and nbr_actuals = . then do;
               Record_Type = "True Negative";
            end;
            /*------------------------------------------------------------------------------------*
               Calculation of False Negatives
               "Ignore this at your peril."
            *------------------------------- -----------------------------------------------------*/
            if nbr_predictions = . and nbr_actuals > 0 then do;
               Record_Type = "False Negative";
               naive_false_negatives = nbr_actuals;
            end;

         run;

         proc cas;

            fedsql.execDirect /
               query = "create table &outputCaslib.._&outputTable_name. {options replace = True} as select a.*, b.&textVar., b.&actualVar., b._category_, b._score_, b._match_text_, b._start_, b._end_ from &outputCaslib..__TEMP4 a left join &outputCaslib.._&outputTable_name. b on a.&docId. = b.&docId. and a.Category_Level = scan(b._category_,-1,'/') ";

         /*------------------------------------------------------------------------------------*
            Unique IDs per observation is useful for downstream analysis in VA.
            Unfortunately, the generateIds action doesn't allow for adding a unique ID
            to the same table.  Therefore, we make a copy and then promote.
         *------------------------------- -----------------------------------------------------*/

            
            textManagement.generateIds /                            
               casOut={name="__&outputTable_name.", caslib="&outputCaslib.", replace=TRUE },
               id="Unique_Obs_ID",
               table={name="_&outputTable_name.", caslib="&outputCaslib."}
            ;

         quit;

         /*------------------------------------------------------------------------------------*
            FUTURE PLACEHOLDER: Make promotion an option (even though VA is a preferred 
                                application for analysis)
         *------------------------------- -----------------------------------------------------*/

         %_promote_cas_table(&outputCaslib., __&outputTable_name., &outputCaslib., &outputTable_name. );


         proc cas;

            function doesTableExist(_casLib, _casTable);
               table.tableExists result=tableExistsResultTable status=rc / 
                  caslib = _casLib, 
                  table  = _casTable;
               tableExists = dictionary(tableExistsResultTable, "exists");
               print tableExists;
               return tableExists;
            end;

            function dropTableIfExists(casLib,casTable);
               print "Entering dropTableIfExists";
               print casLib;
               tableExists = doesTableExist(casLib, casTable);
               if tableExists != 0 then do;
                  print "Dropping table: "||casLib||"."||casTable;
                  table.dropTable status=rc / caslib=casLib, table=casTable, quiet=True;
                  if rc.statusCode != 0 then do;
                     exit();
                  end;
                  dropTableIfExists(casLib, casTable);
               end;
            end;


            dropTableIfExists("&outputCaslib.", "__TEMP4");
            dropTableIfExists("&outputCaslib.", "_&outputTable_name.");
            dropTableIfExists("&outputCaslib.", "__&outputTable_name.");

         quit;

      %end;

   %end;

%mend _nctf_main_execution_code;

/*-----------------------------------------------------------------------------------------*
   END MACRO DEFINITIONS.
*------------------------------------------------------------------------------------------*/


/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE
   The execution code is controlled by the trigger variable defined in this custom step. This
   trigger variable is in an "enabled" (value of 1) state by default, but in some cases, as 
   dictated by logic, could be set to a "disabled" (value of 0) state.
*------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------*
   Create a run-time trigger. 
*------------------------------------------------------------------------------------------*/

%_create_runtime_trigger(_nctf_run_trigger);

%if &_nctf_run_trigger. = 1 %then %do;

   %_nctf_main_execution_code;

%end;
%if &_nctf_run_trigger. = 0 %then %do;

   %put NOTE: This step has been disabled.  Nothing to do.;

%end;


/*-----------------------------------------------------------------------------------------*
   Clean up existing macro variables and macro definitions.
*------------------------------------------------------------------------------------------*/
%if %symexist(_nctf_error_flag) %then %do;
   %symdel _nctf_error_flag;
%end;

%if %symexist(casSessionExists) %then %do;
   %symdel casSessionExists;
%end;

%if %symexist(_nctf_run_trigger) %then %do;
   %symdel _nctf_run_trigger;
%end;

%if %symexist(_current_uuid) %then %do;
   %symdel _current_uuid;
%end;

%if %symexist(_usr_nameCaslib) %then %do;
   %symdel _usr_nameCaslib;
%end;

%if %symexist(analyticsProjectCaslib) %then %do;
   %symdel analyticsProjectCaslib;
%end;

%if %symexist(inputCaslib) %then %do;
   %symdel inputCaslib;
%end;

%if %symexist(outputCaslib) %then %do;
   %symdel outputCaslib;
%end;

%sysmacdelete _create_error_flag;
%sysmacdelete _create_runtime_trigger;
%sysmacdelete _nctf_checkSession;
%sysmacdelete _usr_getNameCaslib;
%sysmacdelete _extract_caslib_from_ms_location;
%sysmacdelete _promote_cas_table;
%sysmacdelete _nctf_main_execution_code;

cas ss terminate;

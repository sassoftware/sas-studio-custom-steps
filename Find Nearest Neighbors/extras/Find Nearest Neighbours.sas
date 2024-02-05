/* templated code goes here*/;
/*-----------------------------------------------------------------------------------------*
   START MACRO DEFINITIONS.
*------------------------------------------------------------------------------------------*/

/* -----------------------------------------------------------------------------------------* 
   Error flag for capture during code execution.
*------------------------------------------------------------------------------------------ */

%global _fnn_error_flag;
%let _fnn_error_flag=0;

/* -----------------------------------------------------------------------------------------* 
   Global macro variable for the trigger to run this custom step. A value of 1 
   (the default) enables this custom step to run.  A value of 0 (provided by upstream code)
   sets this to disabled.
*------------------------------------------------------------------------------------------ */

%global _fnn_run_trigger;

%if %sysevalf(%superq(_fnn_run_trigger)=, boolean)  %then %do;

	%put NOTE: Trigger macro variable _fnn_run_trigger does not exist. Creating it now.;
    %let _fnn_run_trigger=1;

%end;

/*-----------------------------------------------------------------------------------------*
   Macro variable to capture indicator of a currently active CAS session
*------------------------------------------------------------------------------------------*/

%global casSessionExists;
%global _current_uuid_;

/*-----------------------------------------------------------------------------------------*
   Macro to capture indicator and UUID of any currently active CAS session.
   UUID is not expensive and can be used in future to consider graceful reconnect.
*------------------------------------------------------------------------------------------*/

%macro _fnn_checkSession;
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
%mend _fnn_checkSession;

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
   This macro generates additional codepieces based on a condition provided.
*------------------------------------------------------------------------------------------*/

%macro _gac_generate_additional_code(conditionVar, conditionOperator, conditionVal, desiredVar, desiredVal);
   %global _gac_generated_string;
   %put &conditionVar. &conditionOperator. &conditionVal.;
   %if &conditionVar. &conditionOperator. &conditionVal. %then %do; 
      %put NOTE: Hey mama no shoes;
      %let _gac_generated_string = &desiredVar.=&desiredVal.,;
   %end;
   %else %do;
      %let _gac_generated_string = ;
   %end;

%mend;

/*--------------------------------------------------------------------------------------*
   Macro variable to hold the selected input columns to use as matching criteria.
*---------------------------------------------------------------------------------------*/

%let blankSeparatedCols = %_flw_get_column_list(_flw_prefix=inputColumns);

/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE MACRO 
*------------------------------------------------------------------------------------------*/

%macro _fnn_main_execution_code;

/*-----------------------------------------------------------------------------------------*
   Check for an active CAS session
*------------------------------------------------------------------------------------------*/

   %_fnn_checkSession;

   %if &casSessionExists. = 0 %then %do;
      %put ERROR: A CAS session does not exist. Connect to a CAS session upstream. ;
      %let _fnn_error_flag = 1;
   %end;
   %else %do;
/*-----------------------------------------------------------------------------------------*
   Check Input (base) table libref to ensure it points to a valid caslib.
*------------------------------------------------------------------------------------------*/

      %if &_fnn_error_flag. = 0 %then %do;

         %global baseCaslib;
   
         %_usr_getNameCaslib(&baseTable_lib.);
         %let baseCaslib=&_usr_nameCaslib.;
         %put NOTE: &baseCaslib. is the caslib for the base table.;
         %let _usr_nameCaslib=;

         %if "&baseCaslib." = "" %then %do;
            %put ERROR: Base table caslib is blank. Check if Base table is a valid CAS table. ;
            %let _fnn_error_flag=1;
         %end;

      %end;

/*-----------------------------------------------------------------------------------------*
   Check Input (query) table libref to ensure it points to a valid caslib.
*------------------------------------------------------------------------------------------*/

      %if &_fnn_error_flag. = 0 %then %do;

         %global queryCaslib;
   
         %_usr_getNameCaslib(&queryTable_lib.);
         %let queryCaslib=&_usr_nameCaslib.;
         %put NOTE: &queryCaslib. is the caslib for the query table.;
         %let _usr_nameCaslib=;

         %if "&queryCaslib." = "" %then %do;
            %put ERROR: Query table caslib is blank. Check if Query table is a valid CAS table. ;
            %let _fnn_error_flag=1;
         %end;

      %end;

/*-----------------------------------------------------------------------------------------*
   Check Output table libref to ensure it points to a valid caslib.
*------------------------------------------------------------------------------------------*/

      %if &_fnn_error_flag. = 0 %then %do;

         %global outputCaslib;
   
         %_usr_getNameCaslib(&outputTable_lib.);
         %let outputCaslib=&_usr_nameCaslib.;
         %put NOTE: &outputCaslib. is the output caslib.;
         %let _usr_nameCaslib=;

         %if "&outputCaslib." = "" %then %do;
            %put ERROR: Output table caslib is blank. Check if Output table is a valid CAS table. ;
            %let _fnn_error_flag=1;
         %end;

      %end;

/*-----------------------------------------------------------------------------------------*
   Check Output (distance) table libref to ensure it points to a valid caslib.
*------------------------------------------------------------------------------------------*/

      %if &_fnn_error_flag. = 0 %then %do;

         %global outputDistCaslib;
   
         %_usr_getNameCaslib(&outputDistTable_lib.);
         %let outputDistCaslib=&_usr_nameCaslib.;
         %put NOTE: &outputDistCaslib. is the output distance table caslib.;
         %let _usr_nameCaslib=;

         %if "&outputDistCaslib." = "" %then %do;
            %put ERROR: Output distance table caslib is blank. Check if Output distance table is a valid CAS table. ;
            %let _fnn_error_flag=1;
         %end;

      %end;

/*-----------------------------------------------------------------------------------------*
   Run CAS statements
*------------------------------------------------------------------------------------------*/

      %if &_fnn_error_flag. = 0 %then %do;
         
         %local mTreesString;
         %local maxPointsString;

         %let desiredVar=mTrees;
         %_gac_generate_additional_code(&searchMethod.,=,"APPROXIMATE",&desiredVar., &mTrees.);
         %let mTreesString=&_gac_generated_string.;
         %let _gac_generated_string=;

         %let desiredVar=maxPoints;
         %_gac_generate_additional_code(&searchMethod.,=,"APPROXIMATE",&desiredVar., &maxPoints.);
         %let maxPointsString=&_gac_generated_string.;
         %let _gac_generated_string=;
 
         proc cas;         

/*-----------------------------------------------------------------------------------------*
   Obtain inputs from UI.
*------------------------------------------------------------------------------------------*/

            baseTableName      = symget("baseTable_name_base");
            baseTableLib       = symget("baseCaslib");
            queryTableName      = symget("queryTable_name_base");
            queryTableLib       = symget("queryCaslib");
            outputTableName     = symget("outputTable_name_base");
            outputTableLib      = symget("outputCaslib");
            outputDistTableName = symget("outputDistTable_name_base");
            outputDistTableLib  = symget("outputDistCaslib");

            idCol               = symget("idCol");
            numMatches          = symget("numMatches");
            thresholdDistance   = symget("thresholdDistance");
            searchMethod        = symget("searchMethod");
            mTreesString        = symget("mTreesString");
            maxPointsString     = symget("maxPointsString");


/*-----------------------------------------------------------------------------------------*
   Run Fast KNN action
   Note:  We are currently keeping the default parallelization setting for the QUERY
          table currently, due to the chances of some session hangups when running with
          PARALLELIZATION=INPUT.  This is temporary and will be revisited.
*------------------------------------------------------------------------------------------*/
   
            fastknn.fastknn result=r / 
               table           = {name=baseTableName, caslib=baseTableLib},
               query           = {name=queryTableName, caslib=queryTableLib},
               inputs          = ${&blankSeparatedCols.},
               id              = idCol,
               k               = numMatches,
               method          = searchMethod,
               &mTreesString.
               &maxPointsString.
               output          = { casout= {name=outputTableName, caslib=outputTableLib, replace=True}},
               outDist         = { name=outputDistTableName, caslib=outputDistTableLib, replace=True},
               threshDist      = thresholdDistance
            ;

/*-----------------------------------------------------------------------------------------*
   Print summary results to output window;
*------------------------------------------------------------------------------------------*/
       
            print r;

         quit;

      %end;
   %end;

%mend _fnn_main_execution_code;


/*-----------------------------------------------------------------------------------------*
   END MACRO DEFINITIONS.
*------------------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE
   The execution code is controlled by the trigger variable defined in this custom step. This
   trigger variable is in an "enabled" (value of 1) state by default, but in some cases, as 
   dictated by logic, could be set to a "disabled" (value of 0) state.
*------------------------------------------------------------------------------------------*/

%if &_fnn_run_trigger. = 1 %then %do;
   %_fnn_main_execution_code;
%end;
%if &_fnn_run_trigger. = 0 %then %do;
   %put NOTE: This step has been disabled.  Nothing to do.;
%end;



/*-----------------------------------------------------------------------------------------*
   Clean up existing macro variables and macro definitions.
*------------------------------------------------------------------------------------------*/
%if %symexist(_fnn_error_flag) %then %do;
   %symdel _fnn_error_flag;
%end;
%if %symexist(outputDistCaslib) %then %do;
   %symdel outputDistCaslib;
%end;
%if %symexist(queryCaslib) %then %do;
   %symdel queryCaslib;
%end;
%if %symexist(baseCaslib) %then %do;
   %symdel baseCaslib;
%end;
%if %symexist(_fnn_run_trigger) %then %do;
   %symdel _fnn_run_trigger;
%end;
%if %symexist(casSessionExists) %then %do;
   %symdel casSessionExists;
%end;
%if %symexist(_current_uuid_) %then %do;
   %symdel _current_uuid_;
%end;
%if %symexist(_usr_nameCaslib) %then %do;
   %symdel _usr_nameCaslib;
%end;
%if %symexist(outputCaslib) %then %do;
   %symdel outputCaslib;
%end;
%if %symexist(_gac_generated_string) %then %do;
   %symdel _gac_generated_string;
%end;
%if %symexist(blankSeparatedCols) %then %do;
   %symdel blankSeparatedCols;
%end;

%sysmacdelete _fnn_checkSession;
%sysmacdelete _usr_getNameCaslib;
%sysmacdelete _fnn_main_execution_code;
%sysmacdelete _gac_generate_additional_code;
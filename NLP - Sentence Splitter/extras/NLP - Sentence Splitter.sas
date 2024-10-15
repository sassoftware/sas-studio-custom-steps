/* SAS templated code goes here */
/*-----------------------------------------------------------------------------------------*
   START MACRO DEFINITIONS.
*------------------------------------------------------------------------------------------*/

/* -----------------------------------------------------------------------------------------* 
   Error flag for capture during code execution.
*------------------------------------------------------------------------------------------ */

%global _ss_error_flag;
%let _ss_error_flag=0;

/* -----------------------------------------------------------------------------------------* 
   Global macro variable for the trigger to run this custom step. A value of 1 
   (the default) enables this custom step to run.  A value of 0 (provided by upstream code)
   sets this to disabled.
*------------------------------------------------------------------------------------------ */

%global _ss_run_trigger;

%if %sysevalf(%superq(_ss_run_trigger)=, boolean)  %then %do;

	%put NOTE: Trigger macro variable _ss_run_trigger does not exist. Creating it now.;
    %let _ss_run_trigger=1;

%end;

/*-----------------------------------------------------------------------------------------*
   Macro variable to capture indicator of a currently active CAS session
*------------------------------------------------------------------------------------------*/

%global casSessionExists;
%global _current_uuid_;

/*-----------------------------------------------------------------------------------------*
   Macro to capture indicator and UUIDof any currently active CAS session.
   UUID is not expensive and can be used in future to consider graceful reconnect.
*------------------------------------------------------------------------------------------*/

%macro _ss_checkSession;
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
%mend _ss_checkSession;

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
   Macro for Sentence splitter model definition: creates and compiles an information 
   extraction (concepts) model which splits text input into constituent sentences.
*------------------------------------------------------------------------------------------*/

%macro _ss_splitter_model;

   data public.concept_rule;                                    
      length rule $200.;
      ruleId=1;
      rule='ENABLE:SentBoundaries';
      output;
      ruleId=2;
      rule='PREDICATE_RULE:SentBoundaries(first,last):(SENT, (SENTSTART_1, "_first{_w}"), (SENTEND_1, "_last{_w}"))';
      output;
   run;

%mend _ss_splitter_model;



/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE MACRO 
*------------------------------------------------------------------------------------------*/

%macro main_execution_code;

/*-----------------------------------------------------------------------------------------*
   Check for an active CAS session
*------------------------------------------------------------------------------------------*/

   %_ss_checkSession;

   %if &casSessionExists. = 0 %then %do;
      %put ERROR: A CAS session does not exist. Start a CAS session upstream. ;
      %let _ss_error_flag = 1;
   %end;
   %else %do;

/*-----------------------------------------------------------------------------------------*
   The Public CASLIB is required to stage the temp sentence splittermodel.  Check if there 
   exists a valid caslib which the PUBLIC SAS Library points to.
*------------------------------------------------------------------------------------------*/

      %if &_ss_error_flag. = 0 %then %do;
         %_usr_getNameCaslib(PUBLIC);

         %if %sysfunc(upcase("&_usr_nameCaslib.")) = "PUBLIC" %then %do;
            %put NOTE: The library PUBLIC is available.;
            %let _usr_nameCaslib=;
         %end;
         %else %do;
            %let _ss_error_flag=1;
            %put ERROR: The library PUBLIC is not defined or does not point to CASLIB Public. A SAS library PUBLIC pointing to the CASLIB Public needs to exist and will be used for storing intermediate CAS tables. ;
         %end;
      %end;

/*-----------------------------------------------------------------------------------------*
   Check Input libref to ensure it points to a valid caslib.
*------------------------------------------------------------------------------------------*/

      %if &_ss_error_flag. = 0 %then %do;

         %global inputCaslib;
   
         %_usr_getNameCaslib(&inputtable_lib.);
         %let inputCaslib=&_usr_nameCaslib.;
         %put NOTE: &inputCaslib. is the input caslib.;
         %let _usr_nameCaslib=;

         %if "&inputCaslib." = "" %then %do;
            %put ERROR: The input table libref (&inputtable_lib.) is either missing, or not pointing to a valid caslib. Check if the input table is a valid CAS table. ;
            %let _ss_error_flag=1;
         %end;

/*-----------------------------------------------------------------------------------------*
   Check Output libref to ensure it points to a valid caslib.
*------------------------------------------------------------------------------------------*/

         %global outputCaslib;
   
         %_usr_getNameCaslib(&outputtable_lib.);
         %let outputCaslib=&_usr_nameCaslib.;
         %put NOTE: &outputCaslib. is the output caslib.;
         %let _usr_nameCaslib=;

         %if "&outputCaslib." = "" %then %do;
            %put ERROR: The output table libref (&outputtable_lib.) is either missing, or not pointing to a valid caslib. Check if the output table is a valid CAS table. ;
            %let _ss_error_flag=1;
         %end;

      %end;


      %if &_ss_error_flag. = 0 %then %do;

/*-----------------------------------------------------------------------------------------*
   Define the splitter model.
*------------------------------------------------------------------------------------------*/

         %_ss_splitter_model;
 
         proc cas;         

/*-----------------------------------------------------------------------------------------*
   Obtain inputs from UI.
*------------------------------------------------------------------------------------------*/

            outputTableName = symget("outputtable_name_base");
            outputTableLib  = symget("outputCaslib");
            inputTableName  = symget("inputtable_name_base");
            inputTableLib   = symget("inputCaslib");
            docIdVar        = symget("docId");
            textVar         = symget("textVar");
            language        = symget("language");
 
/*-----------------------------------------------------------------------------------------*
   Validate model syntax.
*------------------------------------------------------------------------------------------*/
   
            textRuleDevelop.validateConcept result=validationResults /
               table    = {name="concept_rule", caslib="PUBLIC"},
               config   = "rule",
               ruleId   = "ruleId",
               language = language,
               casOut   = {name="outValidation",caslib="PUBLIC", replace=True}
             ;

            validationErrors = validationResults[1][1]["Rows"];

            if validationErrors = 0 then do;

/*-----------------------------------------------------------------------------------------*
   Compile model.
*------------------------------------------------------------------------------------------*/
 
               textRuleDevelop.compileConcept /
                  table            = {name="concept_rule", caslib="PUBLIC"},
                  config           = "rule",
                  ruleId           = "ruleId",
                  enablePredefined = false,
                  language         = language,
                  casOut           = {name="sentencesplitter", caslib="PUBLIC", replace=TRUE}
               ;     

/*-----------------------------------------------------------------------------------------*
   Score text to obtain sentences.
*------------------------------------------------------------------------------------------*/

               textRuleScore.applyConcept /
                  table     = {name=inputTableName, caslib=inputTableLib, where=textVar||" ne ''" },
                  docId     = docIdVar,
                  text      = textVar,
                  language  = language,
                  model     = {name="sentencesplitter", caslib="PUBLIC"},
                  matchType = "best",
                  casOut    = {name="tempconcept",caslib="PUBLIC", replace=TRUE},
                  factOut   = {name=outputTableName, caslib=outputTableLib, replace=TRUE, where="_fact_argument_=''"}
               ;

            end;
/*-----------------------------------------------------------------------------------------*
   Model validation is unlikely to error for a statically defined model, but good practice.
*------------------------------------------------------------------------------------------*/

            else do;

               put "ERROR: Check Model Validation Table";

            end;

         quit;

/*-----------------------------------------------------------------------------------------*
   FUTURE PLACEHOLDER: The below step has potential for some refactoring with CASL 
   in future. 
   Fact result IDs, through a perhaps lovable quirk of the applyConcept action, are ordered
   in descending order, giving a _result_id_ of 1 to the last occurrence of a sentence, 
   rather than the first.  This data step corrects the same and also generates an overall
   Observation ID which combines the original DocID and Sentence ID.
*------------------------------------------------------------------------------------------*/
         %if %sysfunc(upcase("&docId_1_type."))="NUMERIC" %then %do;
            data &outputtable.;
               length Obs_ID $40. total_sentences 8. ;
               retain total_sentences;
               set &outputtable.(rename=(_result_Id_=_sentence_id_) drop=_fact_argument_ _fact_ _path_);
               by &docId. _start_ ;
               if first.&docId. then do;
                  total_sentences = _sentence_id_;
               end;
               Obs_ID = compress(put(&docId.,z10.)||"_"||put((sum(total_sentences,1)-_sentence_id_),z15.));               _sentence_id_ = sum(total_sentences,1)-_sentence_id_;
            run;
         %end;
         %else %do;
            data &outputtable.;
               length Obs_ID $40. total_sentences 8. ;
               retain total_sentences;
               set &outputtable.(rename=(_result_Id_=_sentence_id_) drop=_fact_argument_ _fact_ _path_);
               by &docId. _start_ ;        
               if first.&docId. then do;
                  total_sentences = _sentence_id_;
               end;
               Obs_ID = compress(substr(compress(&docId.),1,24)||"_"||put((sum(total_sentences,1)-_sentence_id_),z15.));
            run;
         %end;
      %end;
   %end;

%mend main_execution_code;


/*-----------------------------------------------------------------------------------------*
   END OF MACROS
*------------------------------------------------------------------------------------------*/


/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE
   The execution code is controlled by the trigger variable defined in this custom step. This
   trigger variable is in an "enabled" (value of 1) state by default, but in some cases, as 
   dictated by logic, could be set to a "disabled" (value of 0) state.
*------------------------------------------------------------------------------------------*/

%if &_ss_run_trigger. = 1 %then %do;
   %main_execution_code;
%end;
%if &_ss_run_trigger. = 0 %then %do;
   %put NOTE: This step has been disabled.  Nothing to do.;
%end;

/*-----------------------------------------------------------------------------------------*
   Clean up existing macro variables and macro definitions.
*------------------------------------------------------------------------------------------*/
%if %symexist(_ss_error_flag)=1 %then %do; 
   %symdel _ss_error_flag;
%end;
%if %symexist(_ss_run_trigger)=1 %then %do; 
   %symdel _ss_run_trigger;
%end;
%if %symexist(casSessionExists)=1 %then %do; 
   %symdel casSessionExists;
%end;
%if %symexist(_current_uuid_)=1 %then %do; 
   %symdel _current_uuid_;
%end;
%if %symexist(_usr_nameCaslib)=1 %then %do; 
   %symdel _usr_nameCaslib;
%end;
%if %symexist(inputCaslib)=1 %then %do; 
   %symdel inputCaslib;
%end;
%if %symexist(outputCaslib)=1 %then %do; 
   %symdel outputCaslib;
%end;


%sysmacdelete _ss_checkSession;
%sysmacdelete _usr_getNameCaslib;
%sysmacdelete _ss_splitter_model;
%sysmacdelete main_execution_code;
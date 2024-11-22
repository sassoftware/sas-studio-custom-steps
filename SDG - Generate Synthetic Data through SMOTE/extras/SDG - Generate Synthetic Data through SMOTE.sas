/* SAS templated code goes here */

/* -------------------------------------------------------------------------------------------* 
   Synthetic Data Generation (SDG) - Generate Synthetic Data through SMOTE

   v 1.2 (11NOV2024)

   This program generates synthetic data using the Synthetic Minority Oversampling TEchnique
   and is meant for use within a SAS Studio Custom Step. Please modify requisite macro variables
   (hint: use the debug section as a reference) to run this through other interfaces, such as 
   a SAS Program editor or the SAS extension for Visual Studio Code.

   Sundaresh Sankaran (sundaresh.sankaran@sas.com|sundaresh.sankaran@gmail.com)
*-------------------------------------------------------------------------------------------- */

/*-----------------------------------------------------------------------------------------*
   DEBUG Section
   Code under the debug section SHOULD ALWAYS remain commented unless you are tinkering with  
   or testing the step!
*------------------------------------------------------------------------------------------*/

/* Provide test values for the parameters */

/*
%let CLASSTOAUGMENT =1;
%let CLASSVAR =BAD;
%let CLASSVAR_1_TYPE =Numeric;
%let INPUTTABLE =PUBLIC.HMEQ;
%let INPUTTABLE_ENGINE=V9;
%let INPUTTABLE_LIB=PUBLIC;
%let INPUTTABLE_NAME=HMEQ;
%let INPUTTABLE_NAME_BASE=HMEQ;
%let INPUTTABLE_TBLTYPE=table;
%let INPUTTABLE_TYPE=dataTable;
%let INPUTVARS=BAD LOAN MORTDUE VALUE REASON JOB YOJ DEROG DELINQ CLAGE NINQ CLNO DEBTINC;
%let NOMINALVARS=BAD REASON JOB;
%let NOMINALVARS_COUNT=3;
%let CLASSVAR_COUNT=1;
%let NUMK=5;
%let NUMSAMPLES=100;
%let NUMTHREADS=0;
%let OUTPUTTABLE=PUBLIC.HMEQ_SYNTH;
%let OUTPUTTABLE_ENGINE=V9;
%let OUTPUTTABLE_LIB=PUBLIC;
%let OUTPUTTABLE_NAME=HMEQ_SYNTH;
%let OUTPUTTABLE_NAME_BASE=HMEQ_SYNTH;
%let SEEDNUMBER=123;
%let extrapolationFactor=0;
%let sampling_percent=30;

*/;

/*-----------------------------------------------------------------------------------------*
   END DEBUG Section
*------------------------------------------------------------------------------------------*/


/*-----------------------------------------------------------------------------------------*
   MACROS
*------------------------------------------------------------------------------------------*/


/* -------------------------------------------------------------------------------------------* 
   Macro to initialize a run-time trigger global macro variable to run SAS Studio Custom Steps. 
   A value of 1 (the default) enables this custom step to run.  A value of 0 (provided by 
   upstream code) sets this to disabled.

   Input:
   1. triggerName: The name of the runtime trigger you wish to create. Ensure you provide a 
      unique value to this parameter since it will be declared as a global variable.

   Output:
   2. &triggerName : A global variable which takes the name provided to triggerName.
*-------------------------------------------------------------------------------------------- */

%macro _create_runtime_trigger(triggerName);

   %global &triggerName.;

   %if %sysevalf(%superq(&triggerName.)=, boolean)  %then %do;
  
      %put NOTE: Trigger macro variable &triggerName. does not exist. Creating it now.;
      %let &triggerName.=1;

   %end;

%mend _create_runtime_trigger;


/* -----------------------------------------------------------------------------------------* 
   Macro to create an error flag for capture during code execution.

   Input:
      1. errorFlagName: The name of the error flag you wish to create. Ensure you provide a 
         unique value to this parameter since it will be declared as a global variable.
      2. errorFlagDesc: A description to add to the error flag.

    Output:
      1. &errorFlagName : A global variable which takes the name provided to errorFlagName.
      2. &errorFlagDesc : A global variable which takes the name provided to errorFlagDesc.
*------------------------------------------------------------------------------------------ */

%macro _create_error_flag(errorFlagName, errorFlagDesc);

   %global &errorFlagName.;
   %let  &errorFlagName.=0;
   %global &errorFlagDesc.;

%mend _create_error_flag;


/*-----------------------------------------------------------------------------------------*
   Macro to capture indicator and UUIDof any currently active CAS session.
   UUID is not expensive and can be used in future to consider graceful reconnect.

   Input:
   1. errorFlagName: name of an error flag that gets populated in case the connection is 
                     not active. Provide this value in quotes when executing the macro.
                     Define this as a global macro variable in order to use downstream.
   2. errorFlagDesc: Name of a macro variable which can hold a descriptive message output
                     from the check.
                     
   Output:
   1. Informational note as required. We explicitly don't provide an error note since 
      there is an easy recourse(of being able to connect to CAS)
   2. UUID of the session: macro variable which gets created if a session exists.
   3. errorFlagName: populated
   4. errorFlagDesc: populated
*------------------------------------------------------------------------------------------*/

%macro _env_cas_checkSession(errorFlagName, errorFlagDesc);

    %if %sysfunc(symexist(_current_uuid_)) %then %do;
       %symdel _current_uuid_;
    %end;
    %if %sysfunc(symexist(_SESSREF_)) %then %do;
      %let casSessionExists= %sysfunc(sessfound(&_SESSREF_.));
      %if &casSessionExists.=1 %then %do;
         %global _current_uuid_;
         %let _current_uuid_=;   
         proc cas;
            session.sessionId result = sessresults;
            call symputx("_current_uuid_", sessresults[1]);
         quit;
         %put NOTE: A CAS session &_SESSREF_. is currently active with UUID &_current_uuid_. ;
         data _null_;
            call symputx(&errorFlagName., 0);
            call symput(&errorFlagDesc., "CAS session is active.");
         run;
      %end;
      %else %do;
         %put NOTE: Unable to find a currently active CAS session. Reconnect or connect to a CAS session upstream. ;
         data _null_;
            call symputx(&errorFlagName., 1);
            call symput(&errorFlagDesc., "Unable to find a currently active CAS session. Reconnect or connect to a CAS session upstream.");
        run;
      %end;
   %end;
   %else %do;
      %put NOTE: No active CAS session ;
      data _null_;
        call symputx(&errorFlagName., 1);
        call symput(&errorFlagDesc., "No active CAS session. Connect to a CAS session upstream.");
      run;
   %end;

%mend _env_cas_checkSession;   
   

/*-----------------------------------------------------------------------------------------*
   Caslib for a Libname macro
   
   This macro creates a global macro variable called _usr_nameCaslib
   that contains the caslib name (aka. caslib-reference-name) associated with the libname
   and assumes that the libname is using the CAS engine.
 
   As sysvalue has a length of 1024 chars, we use the trimmed option in proc sql
   to remove leading and trailing blanks in the caslib name.
   
   From macro provided by Wilbram Hazejager (wilbram.hazejager@sas.com)

   Inputs:
   - _usr_LibrefUsingCasEngine : A library reference provided by the user which is based 
                                 on a CAS engine.
   
   Outputs:
   - _usr_nameCaslib : Global macro variable containing the caslib name.
*------------------------------------------------------------------------------------------*/
 
%macro _usr_getNameCaslib(_usr_LibrefUsingCasEngine);
 
   %global _usr_nameCaslib;
   %let _usr_nameCaslib=;
 
   proc sql noprint;
      select sysvalue into :_usr_nameCaslib trimmed from dictionary.libnames
      where libname = upcase("&_usr_LibrefUsingCasEngine.") and upcase(sysname)="CASLIB";
   quit;

   /*--------------------------------------------------------------------------------------*
      Note that we output a NOTE instead of an ERROR for the below condition since the 
      execution context determines whether this is an error or just an informational note.
   *---------------------------------------------------------------------------------------*/
   %if "&_usr_nameCaslib." = "" %then %put NOTE: The caslib name for the &_usr_LibrefUsingCasEngine. is blank.;
 
%mend _usr_getNameCaslib;


/*-----------------------------------------------------------------------------------------*
   Macro to check if a given libref belongs to a SAS or CAS engine.

   Input:
   1. sasCasLibref: a libref to be checked. Do not quote.
   2. tableEngine: a flag to hold the table Engine value.
   3. errorFlagName: a flag to populate an error code with.
   4. errorFlagDesc: a flag to describe the error if one occurs.
   5. sessionExists: an indicator (1) whether an active CAS session exists.  If not(0),
                     it will be created.
                     
   Output:
   1. tableEngine: populated with SAS or CAS
   2. errorFlagName: populated with 1 if an error and 0 if not
   3. errorFlagDesc: populated in case of an error
*------------------------------------------------------------------------------------------*/

%macro _sas_or_cas(sasCasLibref, tableEngine, errorFlagName, errorFlagDesc, sessionExists);

   %if &sessionExists. = 0 %then %do;
      cas _temp_ss_ ;
      caslib _ALL_ assign;
   %end;

    proc sql noprint;
        select distinct Engine into:&&tableEngine. from dictionary.libnames where libname = upcase("&sasCasLibref.");
    quit;

    %put "&&&tableEngine.";

    %if %sysfunc(compress("&&&tableEngine.")) = "V9" %THEN %DO;
        data _null_;
            call symput("&tableEngine.","SAS");
            call symputx("&errorFlag.",0);
            call symput("&errorFlagDesc.","");
        run;
    %end;
    %else %if %sysfunc(compress("&&&tableEngine.")) = "CAS" %THEN %DO;
        data _null_;
            call symputx("&errorFlagName.",0);
            call symput("&errorFlagDesc.","");
        run;
    %END;
    %else %do;
        data _null_;
            call symputx("&errorFlagName.",1);
            call symput("&errorFlagDesc.","Unable to associate libref with either SAS or CAS. Check the input libref provided.");
        run;
    %end;

   %if &sessionExists. = 0 %then %do;
      cas _temp_ss_ terminate;
   %end;
    
%mend _sas_or_cas;


/*-----------------------------------------------------------------------------------------*
   Macro to check if an in-memory table exists.

   Input:
   1. tableName: name of the in-memory table
   2. tableLib: caslib backing the in-memory table
   3. sessionExists: an indicator (1) whether an active CAS session exists.  If not(0),
                     it will be created.
                     
   Output:
   1. tableExists: populated with 0 if does not exist, 1 if exists with local scope, 
                   2 if exists with global scope

*------------------------------------------------------------------------------------------*/   

%macro _cas_table_exists(tableName, tableLib, sessionExists, tableExists);

   %if &sessionExists. = 0 %then %do;
      cas _temp_ss_ ;
      caslib _ALL_ assign;
   %end;

   proc cas;
      table.tableExists result = rc /
         name="&tableName.",
         caslib="&tableLib."
      ;
      call symputx("&tableExists.",rc.exists);
   quit;

   %if &sessionExists. = 0 %then %do;
      cas _temp_ss_ terminate;
   %end;
    
%mend _cas_table_exists;
   

/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE MACRO 

   _smt prefix stands for SMOTE
*------------------------------------------------------------------------------------------*/

%macro _smt_execution_code;

/*-----------------------------------------------------------------------------------------*
   Create an error flag. 
*------------------------------------------------------------------------------------------*/

   %_create_error_flag(_smt_error_flag, _smt_error_desc);

/*-----------------------------------------------------------------------------------------*
   Check if an active CAS session exists. 
*------------------------------------------------------------------------------------------*/

   %_env_cas_checkSession("_smt_error_flag", "_smt_error_desc");

/*-----------------------------------------------------------------------------------------*
   Check Input table libref to ensure it points to a valid caslib.
*------------------------------------------------------------------------------------------*/

   %if &_smt_error_flag. = 0 %then %do;

      %global inputCaslib;
      %_usr_getNameCaslib(&inputTable_lib.);
      %let inputCaslib=&_usr_nameCaslib.;
      %put NOTE: &inputCaslib. is the caslib for the input table.;
      %let _usr_nameCaslib=;

      %if "&inputCaslib." = "" %then %do;
         data _null_;
            call symputx("_smt_error_flag",1);
            call symput("_smt_error_desc","ERROR: Input table caslib is blank. Check if Base table is a valid CAS table.");
         run;
         %put ERROR: Input table caslib is blank. Check if Base table is a valid CAS table. ;
      %end;

   %end;

/*-----------------------------------------------------------------------------------------*
   Check if input table exists.
*------------------------------------------------------------------------------------------*/
   
   %global casTableExists;

   %if &_smt_error_flag. = 0 %then %do;
      %_cas_table_exists(&inputTable_name_base.,&inputTable_lib.,1,casTableExists);
      %if &casTableExists.=0 %then %do;
         data _null_;
            call symputx("_smt_error_flag",1);
            call symput("_smt_error_desc","ERROR: The given CAS table does not seem to exist. Please check if it is loaded to CAS.");
         run;
         %put ERROR: The given CAS table does not seem to exist. Please check if it is loaded to CAS.;
      %end;    
   %end;

/*-----------------------------------------------------------------------------------------*
   Check Output table libref to ensure it points to a valid caslib.
*------------------------------------------------------------------------------------------*/

   %if &_smt_error_flag. = 0 %then %do;

      %global outputCaslib;
      %_usr_getNameCaslib(&outputTable_lib.);
      %let outputCaslib=&_usr_nameCaslib.;
      %put NOTE: &outputCaslib. is the caslib for the output table.;
      %let _usr_nameCaslib=;

      %if "&outputCaslib." = "" %then %do;
         data _null_;
            call symputx("_smt_error_flag",1);
            call symput("_smt_error_desc","ERROR: Output table caslib is blank. Check if table is a valid CAS table.");
         run;
         %put ERROR: Output table caslib is blank. Check if table is a valid CAS table. ;
      %end;

   %end;

/*-----------------------------------------------------------------------------------------*
   Obtain list of input & nominal variables and store them in macro variables.
*------------------------------------------------------------------------------------------*/

   %if &_smt_error_flag. = 0 %then %do;
      %let blankSeparatedInputVars = %_flw_get_column_list(_flw_prefix=inputVars);
      %let blankSeparatedNominalVars = %_flw_get_column_list(_flw_prefix=nominalVars);
   %end;

   %put NOTE: Input variables selected - &blankSeparatedInputVars.;
   %put NOTE: Nominal variables selected - &blankSeparatedNominalVars.;


/*-----------------------------------------------------------------------------------------*
   Create a program string based on selection of nominal variables.
*------------------------------------------------------------------------------------------*/

   %if &_smt_error_flag. = 0 %then %do;
      %if &nominalVars_count.=0 %then %do;
         data _null_;
            call symput("nominalString","");
         run;
      %end;
      %else %do;
         data _null_;
            call symput("nominalString","nominals=${&blankSeparatedNominalVars.},");
         run;
      %end;
   %end;

/*-----------------------------------------------------------------------------------------*
   Create a program string based on selection of class variables.
*------------------------------------------------------------------------------------------*/
   %if &_smt_error_flag. = 0 %then %do;
      %if &classVar_count.=0 %then %do;
         data _null_;
            call symput("classString","");
            call symput("classToAugment","");
            call symput("classAugmentString","");
         run;
      %end;
      %else %do;
         data _null_;
            call symput("classString","classColumn=classColumnVar,");
            call symput("classAugmentString","classToAugment=class_to_augment,");
         run;
      %end;
   %end;
/*-----------------------------------------------------------------------------------------*
   Check if provenance flag name has been provided otherwise code as default
*------------------------------------------------------------------------------------------*/
   %if &_smt_error_flag. = 0 %then %do;
      %if %sysfunc(compress("&prov_flag_name."))="" %then %do;
         %put NOTE: Value not provided for provenance variable.  Using default.;
         data _null_;
            call symput("prov_flag_name","Synthetic_Data_Provenance");
         run;
      %end;
   %end;
/*-----------------------------------------------------------------------------------------*
   Check if assessment table (optional) has been provided otherwise code as default
*------------------------------------------------------------------------------------------*/
   %if &_smt_error_flag. = 0 %then %do;
      %if &sampling_percent. > 0 %then %do;
         %put NOTE: Assessment table value is - &assessmentTable. ;
         %if %sysevalf(%superq(assessmentTable)=, boolean)  %then %do;
            %put ERROR: An assessment table has not been attached. Please attach the same.;
            data _null_;
               call symputx("_smt_error_flag",1);
               call symput("_smt_error_desc","An assessment table has not been attached. Please attach the same.");
            run;
         %end;
         %else %if "%sysfunc(substr(&assessmentTable.,1,9))"="WORK._flw" %then %do;
            %put NOTE: Value not provided for assessment table.  Using default.;
            data _null_;
               call symput("assessmentTable","PUBLIC.SMOTE_ASSESSMENT");
               call symput("assessmentTable_lib","PUBLIC");
               call symput("assessmentTable_name_base","SMOTE_ASSESSMENT");
            run;
         %end;
         %else %if %sysfunc(compress("&assessmentTable."))="" %then %do;
            %put NOTE: Value not provided for assessment table.  Using default.;
            data _null_;
               call symput("assessmentTable","PUBLIC.SMOTE_ASSESSMENT");
               call symput("assessmentTable_lib","PUBLIC");
               call symput("assessmentTable_name_base","SMOTE_ASSESSMENT");
            run;
         %end;
      %end;
   %end;
/*-----------------------------------------------------------------------------------------*
   Test data set created based on percent
*------------------------------------------------------------------------------------------*/
   %if &_smt_error_flag. = 0 %then %do;
      %if &sampling_percent.=0 %then %do;
         data &outputTable_lib..__temp_smote;
            set &inputTable.;
            _PartInd_ = 0;
         run;
      %end;
      %else %do;
         proc partition data=&inputTable. partind samppct= &sampling_percent. seed=10 ;
            output out=&outputTable_lib..__temp_smote copyvars=(_all_);
            display 'SRSFreq';
         run;
         data &outputTable_lib..__temp_smote &outputTable_lib..__assess_orig;
            set &outputTable_lib..__temp_smote;
            if _PartInd_=0 then output &outputTable_lib..__temp_smote;
            else output &outputTable_lib..__assess_orig;
         run;
/*-----------------------------------------------------------------------------------------*
      Add a provenance flag
*------------------------------------------------------------------------------------------*/
         data &outputTable_lib..__assess_orig;
            length &prov_flag_name. $9.;
            set &outputTable_lib..__assess_orig;
            &prov_flag_name. = "Original";
         run;

      %end;

   %end;
/*-----------------------------------------------------------------------------------------*
   Run SMOTE action
*------------------------------------------------------------------------------------------*/
   %if &_smt_error_flag. = 0 %then %do;
      proc cas;        
         numK                      = symget("numK");
         inputTableCaslib          = symget("inputCaslib");
         inputTableName            = symget("inputTable_name_base");
         blankSeparatedNominalVars = symget("blankSeparatedNominalVars");
         blankSeparatedInputVars   = symget("blankSeparatedInputVars");
         classColumnVar            = symget("classVar");
         classVarType              = symget("classVar_1_Type");
         classToAugment            = symget("classToAugment");
         numSamplesVar             = symget("numSamples");
         outputTableCaslib         = symget("outputCaslib");
         outputTableName           = symget("outputTable_name_base");
         seedNumber                = symget("seedNumber");
         numThreads                = symget("numThreads");
         extrapolation_factor      = symget("extrapolationFactor");

         if classVarType = "Numeric" then class_to_augment = classToAugment*1; 
         else class_to_augment = classToAugment;

         smote.smoteSample result=r/
            table={name="__temp_smote", caslib=outputTableCaslib, where='_PartInd_=0'},
/*             table={name=inputTableName, caslib=inputTableCaslib}, */
            k = numK,
            inputs=${&blankSeparatedInputVars.},
            &nominalString.
            &classString.
            &classAugmentString.
            seed=seedNumber,
            nThreads = numThreads,
            numSamples=numSamplesVar,
            extrapolationFactor=extrapolation_factor,
            casout={name=outputTableName,caslib= outputTableCaslib, replace="TRUE"}
         ;
         print r;
      run;
      quit;
   %end;
/*-----------------------------------------------------------------------------------------*
      Add a provenance flag
*------------------------------------------------------------------------------------------*/
   %if &_smt_error_flag. = 0 %then %do;
      data &outputTable.;
         length &prov_flag_name. $9.;
         set &outputTable.;
         &prov_flag_name. = "Synthetic";
      run;

   %end;

/*-----------------------------------------------------------------------------------------*
      Take a sample from synthetic data and merge with original data
*------------------------------------------------------------------------------------------*/
   %if &_smt_error_flag. = 0 %then %do;
      proc sql noprint;
         select count(*) into: synth_records from &outputTable.;
         select count(*) into: orig_records from &inputTable.;
      quit;

      %put NOTE: Number of synthetic records - &synth_records.;
      %put NOTE: Number of original records - &orig_records.;
      %put NOTE: Sampling Percent provided - &sampling_percent.;
      
      data _null_;
         call symputx("synth_sampling_percent",100*((&sampling_percent./100) * &orig_records. )/&synth_records.);
      run;
      %put NOTE: Synthetic Sampling Percent  - &synth_sampling_percent.;

      %if &sampling_percent.=0 %then %do;
/*-----------------------------------------------------------------------------------------*
   Block deliberately left empty for a future consideration
*------------------------------------------------------------------------------------------*/
      %end;
      %else %do;
         proc partition data=&outputTable. partind samppct= &synth_sampling_percent. seed=10 ;
            output out=&outputTable_lib..__assess_synth copyvars=(_all_);
            display 'SRSFreq';
         run;
         data &assessmentTable.;
            set &outputTable_lib..__assess_orig &outputTable_lib..__assess_synth (where=(_PartInd_=1));
            keep &prov_flag_name. &blankSeparatedInputVars.;
         run;
         proc datasets lib=&outputTable_lib.;
            delete __assess_orig __assess_synth  ;
         quit;
      %end;
      proc datasets lib=&outputTable_lib.;
         delete __temp_smote;
      quit;
   %end;


%mend _smt_execution_code;   

/*-----------------------------------------------------------------------------------------*
   END MACROS
*------------------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE
*------------------------------------------------------------------------------------------*/
   
/*-----------------------------------------------------------------------------------------*
   Create Runtime Trigger
*------------------------------------------------------------------------------------------*/
%_create_runtime_trigger(_smt_run_trigger);

/*-----------------------------------------------------------------------------------------*
   Execute 
*------------------------------------------------------------------------------------------*/

%if &_smt_run_trigger. = 1 %then %do;

   %_smt_execution_code;

%end;

%if &_smt_run_trigger. = 0 %then %do;

   %put NOTE: This step has been disabled.  Nothing to do.;

%end;


%put NOTE: Final summary;
%put NOTE: Status of error flag - &_smt_error_flag. ;
%put &_smt_error_desc.;
%put NOTE: Error desc - &_smt_error_desc. ;

/*-----------------------------------------------------------------------------------------*
   END EXECUTION CODE
*------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------*
   Clean up existing macro variables and macro definitions.
*------------------------------------------------------------------------------------------*/

%if %symexist(inputCaslib) %then %do;
   %symdel inputCaslib;
%end;

%if %symexist(outputCaslib) %then %do;
   %symdel outputCaslib;
%end;

%if %symexist(casTableExists) %then %do;
   %symdel casTableExists;
%end;

%if %symexist(prov_flag_name) %then %do;
   %symdel prov_flag_name;
%end;

%if %symexist(_smt_run_trigger) %then %do;
   %symdel _smt_run_trigger;
%end;

%if %symexist(_smt_error_flag) %then %do;
   %symdel _smt_error_flag;
%end;

%if %symexist(_smt_error_desc) %then %do;
   %symdel _smt_error_desc;
%end;

%sysmacdelete _create_error_flag;
%sysmacdelete _create_runtime_trigger;
%sysmacdelete _env_cas_checkSession;
%sysmacdelete _usr_getNameCaslib;
%sysmacdelete _sas_or_cas;
%sysmacdelete _cas_table_exists;
%sysmacdelete _smt_execution_code;

/* SAS templated code goes here */

/* -------------------------------------------------------------------------------------------* 
   Synthetic Data Generation (SDG) - Generate Synthetic Data through GANs

   v 2.0 (03NOV2024)

   This program generates synthetic data using a pretrained Generative Adversarial Network-based model. 
   Please modify requisite macro variables (hint: use the debug section as a reference) to run this 
   through other interfaces, such as a SAS Program editor or the SAS extension for Visual Studio Code.

   Sundaresh Sankaran (sundaresh.sankaran@sas.com|sundaresh.sankaran@gmail.com)
*-------------------------------------------------------------------------------------------- */

/*-----------------------------------------------------------------------------------------*
   DEBUG Section
   Code under the debug section SHOULD ALWAYS remain commented unless you are tinkering with  
   or testing the step!
*------------------------------------------------------------------------------------------*/

/* Provide test values for the parameters */

/*

%let inputtable1=PUBLIC.HMEQ_ASTORE;
%let inputtable1_lib=PUBLIC;
%let outputtable1=PUBLIC.HMEQ_DATA;
%let outputtable1_lib=PUBLIC;
%let numobs=10000;
%let enableGPU=0;
%let provenance_flag = SYNTHETIC_DATA_FLAG;

*/

/*-----------------------------------------------------------------------------------------*
   START MACRO DEFINITIONS.
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
   This macro creates a dataset of IDs on the fly as per number provided by user.
*------------------------------------------------------------------------------------------*/

%macro _gsd_createData(_data_lib);

   data &_data_lib..IDONLY;
	  length ID 8.;
	  %do i=1 %to &numobs.;
	     ID = &i.;
	     output;
	  %end;
   run;

%mend _gsd_createData;


/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE MACRO (SDG_SCR / sdgscr - synthetic data gen score)
*------------------------------------------------------------------------------------------*/

%macro _sdg_scr_execution_code;

/*-----------------------------------------------------------------------------------------*
   Create an error flag. 
*------------------------------------------------------------------------------------------*/

   %_create_error_flag(_sdgscr_error_flag, _sdgscr_error_desc);

/*-----------------------------------------------------------------------------------------*
   Check if an active CAS session exists. 
*------------------------------------------------------------------------------------------*/

   %_env_cas_checkSession("_sdgscr_error_flag", "_sdgscr_error_desc");

/*-----------------------------------------------------------------------------------------*
   Check Input table libref to ensure it points to a valid caslib.
*------------------------------------------------------------------------------------------*/

   %if &_sdgscr_error_flag. = 0 %then %do;

      %global _sas_or_cas_inp;
      %_sas_or_cas(&inputtable1_lib., _sas_or_cas_inp, _sdgscr_error_flag, _sdgscr_error_desc, 1 );
      %put NOTE: Input table engine is &_sas_or_cas_inp. ;
      %if %sysfunc(compress("&_sas_or_cas_inp."))="CAS" %then %do;
         %put NOTE: Input table belongs to a CAS libref.;
      %end;
      %else %do;
         data _null_;
            call symputx("_sdgscr_error_flag", 60);
            call symput("","The input table should be associated with a CAS engine.");
         run;
      %end;
   %end;

/*-----------------------------------------------------------------------------------------*
   Check Output table libref to ensure it points to a valid caslib.
*------------------------------------------------------------------------------------------*/

   %if &_sdgscr_error_flag. = 0 %then %do;

      %global _sas_or_cas_op;
      %_sas_or_cas(&outputtable1_lib., _sas_or_cas_op, _sdgscr_error_flag, _sdgscr_error_desc, 1 );
       
      %if %sysfunc(compress("&_sas_or_cas_op."))="CAS" %then %do;
         %put NOTE: Output table belongs to a CAS libref.;
      %end;
      %else %do;
         data _null_;
            call symputx("_sdgscr_error_flag", 60);
            call symput("_sdgscr_error_desc","The output table should be associated with a CAS engine.");
         run;
      %end;

   %end;

/*-----------------------------------------------------------------------------------------*
   Check if input table exists.
*------------------------------------------------------------------------------------------*/
   
   %global casTableExists;

   %if &_sdgscr_error_flag. = 0 %then %do;
      %_cas_table_exists(&inputTable1_name_base.,&inputTable1_lib.,1,casTableExists);
      %if &casTableExists.=0 %then %do;
         data _null_;
            call symputx("_sdgscr_error_flag",1);
            call symput("_sdgscr_error_desc","ERROR: The given CAS table does not seem to exist. Please check if it is loaded to CAS.");
         run;
         %put ERROR: The given CAS table does not seem to exist. Please check if it is loaded to CAS.;
      %end;    
   %end;

   /*--------------------------------------------------------------------------------------*
      Generate a dataset of IDs. 
   *---------------------------------------------------------------------------------------*/

   %if &_sdgscr_error_flag. = 0 %then %do;
      %_gsd_createData(&outputTable1_lib.);
   %end;

   %if &_sdgscr_error_flag. = 0 %then %do;
      %put NOTE: GPU enabled status is &enableGPU.;
      proc astore;
         setoption USEGPU &enableGPU.;
         setoption NDEVICES 1;
         score data=&outputtable1_lib..IDONLY 
         rstore=&inputtable1.
         out=&outputtable1.;
      quit;
   %end;

   /*--------------------------------------------------------------------------------------*
      Generate a provenance variable. 
   *---------------------------------------------------------------------------------------*/

   data &outputtable1.;
	  set &outputtable1.;
	  &provenance_flag.=1;
   run;

   /*--------------------------------------------------------------------------------------*
      Clean up ID table as you go
   *---------------------------------------------------------------------------------------*/
   proc datasets lib=&outputtable1_lib.;
      delete IDONLY;
   quit;

%mend _sdg_scr_execution_code;

/*-----------------------------------------------------------------------------------------*
   END MACROS
*------------------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE
   The execution code is controlled by the trigger variable defined in this custom step. This
   trigger variable is in an "enabled" (value of 1) state by default, but in some cases, as 
   dictated by logic, could be set to a "disabled" (value of 0) state.
*------------------------------------------------------------------------------------------*/

%_create_runtime_trigger(_gsd_run_trigger);

%if &_gsd_run_trigger. = 1 %then %do;
   %_sdg_scr_execution_code;
%end;
%if &_gsd_run_trigger. = 0 %then %do;
   %put NOTE: This step has been disabled.  Nothing to do.;
%end;

%put NOTE: Final summary;
%put NOTE: Status of error flag - &_sdgscr_error_flag. ;
%put &_sdgscr_error_desc.;
%put NOTE: Error desc - &_sdgscr_error_desc. ;


/*-----------------------------------------------------------------------------------------*
   END EXECUTION CODE
*------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------*
   Clean up existing macro variables and macro definitions.
*------------------------------------------------------------------------------------------*/

%if %symexist(casTableExists) %then %do;
   %symdel casTableExists;
%end;

%if %symexist(_sas_or_cas_inp) %then %do;
   %symdel _sas_or_cas_inp;
%end;

%if %symexist(_sas_or_cas_op) %then %do;
   %symdel _sas_or_cas_op;
%end;

%if %symexist(_gsd_run_trigger) %then %do;
   %symdel _gsd_run_trigger;
%end;

%if %symexist(_sdgscr_error_flag) %then %do;
   %symdel _sdgscr_error_flag;
%end;

%if %symexist(_sdgscr_error_desc) %then %do;
   %symdel _sdgscr_error_desc;
%end;

%sysmacdelete _create_error_flag;
%sysmacdelete _create_runtime_trigger;
%sysmacdelete _env_cas_checkSession;
%sysmacdelete _gsd_createData;
%sysmacdelete _sas_or_cas;
%sysmacdelete _cas_table_exists;
%sysmacdelete _sdg_scr_execution_code;

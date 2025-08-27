/* SAS templated code goes here */

/* -------------------------------------------------------------------------------------------* 
   Synthetic Data Generation (SDG) - Train a Synthetic Data Generator through GANs

   v 2.1 (17FEB2025)

   This program train a model through Generative Adversarial Networks (GANs) using underlying 
   distributions and correlations learnt from an existing dataset.  
   This step results in a model binary, known as an astore, which can be used in a scoring process. 
   Please modify requisite macro variables (hint: use the debug section as a reference) to run this 
   through other interfaces, such as a SAS Program editor or the SAS extension for Visual Studio Code.

   Sundaresh Sankaran (sundaresh.sankaran@sas.com|sundaresh.sankaran@gmail.com)
*-------------------------------------------------------------------------------------------- */


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
            call symputx("&errorFlagName.",0);
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


/*--------------------------------------------------------------------------------------*
   Macro to execute string substitution for "GPU Devices" in case the user enables GPU & 
   specifies a GPU device ID. 

   Note : For those interested, a little dated but insightful SAS Global Forum paper on 
   the best way to evaluate if a macro variable is blank (as used below), provided here:
   http://support.sas.com/resources/papers/proceedings09/022-2009.pdf 
*---------------------------------------------------------------------------------------*/

%macro _gpu_status_string_substitute;
   %global deviceArgumentString;
   %if &gpuEnabled.=0 %then %do;
      %let deviceArgumentString=;
   %end;
   %else %do;
      %if %sysevalf(%superq(numDevices)=,boolean) %then %do;
         data _null_;
            call symput("deviceArgumentString","useGPU (device=0)");
         run;
      %end;
      %else %do;
         data _null_;
            call symput("deviceArgumentString","useGPU (device=&numDevices.)");
         run;
      %end;
   %end;

%mend _gpu_status_string_substitute;

/* -----------------------------------------------------------------------------------------* 
   This macro creates a global macro variable called _usr_nameCaslib
   that contains the caslib name (aka. caslib-reference-name) associated with the libname 
   and assumes that the libname is using the CAS engine.

   As sysvalue has a length of 1024 chars, we use the trimmed option in proc sql
   to remove leading and trailing blanks in the caslib name.
*------------------------------------------------------------------------------------------ */

%macro _usr_getNameCaslib(_usr_LibrefUsingCasEngine); 

   %global _usr_nameCaslib;
   %let _usr_nameCaslib=;

   proc sql noprint;
      select sysvalue into :_usr_nameCaslib trimmed from dictionary.libnames
      where libname = upcase("&_usr_LibrefUsingCasEngine.") and upcase(sysname)="CASLIB";
   quit;

%mend _usr_getNameCaslib;


/* -----------------------------------------------------------------------------------------* 
   This macro loops through all selected input interval variables and creates centroid tables
   for them.
*------------------------------------------------------------------------------------------ */
%macro _tsdg_create_centroids_table;

  
     /* Loop over all variables that need centroids generation */
   %do i=1 %to &intervalVars_count.;

      %let name&i. = %scan(%nrquote(&blankSeparatedIntervalVars.), &i., %str(" "));
     
     /* Call PROC GMM to cluster each variable */
      proc gmm
         data=&inputtable1.
         seed=42
         maxClusters=10
         alpha=1
         inference=VB (maxVbIter=30 covariance=diagonal threshold=0.01);
         input &&name&i..;
         ods select ClusterInfo;
         ods output ClusterInfo = work.outinfo&i;
      run;

     /* Save variable name, weights, mean,     */
     /* and standard deviation of each cluster */
      data  work.outinfo&i;
        length varname $32.;
         varname = "&&name&i.";
         set  work.outinfo&i.(rename=(&&name&i.._Mean=Mean &&name&i.._Variance=Var));
         /* Calculate standard deviation from variance*/
         std = sqrt(Var);
         drop Var;
      run;

     /* Construct centroids table from saved weights */
      %if &i.=1 %then %do;

         data work._centroids;
            set work.outinfo&i.;
         run;
         proc datasets lib=work;
            delete outinfo&i. ;
         run;

      %end;
      %else %do;
         data work._centroids;
            set work._centroids work.outinfo&i;
         run;

         proc datasets lib=work;
            delete outinfo&i. ;
         run;

      %end;
   %end;

 %mend _tsdg_create_centroids_table;


/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE MACRO - tsdg stands for train synthetic data generator
*------------------------------------------------------------------------------------------*/

%macro _tsdg_execution_code;

/*-----------------------------------------------------------------------------------------*
   Create an error flag. 
*------------------------------------------------------------------------------------------*/

   %_create_error_flag(_tsdg_error_flag, _tsdg_error_desc);

/*-----------------------------------------------------------------------------------------*
   Check if an active CAS session exists. 
*------------------------------------------------------------------------------------------*/

   %_env_cas_checkSession("_tsdg_error_flag", "_tsdg_error_desc");

/*-----------------------------------------------------------------------------------------*
   Check Input table libref to ensure it points to a valid caslib.
*------------------------------------------------------------------------------------------*/

   %if &_tsdg_error_flag. = 0 %then %do;

      %global _sas_or_cas_inp;
      %_sas_or_cas(&inputtable1_lib., _sas_or_cas_inp, _tsdg_error_flag, _tsdg_error_desc, 1 );
      %put NOTE: Input table engine is &_sas_or_cas_inp. ;
      %if %sysfunc(compress("&_sas_or_cas_inp."))="CAS" %then %do;
         %put NOTE: Input table belongs to a CAS libref.;
      %end;
      %else %do;
         data _null_;
            call symputx("_tsdg_error_flag", 60);
            call symput("_tsdg_error_desc","The input table should be associated with a CAS engine.");
         run;
      %end;
   %end;

/*-----------------------------------------------------------------------------------------*
   Check output table 2 (model) table libref to ensure it points to a valid caslib.
*------------------------------------------------------------------------------------------*/

   %if &_tsdg_error_flag. = 0 %then %do;

      %global _sas_or_cas_op2;
      %_sas_or_cas(&outputtable2_lib., _sas_or_cas_op2, _tsdg_error_flag, _tsdg_error_desc, 1 );
      %put NOTE: Model table engine is &_sas_or_cas_op2. ;
      %if %sysfunc(compress("&_sas_or_cas_op2."))="CAS" %then %do;
         %put NOTE: Model table belongs to a CAS libref.;
      %end;
      %else %do;
         data _null_;
            call symputx("_tsdg_error_flag", 60);
            call symput("_tsdg_error_desc","The model table should be associated with a CAS engine.");
         run;
      %end;
   %end;

/*-----------------------------------------------------------------------------------------*
   Check Sample output table libref to ensure it points to a valid caslib.
*------------------------------------------------------------------------------------------*/

   %if &_tsdg_error_flag. = 0 %then %do;
      %if %sysevalf(%superq(outputtable1_lib)=,boolean)  %then %do;
         %put ERROR: No sample table library provided. Please attach a CAS table to the outputtable1 port.;
         data _null_;
            call symput("_tsdg_error_flag",1);
            call symput("_tsdg_error_desc","No sample table library provided. Please attach a CAS table to the outputtable1 port.");
         run;
      %end;
      %else %do;
         %global _sas_or_cas_op;
         %_sas_or_cas(&outputtable1_lib., _sas_or_cas_op, _tsdg_error_flag, _tsdg_error_desc, 1 );
         %put NOTE: Sample output table engine is &_sas_or_cas_op. ;
         %if %sysfunc(compress("&_sas_or_cas_op."))="CAS" %then %do;
            %put NOTE: Sample output table belongs to a CAS libref.;
         %end;
         %else %if %sysfunc(compress("&_sas_or_cas_op."))="SAS" %then %do;
            data _null_;
               call symputx("_tsdg_error_flag", 60);
               call symput("_tsdg_error_desc","The sample table should be associated with a CAS engine.");
            run;
            %put ERROR:&_tsdg_error_desc.;
         %end;
      %end;
   %end;



/*-----------------------------------------------------------------------------------------*
   Check if input table exists.
*------------------------------------------------------------------------------------------*/
   
   %global casTableExists;

   %if &_tsdg_error_flag. = 0 %then %do;
      %_cas_table_exists(&inputTable1_name_base.,&inputTable1_lib.,1,casTableExists);
      %if &casTableExists.=0 %then %do;
         data _null_;
            call symputx("_tsdg_error_flag",1);
            call symput("_tsdg_error_desc","ERROR: The given CAS table does not seem to exist. Please check if it is loaded to CAS.");
         run;
         %put ERROR: The given CAS table does not seem to exist. Please check if it is loaded to CAS.;
      %end;    
   %end;

/*--------------------------------------------------------------------------------------*
   Macro variables to hold the selected interval and nominal input variables.
*---------------------------------------------------------------------------------------*/

   %if &_tsdg_error_flag. = 0 %then %do;
      %let blankSeparatedIntervalVars = %_flw_get_column_list(_flw_prefix=intervalVars);
      %let blankSeparatedNominalVars = %_flw_get_column_list(_flw_prefix=nominalVars);
   %end;

/*-----------------------------------------------------------------------------------------*
   Run the libref check macro in order to obtain the correct Caslib for desired tables.
*------------------------------------------------------------------------------------------*/

   %if &_tsdg_error_flag. = 0 %then %do;

      %global inputCaslib;
      %global outputCaslib;
      %global modelCaslib;

      %_usr_getNameCaslib(&inputtable1_lib.);
      %let inputCaslib=&_usr_nameCaslib.;
      %put NOTE: &inputCaslib. is the input caslib.;
      %let _usr_nameCaslib=;

      %_usr_getNameCaslib(&outputtable1_lib.);
      %let outputCaslib=&_usr_nameCaslib.;
      %let _usr_nameCaslib=;

      %_usr_getNameCaslib(&outputtable2_lib.);
      %let modelCaslib=&_usr_nameCaslib.;
      %let _usr_nameCaslib=;

   %end;


   /* -----------------------------------------------------------------------------------------* 
      Run the _tsdg_create_centroids_table macro to generate the centroids table.
   *------------------------------------------------------------------------------------------ */

   %if &_tsdg_error_flag. = 0 %then %do;
      %_tsdg_create_centroids_table;

      data &outputtable2_lib.._centroids;
         set work._centroids;
      run;

      proc datasets lib=work;
         delete _centroids;
      quit;

   %end;


   %if &_tsdg_error_flag. = 0 %then %do;

/*    -----------------------------------------------------------------------------------------*  */
/*       Execute the gpu_status_string_substitute macro. */
/*    *------------------------------------------------------------------------------------------ */

      
      %_gpu_status_string_substitute;

      proc tabulargan
         data=&inputtable1. 
         seed=123 
         numSamples=&numSamples. 
         &deviceArgumentString.
      ;
         input               &blankSeparatedIntervalVars. /level=interval;
         input               &blankSeparatedNominalVars./level=nominal;
         gmm                 centroidsTable=&outputtable2_lib.._centroids;
         aeoptimization      ADAM numEpochs=&aeEpochs.;
         ganoptimization     ADAM numEpochs=&ganEpochs.;
         train               miniBatchSize=&miniBatchSize.;
         savestate           rstore=&outputtable2.;
         output              out=&outputtable1.;
      run;

      data &outputtable1.;      
         set &outputtable1.;      
         SYNTHETIC_DATA_FLAG = 1;       
      run;

   %end;

/* -----------------------------------------------------------------------------------------* 
   Persist score table (astore)
*------------------------------------------------------------------------------------------ */

   %if &_tsdg_error_flag. = 0 %then %do;

      proc cas;

         /* -----------------------------------------------------------------------------------------* 
            Obtain values from UI and store inside variables
         *------------------------------------------------------------------------------------------ */
         input_table_name =symget("inputtable1_name_base");
         input_table_lib  =symget("inputCaslib");
         model_table_name =symget("outputtable2_name_base");
         model_table_lib  =symget("modelCaslib");
         output_table_name=symget("outputtable1_name_base");
         output_table_lib =symget("outputCaslib");
	
         table.save /
            table  ={name = model_table_name, caslib=model_table_lib}
            name   =model_table_name
            caslib =model_table_lib
            replace=True
         ;
      quit;

      proc datasets lib=&outputtable2_lib.;
         delete _centroids;
      run;

   %end;

%mend _tsdg_execution_code;

/*-----------------------------------------------------------------------------------------*
   END OF MACROS
*------------------------------------------------------------------------------------------*/


/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE
   The execution code is controlled by the trigger variable defined in this custom step. This
   trigger variable is in an "enabled" (value of 1) state by default, but in some cases, as 
   dictated by logic, could be set to a "disabled" (value of 0) state.
*------------------------------------------------------------------------------------------*/



%_create_runtime_trigger(_tsdg_run_trigger);

%if &_tsdg_run_trigger. = 1 %then %do;
   %_tsdg_execution_code;
%end;
%if &_tsdg_run_trigger. = 0 %then %do;
   %put NOTE: This step has been disabled.  Nothing to do.;
%end;


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

%if %symexist(_sas_or_cas_op2) %then %do;
   %symdel _sas_or_cas_op2;
%end;

%if %symexist(_tsdg_run_trigger) %then %do;
   %symdel _tsdg_run_trigger;
%end;

%if %symexist(_tsdg_error_flag) %then %do;
   %symdel _tsdg_error_flag;
%end;

%if %symexist(_tsdg_error_desc) %then %do;
   %symdel _tsdg_error_desc;
%end;

%if %symexist(_current_uuid_) %then %do;
   %symdel _current_uuid_;
%end;

%if %symexist(deviceArgumentString) %then %do;
   %symdel deviceArgumentString;
%end;

%if %symexist(inputCaslib) %then %do;
   %symdel inputCaslib;
%end;

%if %symexist(modelCaslib) %then %do;
   %symdel modelCaslib;
%end;

%if %symexist(outputCaslib) %then %do;
   %symdel outputCaslib;
%end;

%sysmacdelete _create_error_flag;
%sysmacdelete _create_runtime_trigger;
%sysmacdelete _env_cas_checkSession;
%sysmacdelete _sas_or_cas;
%sysmacdelete _cas_table_exists;
%sysmacdelete _gpu_status_string_substitute;
%sysmacdelete _usr_getNameCaslib;
%sysmacdelete _tsdg_create_centroids_table;
%sysmacdelete _tsdg_execution_code;

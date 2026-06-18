/* SAS templated code goes here */

/* -------------------------------------------------------------------------------------------* 
   Synthetic Data Generation (SDG) - Generate Synthetic Data through SMOTE

   v 1.3.1 (10DEC2024)

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
   Python Block Definition
*------------------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------------*
   The following block of code has been created for the purpose of allowing proc python 
   to execute within a macro. Execution within a macro allows for other checks to be carried 
   out through SAS prior to handing off to the Python step.

   In this example, a temporary file is created containing the requisite Python commands, which 
   are then executed through infile reference.

   Note that Python code is pasted as-is and may be out of line with the SAS indentation followed.

   This Python block comes into operation only upon the selection of Privacy Risk (Singling
   Out Risk) metrics.

*------------------------------------------------------------------------------------------*/
filename smtcode temp;

data _null_;

   length line $32767;               * max SAS character size ;
   infile datalines4 truncover pad;
   input ;   
   file smtcode;
   line = strip(_infile_);           * line without leading and trailing blanks ;
   l1 = length(trimn(_infile_));     * length of line without trailing blanks ;
   l2 = length(line);                * length of line without leading and trailing blanks ;
   first_position=l1-l2+1;           * position where the line should start (alignment) ;
   if (line eq ' ') then put @1;     * empty line ;
   else put @first_position line;    * line without leading and trailing blanks correctly aligned ;

   datalines4;
# Imports
_smt_error_flag          = int(SAS.symget("_smt_error_flag"))
_smt_error_desc          = SAS.symget("_smt_error_desc")


citation = """

   Calculated using anonymeter (https://pypi.org/project/anonymeter/)

  "A Unified Framework for Quantifying Privacy Risk in Synthetic Data", M. Giomi et al, PoPETS 2023. 


"""


try:
   import os
   import swat
   import json 
   from anonymeter.evaluators import SinglingOutEvaluator
except ImportError as ie:
   _smt_error_flag = 1
   _smt_error_desc = ie
   SAS.symput("_smt_error_flag",_smt_error_flag)
   SAS.symput("_smt_error_desc",_smt_error_desc)
   SAS.logMessage(_smt_error_desc,"error")

if _smt_error_flag ==0:
   # Obtain values from UI & SAS macro variables
   evaluation_mode          = SAS.symget('evaluation_mode')
   conf_interval            = float(SAS.symget('conf_interval'))
   s_o_attacks              = int(SAS.symget('s_o_attacks'))
   singling_out_results_tbl = SAS.symget('singling_out_results_tbl')
   singling_out_queries_tbl = SAS.symget('singling_out_queries_tbl')
   cas_session_exists       = SAS.symget('casSessionExists')
   assessment_table_name    = SAS.symget('assessmentTable_name_base')
   assessment_table_caslib  = SAS.symget('assessmentCaslib')
   input_caslib             = SAS.symget('inputCaslib')
   input_table_name         = SAS.symget('inputTable_name_base')
   so_queries_tbl           = SAS.symget('so_queries_tbl_name_base')
   so_results_tbl           = SAS.symget('so_results_tbl_name_base')
   so_queries_caslib        = SAS.symget('so_queries_caslib')
   so_results_caslib        = SAS.symget('so_results_caslib')

   # Retrieve values for SAS options cashost and casport, these are needed by SWAT connection 
   cas_host_name = SAS.sasfnc('getoption','cashost')
   cas_host_port = SAS.sasfnc('getoption','casport')

   #  Add certificate location to operating system list of trusted certs
   os.environ['CAS_CLIENT_SSL_CA_LIST'] = os.environ['SSLCALISTLOC']
                                                                                                                  
                                                               
   #  Connect to CAS
   if cas_session_exists == '1':
      cas_session_uuid = SAS.symget('casSessionUUID')
      SAS.logMessage(f"CAS connection exists. Session UUID is {cas_session_uuid}")   
      conn = swat.CAS(hostname = cas_host_name, port = cas_host_port, password = os.environ['SAS_SERVICES_TOKEN'], session = cas_session_uuid)
      if conn:
         SAS.logMessage('SWAT connection established.')
   else:
      SAS.logMessage('ERROR: No active CAS session. Connect to a CAS session in upstream step in the flow.')
      _smt_error_flag = 1
      _smt_error_desc = "ERROR: No active CAS session. Connect to a CAS session in upstream step in the flow."

   df_org = conn.CASTable(name=input_table_name, caslib=input_caslib).to_frame()
   df_syn = conn.CASTable(name=assessment_table_name, caslib=assessment_table_caslib, where="Synthetic_Data_Provenance='Synthetic'").to_frame()
   df_con = conn.CASTable(name=assessment_table_name, caslib=assessment_table_caslib, where="Synthetic_Data_Provenance='Original'").to_frame()


   evaluator = SinglingOutEvaluator(ori=df_org, syn=df_syn, control=df_con, n_attacks=s_o_attacks)

   try:
      evaluator.evaluate(mode=evaluation_mode)
      risk = evaluator.risk(confidence_level=conf_interval)
      print(risk)

   except RuntimeError as ex: 
      _smt_error_flag = 1
      _smt_error_desc = f"Singling out evaluation failed with {ex}. Please re-run this operation. For more stable results increase `n_attacks`. Note that this will make the evaluation slower."
      SAS.symput("_smt_error_flag",1)
      SAS.symput("_smt_error_desc",_smt_error_desc)

# Create a summary (title section will be modified in future version based on adding more metrics)
# SAS.submit("title 'Singling Out Risk: Summary'; run;")

if _smt_error_flag == 0:
    summary = f"Singling out privacy risk has been found to be {risk.value} between a confidence interval of {risk.ci[0]} and {risk.ci[1]}"
    query_status = f"{len(evaluator.queries())} queries were successful attacks."
    # Print to SAS results window
    SAS.submit(f"ods text = 'Singling Out Risk: Summary';")
    SAS.submit(f"ods text = '{summary}';")
    SAS.submit(f"ods text = '{query_status}';")
    SAS.submit(f"ods text = '{citation}';")
    SAS.logMessage(citation)
    citation_col = []
    for a in range(0,len(evaluator.queries())):
        citation_col.append(citation)
    # Define table for results and queries
    so_results_table = conn.CASTable(name=so_results_tbl, caslib=so_results_caslib, replace=True)
    so_queries_table = conn.CASTable(name=so_queries_tbl, caslib=so_queries_caslib, replace=True)
    # Create a Results dict
    so_res = evaluator.results()
    res_dict = {"Citation":[citation], "Privacy_Risk": [risk.value], "Privacy_Risk_Conf_Interval_Lower": [risk.ci[0]],"Privacy_Risk_Conf_Interval_Upper": [risk.ci[1]],"Attack_Rate":[so_res.attack_rate.value],"Attack_Rate_Error":[so_res.attack_rate.error], "Baseline_Rate":[so_res.baseline_rate.value],"Baseline_Rate_Error":[so_res.baseline_rate.error], "Control_Rate":[so_res.control_rate.value],"Control_Rate_Error":[so_res.control_rate.error], "N_Attacks":[so_res.n_attacks],"N_Success":[so_res.n_success], "N_Baseline": [so_res.n_baseline],"N_Control":[so_res.n_control] }
    # Load Results to a CAS table
    so_results_table.from_dict(data=res_dict, connection=conn, casout=so_results_table)
    SAS.logMessage("Results table loaded to CAS.")
    # Load Queries to a CAS table
    so_queries_table.from_dict(data={"Query":evaluator.queries(), "Citation": citation_col}, connection=conn, casout=so_queries_table)
    SAS.logMessage("Queries table loaded to CAS.")


;;;;
   

run;
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
    %global casSessionExists;
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
   Macro to calculate singling out risk

   Input: invoked with current state of macro variables                     
   Output (implicit):
          1. Singling Out Risk Results table
          2. Singling Out Risk Queries table

  As the calculation of Singling Out Risk is based on an open-source Python package (anonymeter),
  we note the following citation: 

  "A Unified Framework for Quantifying Privacy Risk in Synthetic Data", M. Giomi et al, PoPETS 2023. 
  
   This bibtex entry can be used to refer to the paper:

  @misc{anonymeter,
    doi = {https://doi.org/10.56553/popets-2023-0055},
    url = {https://petsymposium.org/popets/2023/popets-2023-0055.php},
    journal = {Proceedings of Privacy Enhancing Technologies Symposium},
    year = {2023},
    author = {Giomi, Matteo and Boenisch, Franziska and Wehmeyer, Christoph and Tasnádi, Borbála},
    title = {A Unified Framework for Quantifying Privacy Risk in Synthetic Data},
  }


*------------------------------------------------------------------------------------------*/ 

%macro _smt_singling_out_risk;

   %put NOTE: Singling out risk macro;
/*-----------------------------------------------------------------------------------------*
   Check Results table libref to ensure it points to a valid caslib.
*------------------------------------------------------------------------------------------*/
   %if &_smt_error_flag. = 0 %then %do;
      %global so_results_caslib;
      %_usr_getNameCaslib(&so_results_tbl_lib.);
      %let so_results_caslib=&_usr_nameCaslib.;
      %put NOTE: &so_results_caslib. is the caslib for the Singling Out Risk results table.;
      %let _usr_nameCaslib=;
      %if "&so_results_caslib." = "" %then %do;
         data _null_;
            call symputx("_smt_error_flag",1);
            call symput("_smt_error_desc","ERROR: Singling Out Results table caslib is blank. Check if table is a valid CAS table.");
         run;
         %put ERROR: Singling Out Results table caslib is blank. Check if table is a valid CAS table. ;
      %end;
   %end;
/*-----------------------------------------------------------------------------------------*
   Check Queries table libref to ensure it points to a valid caslib.
*------------------------------------------------------------------------------------------*/
   %if &_smt_error_flag. = 0 %then %do;
      %global so_queries_caslib;
      %_usr_getNameCaslib(&so_queries_tbl_lib.);
      %let so_queries_caslib=&_usr_nameCaslib.;
      %put NOTE: &so_queries_caslib. is the caslib for the Singling Out Risk queries table.;
      %let _usr_nameCaslib=;
      %if "&so_queries_caslib." = "" %then %do;
         data _null_;
            call symputx("_smt_error_flag",1);
            call symput("_smt_error_desc","ERROR: Singling Out Queries table caslib is blank. Check if table is a valid CAS table.");
         run;
         %put ERROR: Singling Out Queries table caslib is blank. Check if table is a valid CAS table. ;
      %end;
   %end;
   %if &_smt_error_flag. = 0 %then %do;
      proc python infile=smtcode;
      quit;
   %end;


%mend _smt_singling_out_risk;

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
   Account for edge cases where singling out risk has been requested even without a sample. 
*------------------------------------------------------------------------------------------*/
   data _null_;
      call symputx("singling_out_risk",min(1, &singling_out_risk. * &sampling_percent.));
   run;

   %if &singling_out_risk.=0 %then %do;
      %put NOTE: Privacy risk assessment will not be carried out because a sample has not been specified.;
   %end;

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
   Check Assessment table libref to ensure it points to a valid caslib.
*------------------------------------------------------------------------------------------*/

   %if &_smt_error_flag. = 0 %then %do;

      %global assessmentCaslib;
      %_usr_getNameCaslib(&outputTable_lib.);
      %let assessmentCaslib=&_usr_nameCaslib.;
      %put NOTE: &assessmentCaslib. is the caslib for the assessment table.;
      %let _usr_nameCaslib=;

      %if "&assessmentCaslib." = "" %then %do;
         data _null_;
            call symputx("_smt_error_flag",1);
            call symput("_smt_error_desc","ERROR: Assessment table caslib is blank. Check if table is a valid CAS table.");
         run;
         %put ERROR: Assessment table caslib is blank. Check if table is a valid CAS table. ;
      %end;

   %end;


/*-----------------------------------------------------------------------------------------*
   Obtain list of input & nominal variables and store them in macro variables.
*------------------------------------------------------------------------------------------*/

   %if &_smt_error_flag. = 0 %then %do;
      %let blankSeparatedInputVars = %_flw_get_column_list(_flw_prefix=inputVars);
      %let blankSeparatedNominalVars = %_flw_get_column_list(_flw_prefix=nominalVars);
      %put NOTE: Input variables selected - &blankSeparatedInputVars.;
      %put NOTE: Nominal variables selected - &blankSeparatedNominalVars.;
   %end;

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
         %else %do;
/*-----------------------------------------------------------------------------------------*
   Check Assessment table libref to ensure it points to a valid caslib.
*------------------------------------------------------------------------------------------*/
            %if &_smt_error_flag. = 0 %then %do;
               %global assessmentCaslib;
               %_usr_getNameCaslib(&outputTable_lib.);
               %let assessmentCaslib=&_usr_nameCaslib.;
               %put NOTE: &assessmentCaslib. is the caslib for the assessment table.;
               %let _usr_nameCaslib=;
               %if "&assessmentCaslib." = "" %then %do;
                  data _null_;
                     call symputx("_smt_error_flag",1);
                     call symput("_smt_error_desc","ERROR: Assessment table caslib is blank. Check if table is a valid CAS table.");
                  run;
                  %put ERROR: Assessment table caslib is blank. Check if table is a valid CAS table. ;
               %end;
            %end;
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
         proc datasets lib=&outputTable_lib. nolist nodetails;
            delete __assess_orig __assess_synth  ;
         quit;
/*-----------------------------------------------------------------------------------------*
   Check and address singling out risk
*------------------------------------------------------------------------------------------*/
         %if &singling_out_risk.=1 %then %do;

            %_smt_singling_out_risk;

         %end;

      %end;
      proc datasets lib=&outputTable_lib. nolist nodetails;
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

%if %symexist(assessmentCaslib) %then %do;
   %symdel assessmentCaslib;
%end;

%if %symexist(so_results_caslib) %then %do;
   %symdel so_results_caslib;
%end;

%if %symexist(so_queries_caslib) %then %do;
   %symdel so_queries_caslib;
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

%if %symexist(casSessionExists) %then %do;
   %symdel casSessionExists;
%end;

%sysmacdelete _create_error_flag;
%sysmacdelete _create_runtime_trigger;
%sysmacdelete _env_cas_checkSession;
%sysmacdelete _usr_getNameCaslib;
%sysmacdelete _sas_or_cas;
%sysmacdelete _cas_table_exists;
%sysmacdelete _smt_execution_code;
%sysmacdelete _smt_singling_out_risk;

filename smtcode clear;

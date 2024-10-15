/* SAS templated code goes here */

/*-----------------------------------------------------------------------------------------*
   START MACRO DEFINITIONS.
*------------------------------------------------------------------------------------------*/

/* -----------------------------------------------------------------------------------------* 
   Create a global macro variable for the trigger to run this custom step. A value of 1 
   (the default) enables this custom step to run.  A value of 0 (provided by upstream code)
   sets this to disabled.
*------------------------------------------------------------------------------------------ */

%global _erc_run_trigger;

%if %sysevalf(%superq(_erc_run_trigger)=, boolean)  %then %do;
	%put NOTE: Trigger macro variable _erc_run_trigger does not exist. Creating it now.;
    %let _erc_run_trigger=1;
%end;

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


/*-----------------------------------------------------------------------------------------*
   Macro to check if an input table has been provided.  If not, the program aborts.
*------------------------------------------------------------------------------------------*/

%macro _erc_check_input_table(listOfRuleConfigs);

   %put &listOfRuleConfigs.;
   %if %sysevalf(%superq(listOfRuleConfigs)=, boolean)  %then %do;
      %put ERROR: Connect an input table to the input port.;
      %abort exit 4321;
   %end;

%mend _erc_check_input_table;

/*-----------------------------------------------------------------------------------------*
   Macro to extract a rule configuration as per specified parameters.
*------------------------------------------------------------------------------------------*/

%macro _erc_extract_rule_config(ruleConfigName, projectType, astoreName, projectCaslib);

   %local projectCaslib;
   %local projectType;
   %local ruleConfigName;
   %local astoreName;

   %put NOTE: Entered extract macro;
   %put "rule config name is: &ruleConfigName.";

   proc cas;

/*-----------------------------------------------------------------------------------------*
   Source code blocks
*------------------------------------------------------------------------------------------*/
      source CategoryCode;
         data &outputCaslib..tempRuleConfig (drop=re) ;
            length Astore_Name $100. Project_Caslib $100. Ruleconfig_Name $100. Type $20. category_name varchar(*) rule_string varchar(*);
         set &outputCaslib..tempRuleConfig;
            Astore_Name="&astoreName.";
            Project_Caslib="&projectCaslib.";
            Type="&projectType.";
            Ruleconfig_Name="&ruleConfigName.";
            re=PRXPARSE('/(\(.*\))/');
            category_name=scan(config, 2, ":");
            if prxmatch(re, config) then do;
               rule_string=prxposn(re, 1, config);
            end;
            config=compbl(config);
         run;
      endsource;

      source ConceptCode;
         data &outputCaslib..tempRuleConfig (drop=i) ;
            length Astore_Name $100. Project_Caslib $100. Ruleconfig_Name $100. Type $20. configline entity_attribute rule_string concept_name varchar(*);
         set &outputCaslib..tempRuleConfig;
            Astore_Name="&astoreName.";
            Project_Caslib="&projectCaslib.";
            Type="&projectType.";
            Ruleconfig_Name="&ruleConfigName.";
            do i = 1 to sum(count(config, "0A"x), 1);
               entity_attribute="";
               rule_string="";
               concept_name="";
               configline=scan(config, i, "0A"x, "MO");
               concept_name=scan(configline, 2, ":", "MO");
               entity_attribute=scan(configline, 1, ":", "MO");
               if compress(entity_attribute) in ("PRIORITY", "FULLPATH", "PREDEFINED") then do;
                  rule_string=transtrn(configline, compress(entity_attribute||":"||concept_name||":"), "");
               end;
               else if compress(entity_attribute) in ("ENABLE", "CASE_INSENSITIVE_MATCH") then do;
                  rule_string=transtrn(configline, compress(entity_attribute||":"||concept_name), "");
               end;
               else do;
                  entity_attribute="RULE";
                  rule_string=transtrn(configline, compress(concept_name||":"), "");
               end;
               output;
            end;
         run;
      endsource;

/*-----------------------------------------------------------------------------------------*
   Obtain values from the UI
*------------------------------------------------------------------------------------------*/

      targetCaslib=symget("outputCaslibRef");
      nameTable="&ruleConfigName.";
      projectCaslib="&projectCaslib.";
      projectType="&projectType.";

      table.copyTable /
 	    table={name=nameTable, caslib=projectCaslib}
        casout={name="tempRuleConfig", caslib=targetCaslib, replace=True}
      ;
      
      if projectType=="CATEGORY" then do;
         dataStep.runCode / 
            code=CategoryCode;  
      end;
      else if projectType=="CONCEPT" then do;
         dataStep.runCode / 
            code=ConceptCode;  
      end;

     table.save /
         table={name="tempRuleConfig", caslib=targetCaslib},
         name=nameTable,
         caslib=targetCaslib,
         replace=True
      ;
   quit;

%mend _erc_extract_rule_config;


/*-----------------------------------------------------------------------------------------*
   Macro to loop over rule configuration table and operate on each observation.
*------------------------------------------------------------------------------------------*/
%macro _erc_loop_over_observations(listOfRuleConfigs);

   %local ruleConfigName;
   %local projectType;
   %local astoreName;
   %local projectCaslib;

   proc sql noprint;
      select count(*) into:nbr_configs from &listOfRuleConfigs.;
   quit;
   
   %do n=1 %to &nbr_configs.;

      data _null_;
      set &listOfRuleConfigs.;
         if _n_=&n. then do;
            call symput("ruleConfigName", Name);
            call symput("projectType", Type);
	        call symput("astoreName", AstoreName);
            call symput("projectCaslib", Project_Caslib);
         end;
      run;

      %_erc_extract_rule_config(&ruleConfigName., &projectType., &astoreName., &projectCaslib.);

   %end;
 
%mend _erc_loop_over_observations;

/*-----------------------------------------------------------------------------------------*
   Macro to check if table assigned to output port is a valid SAS BASE / V9 engines.
*------------------------------------------------------------------------------------------*/

%macro _erc_check_output_table(ruleConfigEngine);

   %if "&ruleConfigEngine."="BASE" OR "&ruleConfigEngine."="V9" %then %do; %end;
   %else %do;
      %put ERROR: The output port should refer to only a SAS9 (Compute) dataset and not a CAS table.;
      %abort exit 4322;
   %end;

%mend _erc_check_output_table;



/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE MACRO 
   Driven by user choice from UI. 
*------------------------------------------------------------------------------------------*/
%macro main_execution_code;


/*-----------------------------------------------------------------------------------------*
   Scenario 1 : 
   User chooses to only generate a list of rule configurations.
*------------------------------------------------------------------------------------------*/

   %if "&taskSelect."="Generate a list of rule configurations" %then %do;

      %_erc_check_output_table(&generatedRuleConfigs_engine.);

/*-----------------------------------------------------------------------------------------*
   On the off-chance that the user originally added an input port by mistake, assign dummy.
*------------------------------------------------------------------------------------------*/
   
      %let listOfRuleConfigs="WORK._RULECONFIGLISTDUMMY_";

      %put NOTE: User chose to generate list of rule configurations.;

      proc cas;

/*-----------------------------------------------------------------------------------------*
   Obtain values from the UI
*------------------------------------------------------------------------------------------*/
   
         projectCaslibFullName=symget("projectCaslibFullName");
         generatedRuleConfigs=symget("generatedRuleConfigs");

/*-----------------------------------------------------------------------------------------*
   Extract the project caslib from the name provided by the user.
*------------------------------------------------------------------------------------------*/

         projectCaslib = scan(projectCaslibFullName,2,"/");
   
/*-----------------------------------------------------------------------------------------*
   List all tables within the project caslib which are rule configurations.
*------------------------------------------------------------------------------------------*/

         table.tableInfo /
            caslib=projectCaslib
         ;
         table.tableInfo result=tableList /
            caslib=projectCaslib
         ;
         ruleConfigList = tableList.TableInfo.where(Name contains "_RULESCONFIG");

/*-----------------------------------------------------------------------------------------*
   Placeholder for future - allow user to choose to list only concepts or category configs. 
*------------------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------------*
   Create additional variables to hold the type (whether category or concept) and the astore
   name (which will prove useful in linking to downstream projects later). Also create a 
   variable to hold the analytics project caslib to avoid the user having to retype the same.
*------------------------------------------------------------------------------------------*/

         ruleConfigList=ruleConfigList.compute("Type", scan(Name, -2, "_"));
         ruleConfigList=ruleConfigList.compute("AstoreName", scan(Name, 1, "_"));
         ruleConfigList=ruleConfigList.compute("Project_Caslib", projectCaslib);

/*-----------------------------------------------------------------------------------------*
   Print to screen for the benefit of the user. 
*------------------------------------------------------------------------------------------*/

         print ruleConfigList;

         saveresult ruleConfigList dataout=&generatedRuleConfigs.;

      quit;

/*-----------------------------------------------------------------------------------------*
   Generating a list is usually followed by a need to extract them, therefore
*------------------------------------------------------------------------------------------*/
      %let listOfRuleConfigs=&generatedRuleConfigs.;

   %end;



/*-----------------------------------------------------------------------------------------*
   Scenario 2: 
   User chooses to specify a single rule configuration table.
*------------------------------------------------------------------------------------------*/

   %if "&taskSelect."="Extract a single rule configuration table" %then %do;

/*-----------------------------------------------------------------------------------------*
   On the off-chance that the user originally added an input port by mistake, assign dummy.
*------------------------------------------------------------------------------------------*/
   
      %let listOfRuleConfigs="WORK._RULECONFIGLISTDUMMY_";
      %put NOTE: User chose to extract a single rule configuration table.;

/*-----------------------------------------------------------------------------------------*
   Run the libref check macro in order to obtain the correct Caslib for the output table.
*------------------------------------------------------------------------------------------*/
   
      %_usr_getNameCaslib(&outputCaslibRef);
      %let outputCaslib=&_usr_nameCaslib.;
      %let _usr_nameCaslib=;
   
      %let projectType=%sysfunc(scan(&ruleConfigName., 2, "_"));
      %let astoreName=%sysfunc(scan("&ruleConfigName.", 1, "_"));
      %let projectCaslib=%sysfunc(scan("&&projectCaslibFullName.", 2, "/"));;
    
      %_erc_extract_rule_config(&ruleConfigName., &projectType., &astoreName., &projectCaslib.);

/*-----------------------------------------------------------------------------------------*
   Set global var listOfRuleConfigs to blank so that reruns are clean.
*------------------------------------------------------------------------------------------*/

      %let listOfRuleConfigs=;

/*-----------------------------------------------------------------------------------------*
   Clean up any macro variables
*------------------------------------------------------------------------------------------*/
   
      %symdel ruleConfigName;

   %end;


/*-----------------------------------------------------------------------------------------*
   Scenario 3:
   User chooses to attach an input table and extract all configurations within.
*------------------------------------------------------------------------------------------*/

   %if "&taskSelect."="Extract all rule configurations as per an input list" %then %do;

      %put NOTE: Attempting extraction.;

/*-----------------------------------------------------------------------------------------*
   First, check if there is a table provided. We call a macro for the same.
   Note : For those interested, a little dated but insightful SAS Global Forum paper on 
   the best way to evaluate if a macro variable is blank (as used below), provided here:
   http://support.sas.com/resources/papers/proceedings09/022-2009.pdf
*------------------------------------------------------------------------------------------*/
      %_erc_check_input_table(&listOfRuleConfigs.);


/*-----------------------------------------------------------------------------------------*
   Run the libref check macro in order to obtain the correct Caslib for the output table.
*------------------------------------------------------------------------------------------*/
   
      %_usr_getNameCaslib(&outputCaslibRef);
      %let outputCaslib=&_usr_nameCaslib.;
      %let _usr_nameCaslib=;


/*-----------------------------------------------------------------------------------------*
   Count the number of observations and create a loop over each observation.
*------------------------------------------------------------------------------------------*/
      %_erc_loop_over_observations(&listOfRuleConfigs.);

/*-----------------------------------------------------------------------------------------*
   Clean up any macro variables
*------------------------------------------------------------------------------------------*/

      %symdel ruleConfigName;

   %end;


/*-----------------------------------------------------------------------------------------*
   Clean up all macro definitions
*------------------------------------------------------------------------------------------*/

   %sysmacdelete _usr_getNameCaslib ;
   %sysmacdelete _erc_check_input_table ;
   %sysmacdelete _erc_extract_rule_config ;
   %sysmacdelete _erc_loop_over_observations;
   %sysmacdelete _erc_check_output_table;



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



%if &_erc_run_trigger. = 1 %then %do;
   %main_execution_code;
%end;
%if &_erc_run_trigger. = 0 %then %do;
   %put NOTE: This step has been disabled.  Nothing to do.;
%end;

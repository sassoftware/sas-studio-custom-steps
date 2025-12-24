/* SAS templated code goes here */

/* -------------------------------------------------------------------------------------------*
   Nominal Dimensionality Reduction - Version 1.0.2

   This program uses the SAS procedure NOMINALDR to perform dimensionality reduction on
   nominal variables in a dataset. It supports two methods: Multiple Correspondence Analysis (MCA)
   and Logistic Principal Component Analysis (LPCA). The program also allows for the inclusion of
   additional variables and saving the results in a specified output table or rstore.

   Author: Sundaresh Sankaran (original)
   Refactor: Polished after AI-assisted automation
   Version: 1.0.2 (24DEC2025)
*-------------------------------------------------------------------------------------------- */

%put NOTE: Starting Nominal Dimensionality Reduction program...;

/* -------------------------------------------------------------------------------------------*
    User Parameters
    
    The parameters below allow customization of the aggregation operation,
    including the input file path, aggregation functions, columns to aggregate,
    grouping columns, and output table.
    
    Users can modify these parameters to suit their specific data and analysis needs.
* -------------------------------------------------------------------------------------------- */

/* input_table takes in the name of the input data set from an input port */
/* %let input_table=SASHELP.CARS; */

/* nominal_vars takes in the list of nominal variables to be reduced through a column selector */
/* %let nominal_vars=Make Model Type Origin DriveTrain; */

/* other_vars takes in the list of other variables to copy to output through a column selector */
/* %let other_vars=MSRP Invoice EngineSize Cylinders Horsepower MPG_City MPG_Highway Weight Wheelbase Length; */

/* num_dimensions takes in the number of dimensions specified for the analysis */
/* %let num_dimensions=8; */

/* method takes in the method to be used for the analysis, either MCA or LPCA*/
/* %let method=MCA; */

/* prefix takes in the prefix for the output variables */
/* %let prefix=mca_rv_; */

/* output_table takes in the name of the output data set with reduced dimensions */
/* %let output_table=WORK.NEWCARS; */

/* rstore_name takes in the name of the RStore file to save the model binary.  */
/* %let rstore_name=MCASTORE; */

/* -----------------------------------------------------------------------------------------*
   Macros

   The macros below follow the structural conventions used in SAS programs for custom step:

   - small utility macros for runtime triggers and error flags
   - a focused macro for execution of the main step
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
*-------------------------------------------------------------------------------------------- */;

%macro _create_runtime_trigger(triggerName);
  %global &triggerName.;
  %if %sysevalf(%superq(&triggerName.)=, boolean) %then %do;
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
  %let &errorFlagName.=0;
  %global &errorFlagDesc.;
%mend _create_error_flag;

/* -----------------------------------------------------------------------------------------* 
   Macro to safely delete a macro symbol if it exists.

   Input:
      1. sym: The name of the macro symbol to delete.
*------------------------------------------------------------------------------------------ */
%macro _safe_symdel(sym);
  %if %symexist(&sym) %then %do; %symdel &sym; %end;
%mend _safe_symdel;

/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE MACRO 

   _ndr prefix stands for Nominal Dimensionality Reduction. This macro contains the main 
   logic for the Nominal Dimensionality Reduction step. It includes validation, default 
   settings, and the execution of the main step.
*------------------------------------------------------------------------------------------*/
%macro _ndr_execution_code;

/* Initialize runtime trigger and error flags */
    %_create_error_flag(_ndr_error_flag, _ndr_error_desc);

   %if &_ndr_error_flag. = 0 %then %do;
        %if "%sysfunc(symexist(rstore_name))"="0" %then %do; 
            %let rstore_name_name_base=_TEMP_RSTORE; 
            %put NOTE: rstore_name not provided, defaulting to _TEMP_RSTORE.; 
        %end;
   %end;

   %if &_ndr_error_flag. = 0 %then %do;
        %if %sysevalf(%superq(input_table)=, boolean) %then %do; 
            %let _ndr_error_flag=1; 
            %let _ndr_error_desc=Input table is required.; 
            %put ERROR: &_ndr_error_desc.; 
        %end;
   %end;
   %if &_ndr_error_flag. = 0 %then %do;
        %if %sysevalf(%superq(nominal_vars)=, boolean) %then %do; 
            %let _ndr_error_flag=1; 
            %let _ndr_error_desc=At least one nominal variable is required.; 
            %put ERROR: &_ndr_error_desc.; 
        %end;
   %end;
   %if &_ndr_error_flag. = 0 %then %do;
        %if %sysevalf(%superq(num_dimensions)=, boolean) %then %do; 
            %let num_dimensions=8; 
            %put NOTE: num_dimensions not provided, defaulting to 8.; 
        %end;
   %end;
   %if &_ndr_error_flag. = 0 %then %do;
        proc NOMINALDR data=&input_table. dimension=&num_dimensions. method=%upcase(&method.) prefix=&prefix.;
            input &nominal_vars. / level=nominal;
            %if %sysevalf(%superq(other_vars)=, boolean) %then %do;output out=&output_table.; %end; %else %do; output out=&output_table. copyVars=(&other_vars.); %end;
            savestate RSTORE=&rstore_name_name_base.; 
        run;
   %end;
   %if &_ndr_error_flag. = 0 %then %do;
        %if "%sysfunc(symexist(rstore_name))"="0" %then %do;
            %put NOTE: rstore_name not provided, no RStore file will be saved.; 
            proc datasets lib = _SASUSR_ nolist;
                delete &rstore_name_name_base.;
            run;
            proc datasets lib = WORK nolist;
                delete &rstore_name_name_base.;
            run;
        %end;
        %else %if "&rstore_name."="" %then %do; 
            %put NOTE: rstore_name not provided, no RStore file will be saved.; 
            proc datasets lib = _SASUSR_ nolist;
                delete &rstore_name_name_base.;
            run;
            proc datasets lib = WORK nolist;
                delete &rstore_name_name_base.;
            run;
         %end;
        %else %do;
            data &rstore_name.;
               set _SASUSR_.&rstore_name_name_base.;
            run;
         %end;
   %end;

%mend _ndr_execution_code;

/*-----------------------------------------------------------------------------------------*
   END MACROS
*------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE
*------------------------------------------------------------------------------------------*/
   
/*-----------------------------------------------------------------------------------------*
   Create Runtime Trigger
*------------------------------------------------------------------------------------------*/

%_create_runtime_trigger(_ndr_run_trigger);
%put NOTE: Run trigger is &_ndr_run_trigger.;

/*-----------------------------------------------------------------------------------------*
   Execute 
*------------------------------------------------------------------------------------------*/
/* Basic validation and defaults */
%if &_ndr_run_trigger. = 1 %then %do;
    %_ndr_execution_code;
%end;
%else %do;
  %put NOTE: This step has been disabled by runtime trigger.;
%end;

%put NOTE: Final summary;
%put NOTE: Status of error flag - &_ndr_error_flag. ;
%put &_ndr_error_desc.;
%put NOTE: Error desc - &_ndr_error_desc. ;

/*-----------------------------------------------------------------------------------------*
   END EXECUTION CODE
*------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------*
   Clean up existing macro variables and macro definitions.
*------------------------------------------------------------------------------------------*/



%put NOTE: Nominal Dimensionality Reduction program completed.;

%_safe_symdel(_ndr_run_trigger);

%sysmacdelete _create_runtime_trigger;
%sysmacdelete _create_error_flag;

%_safe_symdel(_ndr_error_flag);
%_safe_symdel(_ndr_error_desc);
%sysmacdelete _safe_symdel;
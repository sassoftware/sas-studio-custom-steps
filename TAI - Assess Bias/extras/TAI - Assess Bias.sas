/* -------------------------------------------------------------------------------------------*
   TAI - Assess Bias

   v 1.0.15 (26JUN2026)

   This program helps users to check if the model treats different groups fairly by comparing predictions across demographics. 
   Helps identify potential bias in the results.

   Tested in SAS Viya 2026.05

   Dawn Pancholi (Shubham.pancholi@sas.com)
   
*-------------------------------------------------------------------------------------------- */


/* Setting up variables for inputTable's library and table name */
%let inputTable_lib = &inputTable_lib.;
%let inputTable_name = &inputTable_name.;

/* Probability Variable Column Selector */
%let probabilityVariable = &probabilityVariable.;

/* Target Variable Column Selector and Target Level Dropdown*/
/* Target Level Dropdown has the options of only "Interval" or "Nominal"*/
%let targetVariable = &targetVariable.;
%let targetLevel = &targetLevel.;
%let targetEvent = &targetEvent.;

/* Sensistive Variable Column Selector */
%let sensitiveVariable = &sensitiveVariable.;

/* Setting up variables in Options section */
%let cutoff = &cutoff.;
%let numBins = &numBins.;
%let numCuts = &numCuts.;
%let selectionDepth = &selectionDepth.;
%let weight = &weight.;
%let freq = &freq.;

/* Setting up fitStat Variables */
%let pVars = &pVars.;
%let pEvent = &pEvent.;
%let FitStatDelimiter = &FitStatDelimiter.;


/*************************************************************
 MACRO DEFINITIONS
*************************************************************/;

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


/* Macro to ensure that there's a proper input for all the required fields */
%macro _ab_validate_inputs;

    /* Check Input Table library */
    %if %sysevalf(%superq(inputTable_lib)=, boolean) %then %do;
        %let _ab_error_flag = 1;
        %let _ab_error_desc = Input Table has not been specified;
        %put ERROR: &_ab_error_desc. ;
    %end;

    /* Check Input Table name */
    %if %sysevalf(%superq(inputTable_name)=, boolean) %then %do;
        %let _ab_error_flag = 1;
        %let _ab_error_desc = Input Table has not been specified;
        %put ERROR: &_ab_error_desc. ;
    %end;

    /* Check Predicted Probability Variable */
    %if %sysevalf(%superq(probabilityVariable)=, boolean) %then %do;
        %let _ab_error_flag = 1;
        %let _ab_error_desc = Predicted Probability Variable has not been specified.;
        %put ERROR: &_ab_error_desc. ;
    %end;

    /* Check Target Variable */
    %if %sysevalf(%superq(targetVariable)=, boolean) %then %do;
        %let _ab_error_flag = 1;
        %let _ab_error_desc = Target Variable has not been specified.;
        %put ERROR: &_ab_error_desc. ;
    %end;

    /* Check Sensitive Variable */
    %if %sysevalf(%superq(sensitiveVariable)=, boolean) %then %do;
        %let _ab_error_flag = 1;
        %let _ab_error_desc = Sensitive Variable has not been specified;
        %put ERROR: &_ab_error_desc. ;
    %end;
%mend _ab_validate_inputs;

/* Macro to determine which delimiter the dropdown in FitStatDelimiter is referring to */
%macro setDelimiter;

    %if %superq(FitStatDelimiter) = %str(%;) %then %do;
        %let fsDelimiterClean = %str(%;);
    %end;
    %else %if %superq(FitStatDelimiter) = %str(*) %then %do;
        %let fsDelimiterClean = %str(*);
    %end;
    %else %if %superq(FitStatDelimiter) = %str(.) %then %do;
        %let fsDelimiterClean = %str(.);
    %end;
    %else %if %superq(FitStatDelimiter) = %str(,) %then %do;
        %let fsDelimiterClean = %str(,);
    %end;
    %else %do;
        %let fsDelimiterClean = %str( );
    %end;
%mend setDelimiter;

/* 
    Macro to determine which fitstat step to do if there's a pEvent and a Delimiter
    If there is, then use the pEvent and Delimiter add-ons
    If not, use the base fitstat
*/
%macro conditionalFitstat;
    %if %superq( pVars ) ne and %superq( pEvent ) ne %then %do;
        fitstat pVar=&pVars / pEvent= "&pEvent" Delimiter = "&fsDelimiterClean";
    %end;
    %else %if %superq( pVars ) ne %then %do;
        fitstat pVar=&pVars;
    %end;
%mend conditionalFitstat;


/*
    Macro to determine direction of execution on the code.
    If there's a major component missing (specified in the if statements below _create_error_flag) then the if block will execute
    Otherwise, the else block containing the proc assessbias will execute
*/
%macro _ab_guard;
    
    %local fsDelimiterClean;
    %let fsDelimiterClean=;

    %if &_ab_error_flag. = 1 %then %do;
        %put NOTE: PROC ASSESSBIAS will not run because one or more required variables are missing.;
    %end;
    %else %do;
        proc assessbias data=&inputTable_lib..&inputTable_name 
            cutoff=&cutoff 
            nBins=&numBins 
            nCuts=&numCuts 
            selectionDepth=&selectionDepth;
            
            /* Input/Probability Variable*/
                var &probabilityVariable;
            
            /* Target Code */
                %if %upcase(&targetLevel)=NOMINAL and %superq(targetEvent) ne %then %do;
                    target &targetVariable / event="&targetEvent" level=&targetLevel;
                %end;
                %else %do;
                    target &targetVariable;
                %end;    
            
            /*Sensitive Variable */
                sensitivevar &sensitiveVariable;
            
            /* Weight (Optional) */
                %if %superq( weight ) ne %then %do;
                    weight &weight;
                %end;

            /* Frequency */
                %if %superq( freq ) ne %then %do;
                    freq &freq;
                %end;

            /* Calling the setDelimiter macro to set up the delimiter */
                %setDelimiter;

            /* Calling the conditionalFitstat macro to determine which fitStat to run */
                %conditionalFitstat;
        
            run;
    %end;
%mend _ab_guard;

/*************************************************************
 EXECUTION CODE
*************************************************************/;

TITLE1 "AssessBias";

/* Calling the macro to create an error flager */
%_create_error_flag(_ab_error_flag, _ab_error_desc);

/* Validate that all required inputs were provided */
%_ab_validate_inputs;

/* Macro to determine direction of execution on the code. */
%_ab_guard;

/*************************************************************
 CLEANUP
*************************************************************/;

*Clean up global macros created during execution;
%if %symexist(_ab_error_flag) %then %do;
   %symdel _ab_error_flag;
%end;

%if %symexist(_ab_error_desc) %then %do;
   %symdel _ab_error_desc;
%end;

/* Remove helper macros from global symbol table */
%sysmacdelete _create_error_flag;
%sysmacdelete _ab_validate_inputs;
%sysmacdelete setDelimiter;
%sysmacdelete conditionalFitstat;
%sysmacdelete _ab_guard;

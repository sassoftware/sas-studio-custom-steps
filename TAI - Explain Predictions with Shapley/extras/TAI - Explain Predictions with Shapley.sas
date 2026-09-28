/************************************************************************
Trustworthy AI (TAI) - Explain Predictions with Shapley

Purpose: This SAS program executes PROC SHAPLEY to compute Shapley values 
for explaining machine learning model predictions. It supports both 
HyperSHAP and KernelSHAP methods with method-specific parameter controls.

Input Parameters:
- refData: Reference data table containing background observations (macro variable)
- intervalVars: List of interval input variables (macro variable)
- nominalVars: List of nominal input variables (macro variable)
- targetVar: Predicted target variable containing model predictions (macro variable)
- weightVar: Optional weight variable (macro variable)
- astoreTable: Optional Analytic Store (ASTORE) table (macro variable)
- methodType: Explainer method, HYPERSHAP or KERNELSHAP (macro variable)

Method - HyperSHAP Options:
- hyperDepth: Maximum depth of coalitional approximation (Default: 1)

Method - KernelSHAP Options:
- kernelBinWidth: Bin width for interval variables (Default: 0.1)
- kernelIncMissing: Flag to include missing values (1=Yes, 0=No)
- kernelSampleSize: Number of coalition samples to generate (Default: 500)
- kernelSeed: Random seed value for KernelSHAP method (macro variable)
- kernelUseRaw: Flag to specify whether to use raw data (1=Yes, 0=No)


Tested in SAS Viya 2026.08
Version: 1.0.4 (06SEP2026)
************************************************************************/;


/************************************************************************
MACRO DEFINITION
************************************************************************/;


/* -----------------------------------------------------------------------------------------* 
   Macro to set up the error flagging and determine how Proc Shapley should run assuming all required fields
   Have been filled out
   If there's a major component missing (specified in the if statement) then the if block will execute and throw an error
   Otherwise, the else block containing the proc shapley will execute
*------------------------------------------------------------------------------------------ */
%macro _shapley;
    %local _eps_Query_Data;

    /* Ensure required parameters are provided before executing */
    %if %sysevalf(%superq(refData)=, boolean) or 
        %sysevalf(%superq(targetVar)=, boolean) or
        (
            %sysevalf(%superq(intervalVars)=, boolean) and
            %sysevalf(%superq(nominalVars)=, boolean)
        ) %then %do;
        %put ERROR: Missing required parameters. Please check the input variable and target variable selection.;
    %end;
    %else %do;
        
        /* If astoreTable has no value in the UI then make sure it's set equal to nothing so that it doesn't throw a warning */
        %if not %symexist(astoreTable) %then %let astoreTable=;
        
        /* Move the data to the same engine as the reference data */
        %if %upcase(&refData_engine.) = CAS %then %do;
            %let _eps_Query_Data = &refData_lib.._query;
        %end;
        %else %do;
            %let _eps_Query_Data = work._query;
        %end;

        %put &=_eps_Query_Data;

        /* Create the data for Proc Shapley that only needs one row of the reference data */
        data &_eps_Query_Data.;
            set &refData.(obs=1);
        run; 
        
        proc shapley data=&_eps_Query_Data. referenceData=&refData. impute=&impute.;
            
            /* Reference an Analytic Store (ASTORE) model if provided */
            %if %sysevalf(%superq(astoreTable)=, boolean) = 0 %then %do;
                astoreModel rstore=&astoreTable.;
            %end;

            /* Define Interval input variables if specified */
            %if %sysevalf(%superq(intervalVars)=, boolean) = 0 %then %do;
                input &intervalVars. / level=interval;
            %end;

            /* Define Nominal input variables if specified */
            %if %sysevalf(%superq(nominalVars)=, boolean) = 0 %then %do;
                input &nominalVars. / level=nominal;
            %end;

            /* Specify the Predicted Target Column */
            predictedtarget &targetVar.;

            /* Set observational weight if specified */
            %if %sysevalf(%superq(weightVar)=, boolean) = 0 %then %do;
                weight &weightVar.;
            %end;

            /* Construct dynamic METHOD statement based on selection */
            %if %upcase(&methodType.) = HYPERSHAP %then %do;
                method hyperSHAP (
                    %if %sysevalf(%superq(hyperDepth)=, boolean) = 0 %then depth=&hyperDepth. ;
                );
            %end;
            %else %if %upcase(&methodType.) = KERNELSHAP %then %do;
                method kernelSHAP (
                    %if %sysevalf(%superq(kernelBinWidth)=, boolean) = 0 %then binwidth=&kernelBinWidth. ;
                    %if &kernelIncMissing. = 1 %then includeMissing ;
                    %if %sysevalf(%superq(kernelSampleSize)=, boolean) = 0 %then sampleSize=&kernelSampleSize. ;
                    %if %sysevalf(%superq(kernelSeed)=, boolean) = 0 %then seed=&kernelSeed. ;
                    %if &kernelUseRaw. = 1 %then useRawData ;
                );
            %end;
        run;

        * Clean up;
        proc sql noPrint;
            drop table &_eps_Query_Data.;
        quit;
    %end;
%mend _shapley;

/************************************************************************
EXECUTION CODE
************************************************************************/;

title "Shapley";

%_shapley

title;

%sysmacdelete _shapley;
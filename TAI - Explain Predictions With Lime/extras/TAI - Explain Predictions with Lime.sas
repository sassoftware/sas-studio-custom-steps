/************************************************************************
Trustworthy AI (TAI) - Explain Predictions with LIME

Purpose:
This SAS program executes PROC LIME to explain machine learning model
predictions by fitting a local interpretable surrogate model around a query
observation. The step supports query data supplied by the user or created
automatically from the first observation of the reference data.

Input parameters:
- refData: Reference data table containing background observations
- queryData: Optional query input data table containing the query observation
- useFirstObsAsQuery: Flag to create query data from the first row of refData
- intervalVars: List of interval input variables
- nominalVars: List of nominal input variables
- targetVar: Predicted target variable containing model predictions
- weightVar: Optional weight variable
- freqVar: Optional frequency variable

PROC LIME options:
- includeMissing: Flag to treat missing nominal values as a valid level
- logLevel: Controls notes printed to the client log
- nThreads: Number of threads to use in computation
- sampleSize: Number of observations to generate
- seed: Random seed for pseudorandom number generation

ASTOREMODEL / CODE options:
- astoreTable1: Optional first ASTORE model table
- astoreTable2: Optional second ASTORE model table
- astoreTable3: Optional third ASTORE model table
- codeSourceType: Optional CODE source type, NONE, FILE, or TABLE
- codeFilePath: External file that contains DATA step or DS2 score code
- codeTable: Table that contains DATA step or DS2 score code

DISTANCE options:
- distanceExponentialKernel: Denominator for the exponential kernel
- distanceImpute: Missing value imputation method
- distanceMixedWeight: Weighting to balance interval and nominal inputs

EXPLAINER options:
- explainerMaxEffects: Maximum number of effects the LASSO regression can select
- explainerMinEffects: Minimum number of effects the LASSO regression can select
- explainerStandardize: Variables whose parameter estimates should be standardized

Output parameters:
- outputTable: Optional output table for PROC LIME ODS output

Tested in SAS Viya 2026.05
Version: 1.0.0 (31JUL2026)
************************************************************************/


/************************************************************************
MACRO DEFINITION
************************************************************************/

/*-----------------------------------------------------------------------------------------*
   Macro to validate required inputs, construct optional PROC LIME statements,
   and execute PROC LIME using the selected SAS Studio custom step options.

   Required components:
   - Reference data table
   - Query data table, unless the user chooses to create query data from the
     first observation of the reference data
   - Predicted target column
   - At least one interval or nominal input variable

   Conditional requirement:
   - If more than one ASTOREMODEL statement is generated, then a CODE statement
     must also be generated.
*------------------------------------------------------------------------------------------*/
%macro _lime;

    %local
        _astoreCount
        _limeQueryData
        _deleteQueryData
        _notesOption
    ;

    /************************************************************************
    INITIALIZE OPTIONAL MACRO VARIABLES
    ************************************************************************/

    %if not %symexist(queryData) %then %let queryData=;
    %if not %symexist(useFirstObsAsQuery) %then %let useFirstObsAsQuery=0;

    %if not %symexist(intervalVars) %then %let intervalVars=;
    %if not %symexist(nominalVars) %then %let nominalVars=;
    %if not %symexist(targetVar) %then %let targetVar=;

    %if not %symexist(weightVar) %then %let weightVar=;
    %if not %symexist(freqVar) %then %let freqVar=;

    %if not %symexist(astoreTable1) %then %let astoreTable1=;
    %if not %symexist(astoreTable2) %then %let astoreTable2=;
    %if not %symexist(astoreTable3) %then %let astoreTable3=;

    %if not %symexist(codeSourceType) %then %let codeSourceType=NONE;
    %if not %symexist(codeFilePath) %then %let codeFilePath=;
    %if not %symexist(codeTable) %then %let codeTable=;

    %if not %symexist(includeMissing) %then %let includeMissing=0;
    %if not %symexist(logLevel) %then %let logLevel=;
    %if not %symexist(nThreads) %then %let nThreads=;
    %if not %symexist(sampleSize) %then %let sampleSize=;
    %if not %symexist(seed) %then %let seed=;

    %if not %symexist(distanceExponentialKernel) %then %let distanceExponentialKernel=;
    %if not %symexist(distanceImpute) %then %let distanceImpute=NONE;
    %if not %symexist(distanceMixedWeight) %then %let distanceMixedWeight=;

    %if not %symexist(explainerMaxEffects) %then %let explainerMaxEffects=;
    %if not %symexist(explainerMinEffects) %then %let explainerMinEffects=;
    %if not %symexist(explainerStandardize) %then %let explainerStandardize=NONE;

    %if not %symexist(outputTable) %then %let outputTable=;

    %let _deleteQueryData=0;

    /************************************************************************
    SAVE CURRENT SAS OPTION SETTINGS
    ************************************************************************/

    %let _notesOption=%sysfunc(getoption(notes));

    /************************************************************************
    DERIVE ASTORE COUNT
    ************************************************************************/

    %let _astoreCount=0;

    %if not %sysevalf(%superq(astoreTable1)=, boolean) %then
        %let _astoreCount=%eval(&_astoreCount. + 1);

    %if not %sysevalf(%superq(astoreTable2)=, boolean) %then
        %let _astoreCount=%eval(&_astoreCount. + 1);

    %if not %sysevalf(%superq(astoreTable3)=, boolean) %then
        %let _astoreCount=%eval(&_astoreCount. + 1);

    /************************************************************************
    REQUIRED PARAMETER VALIDATION
    ************************************************************************/

    %if %sysevalf(%superq(refData)=, boolean) or
        %sysevalf(%superq(targetVar)=, boolean) or
        (
            %sysevalf(%superq(intervalVars)=, boolean) and
            %sysevalf(%superq(nominalVars)=, boolean)
        )
    %then %do;

        %put ERROR: Missing required parameters.;
        %put ERROR: Select a reference data table, a predicted target column, and at least one input variable.;

    %end;
    %else %if
        (
            %upcase(%superq(useFirstObsAsQuery)) ne TRUE and
            %superq(useFirstObsAsQuery) ne 1 and
            %sysevalf(%superq(queryData)=, boolean)
        )
    %then %do;

        %put ERROR: Missing query data table.;
        %put ERROR: Select a query data table or select the option to use the first observation of the reference data as the query observation.;

    %end;
    %else %if &_astoreCount. > 1 and %upcase(%superq(codeSourceType)) = NONE
    %then %do;

        %put ERROR: CODE support is required when more than one ASTORE model table is supplied.;
        %put ERROR: Select a code file or code table in the Configuration tab.;

    %end;
    %else %if &_astoreCount. > 1 and
        %upcase(%superq(codeSourceType)) = FILE and
        %sysevalf(%superq(codeFilePath)=, boolean)
    %then %do;

        %put ERROR: Code file was selected, but no code file path was provided.;

    %end;
    %else %if &_astoreCount. > 1 and
        %upcase(%superq(codeSourceType)) = TABLE and
        %sysevalf(%superq(codeTable)=, boolean)
    %then %do;

        %put ERROR: Code table was selected, but no code table was provided.;

    %end;
    %else %do;

        /************************************************************************
        CREATE OR ASSIGN QUERY DATA
        ************************************************************************/

        %if %upcase(%superq(useFirstObsAsQuery)) = TRUE or
            %superq(useFirstObsAsQuery) = 1
        %then %do;

            data casuser._lime_query;
                set &refData.(obs=1);
            run;

            %let _limeQueryData=casuser._lime_query;
            %let _deleteQueryData=1;

        %end;
        %else %do;

            %let _limeQueryData=&queryData.;

        %end;

        /************************************************************************
        OPTIONAL ODS OUTPUT CAPTURE
        ************************************************************************/

        %if not %sysevalf(%superq(outputTable)=, boolean) %then %do;
            ods output _all_=&outputTable.;
        %end;

        /************************************************************************
        EXECUTE PROC LIME
        ************************************************************************/

        proc lime data=&_limeQueryData. referencedata=&refData.

            %if %upcase(%superq(includeMissing)) = TRUE or
                %superq(includeMissing) = 1
            %then %do;
                includemissing
            %end;

            %if not %sysevalf(%superq(logLevel)=, boolean) %then %do;
                loglevel=&logLevel.
            %end;

            %if not %sysevalf(%superq(nThreads)=, boolean) %then %do;
                nthreads=&nThreads.
            %end;

            %if not %sysevalf(%superq(sampleSize)=, boolean) %then %do;
                samplesize=&sampleSize.
            %end;

            %if not %sysevalf(%superq(seed)=, boolean) %then %do;
                seed=&seed.
            %end;
        ;

            /********************************************************************
            ASTOREMODEL STATEMENTS
            ********************************************************************/

            %if not %sysevalf(%superq(astoreTable1)=, boolean) %then %do;
                astoremodel rstore=&astoreTable1.;
            %end;

            %if not %sysevalf(%superq(astoreTable2)=, boolean) %then %do;
                astoremodel rstore=&astoreTable2.;
            %end;

            %if not %sysevalf(%superq(astoreTable3)=, boolean) %then %do;
                astoremodel rstore=&astoreTable3.;
            %end;

            /********************************************************************
            OPTIONAL CODE STATEMENT
            ********************************************************************/

            %if %upcase(%superq(codeSourceType)) = FILE and
                not %sysevalf(%superq(codeFilePath)=, boolean)
            %then %do;

                code file="%superq(codeFilePath)";

            %end;
            %else %if %upcase(%superq(codeSourceType)) = TABLE and
                not %sysevalf(%superq(codeTable)=, boolean)
            %then %do;

                code table=&codeTable.;

            %end;

            /********************************************************************
            OPTIONAL DISTANCE STATEMENT
            ********************************************************************/

            %if not %sysevalf(%superq(distanceExponentialKernel)=, boolean) or
                %upcase(%superq(distanceImpute)) ne NONE or
                not %sysevalf(%superq(distanceMixedWeight)=, boolean)
            %then %do;

                distance
                    %if not %sysevalf(%superq(distanceExponentialKernel)=, boolean) %then %do;
                        exponentialkernel=&distanceExponentialKernel.
                    %end;

                    %if %upcase(%superq(distanceImpute)) ne NONE %then %do;
                        impute=%upcase(%superq(distanceImpute))
                    %end;

                    %if not %sysevalf(%superq(distanceMixedWeight)=, boolean) %then %do;
                        mixeddistanceweight=&distanceMixedWeight.
                    %end;
                ;

            %end;

            /********************************************************************
            OPTIONAL EXPLAINER STATEMENT
            ********************************************************************/

            %if not %sysevalf(%superq(explainerMaxEffects)=, boolean) or
                not %sysevalf(%superq(explainerMinEffects)=, boolean) or
                %upcase(%superq(explainerStandardize)) ne NONE
            %then %do;

                explainer
                    %if not %sysevalf(%superq(explainerMaxEffects)=, boolean) %then %do;
                        maxeffects=&explainerMaxEffects.
                    %end;

                    %if not %sysevalf(%superq(explainerMinEffects)=, boolean) %then %do;
                        mineffects=&explainerMinEffects.
                    %end;

                    %if %upcase(%superq(explainerStandardize)) ne NONE %then %do;
                        standardizeestimates=%upcase(%superq(explainerStandardize))
                    %end;
                ;

            %end;

            /********************************************************************
            OPTIONAL FREQ STATEMENT
            ********************************************************************/

            %if not %sysevalf(%superq(freqVar)=, boolean) %then %do;
                freq &freqVar.;
            %end;

            /********************************************************************
            INPUT STATEMENTS
            ********************************************************************/

            %if not %sysevalf(%superq(intervalVars)=, boolean) %then %do;
                input &intervalVars. / level=interval;
            %end;

            %if not %sysevalf(%superq(nominalVars)=, boolean) %then %do;
                input &nominalVars. / level=nominal;
            %end;

            /********************************************************************
            REQUIRED PREDICTEDTARGET STATEMENT
            ********************************************************************/

            predictedtarget &targetVar.;

            /********************************************************************
            OPTIONAL WEIGHT STATEMENT
            ********************************************************************/

            %if not %sysevalf(%superq(weightVar)=, boolean) %then %do;
                weight &weightVar.;
            %end;

        run;

        /************************************************************************
        CLOSE OPTIONAL ODS OUTPUT CAPTURE
        ************************************************************************/

        %if not %sysevalf(%superq(outputTable)=, boolean) %then %do;
            ods output close;
        %end;

        /************************************************************************
        REMOVE TEMPORARY DATA CREATED BY THIS STEP
        ************************************************************************/

        %if &_deleteQueryData. = 1 %then %do;

            proc casutil;
                droptable casdata="_lime_query" incaslib="casuser" quiet;
            quit;

        %end;

    %end;

    /************************************************************************
    RESTORE SAS OPTION SETTINGS
    ************************************************************************/

    options &_notesOption.;

%mend _lime;


/************************************************************************
EXECUTION CODE
************************************************************************/

title1 "LIME";

%_lime;

title;
footnote;

%sysmacdelete _lime;
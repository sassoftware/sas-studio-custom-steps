/* The following program will utilize the P_[ColumnName] Column from a previous
   Step in order to determine if there is a bias in the dataset using PROC ASSESSBIAS*/

/* Setting up variables for inputTable's libarary and table name */
%let inputTable_lib = &inputTable_lib;
%let inputTable_name = &inputTable_name;

/* Probability Variable Column Selector */
%let probabilityVariable = &probabilityVariable;

/* Target Variable Column Selector and Target Level Dropdown*/
/* Target Level Dropdown has the options of only "Interval" or "Nominal"*/
%let targetVariable = &targetVariable;
%let targetLevel = &targetLevel;
%let targetEvent = &targetEvent;

/* Sensistive Variable Column Selector */
%let sensitiveVariable = &sensitiveVariable;

/* Setting up variables in Options section */
%let cutoff = &cutoff;
%let numBins = &numBins;
%let numCuts = &numCuts;
%let selectionDepth = &selectionDepth;
%let weight = &weight;
%let freq = &freq;

/* Setting up fitStat Variables */
%let pVars = &pVars;
%let pEvent = &pEvent;
%let FitStatDelimiter = &FitStatDelimiter;


%macro setDelimiter();
    %global fsDelimiterClean;

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
    %else %do;                /* ← fixed: %do instead of ; */
        %let fsDelimiterClean = %str( );
    %end;
%mend setDelimiter;

%macro fsIf();
    %if %superq( pVars ) ne and %superq( pEvent ) ne %then %do;
        fitstat pVar=&pVars / pEvent= "&pEvent" Delimiter = "&fsDelimiterClean";
    %end;
    %else %if %superq( pVars ) ne %then %do;
        fitstat pVar=&pVars;
    %end;
%mend fsIf;


proc assessbias 
data=&inputTable_lib..&inputTable_name
cutoff=&cutoff nBins=&numBins 
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

    
    /* Normalize delimiter value */
    %let fsDelimiterClean=;

     
    %setDelimiter;
    /*%if %upcase(%superq(FitStatDelimiter)) = %upcase(%str( )) 
        or %superq(FitStatDelimiter) = %nrquote(%(Space%)) %then %do;
        %let fsDelimiterClean=%str( );
    %end;  */


    *Design for fitstat;  
    %fsIf;

    *target &targetVar;
    /*fitstat pVar=&pVars / pEvent=&pEvent Delimiter = &fsDelimiter;
    target &targetVar / event = &targetEvent level = &targetLevel;*/
run;
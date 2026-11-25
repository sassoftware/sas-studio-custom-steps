options nonotes nosource;
/*
++
Program : Log - Collect SAS Viya Monitoring Logs.step
Alias   : Rake (aka Kumade)
Version : 1.4(14AUG2026)
README.md contains program descriptions.
--
*/

/* Suppresses source code log output. */
%let _source=%sysfunc(getoption(source));
options nosource;

/* If the configuration file does not exist, the macro creates it. */
%let configFolder=/Users/&sysuserid/My Folder;
%let configFile=rakeConfig.txt;
%let configUrl=https://v4m-search.logging.svc.cluster.local:9200/viya_logs-*/_search;
%let configMaxLoop=300;

/* ---------------------------------------------------------------------
    Begin Macro Definitions
----------------------------------------------------------------------*/

/* Obtain the number of observations from descriptor information.
   Reference:
   Determining the Number of Observations in a SAS Data Set Efficiently
   https://communities.sas.com/t5/SAS-Communities-Library/Determining-the-number-of-observations-in-a-SAS-data-set/ta-p/475174
*/
%macro obscnt(dsn);
  %local nobs dsnid;
  %let nobs=.;
  %* Open the data set of interest;
  %let dsnid = %sysfunc(open(&dsn));
  %* If the open was successful get the;
  %* number of observations and CLOSE &dsn;

  %if &dsnid %then
    %do;
      %let nobs=%sysfunc(attrn(&dsnid, nlobs));
      %let rc  =%sysfunc(close(&dsnid));
    %end;
  %else
    %do;
      %let nobs=0;
    %end;
  %* Return the number of observations;
  &nobs
%mend obscnt;

/* Return 1 if the dataset exists. */
%macro checkds(dsn);
   %if %sysfunc(exist(&dsn)) %then 1;
   %else 0;
%mend checkds;

/* Check for the existence of a specified variable */
%macro varExist(data=, var=);
  %local dsid rc;

  %let dsid=%sysfunc(open(&data));

  %if (&dsid) %then %do;
    %if %sysfunc(varnum(&dsid, &var)) %then 1;
    %else 0;
    %let rc=%sysfunc(close(&dsid));
  %end;
  %else 0;
%mend varExist;

/* Log variable metadata (name, type, length, format, label) of a SAS dataset to the SAS log */
%macro LogDatasetVariables(data=);

    %local lib mem nword;

    /* Determine whether data= is a one-level or two-level dataset name */
    %let nword = %sysfunc(countw(&data,.));

    %if &nword = 1 %then %do;
        /* If only a member name is given, assume the WORK library */
        %let lib = WORK;
        %let mem = &data;
    %end;
    %else %if &nword = 2 %then %do;
        /* If a two-level name is given, split it into library and member */
        %let lib = %scan(&data,1,.);
        %let mem = %scan(&data,2,.);
    %end;
    %else %do;
        /* Invalid dataset name format */
        %put ERROR: data=&data is not a valid SAS data set name.;
        %return;
    %end;

    /* Write an informational message to the SAS log */
    title "Listing variables for &lib..&mem by LogDatasetVariables";

    /* Use PROC DATASETS to output dataset variable information to the SAS log */
    proc datasets library=&lib nolist;
        contents data=&mem;
    quit;
    title;

%mend LogDatasetVariables;

/* Returns the name of the TSV file based on date and time. */
%macro rakeOutputFileName(file);
  %local _date _time _out;

  %let _date=%sysfunc(today(), yymmddn8.);
  %let _time=%sysfunc(time(), time8.);
  %let _time=%sysfunc(compress(%superq(_time), :));
  %if %length(&_time)<4 %then %do;
    %let _time=0&_time.;
  %end;

  /* Replace the two placeholders. */
  %let _out=%superq(file);
  %let _out=%sysfunc(tranwrd(%superq(_out), %nrstr(${date}), %superq(_date)));
  %let _out=%sysfunc(tranwrd(%superq(_out), %nrstr(${time}), %superq(_time)));

  /* Return the replacement string. */
  &_out
%mend rakeOutputFileName;


/* Output logs to TSV file. */
%macro makeOutputFile(in=work.log, folder="sasserver:/tmp", filename="OpenSearch.tsv", debug=0);
  %local path status _filename;
  %if &debug=1 %then %put DEBUG: makeOutputFile(&=in, &=folder, &=filename, &=debug);
  
  %let status=-1;

  %if %length(&folder)=0 | &folder="" %then
    %return;

  /* Output to the direcory */
  %if %index(&folder, sasserver:/)>0 %then %do;
    %let path=%sysfunc(transtrn(%superq(folder), sasserver:, ));
    %let path=%qsysfunc(compress(&path/&filename, %str(%")));
    
    /* TSV format */
    %if %upcase(%substr(&path,%length(&path)-3))=.TSV %then %do;
      proc export data=&in dbms=tab replace outfile="&path";
      run;
      %let status=&syserr;
    %end;

    /* JSON format */
    %if %upcase(%substr(&path,%length(&path)-4))=.JSON %then %do;
      proc json out="&path" pretty nosastags;
        export &in;
      run;
      %let status=&syserr;
    %end;
  %end;

  /* Output to the SAS folder */
  %if %index(&folder, sascontent:/)>0 %then %do;
    %let path=%sysfunc(transtrn(%superq(folder), sascontent:, ));
    %let path=%qsysfunc(compress(&path, %str(%")));
    %let _filename=%sysfunc(dequote(&filename));
    filename _rakeTsv filesrvc folderpath="&path" filename=&filename;
    
    /* TSV format */
    %if %upcase(%substr(&_filename,%length(&_filename)-3))=.TSV %then %do;
      proc export data=&in dbms=tab replace outfile=_rakeTsv;
      run;
      %let status=&syserr;
    %end;
    
    /* JSON format */
    %if %upcase(%substr(&_filename,%length(&_filename)-4))=.JSON %then %do;
      proc json out=_rakeTsv pretty;
        export &in;
      run;
      %let status=&syserr;
    %end;

    filename _rakeTsv clear;
  %end;
    
  %if &status=0 %then %do;
    %local _notes_;
    %let _notes_=%sysfunc(getoption(notes));
    options notes;
    %put NOTE: Output file saved to %sysfunc(dequote(&folder))/%sysfunc(dequote(&filename));
    options &_notes_;
  %end;
%mend makeOutputFile;

/* Create a configuration file under My Folder. */
%macro createRakeConfig(folder=&configFolder, file=&configFile, debug=0);
  %local source mprint symbolgen;
  %if &debug=1 %then %put DEBUG: createRakeConfig(&=folder, &=file, &=debug);
  
  filename rakeConf filesrvc folderpath="&folder" filename="&file";

  /* If the file already exists, it is not created. */
  %if &sysfilrc ne 1 %then
    %return;
  
  /* Suppress log messages */
  %let source=%sysfunc(getoption(source));
  %let mprint=%sysfunc(getoption(mprint));
  %let symbolgen=%sysfunc(getoption(symbolgen));
  options nosource nomprint nosymbolgen;

  /* Output query pattern. */
  %macro _writeQuery(text);
    write open object;
    write values "pattern" &text.;
    write close;
  %mend _writeQuery;

  proc json out=rakeConf pretty;
    write open object;
    write values "name" "rake";
    write values "description" "This file is a configuration file for the macro rake(aka kumade).";
    write values "url" "&configUrl";
    write values "queries";
    write open array;
    %_writeQuery("Child terminated by signal");
    %_writeQuery("endpoints have no available addresses");
    %_writeQuery("Error creating compute session");
    %_writeQuery("Error stopping CAS session");
    %_writeQuery("EvictionThresholdMet");
    %_writeQuery("Exception");
    %_writeQuery("FailedScheduling");
    %_writeQuery("Failure");
    %_writeQuery("FreeDiskSpaceFailed");
    %_writeQuery("Gateway Time-out");
    %_writeQuery("I/O error on");
    %_writeQuery("ImageGCFailed");
    %_writeQuery("Insufficient ephemeral-storage");
    %_writeQuery("Internal Server Error");
    %_writeQuery("INTERNAL_SERVER_ERROR");
    %_writeQuery("Java heap space");
    %_writeQuery("JobExecutionException");
    %_writeQuery("killed");
    %_writeQuery("NetworkUnavailable");
    %_writeQuery("No left space");
    %_writeQuery("No space left");
    %_writeQuery("NodeHasDiskPressure");
    %_writeQuery("NodeHasMemoryPressure");
    %_writeQuery("NodeHasPIDPressure");
    %_writeQuery("NodeNotReady");
    %_writeQuery("OAuth token is expired");
    %_writeQuery("ObjectOptimisticLockingFailureException");
    %_writeQuery("ODBC SQL Server Wire Protocol driver");
    %_writeQuery("OOM");
    %_writeQuery("OOMKilled");
    %_writeQuery("OOMKilling");
    %_writeQuery("Operation timed out");
    %_writeQuery("out of memory");
    %_writeQuery("OutOfMemory");
    %_writeQuery("panic:");
    %_writeQuery("SAS/TK is aborting");
    %_writeQuery("ServerOperationException");
    %_writeQuery("ServletOutputStream failed to write:");
    %_writeQuery("SIGSEGV");
    %_writeQuery("SSL error");
    %_writeQuery("SystemOOM");
    %_writeQuery("The system has encountered an unhandled Exception");
    %_writeQuery("timed out after 60");
    %_writeQuery("Traceback");
    %_writeQuery("Unable to launch node");
    %_writeQuery("Unexpected");
    %_writeQuery("unhandled Exception");
    write close;
    write close;
  run;

  filename rakeConf clear;
  options &source &symbolgen &mprint;
%mend createRakeConfig;

/* All the contents of the configuration file are stored in the data set. */
%macro readRakeConfig(folder=, file=, out=, debug=0);
  %local source mprint symbolgen;
  %if &debug=1 %then %put DEBUG: readRakeConfig(&=folder, &=file, &=out, &=debug);
  
  filename rakeConf filesrvc folderpath="&folder" filename="&file";

  %if not %sysfunc(fexist(rakeConf)) %then
    %do;
      %put ERROR: &folder./&file. not found.;
      %return;
    %end;
    
  /* Suppress log messages */
  %let source=%sysfunc(getoption(source));
  %let mprint=%sysfunc(getoption(mprint));
  %let symbolgen=%sysfunc(getoption(symbolgen));
  options nosource nomprint nosymbolgen;
    
  libname rakeLib json fileref=rakeConf;

  data &out;
    format p p1 p2 value;
    attrib Value length=$256;
    set rakeLib.alldata;
  run;

  filename rakeConf clear;
  libname rakeLib clear;
  options &source &symbolgen &mprint;
%mend readRakeConfig;

/* Output ALLDATA of the data set to SAS content. */
%macro updateRakeConfig(data=, folder=&configFolder, file=&configFile, debug=0);
  %local source mprint symbolgen;
  %local pmax qmax;
  %if &debug=1 %then %put DEBUG: updateRakeConfig(&=data, &=folder, &=file, &=debug);

  %if %sysfunc(exist(&data))=0 %then
    %do;
      %put ERROR: &data does not exists.;
      %return;
    %end;
  filename rakeConf filesrvc folderpath="&folder" filename="&file";

  %if &sysfilrc^=0 & &sysfilrc^=1 %then
    %do;
      %put &sysfilrc;
      %put ERROR: Execution of the FILENAME statement failed.;
      %return;
    %end;
  
  /* Suppress log messages */
  %let source=%sysfunc(getoption(source));
  %let mprint=%sysfunc(getoption(mprint));
  %let symbolgen=%sysfunc(getoption(symbolgen));
  options nosource nomprint nosymbolgen;

  /* Put the key and value to be output into the macro variables. */
  data _null_;
    attrib pmax length=8;
    attrib qmax length=8;
    retain pmax qmax;
    set &data end=flag;

    if _n_ eq 1 then
      do;
        pmax=0;
        qmax=0;
      end;

    if v eq 1 and p eq 1 then
      do;
        pmax=pmax + 1;
        call symputx(compress("pkey"||put(pmax, best.)), p1, 'L');
        call symputx(compress("pval"||put(pmax, best.)), value, 'L');
      end;

    if v eq 1 and p eq 2 and p2 eq 'pattern' then
      do;
        qmax=qmax + 1;
        call symputx(compress("qval"||put(qmax, best.)), value, 'L');
      end;

    if flag then
      do;
        call symputx("pmax", compress(put(pmax, best.)), 'L');
        call symputx("qmax", compress(put(qmax, best.)), 'L');
      end;
  run;

  /* update the file */
  proc json out=rakeConf pretty;
    write open object;

    %do i=1 %to &pmax;
      write values "&&pkey&i" "&&pval&i";
    %end;
    write values "queries";
    write open array;

    %do i=1 %to &qmax;
      write open object;
      write values "pattern" "&&qval&i";
      write close;
    %end;
    write close;
    write close;
  run;

  filename rakeConf clear;
  options &source &symbolgen &mprint;
%mend updateRakeConfig;

/* Delete the configuration file under My Folder. */
%macro deleteRakeConfig(folder=&configFolder, file=&configFile, debug=0);
  %if &debug=1 %then %put DEBUG: deleteRakeConfig(&=folder, &=file, &=debug);
  
  filename rakeConf filesrvc folderpath="&folder" filename="&file";

  %if &sysfilrc^=0 & &sysfilrc^=1 %then
    %do;
      %put &sysfilrc;
      %put ERROR: Execution of the FILENAME statement failed.;
      %return;
    %end;
    
  data _null_;
    rc = fdelete("rakeConf");
  run;
  
  filename rakeConf clear;
%mend deleteRakeConfig;

/* Get the value of encodedCredential without using the JSON engine. */
%macro getEncodedCredential(macvar=basic);
  %global &macvar;
  %local notes;

  /* Suppress log messages */
  %let notes=%sysfunc(getoption(notes));
  options nonotes;
  %let &macvar=dummy;
  
  filename rakeConf filesrvc folderpath="&configFolder" filename="&configFile";

  %if &sysfilrc=0 %then
    %do;
      data _null_;
        infile rakeConf recfm=v truncover;
        length buf1 buf2 $256;
        input buf1 buf2 $;

        if buf1 eq '"encodedCredential":' then
          do;
            buf2=dequote(buf2);
            call symputx("&macvar", compress(buf2), 'G');
          end;
      run;

      filename rakeConf clear;
    %end;
  options &notes;
%mend getEncodedCredential;

/* Get the value of the specified key in the config file. */
%macro getRakeConfigKeyValue(folder=&configFolder, file=&configFile, key=, macvar=);
  %local dsn;
  %global &macvar;
  
  %let &macvar=;
  
  /* Create a temporary data set. */
  data;
    stop;
  run;
  %let dsn=&syslast;

  %readRakeConfig(folder=&folder, file=&file, out=&dsn);

  data &dsn;
    set &dsn;
    if (p1 eq "&key") and (v eq 1) then
        call symputx("&macvar", trim(value), 'G');
  run;
  
  /* Create the temporary data set. */
  proc datasets lib=work nolist nowarn;
    delete %substr(&dsn, 6);
  quit;
%mend;

/* Reads the configuration file and outputs the query string to the dataset. */
%macro readRakeConfigQueries(folder=&configFolder, file=&configFile, out=, debug=0);
  %if &debug=1 %then %put DEBUG: readRakeConfigQueries(&=folder, &=file, &=out, &=debug);
  
  %if %length(&out)=0 %then %do;
    %put ERROR: Argument out is missing in readRakeConfigQueries.;
    %return;
  %end;
  
  filename rakeConf filesrvc folderpath="&folder" filename="&file";

  %if not %sysfunc(fexist(rakeConf)) %then
    %do;
      %put ERROR: &folder./&file. not found.;
      %return;
    %end;
  libname rakeLib json fileref=rakeConf;

  data &out;
    attrib n length=8;
    attrib text length=$132;
    attrib len length=8;
    set rakeLib.queries;
    text=pattern;
    len=length(text);
    keep n text len;
  run;

  proc sort data=&out out=&out(drop=len);
    by descending len text;
  run;

  filename rakeConf clear;
  libname rakeLib clear;
%mend readRakeConfigQueries;

/* Get the encoded credential from the configuration file. Set it to a global macro variable. */
%macro getRakeConfigCredential(folder=&configFolder, file=&configFile, macvar=basic);
  %global &macvar;
  %getRakeConfigKeyValue(folder=&configFolder, file=&configFile, key=encodedCredential, macvar=&macvar);
%mend getRakeConfigCredential;

/* Get the OpenSearch url from the configuration file. Set it to a global macro variable. */
%macro getRakeConfigUrl(folder=&configFolder, file=&configFile, macvar=url);
  %global &macvar;
  %getRakeConfigKeyValue(folder=&configFolder, file=&configFile, key=url, macvar=&macvar);

  %if %length(&&macvar)=0 %then
    %let &macvar=&configUrl;
%mend getRakeConfigUrl;

/* Search for suspected error strings and set a flag in the WORK.LOG variable. */
%macro checkErrorPatterns(data=work.log, queries=work.query, out=work.query, debug=0, check=0);
  %local i nobs count mprint symbolgen;
  %local /readonly tmp=tmpKeyPhrase;
  %if &debug=1 %then %put DEBUG: checkErrorPatterns(&=data, &=queries, &=out, &=debug, &=check);
    
  %let mprint=%sysfunc(getoption(mprint));
  %let symbolgen=%sysfunc(getoption(symbolgen));
  options nomprint nosymbolgen;

  %if &check=0 %then %goto exit;
  
  /* Check the number of records in the two input datasets. */
  %let nobs=%obscnt(&data);
  %if &nobs=. %then %do;
    %put ERROR: &data does not exists.;
    %goto exit;
  %end;

  %if &nobs=0 %then %do;
    %put DEBUG: Skip check execution since the number of data is zero.;
    %goto exit;
  %end;

  %if not(%obscnt(&queries)>0) %then %do;
    %put ERROR: &queries does not exists.;
    %goto exit;
  %end;
  
  /* Check whether the two input datasets contain the necessary variables. */
  %if %varExist(data=&data, var=timestamp)=0 %then %do;
    %put ERROR: An internal error occurred during the macro check.;
    %put ERROR: Variable timestamp is not present in dataset &data;
    %LogDatasetVariables(data=&data);
    %goto exit;
  %end;
  
  %if %varExist(data=&data, var=message)=0 %then %do;
    %put ERROR: An internal error occurred during the macro check.;
    %put ERROR: Variable message is not present in dataset &data;
    %LogDatasetVariables(data=&data);
    %goto exit;
  %end;
  
  %if %varExist(data=&queries, var=text)=0 %then %do;
    %put ERROR: An internal error occurred during the macro check.;
    %put ERROR: Variable text is not present in dataset &queries;
    %LogDatasetVariables(data=&queries);
    %goto exit;
  %end;  
  
  /* Set the key phrase to be searched to a macro variable. */
  data _null_;
    set &queries end=flag;
    attrib name length=$16;
    name=compress('name'|| put(_n_, best.));
    call symputx(name, text, 'L');

    if flag then
      call symputx('count', put(_N_, best.));
  run;
  %if &syserr^=0 %then %goto exit;

  /* Search for key phrases and output the number of cases in the data set. */      
  %do i=1 %to &count;

    %if &debug=1 %then
      %put &=i text=&&name&i;

    proc sql;
      create table
        %if &i=1 %then &out; %else &tmp;
      as
      select count(*) as N, "%bquote(&&name&i)" length=132 as Message
      from &data
      where message contains "%bquote(&&name&i)";
    quit;

    %if &i>1 %then %do;
      proc append base=&out data=&tmp;
      run;
    %end;
  %end;

  /* Set the value to the variable Check in the row containing the key phrase.*/
  data &data;
    set &data;
    attrib pattern length=$132 label='String retrieved from the message field';

    %do i=1 %to &count;
      %if &i>1 %then
        else;

      if index(message, "%bquote(&&name&i)")>0 then do;
        check=&i;
        pattern="%bquote(&&name&i)";
      end;
    %end;
  run;
  %if &syserr^=0 %then %goto exit;

  title "Number of logs matching the pattern in &queries..";
  title2 "The pattern is set in &configFolder/&configFile..";

  proc print data=&out;
  run;
  
  %local _notes_;
  %let _notes_=%sysfunc(getoption(notes));
  options notes;
  %put NOTE: Checked dataset &data and saved the results to &out;
  options &_notes_;

%exit:
  proc datasets lib=work nolist nowarn;
    delete &tmp;
  quit;
  title;
  footnote;
  options &mprint &symbolgen;
%mend checkErrorPatterns;

/* Encode the credential and assignment to a global macro variable. */
%macro encodeCredential(user=, password=, macvar=, debug=0);
  %global &macvar;
  %local value;

  %if &debug=1 %then
    %put DEBUG: encodeCredential(&=user, &=password, &=macvar, &=debug);
  
  /* Check the value of the environment variable that stores the credentials */
  %let value=;
  data _null_;
    length value $1024;
    if sysexist('RAKE_CREDENTIALS') then do;
      value = sysget('RAKE_CREDENTIALS');
      call symputx('value', trim(value), 'L');
    end;
  run;
  
  /* If neither a username, password, nor environment variable definition exists */
  %if %length(&user)=0 & %length(&password)=0 & %length(&value)=0 %then %do;
    %let &macvar=;
    %return;
  %end;
  
  %if %length(&user)>0 & %length(&password)>0 %then %do;
    %obfuscate(var=RAKE_CREDENTIALS, debug=&debug);
  %end;

  %if %length(&value)=0 %then %do;
    data _null_;
      attrib code length=$256;
      code=put("&user.:&password.", $base64x64.);
      call symputx("&macvar", compress(code), 'G');
    run;
  %end;
  %else %if %length(&value)>0 %then %do;
    /* Decode the value of the environment variable to retrieve the encoded credentials */
    %deobfuscate(var=RAKE_CREDENTIALS, basic=&macvar, debug=&debug);
  %end;

%mend encodeCredential;

/* Convert the DT value to E8601LX25 format and return it to the macro variable. */
%macro formatDateTime(dt=, tz=, macvar=, debug=0);
  %let &macvar=;
  %local macname tmp _tz;
  %let macname=formatDateTime;
  
  /* Check parameters */
  %if %length(&dt)=0 %then %do;
    %put ERROR: Missing parameter dt in &macname;
    %goto exit;
  %end;

  %if %length(&macvar)=0 %then %do;
    %put ERROR: Missing parameter macvar in &macname;
    %goto exit;
  %end;
  
  /* Check time zone. */
  data _null_;
    length tz $32;
    tz = compress(dequote(symget('tz')));
    tz = upcase(tz);
    if missing(tz) or tz eq 'DEFAULT' then do;
      call symputx('_tz', '', 'L');
    end;
    else do;
      offset = tzoneoff(tz);
      if missing(offset) then call symputx('_tz', '.', 'L');
      else call symputx('_tz', compress(tz));
    end;
  run;
  
  %if "&_tz"="." %then %do;
    %put ERROR: The time zone offset(&tz) value cannot be obtained.;
    %goto exit;
  %end;
  
  /* Format and inspect to handle even if parameter is quoted */
  data _null_;
    attrib dt length=$36;;
    attrib now length=8 format=E8601LX25.;
    attrib tz length=$32;
    attrib len length=8;
    attrib token length=$64;
    attrib token1 length=$32;
    attrib token2 length=$32;
    
    /* Remove double or single quotation marks */
    dt = dequote(symget('dt'));
    tz = compress(dequote(symget('_tz')));
    len = length(dt);

    /* 1. Check E8601LX25 Format. */
    if prxmatch('/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}/', dt) and (len eq 25) then do;
      /* Check whether it can be read as a valid date and time */
      now = inputn(dt, 'E8601LX25.');
      if not missing(now) then do;
        call symputx('tmp', compress(dt));
      end;
      stop;
    end;
    
    /* 2. Check E8601DT19 Format. */
    if prxmatch('/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/', dt) and (len eq 19) then do;
      /* Check whether it can be read as a valid date and time */
      now = inputn(dt, 'E8601DT19.');
      if not missing(now) then do;
        length off 8;
        length offsetstr $16;
        if not missing(tz) then off = tzoneoff(tz);
        else off = tzoneoff();
        
        sign = ifc(off < 0, '-', '+');
        offsetstr=cats(sign, put(hour(abs(off)), z2.), ':', put(minute(abs(off)), z2.));
        
        call symputx('tmp', compress(cats(dt, offsetstr)));
      end;
      stop;
    end;
    
    /* Check the DateMath format. */
    re = prxparse('/now(\/(y|M|w|d|h|m|s))*(-\d+(y|M|w|d|h|m|s))*/');
    start = prxmatch(re, dt);
    if start > 0 then do;
      token = prxposn(re, 0, dt);
      if length(token) eq length(dt) then do;
        if index(dt, '-')>0 then do;
          token1 = substr(dt, 1, index(dt,'-')-1);
          token2 = substr(dt, index(dt,'-'));
        end;
        else do;
          token1 = dt;
          token2 = '';
        end;
        
        /* If the left-hand value contains a slash symbol, round the decimal places. */
        now = datetime();
        if index(token1,'/') > 0 then do;
          p=substr(token1, length(token1));
          if p eq 's' then interval='DTSECOND';
          else if p eq 'm' then interval='DTMINUTE';
          else if p eq 'h' then interval='DTHOUR';
          else if p eq 'd' then interval='DTDAY';
          else if p eq 'w' then interval='DTWEEK';
          else if p eq 'M' then interval='DTMONTH';
          else if p eq 'y' then interval='DTYEAR';
          else interval='DTSECOND';
          
          now=intnx(compress(interval), now, 0, 'BEGIN');
        end;
        
        /* If there is a minus sign, adjust the date and time. */
        if not missing(token2) then do;
          n=input(substr(token2, 1, length(token2)-1), best.);
          p=substr(token2, length(token2));
          
          if p eq 's' then interval='DTSECOND';
          else if p eq 'm' then interval='DTMINUTE';
          else if p eq 'h' then interval='DTHOUR';
          else if p eq 'd' then interval='DTDAY';
          else if p eq 'w' then interval='DTWEEK';
          else if p eq 'M' then interval='DTMONTH';
          else if p eq 'y' then interval='DTYEAR';
          else interval='DTSECOND';
          now=intnx(compress(interval), now, n, 'SAME');
        end;
        
        call symputx('tmp', compress(put(now, E8601LX25.)));
      end;
    end;
  run;

%exit:
  %let &macvar=&tmp;
  %if &debug=1 %then %put DEBUG: &macname(&=dt, &=tz, &=macvar, &=debug) &macvar=&tmp;
%mend formatDateTime;

/* Derive the UTC offset (+HH:MM) from a given time zone identifier. */
%macro tz2UtcOffset(tz=, macvar=rc, debug=1);
  %let &macvar=;
  %local _tz _offset;
  %let _tz=%upcase(%superq(tz));
  %if %length(&_tz)>0 %then %let _tz=%sysfunc(dequote(&_tz));

  %if "&_tz"="DEFAULT" %then %let _tz=;
  %let _offset=;

  data _null_;
    sec=tzoneoff("&_tz");

    if not missing(sec) then do;
      attrib sign length=$1;
      attrib hh length=$2;
      attrib mm length=$2;
      attrib offset length=$6;

      if sec < 0 then sign='-';
      else sign='+';
      hour=floor(abs(sec)/3600);
      minute=floor(mod(sec, 3600) / 60);
      hh=put(hour, z2.);
      mm=put(minute, z2.);
      offset=compress(sign || hh || ':' || mm);
      call symputx("_offset", compress(offset), 'L');
    end;
  run;

  %let &macvar=&_offset;

  %if &debug=1 %then %put DEBUG: tz2UtcOffset(&=tz, &=macvar, &=debug) &macvar=&&&macvar;
%mend;

/* Convert a JSON file to a SAS dataset. */
%macro json2ds(lib=, fileref=, out=);
  libname &lib json fileref=&fileref;

  data &out;
    set &lib..alldata end=flag;
    attrib timestamp length=8 format=e8601dt23.3;
    attrib hour length=8;
    attrib minute length=8;
    attrib second length=8;
    attrib check length=8;
    attrib utc length=$32;
    attrib id length=$64;
    attrib level length=$16;
    attrib logsource length=$64;
    attrib container length=$64;
    attrib pod length=$64;
    attrib message length=$4096;
    attrib username length=$32;
    attrib client length=$32;
    retain timestamp utc id level logsource container pod message username client;
    keep timestamp hour minute second check utc id level logsource container pod 
      message username client;

    if not missing(id) then
      do;

        if (p eq 2 and p1 eq 'hits' and p2 eq 'hits') or (flag eq 1) then
          do;
            hour=hour(timestamp);
            minute=minute(timestamp);
            second=int(second(timestamp));
            output;
            timestamp=.;
            id='';
            utc='';
            level='';
            logsource='';
            container='';
            pod='';
            message='';
            username='';
            client='';
          end;
      end;
    else if missing(id) and flag eq 1 then
      do;
        stop;
      end;

    if p1 eq 'hits' and p2 eq 'hits' then
      do;

        if p3 eq '_source' then
          do;

            if p4 eq '@timestamp' then
              do;
                utc=value;
                timestamp=tzoneu2s(input(utc, e8601dt23.3));
              end;
            else if p4 eq 'level' then
              level=upcase(value);
            else if p4 eq 'logsource' then
              logsource=value;
            else if p4 eq 'message' then
              do;

                /* Replace line breaks and tabs with spaces. */
                message=tranwrd(value, '09'x, ' ');
                message=tranwrd(message, '0A'x, ' ');
              end;
            else if p4 eq 'kube' and p5 eq 'labels' then
              do;

                if p6 eq 'launcher_sas_com/username' then
                  username=value;
                else if p6 eq 'launcher_sas_com/requested-by-client' then
                  client=value;
              end;
            else if p5 eq 'container' then
              container=value;
            else if p5 eq 'pod' then
              pod=value;
          end;
        else if p3 eq '_id' then
          id=value;
      end;
  run;

  libname &lib clear;
%mend json2ds;

/* Execute OpenSearch queries with the REST API, specifying fields and text. */
%macro query(basic=, url=, from=, to=, field=, text=, out=);
  %local /readonly cert="/opt/sas/viya/home/SASSecurityCertificateFramework/tls/certs/ca-bundle.pem";
  %local query result;
  %let query=_LF%sysfunc(putn(%sysfunc(monotonic()), z5.));
  %let result=_LF%sysfunc(putn(%sysfunc(monotonic()), z5.));

  /* Check if there is a value for BASIC authentication and URL. */
  %if %length(&basic)=0 | %length(&url)=0 %then
    %return;
    
  filename &result "/tmp/rake_result.txt";
  filename &query '/tmp/rake_query.txt';

  data _null_;
    file &query lrecl=32767;
    length buf $4096;
    length source $512;
    length f1-f8 $64;

    /* Create a string that specifies the fields to be extracted. */
    array field{*} $ f1-f8 ('@timestamp', 'level', 'logsource', 'kube.container', 
      'kube.pod', 'message', 'kube.labels.launcher_sas_com/username', 
      'kube.labels.launcher_sas_com/requested-by-client');

    do i=1 to dim(field);

      if i eq 1 then
        source='"_source":[';

      if i>1 then
        source=trim(source) || ',';
      source=trim(source) || '"' || trim(field[i]) || '"';

      if i eq dim(field) then
        source=trim(source) || '],';
    end;

    /* Output the search request to a file. */
    put '{' @;
    put '"size":10000,' @;

    %if %length(&field)>0 & %length(&text)>0 %then
      buf='"query":{"bool":{"must":[],"filter":[{"bool":{"should":[{"match_phrase":{"<@FIELD>":"<@TEXT>"}}],"minimum_should_match":1}},{"range":{"@timestamp":{"gte":"<@FROM>","lte":"<@TO>"}}}],"should":[],"must_not":[]}},';
    %else
      buf='"query":{"range":{"@timestamp":{"gte":"<@FROM>","lt":"<@TO>"}}},';
    ;
    buf=tranwrd(buf, '<@FROM>', &from);
    buf=tranwrd(buf, '<@TO>', &to);

    %if %length(&field)>0 & %length(&text)>0 %then
      %do;
        buf=tranwrd(buf, '<@FIELD>', &field);
        buf=tranwrd(buf, '<@TEXT>', &text);
      %end;
    put buf @;
    put source @;
    put '"sort":[{"@timestamp":"asc"}]' @;
    put '}';
  run;

  proc http url="&url" in=&query out=&result timeout=30;
    sslparms "SSLREQCERT"="allow" SSLCERTLOC=&cert;
    headers "content-type"="application/json" "authorization"="Basic &basic.";
    debug level=0;
  run;
  
  %if &SySERR=3000 %then %do;
    %put ERROR: Please check the value of URL &url. as failed to resolved DNS hostname.;  
    %goto exitQuery;
  %end;

  %if %symexist(SYS_PROCHTTP_STATUS_CODE) %then %do;
    %if &SYS_PROCHTTP_STATUS_CODE=200 %then
      %json2ds(lib=rakejson, fileref=&result, out=&out);
    %else %if &SYS_PROCHTTP_STATUS_CODE=301 | &SYS_PROCHTTP_STATUS_CODE=400 | &SYS_PROCHTTP_STATUS_CODE=405 %then
      %put ERROR: Please check the value of URL &url as Bad Request has occured.;
    %else %if &SYS_PROCHTTP_STATUS_CODE=401 %then
      %put ERROR: Please check your username and password as an authentication error has occurred.;
    %else
      %put ERROR: REST API returned unexpected code &SYS_PROCHTTP_STATUS_CODE..;
    ;
  %end;

%exitQuery:
  filename &result clear;
  filename &query clear;
%mend query;

/* Aggregate and visualize logs with SGPANEL, SGPLOT. */
%macro rakeFreqPlot(data=work.log, freq=0);
  %local nobs;

  %if &freq=0 %then
    %return;
  %let nobs=%obscnt(&data);

  %if &nobs=. %then
    %do;
      %put DEBUG: Skip summary execution since there is no data.;
      %return;
    %end;

  %if &nobs=0 %then
    %do;
      %put DEBUG: Skip summary execution since the number of data is zero.;
      %return;
    %end;
    
  %local _notes_;
  %let _notes_=%sysfunc(getoption(notes));
  options notes;
  %put NOTE: Insights from the search results are visualized using &data;
  options &_notes_;
    
  title "proc freq data=&data";
  title2 "tables logsource pod level container username client / nocum missing plogs=(freqplot);";

  proc freq data=&data;
    tables logsource pod level container username client / nocum missing 
      plots=(freqplot);
  run;

  title "proc sgpanel data=&data";
  title2 "panel level / columns=1; histgram timestamp;";

  proc sgpanel data=&data;
    panelby level / columns=1;
    histogram timestamp;
  run;

  title2 "histgram timestamp / group=level;";

  proc sgplot data=&data;
    histogram timestamp / group=level;
  run;

  title2 "histgram timestamp / group=container;";

  proc sgplot data=&data;
    histogram timestamp / group=container;
  run;

  title2 "histgram timestamp / group=username;";

  proc sgplot data=&data;
    histogram timestamp / group=username;
  run;

  title "proc sgpanel data=&data(level eq 'ERROR')";
  title2 "histgram timestamp / group=container;";

  proc sgplot data=&data(where=(level eq 'ERROR'));
    histogram timestamp / group=container;
  run;

  title2 "histgram timestamp / group=username;";

  proc sgplot data=&data(where=(level eq 'ERROR'));
    histogram timestamp / group=username;
  run;

  title2 "histgram timestamp / group=client;";

  proc sgplot data=&data(where=(level eq 'ERROR'));
    histogram timestamp / group=client;
  run;

  title2 "histgram timestamp / group=logsource;";

  proc sgplot data=&data(where=(level eq 'ERROR'));
    histogram timestamp / group=logsource;
  run;

  title;
%mend rakeFreqPlot;

/* Delete a dataset. */
%macro deleteData(data=);
  %local p mem lib;
  %let p=%index(&data, .);

  %if &p>0 %then
    %do;
      %let lib=%substr(&data, 1, %eval(&p-1));
      %let mem=%substr(&data, %eval(&p+1));
    %end;
  %else
    %do;
      %let lib=work;
      %let mem=&out;
    %end;

  proc datasets lib=&lib nolist nowarn;
    delete &mem;
  quit;

%mend deleteData;

/* Rake up the fallen leaves. */
%macro rakeUp(from=, to=, message=, basic=, url=, out=);
  %local n count timestamp prev;
  %local temp;
  %global rake_qcount rake_qobs rake_url;
  %let temp=_LN%sysfunc(putn(%sysfunc(monotonic()), z5.));
  %let rake_qcount=0;
  %let rake_qobs=0;
  %let n=0;
  
  %local _notes_;
  %let _notes_=%sysfunc(getoption(notes));
  options notes;
  %put NOTE: Rake log extraction started.;
  %put NOTE: Search period: &=from, &=to;
  options &_notes_;

  
  /* The URL for the OpenSearch API is obtained from the configuration file. */
  %if %length(&url)>0 %then
    %if "&url"="default" %then
      %let rake_url=&configUrl;
    %else
      %let rake_url=&url;
  %else
    %getRakeConfigUrl(macvar=rake_url);

  %do %while (&from < &to);

    /*%put from=&from to=&to;*/
    %query(basic=&basic, url=&rake_url, from=&from, to=&to, field="message", text=&message, out=&temp);

    %if %symexist(SYS_PROCHTTP_STATUS_CODE) %then %do;
      %if &SYS_PROCHTTP_STATUS_CODE^=200 %then %do;
        %goto ExitrakeUp;
      %end;
    %end;
    %else %do;
      %goto ExitrakeUp;
    %end;
    %let count=0;

    proc sql noprint;
      select count(*) into :count from &temp;
      select max(utc) into :timestamp from &temp;
    quit;

    options notes;
    %put NOTE: N=%sysfunc(putn(&n, 4.)) COUNT=%sysfunc(putn(&count, 5.)) &=from LAST="%trim(&timestamp)";
    options &_notes_;

    %if &count=0 | "%trim(&timestamp)"=&from %then
      %do;

        %if %sysfunc(exist(&out))=0 %then
          %do;

            data &out;
              set &temp;
            run;

          %end;
        %goto ExitrakeUp;
      %end;

    /* Remove the date and time of the last timestamp. */
    data &temp(compress=yes);
      set &temp;

      if utc eq "%trim(&timestamp)" then
        delete;
    run;

    /* Add to the results data set. */
    data &out(compress=yes);
      set %if &n=0 %then
        &temp;
      %else
        &out &temp;
      ;
      attrib pattern length=$132;
      attrib n length=8;
      n=_n_;
    run;

    %let from="%trim(&timestamp)";
    %let n=%eval(&n + 1);

    %if &n > &configMaxLoop %then
      %goto ExitrakeUp;
  %end;
%ExitrakeUp:

  %if %checkds(&out) %then %do;

    data &out(compress=yes);
      set &out;
      n=_n_;
  
      if missing(username) then
        username='N/A';
  
      if missing(client) then
        client='N/A';
    run;
    %if &syserr=0 %then %do;
      options notes;
      %put NOTE: Search results saved to &out.;
      options &_notes_;
    %end;
  
    %let rake_qcount = %eval(&n+1);
  
    proc sql noprint;
      select count(*) into :rake_qobs from &out;
    quit;
  
  %end;

  proc datasets lib=work nolist nowarn;
    delete &temp;
  quit;

%mend rakeUp;

/* If reset=1 is specified, URL in the configuration file will be changed to the default value. */
%macro resetSettings(folder=&configFolder, file=&configFile, url=&configUrl);
  %local dsn;
  %let dsn=_RAKE%sysfunc(monotonic());
    
  %put DEBUG: The URL in the configuration file has been changed to the initial value.;
  %put url=&url;
   
  %readRakeConfig(folder=&folder, file=&file, out=&dsn);

  data &dsn;
    set &dsn;
    if (p1 eq "url") and (v eq 1) then
      value="&url";
  run;

  %updateRakeConfig(folder=&folder, file=&file, data=&dsn);

  proc datasets lib=work nolist nowarn;
    delete &dsn;
  quit;
%mend resetSettings;

/* Main process if the argument reset=1 is specified. */
%macro rakeReset(macname=);
  %global basic;

  %deleteRakeConfig;
  %createRakeConfig;
  
  %rakeInfoReset(macname=&macname);
%mend;

/* Utility macro to output parameters of execution. */
%macro _outKeyValue(key, value);
  key=&key;
  value=&value;
  output;
%mend;

/* Obfuscate credentials using Base64, XOR, and HEX encoding. */
%macro obfuscate(var=, debug=0);
  %local encoded notes symbolgen mlogic;

  %let notes=%sysfunc(getoption(notes));
  %let symbolgen=%sysfunc(getoption(symbolgen));
  %let mlogic=%sysfunc(getoption(mlogic));
  options nonotes nosymbolgen nomlogic;
  
  data _null_;

    /* Prepare working variables */
    length username password encoded key encrypted_hex $512;
    length len 8;

    /* Read credentials from macro variables */
    username=symget('user');
    password=symget('password');
    
    /* Use SERVICESBASEURL as XOR key source */
    key=getoption('SERVICESBASEURL');

    /* Encode credentials as Base64 */
    encoded=put(trim(catx(':', username, password)), $base64x64.);

    len=length(key);

    /* Obfuscate Base64 text with XOR */
    do i=1 to length(encoded);

      c1=rank(substr(encoded, i, 1));
      c2=rank(substr(key, mod(i-1, len)+1, 1));

      xor_byte=bxor(c1, c2);

      /* Store XOR result as HEX */
      encrypted_hex=cats(encrypted_hex, put(xor_byte, hex2.));
    end;

    /* Return obfuscated value to macro scope */
    call symputx("encoded", trim(encrypted_hex), 'L');
    %if &debug=1 %then %do;
      put encoded=;
    %end;
  run;

  /* Store obfuscated value in environment variable */
  %if &syserr=0 %then %do;
    options set=&var="&encoded";
    options notes;
    %put NOTE: Define RAKE_CREDENTIALS to skip credential prompts.;
    %put options set=&var="&encoded"%str(;);
  %end;

  options &notes &symbolgen &mlogic;
%mend;

/* Restore obfuscated credentials from an environment variable. */
%macro deobfuscate(var=, basic=, debug=0);
  %local credential notes symbolgen mlogic;

  %let notes=%sysfunc(getoption(notes));
  %let symbolgen=%sysfunc(getoption(symbolgen));
  %let mlogic=%sysfunc(getoption(mlogic));
  options nonotes nosymbolgen nomlogic;

  %let credential=;

  data _null_;

    /* Prepare working variables */
    length key hexpair encrypted_hex decoded $1024;

    /* Read obfuscated value from environment variable */
    encrypted_hex=sysget("&var");

    /* Use the same XOR key source */
    key=getoption('SERVICESBASEURL');

    decoded='';
    len=length(key);

    /* Restore Base64 text from HEX/XOR */
    do i=1 to length(encrypted_hex) by 2;

      hexpair=substr(encrypted_hex, i, 2);
      xor_byte=input(hexpair, hex2.);

      c2=rank(substr(key, mod((i-1)/2, len)+1, 1));
      decoded=cats(decoded, byte(bxor(xor_byte, c2)));
    end;

    /* Return decoded Base64 text */
    call symputx("&basic", trim(decoded), 'G');

    /* Decode Base64 to plain credentials */
    %if &debug>0 %then %do;
      put decoded=;
    %end;
    %if &debug>1 %then %do;
      length plain $1024;
      plain=input(trim(decoded), $base64x64.);
      put plain=;
    %end;
  run;

  /* Store decoded value in environment variable */
  /*
  %if &syserr=0 %then %do;
    options set=&basic="&credential";
  %end;
  */
 
  options &notes &symbolgen &mlogic;
%mend;

/* Outputs macro execution information. */
%macro rakeInfo(macname=, from=, to=, out=, debug=, verbose=, freq=, check=, message=, folder=, filename=, url=, count=, obs=, stime=, etime=);
  %local dsn;
  %let dsn=_RAKEINFO%sysfunc(monotonic());
  
  %if &debug=1 %then %put DEBUG: rakeInfo(&=macname, &=from, &=to, &=out, &=debug, &=verbose, &=freq, &=check, &=message, &=folder, &=filename, &=url, &=count, &=obs, &=stime, &=etime);

  data &dsn;
    length key value $132;
    length buf $132;
    %_outKeyValue("macro", "&macname");
    %_outKeyValue("args(1)", "from=&from, to=&to out=&out");
    %_outKeyValue("args(2)", "check=&check, freq=&freq, verbose=&verbose, debug=&debug");
    %_outKeyValue("args(3)", "url=&url");
    %if %length(&message)>0 %then %do;
      %_outKeyValue("args(4)", "message=%sysfunc(dequote(&message))");
    %end;
    %_outKeyValue("user", "&sysuserid");
    buf=catt("from=", "&from", " to=", "&to");
    %_outKeyValue("time range(utc)", buf);
    buf=catt("start=", "&stime", " stop=", "&etime");
    %_outKeyValue("query time", buf);
    %_outKeyValue("obs", "&obs");
    %_outKeyValue("number of api calls", "&count");
    %if &folder^="" & &filename^="" %then
      %do;
        buf=catt(&folder, "/", &filename);
        %_outKeyValue("tsv file", buf);
      %end;
    
    keep key value;
  run;

  title "Macro arguments and execution information.";
  proc print data=&dsn noobs;
  run;
  title;
  
  proc datasets lib=work nolist nowarn;
    delete &dsn;
  quit;

%mend;

/* Output the result of the reset to the custom step. */
%macro rakeInfoReset(macname=, debug=0);
  %local dsn;
  %let dsn=_RAKEINFO%sysfunc(monotonic());
  
  %if &debug=1 %then %put DEBUG: rakeInfoReset(&=macname, &=debug);

  data &dsn;
    length key value $132;
    %_outKeyValue("macro", "&macname(reset=1)");
    keep key value;
  run;

  title "Configuration file &configFolder/&configFile has been deleted and recreated.";
  proc print data=&dsn noobs;
  run;
  title;
  
  proc datasets lib=work nolist nowarn;
    delete &dsn;
  quit;

%mend;

/* Check for errors before raking up the logs. */
%macro rakeSearch(macname=, user=, password=, url=, from=, to=, tz=default, out=, debug=, verbose=, freq=, check=, message=, folder=, filename=);
  %global basic utc_from utc_to;
  
  %if &debug=1 %then %put DEBUG: rakeSearch(&=macname, &=user, &=url, &=from, &=to, &=tz, &=out, &=debug, &=verbose, &=freq, &=check, &=message, &=folder, &=filename);  
  
  /* Convert the time specification to UTC. */
  %formatDateTime(dt=&from, macvar=utc_from, tz=&tz, debug=0);
  %formatDateTime(dt=&to, macvar=utc_to, tz=&tz, debug=0);

  /* Set global macro settings to local variables. */
  %if %length(&user)=0 & %symexist(opensearch_user) %then
    %let user=&opensearch_user;
  %if %length(&password)=0 & %symexist(opensearch_password) %then
    %let password=&opensearch_password;

  /* Encode the credential and set it to a macro variable. */
  %encodeCredential(user=&user, password=&password, macvar=basic);

  /* If the default configuration file does not exist, create it. */
  %createRakeConfig;

  /* Check the credentials */
  %if %length(&basic)=0 %then
    %do;
      %put ERROR: Unable to obtain credential for Basic authentication. Please specify a user name and password.;
      %return;
    %end;

  /* Test file deletion. */
  %deleteData(data=&out);
  %if &syserr^=0 %then
    %do;
      %return;
    %end;

  /* Checks the date order. */
  %if "&utc_from">"&utc_to" %then
    %do;
      %put ERROR: The datetime FROM is more recent than TO.;
      %return;
    %end;

  /* Loop through every 10,000 cases and log OpenSearch. */  
  %rakeUp(from="&utc_from", to="&utc_to", message=&message, basic=&basic, url=&url, out=&out);
  %let etime=%sysfunc(datetime(), e8601dt.);

  /* Outputs macro execution information. */
  %rakeInfo(
    macname=&macname, 
    from=&utc_from,
    to=&utc_to,
    url=&url,
    out=&out,
    debug=&debug,
    verbose=&verbose,
    freq=&freq,
    check=&check,
    message=&message,
    folder=&folder,
    filename=&filename,
    count=&rake_qcount,
    obs=&rake_qobs,
    stime=&stime,
    etime=&etime);

%mend;

/* Extracts the SAS program stored in the templates.SAS section of a custom step file in SAS Content. */
/* Extracts the SAS program stored in the templates.SAS section of a custom step file in SAS Content. */
%macro extractTemplatesSAS(path=, macvar=rc, debug=0);
  %let &macvar=1;
  %local _viyaurl _status work;
  %local _sc_path _folder _file;
  %local cstep json1 json2 json3 program macname;
  %let macname=extractTemplatesSAS;

  /* 0) Pre-process the path parameter */
  %let cstep=_CS%sysfunc(putn(%sysfunc(monotonic()), z5.));
  %let json1=_JS%sysfunc(putn(%sysfunc(monotonic()), z5.));
  %let json2=_JS%sysfunc(putn(%sysfunc(monotonic()), z5.));
  %let json3=_JS%sysfunc(putn(%sysfunc(monotonic()), z5.));
  %let program=_PG%sysfunc(putn(%sysfunc(monotonic()), z5.));
  %let work=DS%sysfunc(putn(%sysfunc(monotonic()), z5.));

  /* Remove the "sascontent:" prefix */
  %let _sc_path=%sysfunc(prxchange(s/^sascontent://, 1, &path));

  /* Extract the file name (everything after the last "/") */
  %let _file=%scan(&_sc_path, -1, /);
  %let _folder=%substr(&_sc_path, 1, %eval(%length(&_sc_path) - %length(&_file)-1));

  /* Temporary file used as an intermediate buffer */
  filename &json1 "/tmp/&json1.txt";
  filename &json2 "/tmp/&json2.txt";
  filename &json3 "/tmp/&json3.txt";

  /* Base URL of the Viya services */
  %let _viyaurl=%sysfunc(getoption(servicesbaseurl));

  /* 1) Reference the custom step in SAS Content via FILESRVC */
  filename &cstep filesrvc folderpath="&_folder" filename="&_file";
  %if &sysfilrc^=0 %then %do;
    %if &sysfilrc=1 %then %put ERROR: &path does not exists.;
    %goto exit;
  %end;

  /* Output target: save as "rake.sas" in the same folder as the custom step */
  filename &program filesrvc folderpath="&_folder" filename="rake.sas";
  %if not %symexist(_FILESRVC_&CSTEP._URI) %then %do;
    %put ERROR: filesrvc URI macro variable was not created.;
    %put ERROR: path=&path;
    %goto exit;
  %end;

  /* 2) Retrieve the JSON definition via PROC HTTP */
  proc http method="GET" url="&_viyaurl&&_FILESRVC_&CSTEP._URI" out=&json1
    OAUTH_BEARER=SAS_SERVICES;
    sslparms "SSLREQCERT"="ALLOW";
  run;

  %let _status=&SYS_PROCHTTP_STATUS_CODE;
  %if "&_status"^="200" %then %do;
    %put ERROR: PROC HTTP failed. HTTP_STATUS=&_status;
    %goto exit;
  %end;

  /* 3) Expand escaped line breaks, tabs, and double quotes in a JSON file */
  data _null_;
    infile &json1 recfm=n lrecl=256 end=eof;
    file &json2 recfm=n lrecl=256;

    length c ht lf $1;
    retain saw_bs 0 drop_next_n 0;

    ht=byte(9);
    lf=byte(10);
    input c $char1.;

    if saw_bs then do;
      if c='n' then do;
        if drop_next_n then drop_next_n=0;
        else put lf;
      end;
      else if c='r' then do;
        put lf;
        drop_next_n=1;
      end;
      else if c='t' then do;
        put ht;
        drop_next_n=1;
      end;
      else if c='\' then do;
        put '\';
        drop_next_n=0;
      end;
      else if c='"' then do;
        put '"';
        drop_next_n=0;
      end;
      else do;
        put '\';
        put c $char1.;
        drop_next_n=0;
      end;
      saw_bs=0;
    end;
    else do;
      if c='\' then saw_bs=1;
      else do;
        put c $char1.;
        drop_next_n=0;
      end;
    end;

    /* Handle the edge case where the file ends with a single backslash */
    if eof and saw_bs then put '\';
  run;
  %if &syserr^=0 %then %goto exit;

  /* 4) Output the portion of the JSON file that contains the program to a file */
  data _null_;
    length line remain $32767;
    retain found 0;

    infile &json2 lrecl=32767 truncover;
    file &json3 lrecl=32767;

    input line $char32767.;

    if found=0 then do;
      pos=index(line, '"templates":{"SAS":"');
      if pos > 0 then do;
        found=1;
        remain=substr( line, pos + length('"templates":{"SAS":"') );
        put remain $char4096.;
      end;
    end;
    else do;
      put line $char4096.;
    end;
  run;
  %if &syserr^=0 %then %goto exit;

  /* 5) Create a dataset by removing the extra characters at the end of each file for debugging purposes */
  data &work(keep=line lineno);
    length line $4096;
    infile &json3 lrecl=4096 truncover end=eof;
    lineno + 1;
    input line $char4096.;
    
    if eof then do;
      pos = index(line,'"}}');
      if substr(strip(line), max(1,length(strip(line))-2))='"}}' then do;
        line=substr(strip(line), 1, length(strip(line))-3);
      end;
    end;
  run;
  %if &syserr^=0 %then %goto exit;

  /* 6) Output the SAS program */
  data _null_;
    set &work;
    file &program lrecl=4096;
    len=length(line)+1;
    put line $varying4096. len;
  run;

  %if &syserr=0 %then %do;
    %put DEBUG: The SAS program was saved to &_folder/rake.sas;
    %let &macvar=0;
  %end;

%exit:
  %if &debug=0 %then %do;
    filename &json1 clear;
    filename &json2 clear;
    filename &json3 clear;
    filename &program clear;
    filename &cstep clear;
    proc datasets lib=work nolist nodetails;
      delete &work;
    quit;
  %end;
  %if &debug=1 %then %put DEBUG: &macname(&=path, &=macvar, &=debug) &macvar=&&&macvar;
%mend;

/* rake is a utility for extracting OpenSearch logs. */
%macro rake(
  user=,
  password=,
  url=,
  from="now-10m",
  to="now",
  tz=default,
  out=work.log,
  query=work.query,
  debug=0,
  verbose=0,
  freq=0,
  check=0,
  message=,
  folder="sasserver:/tmp",
  filename="OpenSearch_${date}T{$time}.tsv",
  reset=0);
  %local count n stime etime macname options info outputfilename notes compress;
  %local i var max list;
  %let stime=%sysfunc(datetime(), e8601dt.);
  %let options=_RAKEOPT%sysfunc(monotonic());
  %let outputfilename="%rakeOutputFileName(%sysfunc(dequote(&filename)))";
  %let macname=&sysmacroname;
  %let macname=%lowcase(&macname);

  /* Save the settings and then reflect the argument specifications in the options. */
  %let notes=%sysfunc(getoption(notes));
  %let compress=%sysfunc(getoption(compress));
  options nonotes compress=yes;
  proc optsave out=&options;
  run;

  /* Show usage tips */
  options notes;
  %put NOTE: Equivalent macro call:;
  options nonotes;
  data _null_;
    length buf $4096;
    putlog '%rake(';
    
    %let list=user password from to tz out query debug verbose freq check message folder filename reset;
    %let max=%sysfunc(countw(&list, %str( )));
    
    %do i=1 %to &max;
      %let var=%scan(&list, &i, %str( ));

      %if &var=password %then %do;
        buf="password=<hidden>,";
      %end;
      %else %if &i<&max %then %do;
        buf=cat("&var=", trim(symget("&var")), ',');
      %end;
      %else %do;
        buf=cat("&var=", trim(symget("&var")));
      %end;
      putlog "  " buf;
    %end;
    putlog ');';
  run;
  
  %if &verbose=0 %then
    options nonotes nomprint nomprintnest nosource nosource2 nosymbolgen nomlogic;
  %else %if &verbose=1 %then
    options notes nomprint nosymbolgen;
  ;

  %if &debug=1 %then
    options nomprint source source2 nosymbolgen;
  ;
  %if &reset=1 %then
    %rakeReset(macname=&macname);

  %if &reset=0 %then %do;
    %let tz=%sysfunc(dequote(&tz));
    %if "&password"="<hidden>" %then %let password=;

    /* Rake up the fallen leaves. */
    %rakeSearch(
      macname=&macname,
      user=&user,
      password=&password,
      url=&configUrl,
      from=&from,
      to=&to,
      tz=&tz,
      out=&out,
      debug=&debug,
      verbose=&verbose,
      freq=&freq,
      check=&check,
      message=&message,
      folder=&folder,
      filename=&filename
    );
  
    %if %checkds(&out)=0 %then
      %put DEBUG: &out has not been created.;
    %else %if %obscnt(&out)>0 %then %do;
      %readRakeConfigQueries(out=&query);
      %checkErrorPatterns(data=&out, queries=&query, out=&query, check=&check);
      %rakeFreqPlot(data=&out, freq=&freq);
      %makeOutputFile(in=&out, folder=&folder, filename=&outputfilename);
    %end;
  %end;

  proc optload data=&options;
  run;

  proc datasets lib=work nolist nodetails nowarn;
    delete _RAKEOPT: _RAKEINFO: _SGSORT_;
  quit;

  %if &syscc^=0 %then
    %put DEBUG: &=syscc;
  %symdel basic /nowarn;
  %symdel rake_qcount /nowarn;
  %symdel rake_qobs /nowarn;
  options &notes compress=&compress;
%mend rake;

/* Kumade is an alias for Rake. */
%macro kumade(
  user=,
  password=,
  from="now-10m",
  to="now",
  tz=default,
  out=work.log,
  debug=0,
  verbose=0,
  freq=0,
  check=0,
  message=,
  folder="sasserver:/tmp",
  filename="OpenSearch_${date}T${time}.tsv",
  reset=0);
  %rake(
    user=&user,
    password=&password, 
    url=&configUrl,
    from=&from,
    to=&to,
    tz=&tz,
    out=&out, 
    debug=&debug,
    verbose=&verbose,
    freq=&freq,
    check=&check, 
    message=&message,
    folder=&folder,
    filename=&filename,
    reset=&reset
  );
%mend kumade;

/* Judge from the macro variable whether the execution is from a custom step or not. */
%macro checkCustomStep;
  %local rc i macvar;
  %let rc=1;
  %local /readonly cs=user password query freq check verbose message folder filename reset custom_step tz;
  %local /readonly radio=To From;
  
  %do i=1 %to %sysfunc(countw(&cs));
    %let macvar= cs_%scan(&cs, &i, %str( ));
    %if %symexist(&macvar)=0 %then %let rc=0;
  %end;

  %do i=1 %to %sysfunc(countw(&radio));
    %let macvar= radio%scan(&radio, &i, %str( ));
    %if %symexist(&macvar)=0 %then %let rc=0;
  %end;

  %* Return 1 if the macro variables for the custom step are defined.;
  &rc
%mend checkCustomStep;

/* Macro definitions for custom steps. */
%macro customStepRake;
  %local from to rc tz;

  %if not %checkCustomStep=1 %then
    %return;
    
  %if %length(&cs_custom_step)>0 %then %do;
    %extractTemplatesSAS(path=&cs_custom_step, macvar=rc, debug=0);
    %return;
  %end;

  %if &radioFrom=REL %then 
    %let from="&cs_rel_from";
  %else %if &radioFrom=ABS %then
    %let from="&cs_abs_from";

  %if &radioTo=REL %then
    %let to="&cs_rel_to";
  %else %if &radioTo=ABS %then
    %let to="&cs_abs_to";

  %let tz=%scan(&cs_tz, 1, %str( ));;
    
  %rake(
    user=&cs_user,
    password=&cs_password,
    from=&from,
    to=&to,
    tz=&tz,
    %if %symexist(cs_out) %then %do;
      out=&cs_out,
    %end;
    %if %symexist(cs_query) %then %do;
      query=&cs_query,
    %end;
    debug=&cs_debug,
    verbose=&cs_verbose,
    freq=&cs_freq,
    check=&cs_check, 
    %if %symexist(cs_message) & %length(&cs_message)>0 %then %do;
      message="&cs_message",
    %end;
    folder="&cs_folder",
    filename="&cs_filename",
    reset=&cs_reset
  );
%mend customStepRake;

/* ---------------------------------------------------------------------
    End Macro Definitions
----------------------------------------------------------------------*/

/* ---------------------------------------------------------------------
    Execution Code
----------------------------------------------------------------------*/

%customStepRake;

/* ---------------------------------------------------------------------
    Clean up all defined macros etc.
----------------------------------------------------------------------*/

%sysmacdelete obscnt /nowarn;
%sysmacdelete checkds /nowarn;
%sysmacdelete varExist /nowarn;
%sysmacdelete LogDatasetVariables /nowarn;
%sysmacdelete rakeOutputFileName /nowarn;
%sysmacdelete makeOutputFile /nowarn;
%sysmacdelete createRakeConfig /nowarn;
%sysmacdelete _writeQuery /nowarn;
%sysmacdelete readRakeConfig /nowarn;
%sysmacdelete updateRakeConfig /nowarn;
%sysmacdelete deleteRakeConfig /nowarn;
%sysmacdelete getEncodedCredential /nowarn;
%sysmacdelete getRakeConfigKeyValue /nowarn;
%sysmacdelete readRakeConfigQueries /nowarn;
%sysmacdelete getRakeConfigCredential /nowarn;
%sysmacdelete getRakeConfigUrl /nowarn;
%sysmacdelete checkErrorPatterns /nowarn;
%sysmacdelete encodeCredential /nowarn;
%sysmacdelete obfuscate /nowarn;
%sysmacdelete deobfuscate /nowarn;
%sysmacdelete formatDateTime /nowarn;
%sysmacdelete tz2UtcOffset /nowarn;
%sysmacdelete json2ds /nowarn;
%sysmacdelete query /nowarn;
%sysmacdelete rakeFreqPlot /nowarn;
%sysmacdelete deleteData /nowarn;
%sysmacdelete rakeUp /nowarn;
%sysmacdelete resetSettings /nowarn;
%sysmacdelete rakeReset /nowarn;
%sysmacdelete _outKeyValue /nowarn;
%sysmacdelete rakeInfo /nowarn;
%sysmacdelete rakeInfoReset /nowarn;
%sysmacdelete rakeSearch /nowarn;
%sysmacdelete extractTemplatesSAS /nowarn;
%sysmacdelete rake /nowarn;
%sysmacdelete kumade /nowarn;
%sysmacdelete checkCustomStep /nowarn;
%sysmacdelete customStepRake /nowarn;

/* Collect global macro variables that start with "RAKE" */
%let _rakevars=;
proc sql noprint;
    select name
      into :_rakevars separated by ' '
    from sashelp.vmacro
    where scope='GLOBAL'
      and upcase(name) like 'RAKE%';
quit;

/* Delete */
%if %length(&_rakevars) > 0 %then %do;
    %put NOTE: RAKE macro variables = &_rakevars;
    %symdel &_rakevars / nowarn;
    %put NOTE: Deleted RAKE macro variables.;
%end;
%else %do;
    %put NOTE: No RAKE macro variables found.;
%end;

/* Restore source option. */
options &_source;
%symdel _source basic utc_from utc_to _rakevars /nowarn;
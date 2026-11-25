/* Data Quality - Enrichment: Get QKB Info and create QKBREF Tables */
/* This code must be run in the SAS COMPUTE context.
   It builds reference tables for the default QKB in SAS Compute */


/* Suppress logging to avoid getting Max Log size exceeded warning */
options nosource nonotes ; 


/* Create macro variables from custom step selections */
%let _dm_qkbOutLib = &qkbLibName; 
%let _dm_tempQkbOutPath = &qkbLibPath; 


/* Parse parts of the selected qkbOutPath */
%let fileLoc=%qscan(&_dm_tempQkbOutPath,1,:);
%put QKB File Location: &fileLoc;
%let _dm_qkbOutPath="%qscan(&_dm_tempQkbOutPath,2,:)";
%put QKB File Path: &_dm_qkbOutPath;

 

/* Macro to get QKB information and tokens */
%macro dqputloc_dqref(loc, short=0, parsedefn=1); 
   /* Save the current value of the NOTES/NONOTES option
      and then turn notes off. */
   %let dqnotes = %sysfunc(getoption(NOTES));
   options nosource nonotes;

   /* Save the current value of the PAGESIZE option
      and then increase the value to avoid pagebreaks in the
      dqLocaleInfoList output. */
   %let dqps = %sysfunc(getoption(PS));
   options ps=32767;
   
   /* Prepare the LISTLOC value, uppercasing it, and transforming it into
      the actual locale value if one wasn't passed in. */
   %let listloc=%trim(%upcase(&loc));
   %if &listloc= %then %do;
      data _null_;
         x=dqlocaleinfoget('loaded');
         call symput('listloc', trim(scan(x, 1, ',')));
      run;
   %end;
   
   /* Check to make sure that the specified locale is loaded. */
   data _null_;
      x=upcase(dqlocaleinfoget('loaded'));
      call symput('loaded', trim(x));
      if index(x, "&listloc") = 0 then call symput('error', 1);
      else call symput('error', 0);
   run;
   
   /* If the specified locale is not loaded, error out. */
   %if &error=1 %then %do;
      %put ERROR: You specified a locale that is not loaded (&listloc).;
      %put ERROR: The loaded locales are (&loaded).;
      %put ERROR: The DQPUTLOC macro is terminating.;
   %end;
   /* If the specified locale is loaded, then proceed. */
   %else %do;
      /* Allocate a temporary file (in this case, actually a
            source entry in the work library so that it will be
            consistent from host to host, and it will automatically
            be removed when SAS exits). */
      filename dqtmp catalog 'work.temp.dqtmp.source';
   
      /* Re-direct the log to the source entry. */
      proc printto log=dqtmp new;
      run;
   
      /* Get the number of definitions written to help in parsing
         the output. */
      data _null_;
         numdefns=dqLocaleInfoList('ALL', "&listloc");
         call symput('numdefns', left(put(numdefns, 5.)));
      run;
   
      /* Stop the redirection. */
      proc printto;
      run;
   
      /* Read the definitions from the source entry. */
      data definitions(drop=line i done j tokens);
         length line operation defnname $ 200;
         length tokens $ 5000 token $ 50 parsedefn $ 50;
         infile dqtmp truncover;
         input line $char200.;
         if line =:'OPERATION: ' then do;
            input; /* Advance past the line of dashes. */
            do i=1 to &numdefns;
               input line $char200.;
               operation=scan(line, 1, ':');
               defnname=left(scan(line, 2, ':'));
               parsedefn = '';
               tokens='';
               token='';
   
               /* Get the tokens associated with a parse definition. */
               if operation='PARSE' then do;
                  tokens=dqParseInfoGet(defnname, "&listloc");
   
                  done=0;
                  j=1;
                  do until(done);
                     token=scan(tokens, j, ',');
                     if token='' then done=1;
                     else output;
                     j+1;
                  end;
               end;
   
               /* Get the tokens associated with an extraction definition. */
               if operation='EXTRACTION' then do;
                  tokens=dqExtInfoGet(defnname, "&listloc");
   
                  done=0;
                  j=1;
                  do until(done);
                     token=scan(tokens, j, ',');
                     if token='' then done=1;
                     else output;
                     j+1;
                  end;
               end;
   
               /* Get the tokens associated with an identification definition. */
               if operation='IDENTIFICATION' then do;
                  tokens=dqIdentifyInfoGet(defnname, "&listloc");
   
                  done=0;
                  j=1;
                  do until(done);
                     token=scan(tokens, j, ',');
                     if token='' then done=1;
                     else output;
                     j+1;
                  end;
               end;
   
               /* Get the parse definition associated with a match
                  definition (if any). */
               else if operation='MATCH' then do;
                  if &parsedefn=1 then
                     parsedefn=dqMatchInfoGet(defnname, "&listloc");
                  else parsedefn='';
               end;
   
               /* Get the parse definition associated with a gender
                  definition (if any). */
               else if operation='GENDER' then do;
                  if &parsedefn=1 then
                     parsedefn=dqGenderInfoGet(defnname, "&listloc");
                  else parsedefn='';
               end;
   
               if (tokens eq '' or token ne '') then output;
            end;
            stop;
         end;
      run;
   
      /* Sort the data. */
      proc sort data=definitions;
         by operation defnname;
      run;
   
      /* Read the data back in and generate the report to the SAS Log. */
      data _null_;
         set definitions;
         by operation defnname;
         length mixedop $ 100;
   
         /* Header for the whole report. */
         if _n_=1 then do;
            put //
                "The definitions in the &listloc locale are as follows: "
                /;
         end;
   
         mixedop=substr(operation,1,1) || lowcase(substr(operation,2));
   
         /* Header for each operation. */
         if first.operation then do;
            /* Generate the long version of the header for each
               definition type. */
            if &short=0 then do;
               put @1 '/*----------------------------------'
                      '--------------------------------*/';
               put @1 '/*' +1 operation "DEFINITION(S)" @69 '*/';
               put @1 '/*' @69 '*/';
               put @1 '/*'
                   +1 mixedop
                   'definitions are used by the following:' @69 '*/';
   
               /* Generate the static text for each definition type. */
               if operation = 'PARSE' then do;
                  put @1 '/*' @7 'dqParse function' @69 '*/';
                  put @1 '/*' @7 'dqParseInfoGet function' @69 '*/';
                  put @1 '/*' @7 'dqParseTokenGet function' @69 '*/';
                  put @1 '/*' @7 'dqParseTokenPut function' @69 '*/';
                  put @1 '/*' @7 'dqToken function' @69 '*/';
   
               end;
               else if operation = 'MATCH' then do;
                  put @1 '/*'
                      @7 'dqMatch function'
                      @69 '*/';
                  put @1 '/*'
                      @7 'dqMatchParsed function'
                      @69 '*/';
                  put @1 '/*'
                      @7 'dqMatchInfoGet function'
                      @69 '*/';
                  put @1 '/*'
                      @7 'DQMATCH procedure, CRITERIA statement'
                      @69 '*/';
                  put @1 '/*'
                      @7 'DQSCHEME procedure, CREATE statement'
                      @69 '*/';
               end;
               else if operation = 'GENDER' then do;
                  put @1 '/*' @7 'dqGender function' @69 '*/';
                  put @1 '/*' @7 'dqGenderParsed function' @69 '*/';
               end;
               else if operation = 'STANDARDIZATION' then do;
                  put @1 '/*' @7 'dqStandardize function' @69 '*/';
               end;
               else if operation = 'IDENTIFICATION' then do;
                  put @1 '/*' @7 'dqIdentify function' @69 '*/';
               end;
               else if operation = 'CASE' then do;
                  put @1 '/*' @7 'dqCase function' @69 '*/';
               end;
               else if operation = 'GUESS' then do;
                  put @1 '/*' @7 'dqLocaleGuess function' @69 '*/';
               end;
               else if operation = 'PATTERN' then do;
                  put @1 '/*' @7 'dqPattern function' @69 '*/';
               end;
               else if operation = 'EXTRACTION' then do;
                  put @1 '/*' @7 'dqExtract function' @69 '*/';
                  put @1 '/*' @7 'dqExtInfoGet function' @69 '*/';
                  put @1 '/*' @7 'dqExtTokenGet function' @69 '*/';
                  put @1 '/*' @7 'dqExtTokenPut function' @69 '*/';
               end;
   
               put @1 '/*----------------------------------'
                      '--------------------------------*/';
            end;
   
            /* Generate the short version of the header for each
               definition type. */
            else do;
               put @1 operation "DEFINITION(S):";
            end;
         end;
   
         /* First print out each definition name... */
         if first.defnname then
            put @5 defnname;
   
         /* ...and then if it is a parse, match or gender definition which
            has additional info, print that too. */
         if operation='PARSE' then
            put @8 'Token: ' token;
         else if operation='EXTRACTION' then
            put @8 'Token: ' token;
         else if operation='IDENTIFICATION' then
            put @8 'Token: ' token;
         else if operation='MATCH' and parsedefn ne '' then
            put @8 'The associated parse definition is "'
                parsedefn +(-1) '".';
         else if operation='GENDER' and parsedefn ne '' then
            put @8 'The associated parse definition is "'
                parsedefn +(-1) '".';
   
         /* Print out blank lines after each definition and after each
            operation. */
         if last.defnname then put;
         if last.operation then put;
      run;
   %end;
   
   /* Reset NOTES/NONOTES and PAGESIZE to the original values. */
   options &dqnotes ps=&dqps;
   
%mend dqputloc_dqref;


/* This macro gets all the QKB locale and definition information
   from the active QKB on the SAS Compute environment.  
   This is specified using the configuration option -DQSETUPLOC
*/
%macro _dm_getQKBInfoCompute;

   %global _dm_existsQKB _dm_existsQKB _dm_qkbCountInRepo _dm_numLocales _dm_allLocales _dm_qkbOutLib;

   /* If no output library specified then write Compute QKB info out to WORK dir */
   %if &_dm_qkbOutLib eq %then %do; %let _dm_qkbOutLib = %str(WORK); %end;

   /* Get the system options to ensure a QKB is loaded */
   proc optsave out = &_dm_qkbOutLib.._dm_options;
   run;

   /* Check if a system-set QKB exists */
   proc sql noprint;
      select count(OPTVALUE) into :_dm_existsQKB from &_dm_qkbOutLib.._dm_options where OPTNAME = "DQSETUPLOC";
   quit;

   /* If no QKB in the repo */
   %if &_dm_existsQKB. eq 0 %then %do;
      %put QKB is not referenced;
   %end;

   /* Else the QKB system default is referenced */
   %else %do;

      /* Get the list of the QKBs in the repo */
      proc QKB;
         LIST OUT = &_dm_qkbOutLib.._dm_qkbListOutAll;
      run;

      /* Check if the QKB is actually in the repo. */
      proc sql noprint;
         select count(quote(trim(QKB))) into :_dm_qkbCountInRepo from &_dm_qkbOutLib.._dm_qkbListOutAll where not missing(QKB);
      quit;

      /* If we have a qkb in the repo */
      %if &_dm_qkbCountInRepo. > 0 %then %do;

         /* Create base table to hold all definition info */
         data &_dm_qkbOutLib.._dm_defList (replace=yes);
            length Name $200 Type $200 Locale $5 Token $50;
         run;

         /* Create a base table for each definition type */
         %do idxCurrType = 1 %to &_dm_allDefTypesCount;
            %let currDefType=%scan(&_dm_allDefTypes,&idxCurrType,|);
            data &_dm_qkbOutLib.._dm_&currDefType.DefList (replace=yes);
               length Name $200 Type $200 Locale $5 Token $50;
            run;
         %end;

         /* Get the list of available locales */
         proc dqloclst out=&_dm_qkbOutLib.._dm_locList;
         run;

         /* Get the default QKB info */
         proc sql noprint;
            select trim(upcase(LOCALE)) into :_dm_allLocales separated by ' ' from &_dm_qkbOutLib.._dm_locList;
            select count(LOCALE) into :_dm_numLocales from &_dm_qkbOutLib.._dm_locList;
         quit;

         /* Loop through each locale */
         %let _dm_currLoc=;
         %do idxLoc = 1 %to &_dm_numLocales;

            /* Load the current locale to query its definitions */
            %let _dm_currLoc = %scan(&_dm_allLocales,&idxLoc,' ');
            %DQLOAD(DQLOCALE=(&_dm_currLoc));
            %dqputloc_dqref(&_dm_currLoc, PARSEDEFN=0, SHORT=1);

            /* Add the current locale as a var */
            data &_dm_qkbOutLib.._dm_definitions (replace=yes);
               /* Rename the Compute output column names to match CAS */
               set work.definitions (keep=operation defnname token rename=(operation=Type defnname=Name));
               Locale="&_dm_currLoc";
               /* Compute output is uppercase. CAS uses propercase. Normalize to propercase */
               Type = propcase(Type);
               /* Compute calls Locale Guess definitions Guess. Normalize to the
               CAS value, Locale Guess, which is more correct and specific. There is no
               ambiguity risk with Language Guess definitions because those cannot be
               surfaced in the QKB.
               */
               if Type = "Guess" then Type = "Locale Guess";
            run;

            /* Loop throught each definition type */
            %do idxCurrType = 1 %to &_dm_allDefTypesCount;

               /* Create dataset for this definition type */
               %let currDefType=%scan(&_dm_allDefTypes,&idxCurrType,|);
               data &_dm_qkbOutLib.._dm_currDefList (replace=yes where=(upcase(Type)=TRANWRD("&currDefType",'_',' ')));
                  set &_dm_qkbOutLib.._dm_definitions;
                  by Locale;
                  length Name_Tmp $200 Type_Tmp $200 Token_Tmp $50 Locale_Tmp $5;
                  Name_Tmp = Name;
                  Type_Tmp = Type;
                  Locale_Tmp = Locale;
                  Token_Tmp = token;
                  drop Name Type Locale token;
                  rename Name_Tmp=Name; rename Type_Tmp=Type; rename Locale_Tmp=Locale; rename Token_Tmp=Token;
               run;

               /* Append results to base definition type tables to accumulate definitions for each def type info for all locales */
               proc append base=&_dm_qkbOutLib.._dm_&currDefType.DefList force nowarn
                  data=&_dm_qkbOutLib.._dm_currDefList;
               run;

               /* Remove blank initial row after append operation */
               data &_dm_qkbOutLib.._dm_&currDefType.DefList;
                  set &_dm_qkbOutLib.._dm_&currDefType.DefList (where=(not missing(Locale)));
               run;

               /* Drop the temp table before the definition type loop increments */
               proc sql noprint;
                 drop table &_dm_qkbOutLib.._dm_currDefList;
               quit;

            %end; /* end %do idxCurrType = 1 %to &_dm_allDefTypesCount; */

            /* Append results to base definition table of all definitions for all locales */
            proc append base=&_dm_qkbOutLib.._dm_defList force nowarn
               data=&_dm_qkbOutLib.._dm_definitions;
            run;

            /* Drop the temp tables before the locale loop increments */
            proc sql noprint;
               drop table work.definitions, &_dm_qkbOutLib.._dm_definitions;
            quit;

            /* Unload all locales before next locale iteration */
            %DQUNLOAD;

         %end; /* end %do idxLoc = 1 %to &_dm_numLocales; */

         /* Remove blank initial row after append operation */
         data &_dm_qkbOutLib.._dm_defList;
            set &_dm_qkbOutLib.._dm_defList (where=(not missing(Locale)));
         run;

         /* The definitions output table of dqputloc has definition entries for each token of each parse or
         extraction definition. We dont need this info, so deduplicate the tables for these two definition types.
         */
         proc sort data=&_dm_qkbOutLib.._dm_PARSEDEFLIST nodup;
            by Locale;
         run;
         proc sort data=&_dm_qkbOutLib.._dm_EXTRACTIONDEFLIST nodup;
            by Locale;
         run;

      %end; /* end If we have a qkb in the repo */

   %end; /* end else the QKB system default is referenced */

   /* Delete temporary tables */
   proc datasets lib = &_dm_qkbOutLib. nolist nowarn memtype = (data view);
      delete _dm_options _dm_qkbListOutAll ;
   quit;

%mend _dm_getQKBInfoCompute;



/* This macro gets the list of QKB definitions */
%macro _dm_getQKBInfo;

   %global _dm_allDefTypes _dm_allDefTypesCount _dm_qkbListType _dm_qkbOutLib;

   /* Create macro variable to hold all definitions types */
   %let _dm_allDefTypes = CASE|EXTRACTION|GENDER|LOCALE_GUESS|IDENTIFICATION|MATCH|PARSE|PATTERN|STANDARDIZATION;
   %let _dm_allDefTypesCount = %eval(%sysfunc(countc(&_dm_allDefTypes,'|'))+1);

   %_dm_getQKBInfoCompute;

%mend _dm_getQKBInfo;


/* Create Final Tables for DQREF for Customized QKB */
%macro _dm_BuildDQREFTables;

  
	/* Create DM_LOC Table */
	proc sql ;
		create table &_dm_qkbOutLib..DM_LOCTEMP as
			SELECT x.Locale AS DM_LOCALE, y.DM_CNTRY_LONG,
			y.DM_LANG_LONG, y.DM_DESC, y.DM_LANG_SHORT,
			y.DM_CNTRY_SHORT from
			&_dm_qkbOutLib.._DM_LOCLIST as x 
    		left join SASDQREF.DM_LOC as y
			on x.Locale = y.DM_LOCALE ;
		quit ;

    /* delete DM_LOC table if exists */
	%if %sysfunc(exist(&_dm_qkbOutLib..DM_LOC)) 
		%then %do;
			proc delete data=&_dm_qkbOutLib..DM_LOC;
			run;
		%end;
 
	/* rename DM_LOC table */

	proc datasets library=&_dm_qkbOutLib;
    	change DM_LOCTEMP=DM_LOC;
	run;
		/* Delete Temporary Locale list table */
		proc datasets library=&_dm_qkbOutLib. nolist;
    		delete _DM_LOCLIST ;
		quit;


	/* Create macro variable to hold all definitions types */
	%let _dm_allTempTables = _DM_CASEDEFLIST|_DM_DEFLIST|_DM_EXTRACTIONDEFLIST|_DM_GENDERDEFLIST|_DM_IDENTIFICATIONDEFLIST|_DM_LOCALE_GUESSDEFLIST|_DM_MATCHDEFLIST|_DM_PARSEDEFLIST|_DM_PATTERNDEFLIST|_DM_STANDARDIZATIONDEFLIST ;
	%let _dm_allTablesCount = %eval(%sysfunc(countc(&_dm_allTempTables,'|'))+1);
	%let _dm_allFinalTables = DM_CADEF|DM_DEF|DM_EXDEF|DM_GNDEF|DM_IDDEF|DM_LGDEF|DM_MADEF|DM_PADEF|DM_PTDEF|DM_STDEF ;

	/* Create Final Definition Tables */
	%do idxCurrTable = 1 %to &_dm_allTablesCount;
		%let currTempTable=%scan(&_dm_allTempTables,&idxCurrTable,|);
		%let currFinalTable=%scan(&_dm_allFinalTables,&idxCurrTable,|);

    	/* Delete Final table if exists */
		%if %sysfunc(exist(&_dm_qkbOutLib..&currFinalTable)) 
			%then %do;
				proc delete data=&_dm_qkbOutLib..&currFinalTable;
				run;
			%end;

		proc sql ;
			create table &_dm_qkbOutLib..&currFinalTable as
				SELECT x.Name AS DM_NAME, 
    			x.Type AS DM_TYPE, 
    			x.Locale AS DM_LOCALE, y.DM_CNTRY_LONG,
				y.DM_LANG_LONG, y.DM_DESC, y.DM_LANG_SHORT,
				y.DM_CNTRY_SHORT, x.Token as DM_TOKENS from
				&_dm_qkbOutLib..&currTempTable as x 
    			left join &_dm_qkbOutLib..DM_LOC as y
				on x.Locale = y.DM_LOCALE ;
		quit ;

		/* Delete Temporary Data Sets */
		proc datasets library=&_dm_qkbOutLib. nolist;
    		delete &currTempTable ;
		quit;

	%end;

	/* Create Data Masking Table based on Definition Names from Standardization Table */
	data &_dm_qkbOutLib..DM_MKDEF ;
    	set &_dm_qkbOutLib..DM_STDEF ;
    	where upcase(scan(DM_NAME,1)) in ("MASK","ANONYMIZE","TRUNCATE") ;
	run ;

	/* Fix Identification Analysis Table for Identities that have Commas */
    proc sql ;
		update &_dm_qkbOutLib..DM_IDDEF
		set DM_TOKENS = 'CONGO, DEMOCRATIC REPUBLIC OF'
		where DM_TOKENS = ' DEMOCRATIC REPUBLIC OF' ;

		update &_dm_qkbOutLib..DM_IDDEF
		set DM_TOKENS = 'MICRONESIA, FEDERATED STATES OF'
		where DM_TOKENS = 'MICRONESIA' ;

		delete from &_dm_qkbOutLib..DM_IDDEF where DM_TOKENS = ' FEDERATED STATES OF' ;

		update &_dm_qkbOutLib..DM_IDDEF
		set DM_TOKENS = 'IRAN, ISLAMIC REPUBLIC OF'
		where DM_TOKENS = 'IRAN' ;

		delete from &_dm_qkbOutLib..DM_IDDEF where DM_TOKENS = ' ISLAMIC REPUBLIC OF' ;

		update &_dm_qkbOutLib..DM_IDDEF
		set DM_TOKENS = "KOREA, DEMOCRATIC PEOPLE'S REP"
		where DM_TOKENS = " DEMOCRATIC PEOPLE'S REP" ;

		update &_dm_qkbOutLib..DM_IDDEF
		set DM_TOKENS = 'KOREA, REPUBLIC OF'
		where DM_TOKENS = 'KOREA' ;

		update &_dm_qkbOutLib..DM_IDDEF
		set DM_TOKENS = 'MOLDOVA, REPUBLIC OF'
		where DM_TOKENS = 'MOLDOVA' ;

		delete from &_dm_qkbOutLib..DM_IDDEF where DM_TOKENS = ' REPUBLIC OF' ;

		update &_dm_qkbOutLib..DM_IDDEF
		set DM_TOKENS = 'PALESTINIAN TERRITORY, OCCUPIED'
		where DM_TOKENS = 'PALESTINIAN TERRITORY' ;

		delete from &_dm_qkbOutLib..DM_IDDEF where DM_TOKENS = ' OCCUPIED' ;

		update &_dm_qkbOutLib..DM_IDDEF
		set DM_TOKENS = 'VIRGIN ISLANDS, BRITISH'
		where DM_TOKENS = ' BRITISH' ;

		update &_dm_qkbOutLib..DM_IDDEF
		set DM_TOKENS = 'VIRGIN ISLANDS, U.S'
		where DM_TOKENS = ' U.S' ;

		delete from &_dm_qkbOutLib..DM_IDDEF where DM_TOKENS = 'VIRGIN ISLANDS' ;
	quit;

	/* Remove duplicate rows from DM_IDDEF */
	proc sql ;
		create table &_dm_qkbOutLib..DM_IDDEF_NoDupes as
 		select DISTINCT * from &_dm_qkbOutLib..DM_IDDEF;
	quit ;
	proc datasets lib=&_dm_qkbOutLib;
		delete DM_IDDEF ;
		change DM_IDDEF_NoDupes = DM_IDDEF ;
	quit;

%mend _dm_BuildDQREFTables;



/*Perform this section if Path Location is SAS Content */
%if &fileLoc=sascontent %then %do; 
	%put ERROR: You must select a path on the SAS Server;
    %let _dm_qkbOutPath=INVALID;
%end ; /* end if Path Location is SAS Content */

/* check if path exists on the SAS server */
%let _dm_path_exists=%sysfunc(fileexist(&_dm_qkbOutPath));
/* If path doesn't exist */
%if &_dm_path_exists. eq 0 %then %do;
	%put ERROR: Specified path for the library does not exist on the SAS Server;
%end; /* end if path does not exist */
	/* If path exists */
	%else %do;
		/* Create library for DQREF Tables */
		libname &_dm_qkbOutLib &_dm_qkbOutPath;  

		%_dm_getQKBInfo;  /* Write QKB Info to Temp Tables */
		%_dm_BuildDQREFTables;  /* Write QKB Info to Final Tables */


	%end ; /* end if path exists */


/* END OF PROGRAM */
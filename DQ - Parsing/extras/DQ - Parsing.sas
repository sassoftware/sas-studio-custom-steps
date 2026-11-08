/*set QKB locale for the step*/
%DQLOAD(DQLOCALE=(&_locale));

/* Macro to set which definition set was used */
%macro setDefinition();
	%if &_locale = ENUSA %then &_def170;
	%else %if &_locale = ENGBR %then &_def160;
	%else %if &_locale = DEDEU %then &_def210;
	%else %if &_locale = FRFRA %then &_def220;
	%else %if &_locale = ITITA %then &_def260;
	%else %if &_locale = ESESP %then &_def400;
	%else %do ;
		data _null_;
			put "Error: No Locale defined for Parsing!"; 
			abort;
		run;
	%end ;	
%mend setDefinition;
%let definition= %setDefinition();

%macro step_dqParse();
	data work._dqparsingtokens;
		length tokens $500;
		tokens=dqParseInfoGet("&definition", "&_locale");
	run;
	
	data _null_;
		set work._dqparsingtokens;
		length token varname $50;
		length varlist $1500;
		length stmt $150;
	
		varlist= '';
		i= 0;
		do until(token=' ') ;
			i= i+1;
			token= scan(tokens, i, ',');
			varname= tranwrd(token, "/", "_");
			varname= tranwrd(varname, "-", "_");
			varname= tranwrd(strip(varname), " ", "_");
			/* Adding prefix T_ for token to have a better chance that the token column name is unique */
			varname= "T_" || varname;
	
			if token ne ' ' then do;
				varlist= catx(' ', varlist, varname);	
				stmt= strip(varname) || '= dqParseTokenGet(parsedValue, "' || strip(token) || '", "&definition", "&_locale")';
				call symput(cat('stmt', i) , stmt);
			end;
		end;
		call symput('varlist', varlist);
		call symput('maxTokens', i-1);	
	run;
	
	data &_outputtable1;
		length parsedValue &varlist $250;
		set &_inputtable1;
		drop parsedValue;
		parsedValue=dqParse(&_parsecolumn, "&definition", "&_locale");
		%do i=1 %to &maxTokens;
			&&stmt&i;
		%end ;		
	run;

	proc delete data=work._dqparsingtokens; run;
%mend step_dqParse;

%step_dqParse();
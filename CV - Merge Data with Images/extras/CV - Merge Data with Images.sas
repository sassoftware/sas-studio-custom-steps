/*-----------------------------------------------------------------------------------------*
Macro to check if a given libref belongs to a SAS or CAS engine.
 *------------------------------------------------------------------------------------------*/
%if "%upcase(&insert_outtabname_engine)" ne "CAS" %then %do;

	data _null_;
		putlog "ERROR: The selected table is not a CAS table.";
		putlog "ERROR: Please select a library that points to a caslib.";
		abort 42;
	run;

%end;
%else %do;
	%let _tm_nameCaslib=%sysfunc(getlcaslib(&insert_outtabname_lib));
	%put CASLIB name: &_tm_nameCaslib;
%end;

%if "%upcase(&_annotationtbl__engine)" ne "CAS" %then %do;

	data _null_;
		putlog "ERROR: The selected table is not a CAS table.";
		putlog "ERROR: Please select a library that points to a caslib.";
		abort 42;
	run;

%end;
%else %do;
	%let _tm_nameCaslib=%sysfunc(getlcaslib(&_annotationtbl__lib));
	%put CASLIB name: &_tm_nameCaslib;
%end;

%if "%upcase(&_inImgtbl__engine)" ne "CAS" %then %do;

	data _null_;
		putlog "ERROR: The selected table is not a CAS table.";
		putlog "ERROR: Please select a library that points to a caslib.";
		abort 42;
	run;

%end;
%else %do;
	%let _tm_nameCaslib=%sysfunc(getlcaslib(&_inImgtbl__lib));
	%put CASLIB name: &_tm_nameCaslib;
%end;

proc cas;
	_verify_jointype="&_jointypeoption_";

	/* yes no */
	if _verify_jointype="APPEND" then do;
		deepLearn.dlJoin / annotatedTable={name="&_annotationtbl__name", 
			caslib="&_annotationtbl__lib"} casOut={name="&insert_outtabname_name", 
			replace=1, caslib="&insert_outtabname_lib"} joinType="&_jointypeoption_"
			table={name="&_inImgtbl__name", caslib="&_inImgtbl__lib"};
	end;

	if _verify_jointype ne "APPEND" then do;
		deepLearn.dlJoin / annotatedTable={name="&_annotationtbl__name", 
			caslib="&_annotationtbl__lib"} casOut={name="&insert_outtabname_name", 
			replace=1, caslib="&insert_outtabname_lib"} id="&_insert_varjoin"
			joinType="&_jointypeoption_"
			table={name="&_inImgtbl__name", caslib="&_inImgtbl__lib"};
	end;
quit;

%SYMDEL _tm_nameCaslib;
cas import_shape;
caslib _all_ assign;
options MSGLEVEL=I;
option casdatalimit=all mprint symbolgen;
%let SHAPE = %scan("&fileorfolderselector1", 3, ":", "MO");

/*-----------------------------------------------------------------------------------------*
   This macro creates a global macro variable called _usr_nameCaslib
   that contains the caslib name (aka. caslib-reference-name) associated with the libname 
   and assumes that the libname is using the CAS engine.

   As sysvalue has a length of 1024 chars, we use the trimmed option in proc sql
   to remove leading and trailing blanks in the caslib name.
   From macro provided by Wilbram Hazejager
*------------------------------------------------------------------------------------------*/

%macro _usr_getNameCaslib(_usr_LibrefUsingCasEngine); 

   %global _usr_nameCaslib;
   %let _usr_nameCaslib=;

   proc sql noprint;
      select sysvalue into :_usr_nameCaslib trimmed from dictionary.libnames
      where libname = upcase("&_usr_LibrefUsingCasEngine.") and upcase(sysname)="CASLIB";
   quit;

%mend _usr_getNameCaslib;

%macro reduce();

	%if "&usedshapeINFO" = "Yes" %then 
      %do;

		data _import_shape_;
		set &inputtable1;
		__seq__ = _n_;
		run;

		ods html ;
		title j=center color=Black "Example of map using "
		underlin=1 "&IDcolumn" 
		underlin=0 " as ID variable";

		proc gmap map=_import_shape_ data=_import_shape_ all;
		   id &IDcolumn;
		   choro &IDcolumn / discrete;
		run;

		ods html close;

		%if "&promotion" = "Yes" %then
	      %do;		

			/*-----------------------------------------------------------------------------------------*
			   Check Output table libref to ensure it points to a valid caslib.
			*------------------------------------------------------------------------------------------*/

		     %_usr_getNameCaslib(&outputtable1_lib.);
		     %let inputCaslib=&_usr_nameCaslib.;
		     %put NOTE: &inputCaslib. is the caslib for the output table.;
		     %let _usr_nameCaslib=;
		
		     %if "&inputCaslib." = "" %then %do;
		        %put ERROR: The output Library should refer to a valid CAS output. ;
		        %let _nctf_error_flag=1;
		     %end;
			
			proc casutil outcaslib="&outputtable1_lib" ;
				droptable casdata="&outputtable1_name" QUIET; 
			 	load data=_import_shape_ casout="&outputtable1_name" promote ;
				save  incaslib="&outputtable1_lib" casdata="&outputtable1_name" replace;
			quit;

		%end;
		
		%if "&reduceanalysis" = "Yes" %then
	      %do;
			
			proc  greduce data=_import_shape_ out=&outputtable1;
				id &IDcolumn;
			run;
	
			proc sql noprint;
				create table Info as
				select	t1.Density,
					count(Density) as N_Points
				from &outputtable1 t1
				group by Density;
			quit;
	
			data Info (keep= density N_Points_Cumulative);
			    set info;
			    by DENSITY;
				retain cum_N_Points;
			    cum_N_Points+N_Points;
				rename cum_N_Points = N_Points_Cumulative;
			run;

			ods html ;
			title j=center color=Black "Number of points for each density";
	
			proc print data=Info;
			run;

			ods html close;

		%end;

   %end;
   %else %if "&usedshapeINFO" = "No" %then
      %do;

		proc mapimport datafile="&SHAPE" out=_import_shape_;
			id &IDNAME;
		run;

		data _import_shape_;
			set _import_shape;
			__seq__ = _n_;
		run;

		ods html ;
		title j=center color=Black "Example of map using "
		underlin=1 "&IDNAME" 
		underlin=0 " as ID variable";

		proc gmap map=_import_shape_ data=_import_shape_ all;
		   id &IDNAME;
		   choro &IDNAME / discrete;
		run;

		ods html close;

		%if "&promotion" = "Yes" %then
	      %do;		

			/*-----------------------------------------------------------------------------------------*
			   Check Output table libref to ensure it points to a valid caslib.
			*------------------------------------------------------------------------------------------*/

		     %_usr_getNameCaslib(&outputtable1_lib.);
		     %let inputCaslib=&_usr_nameCaslib.;
		     %put NOTE: &inputCaslib. is the caslib for the output table.;
		     %let _usr_nameCaslib=;
		
		     %if "&inputCaslib." = "" %then %do;
		        %put ERROR: The output Library should refer to a valid CAS output. ;
		        %let _nctf_error_flag=1;
		     %end;
			
			proc casutil outcaslib="&outputtable1_lib" ;
				droptable casdata="&outputtable1_name" QUIET; 
			 	load data=_import_shape_ casout="&outputtable1_name" promote ;
				save  incaslib="&outputtable1_lib" casdata="&outputtable1_name" replace;
			quit;

		%end;
		
		%if "&reduceanalysis" = "Yes" %then
	      %do;
			
			proc  greduce data=_import_shape_ out=&outputtable1;
				id &IDNAME;
			run;
	
			proc sql noprint;
				create table Info as
				select	t1.Density,
					count(Density) as N_Points
				from &outputtable1 t1
				group by Density;
			quit;
	
			data Info (keep= density N_Points_Cumulative);
			    set info;
			    by DENSITY;
				retain cum_N_Points;
			    cum_N_Points+N_Points;
				rename cum_N_Points = N_Points_Cumulative;
			run;

			ods html ;
			title j=center color=Black "Number of points for each density";
	
			proc print data=Info;
			run;

			ods html close;
	
		%end;

	%end;

%mend reduce;

%reduce();



%macro Clean();

	proc delete data=work.Info; run;
	proc delete data=work._import_shape_; run;
	
	%if %symexist(SHAPE) %then %do;  	
		%symdel SHAPE; 
	%end;

	%if %symexist(promotion) %then %do;  	
		%symdel promotion; 
	%end;

%mend Clean;

%Clean();
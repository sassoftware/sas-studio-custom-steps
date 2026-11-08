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

data _reduced_shape_;
	set &inputtable1;
	where DENSITY <= &densitylevel;
run;

cas reduce_shape;
caslib _all_ assign;
options MSGLEVEL=I;
option casdatalimit=all mprint symbolgen;

%macro Promotion();

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
		 	load data=_reduced_shape_ casout="&outputtable1_name" promote ;
			save  incaslib="&outputtable1_lib" casdata="&outputtable1_name" replace;
		quit;

%end;

%mend Promotion;

%Promotion();

%macro Clean();

	proc delete data=work._reduced_shape_; run;
	
	%if %symexist(densitylevel) %then %do;  	
		%symdel densitylevel; 
	%end;

	%if %symexist(promotion) %then %do;  	
		%symdel promotion; 
	%end;

%mend Clean;

%Clean();


/*****************************************************************/
/*                                                               */
/* Loads a table into CAS memory converting chars to varchars    */
/*                                                               */
/* Parameters:                                                   */
/*              inlib     - input library                        */
/*              intab     - input table                          */
/*              outlib    - output library (must be a CASLib)    */
/*              outtab    - output table (must be a CAS Table)   */
/*   (optional) indexVars - variables to build indexes on        */
/*   (optional) Selcompress  - compress the output table            */
/*                                                               */
/* 1) The input table is copied into the CASUSER library while   */
/*    incoming CHAR variables are assigned new VARCHAR ones.     */
/*    Only CHAR variables with length >16 are changed to VARCHAR */
/*    If requested the result table is compressed or promoted    */
/* 2) If indexVars have been provided the table is indexed.      */
/* 3) If the output table exists is dropped                      */
/*****************************************************************/


%macro makeItVarChar();

%let inlib=%scan(&inputtable1,1);
%let intab=%scan(&inputtable1,2);

%let outlib=%scan(&outputtable1,1);
%let outtab=%scan(&outputtable1,2);

%if %str(&outputtable1_engine) ^= CAS %then %do;
		%put ">>>>>>>    The OUTPUT ENGINE IS NOT CAS >>>>>>>>>>";;
%end;
	
	   %if %sysfunc(exist(work._cnts_out_)) %then %do;
		    proc delete   data=work._cnts_out_; run;
       %end;
	
		%if %sysfunc(exist(&outlib..&outtab)) %then %do;
			proc casutil; 
  				droptable casdata="&outtab" incaslib=&outlib quiet; 
	 		run; 
		%end;

      proc contents data=&inlib..&intab out=work._cnts_out_(where=(TYPE=2 and length > 16) keep=TYPE NAME LENGTH FORMAT INFORMAT) noprint; run;

	  /* %let obs=1; */
	  
  	  data _null_; 
		if 0 then set work._cnts_out_ nobs=o;
		call symput ('obs', o);
		put o=;
		stop;
	  run;
		
	 

	  %if &obs > 0 %then %do;
		  /**************************************************/
		  /* RENAMES CHAR VARIABLES TO TEMPORARY VARS       */
		  /**************************************************/

		  filename f temp;

		  data _null_; set work._cnts_out_(keep=name) end=eof;
				file f;
				if (_n_=1) then put "data  &outlib..&outtab (compress=&Selcompress); set &inlib..&intab (rename=(";

				length txt $65;
				txt = strip(name) || "=_" || strip(_n_);
				put txt;

				if eof then put "));";
		  run;

		  /**************************************************/
		  /* DECLARE VARCHARS                               */
		  /**************************************************/

		  data _null_; set work._cnts_out_(keep=name length) end=eof;
				file f mod;
				if (_n_=1) then put "length";

				length txt $48;
				txt = strip(name) || " varchar(" || strip(length) || ")";
				put txt;

				if eof then put ";";
		  run;

		  /**************************************************/
		  /* ASSIGNS TRIMMED VALUES TO VARCHARS             */
		  /**************************************************/

		  data _null_; set work._cnts_out_(keep=name);
				file f mod;
				length txt $74;
				txt = strip(name) || "=strip(_" || strip(_n_) || ");";
				put txt;
		  run;

		  /**************************************************/
		  /* DROPS $ FORMATS / INFORMATS FOR VARCHARS       */
		  /**************************************************/

		  data _null_; set work._cnts_out_(keep=name format where=(format="$")) end=eof;
				file f mod;
				if (_n_=1) then put "format";
				put name;
				if eof then put ";";
		  run;

		  data _null_; set work._cnts_out_(keep=name informat where=(informat="$")) end=eof;
				file f mod;
				if (_n_=1) then put "informat";
				put name;
				if eof then put ";";
		  run;

		  /**************************************************/
		  /* DROPS TEMPARY VARIABLES                        */
		  /**************************************************/

		  data _null_; set work._cnts_out_(drop=type) end=eof;
				file f mod;
				if (_n_=1) then put "drop";
				length txt $32;
				txt = "_" || strip(_n_);
				put txt;
				if eof then put ";";
		  run;

		  data _null_;
				file f mod;
				put "run;";
		  run;

		  %include "%sysfunc(pathname(f))";
		  filename f clear;
	  %end;
	  %else %do;
		  data &outlib..&outtab(compress=&Selcompress); set &inlib..&intab; run;
	  %end;

      %if %eval(&SelIndexVars_count) > 0 %then %do;
			data _null_; 
				length a $32000; 
				%do i=1 %to &SelIndexVars_count;  
					%if %eval(&i) > 1 %then			 
						a=cat(strip(a),'","',"&&SelIndexVars_&i._name"); 
					%else 
						a="&&SelIndexVars_&i._name"; 
						; 
				%end; 
				
					a=cat('"',strip(a),'"');; 
					put a=; 
					 
					call SYMPUT("IndexVars",strip(a)); 
				run; 
			
			%put &IndexVars=;
            proc cas;
                  table.index /
                        table  = {caslib="&TargetCasLib", name="&outtab"}
                        casout = {caslib="&TargetCasLib", name="&outtab", replace=true, indexVars={&indexVars}}
                  ;
            quit;
      %end;

	  %if %str(&SelPromote) = Yes %then %do;
	      proc casutil;
	            promote   incaslib="&outlib" casdata="&outtab" outcaslib="&outlib" casout="&outtab"; run;
	      quit;
	  %end;

      proc cas;
            table.tableInfo /
                  caslib="&outlib" name="&outtab";
            table.tableDetails /
                  caslib="&outlib" name="&outtab" level="NODE";
      quit;

%mend;

%makeItVarChar();                
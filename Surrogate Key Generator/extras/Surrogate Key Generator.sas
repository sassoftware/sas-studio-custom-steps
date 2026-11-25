/*==========================================================================* 
 * Custom Step:     Surrogate Key Generator                                 * 
 * Transform:       Surrogate Key Generator                                 * 
 * Description:     Generates a unique key value for a set of business key  * 
 *                   values.                                                * 
 *==========================================================================*/
%macro etls_recordCheck;
	%let etls_recCheckExist = %eval(%sysfunc(exist(&inputtable1, DATA)) or 
		%sysfunc(exist(&inputtable1, VIEW)));

	%if (&etls_recCheckExist) %then %do;
		%local etls_syntaxcheck;
		%let etls_syntaxcheck = %sysfunc(getoption(syntaxcheck));

		/* Turn off syntaxcheck option to perform following steps  */
		options nosyntaxcheck;

		proc contents data = &inputtable1 out = work.etls_contents(keep = nobs) noprint;
		run;

		data _null_;
			set work.etls_contents (obs = 1);
			call symput("etls_recnt", left(put(nobs,32.)));
		run;

		proc datasets lib = work nolist nowarn memtype = (data view);
			delete etls_contents;
		quit;

		/* Reset syntaxcheck option to previous setting  */
		options &etls_syntaxcheck;
	%end;
%mend etls_recordCheck;

%etls_recordCheck;

%macro createSurrogateKey;
	%local etls_maxkey i;
	%global businessKey_name surrogateKey_name surrogateKey;
	%let businessKey_name=;
	%let surrogateKey=&surrogateKey_name;
	options mprint;

	%do i=1 %to &businessKey_count;
		%let businessKey_name = &businessKey_name &&businessKey_&i._name;
	%end;

	%if (%nrquote(&outputtable1) ne ) %then %do;
		%let targetTable = &outputtable1;
	%end;

	%if (%nrquote(&targetTable) eq) %then %do;
		%put ERROR: Missing Target Table Option;
		%let sysrc=8000;
		%goto out;
	%end;

	%if (%nrquote(&surrogateKey) eq) %then %do;
		
		%put ERROR: Missing Surrogate Key Column Option;
		%let sysrc=8000;
		%goto out;
	%end;

	%if (%nrquote(&businessKey_name) eq) %then %do;
		%put ERROR: Missing Business Key Column Option;
		%let sysrc=8000;
		%goto out;
	%end;

	proc sort data = &inputtable1 
		out = work.etls_sortedSource
	;
		by &businessKey_name;
	run;

	%if %sysfunc(exist(&targetTable)) eq 1 %then %do;
		/* If physical target table exists, look up maximum surrogate key value used 
		*/
		proc sql noprint;
			select compress(put(max(&surrogateKey), best32.)) into :etls_maxKey 
				from &targetTable;
		quit;

		%if &syserr gt 0 and &syserr ne 4 %then %do;
			%rcset(&syserr);
			%put ERROR: Failed to get highest surrogate key value from column: &surrogateKey  in table: &targetTable;
			%goto out;
		%end;
	%end;

	%if (&etls_maxkey eq . or &etls_maxkey eq) %then
		%let etls_maxkey = 0;
	%put &etls_maxkey;

	%if %sysfunc(exist(&targetTable)) eq 1 %then %do;

		proc sort data=&targetTable out = work.etls_targetSorted;
			by &businessKey_name;
		run;

		%if &syserr gt 0 and &syserr ne 4 %then %do;
			%rcset(&syserr);
			%put ERROR: &syserr. Sort of &targetTable  failed, so it will not be replaced;
			%goto out;
		%end;

		proc datasets lib = %scan(&targetTable,1,.) nolist nowarn memtype = (data view);
			delete %scan(&targetTable,2,.);
		quit;

		data &targetTable;
			merge 
				work.etls_targetSorted(in = etls_inTarget)
				work.etls_sortedSource end=etls_lastRecord;
			by &businessKey_name;
			retain etls_newkey &etls_maxkey;
			drop etls_newkey  etls_inTarget etls_lastRecord;

			/* If just keeping input records, then when a record is read that is not in input table, return */
			/* without saving the record. */
			if not etls_inTarget then do;
				etls_newkey + 1;
				&surrogateKey = etls_newkey;
			end;

			if etls_lastRecord then
				call symput('etls_maxkey', trim(left(put(etls_newkey,15.))));
		run;

		proc datasets lib = work nolist nowarn memtype=(data view);
			delete etls_targetSorted;
		quit;

		proc datasets lib = work nolist;
			delete etls_sortedSource;
		quit;

	%end;
	%else %do;
		/* Target table does not exist yet. */
		data &targetTable;
			set etls_sortedSource end=etls_lastRecord;
			by &businessKey_name;
			retain etls_newkey &etls_maxkey;
			drop etls_newkey etls_lastRecord;

			/* If just keeping input records, then when a record is read that is not in input table, return */
			/* without saving the record. */
			etls_newkey + 1;
			&surrogateKey = etls_newkey;

			if etls_lastRecord then
				call symput('etls_maxkey', trim(left(put(etls_newkey,15.))));
		run;

		proc datasets lib = work nolist;
			delete etls_sortedSource;
		quit;
 	%end;

%out:
%mend;

%createSurrogateKey;
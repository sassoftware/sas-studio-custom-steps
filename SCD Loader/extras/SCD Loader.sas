/*==========================================================================* 
 * Custom Step:     SCD loader                                              * 
 * Transform:       SCD loader                                              * 
 * Description:     This macro loads a target table and captures Type 2 as  *
 *                  as well as Type 1 changes.                              *           
 *==========================================================================*/
%let BEGINDATE=&BEGINDATE_NAME;
%let ENDDATE=&ENDDATE_NAME;
%let GENERATEDKEY=&GENERATEDKEY_NAME;
%let CURRENTIND=&CURRENTIND_NAME;

%macro scdloader( begindate=
			,enddate=
			,etls_begdate=
			,etls_enddate=
			,businesskey=
			,generatedkey=
			,currentind=
			,detectchanges=
			,type1changes=
			,input_table1=
			,output_table1=
			,closeout=No
			,loopcol=
			,loopval=
			);
	%if (%sysfunc(exist(&output_table1.)) eq 0) %then %do;

		proc sql;
			%if %length(&loopcol.) = 0 %then %do;
				create table &output_table1. as
			%end;
			%else %do;
				create table &output_table1. (drop=&loopcol.)as
			%end;

			select
				. as &generatedkey. length = 8,
				*,
				. as &begindate. length = 8
				format = Datetime20.,
				. as &enddate. length = 8
				format = Datetime20.,
				"" as &currentind. length = 1
			from &input_table1. (obs=0)
			;
		quit;

	%end;

	/*---- Temporary cross reference table being used  ----*/
	/* Delete any existing temporary cross-reference table  */
	proc datasets lib = work nolist nowarn memtype = (data view);
		delete etls_sortedxref;
	quit;

	/* Sort target table records before creating the temporary cross reference  */
	/*  table:                                                                  */
	proc sort data = &output_table1(where = (&currentind. = 'Y'))
		out = work.etls_sortedxref(keep=&generatedkey. &businesskey. &begindate. &enddate. &currentind. &detectchanges.);
		by &businesskey.;
	run;

	%let etls_str = '"' ||KTRIM(KLEFT(%sysfunc(tranwrd(%quote(&detectchanges),%str( ),%str(%)%) || KTRIM%(KLEFT%())))) || '"';

	%if %length(&type1changes.) = 0 %then %do;

		/* Generate change digest (v1.1)  */
		data work.etls_sortedxref(keep = &generatedkey. &businesskey. &begindate. &enddate. DIGEST_VALUE);
			length etls_md5 $16.;
			length DIGEST_VALUE $32.;
			set work.etls_sortedxref;
			by &businesskey.;
			etls_str = &etls_str;
			etls_md5 = md5(etls_str);
			DIGEST_VALUE = put(etls_md5, hex32.);
		run;

	%end;
	%else %do;
		%let etls_str_type1 = '"' ||KTRIM(KLEFT(%sysfunc(tranwrd(%quote(&type1changes),%str( ),%nrstr(%)%) || ' ' || KTRIM%(KLEFT%())))) || '"';

		/* Generate change digest (v1.1)  */
		data work.etls_sortedxref(keep = &generatedkey. &businesskey. &begindate. &enddate. DIGEST_VALUE DIGEST_VALUE_TYPE1);
			length etls_md5 $16.;
			length DIGEST_VALUE $32.;
			length DIGEST_VALUE_TYPE1 $32.;
			set work.etls_sortedxref;
			by &businesskey.;
			etls_str = &etls_str.;
			etls_md5 = md5(etls_str);
			DIGEST_VALUE = put(etls_md5, hex32.);
			etls_str_type1 = &etls_str_type1.;
			etls_md5 = md5(etls_str_type1);
			DIGEST_VALUE_TYPE1 = put(etls_md5, $hex32.);
		run;

	%end;

	proc sql;
		%if %length(&loopcol.) = 0 %then %do;
			create table work.temp0 as
		%end;
		%else %do;
			create table work.temp0 (drop=&loopcol.) as
		%end;

		select
			. as &generatedkey. length = 8,
			*,
			. as &begindate. length = 8
			format = Datetime20.,
			. as &enddate. length = 8
			format = Datetime20.,
			"" as &currentind. length = 1
		from &input_table1.
			%if %length(&loopcol.) > 0 %then

			%do;
				where &loopcol. = &loopval.
			%end;
		;
	quit;

	%let SYSLAST = work.temp0;
	%let etls_lastTable = &SYSLAST;
	%let etls_tableOptions =;

	%if %length(&type1changes.) = 0 %then %do;

		/* Generate change digest (v1.1)  */
		data work.etls_source(drop=etls_str etls_md5 compress=no);
			set &syslast;
			length etls_md5 $16.;
			length DIGEST_VALUE $32.;
			etls_str = &etls_str.;
			etls_md5 = MD5(etls_str);
			DIGEST_VALUE=put(etls_md5, hex32.);
		run;

	%end;
	%else %do;

		/* Generate change digest (v1.1)  */
		data work.etls_source(drop=etls_str etls_md5  etls_str_type1 compress=no);
			set &syslast;
			length etls_md5 $16.;
			length DIGEST_VALUE $32.;
			length DIGEST_VALUE_TYPE1 $32.;
			etls_str = &etls_str.;
			etls_md5 = MD5(etls_str);
			DIGEST_VALUE=put(etls_md5, hex32.);
			etls_str_type1 = &etls_str_type1.;
			etls_md5 = MD5(etls_str_type1);
			DIGEST_VALUE_TYPE1 =put(etls_md5, $hex32.);
		run;

	%end;

	/* Generate the from date expression  */
	%let etls_begdate = &etls_begdate;

	/* Generate the default to date expression  */
	%let etls_enddate = &etls_enddate;

	/* Sort the source table by business key and beginning/from date columns.  */
	proc sort data=work.etls_source out=work.etls_source(compress=no);
		by &businesskey. &begindate.;
	run;

	%let last_word = %scan(&businesskey,-1,%str( ));

	/*---- Set beginning dates and close out any history records   ----*/
	data work.etls_source (drop = etls_sameday etls_cnt etls_closedate);
		set work.etls_source;
		by &businesskey.;

		/* Set beginning dates if null  */
		if &begindate. eq . then
			&begindate. = &etls_begdate.;

		if first.&last_word. then
			etls_cnt = 0;
		else etls_cnt + 1;

		/* Close out any history records if they exist  */
		if not last.&last_word. then do;
			obsnum = _n_ + 1;
			set work.etls_source(keep = &begindate.
				rename = (&begindate. = etls_closedate))
				point = obsnum;

			if etls_closedate eq . then
				etls_closedate = &etls_begdate;

			if &begindate. eq etls_closedate then
				etls_closedate = etls_closedate + (etls_cnt + 1);

			if &enddate. eq . then
				&enddate. = etls_closedate - 1;
		end;

		/* Fix the beginning dates if needed  */
		etls_sameday = lag1(&begindate.);

		if not first.&last_word. and etls_sameday eq &begindate. then
			&begindate. = &begindate. + etls_cnt;
	run;

	/*---- Generate the maximum generated key  ----*/
	/* Calculate the max generated key value and hold the value in the macro  */
	/*  variable &etls_maxkey                                                 */
	%let etls_maxkey = -1;

	proc sql noprint;
		select compress(put(max(&generatedkey.), best32.))
			into :etls_maxkey
				from &output_table1.;
	quit;

	/* If "etls_maxkey" does not have a value, then set it to zero.  */
	%if (&etls_maxkey eq .) %then
		%let etls_maxkey = 0;

	/*---- Slowly Changing Dimension Type 2 Beginning/End Date Method  ----*/
	/* Data merge the cross-reference and source tables  */
	data work.etls_newrcds
		(drop = ETLS_STGDIGEST DIGEST_VALUE NewMaxKey ETLS_KEY ETLS_FROMDATE 
		ETLS_CLSDATE ETLS_TODATE %if %length(&type1changes.) > 0 %then ETLS_TYPE1DIGEST DIGEST_VALUE_TYPE1;)
		work.etls_match
		(drop = ETLS_STGDIGEST DIGEST_VALUE NewMaxKey ETLS_KEY ETLS_FROMDATE 
		ETLS_CLSDATE ETLS_TODATE %if %length(&type1changes.) > 0 %then ETLS_TYPE1DIGEST DIGEST_VALUE_TYPE1;)
		work.etls_close
		(keep = ETLS_KEY ETLS_CLSDATE)
		%if %length(&type1changes.) > 0 %then %do;
			work.etls_type1
				(keep = ETLS_KEY &type1changes.)
		%end;
		;
		retain NewMaxKey &etls_maxkey;
		merge work.etls_source(in=inSort rename=(DIGEST_VALUE = ETLS_STGDIGEST %if %length(&type1changes.) > 0 %then DIGEST_VALUE_TYPE1 = ETLS_TYPE1DIGEST;))
		work.etls_sortedxref (in=inXref rename=(
		&generatedkey. = ETLS_KEY
		&begindate. = ETLS_FROMDATE
		&enddate. = ETLS_TODATE));
		by &businesskey.;
		attrib ETLS_CLSDATE length=8 format = Datetime20.;

		/* Process changes made to existing records  */
		if inSort and inXref then do;
			if last.&last_word. then
				&currentind. = 'Y';
			else &currentind. = 'N';

			if ETLS_STGDIGEST NE DIGEST_VALUE then do;
				if &begindate. eq . then
					&begindate. = &etls_begdate.;

				/* Ignore history records, only accept changes where the cross reference  */
				/*  beginning date is less than the source beginning date                 */
				if ETLS_FROMDATE < &begindate. then do;
					if &enddate. eq . then
						&enddate. = &etls_enddate.;

					/* Save off the close date  */
					if ETLS_TODATE = &etls_enddate. or ETLS_TODATE > &begindate. then do;
						if ETLS_FROMDATE < &begindate. then
							ETLS_CLSDATE = &begindate. - 1;
						else ETLS_CLSDATE = ETLS_FROMDATE;
						output work.etls_close;
					end;

					NewMaxKey = sum(NewMaxKey, 1);
					&generatedkey. = NewMaxKey;

					/* Overwrite the values to compare new records with from cross-reference   */
					/* variable values to the new current values from source  */
					DIGEST_VALUE = ETLS_STGDIGEST;
					ETLS_FROMDATE = &begindate.;
					ETLS_TODATE = &enddate.;
					output work.etls_match;
				end;
			end;/*  End of digest values not equal   */
			else do;
				if &enddate. ne . then do;

					/* If the cross-reference end date is greater then the source end date then  */
					/*  close out the target record with the source end date                     */
					if last.&last_word. then
						if ETLS_TODATE gt &enddate. then do;
						ETLS_CLSDATE = &enddate.;
						output work.etls_close;
					end;
				end;

				/* If the source beginning date is greater then both the cross-reference  */
				/*  beginning and end date, then reactivate the closed out record         */
				if &begindate. gt ETLS_FROMDATE and
					&begindate. gt ETLS_TODATE then do;
					if &enddate. eq . then
						&enddate. = &etls_enddate.;
					NewMaxKey = sum(NewMaxKey, 1);
					&generatedkey. = NewMaxKey;

					/* Update the cross-reference varaibles to the new current values  */
					DIGEST_VALUE = ETLS_STGDIGEST;
					ETLS_FROMDATE = &begindate.;
					ETLS_TODATE = &enddate.;
					output work.etls_match;
				end;

				%if %length(&type1changes.) > 0 %then %do;
				else do;

					/* Output to the type 1 work table if there are type 1 column changes  */
					if ETLS_TYPE1DIGEST NE DIGEST_VALUE_TYPE1 then
						if last.&last_word. then do;
						output work.etls_type1;
					end;
				end;
				%end;
			end;  /* End of digest values are equal  */
		end;  /* End of inSort and inXref  */

		/* Process new records  */
		else if inSort and not inXref then do;
			NewMaxKey = sum(NewMaxKey, 1);
			&generatedkey. = NewMaxKey;

			if last.&last_word. then
				&currentind. = 'Y';
			else &currentind. = 'N';

			if &begindate. eq . then
				&begindate. = &etls_begdate.;

			if &enddate. eq . then
				&enddate. = &etls_enddate.;
			output work.etls_newrcds;
		end;

		%if %upcase(&closeout.) = YES %then %do;

			/* Close out any records that are in the xref table but not in the source.  */
		else if inXref and not inSort then do;
			ETLS_CLSDATE = DATETIME();
			output work.etls_close;
		end;
		%end;
	run;

	/* Sort the output from the data merge step  */
	proc sort data=work.etls_close nodupkey;
		by ETLS_KEY;
	run;

	%if %length(&type1changes.) > 0 %then %do;

		proc sort data=work.etls_type1 nodupkey;
			by ETLS_KEY;
		run;

	%end;

	/* Save record counts into macro: 
		etls_updatecnt 
	*/
	%let etls_recCheckExist = 0;
	%let etls_updatecnt = 0;
	%macro etls_recordCheck;
		%let etls_recCheckExist = %eval(%sysfunc(exist(work.etls_close, DATA)) or 
			%sysfunc(exist(work.etls_close, VIEW)));

		%if (&etls_recCheckExist) %then %do;
			%local etls_syntaxcheck;
			%let etls_syntaxcheck = %sysfunc(getoption(syntaxcheck));

			/* Turn off syntaxcheck option to perform following steps  */
			options nosyntaxcheck;

			proc contents data = work.etls_close out = work.etls_contents(keep = nobs) noprint;
			run;

			data _null_;
				set work.etls_contents (obs = 1);
				call symput("etls_updatecnt", left(put(nobs,32.)));
			run;

			proc datasets lib = work nolist nowarn memtype = (data view);
				delete etls_contents;
			quit;

			/* Reset syntaxcheck option to previous setting  */
			options &etls_syntaxcheck;
		%end;
	%mend etls_recordCheck;
	%etls_recordCheck;

	/* Save record counts into macro: 
		etls_matchcnt 
	*/
	%let etls_recCheckExist = 0;
	%let etls_matchcnt = 0;
	%macro etls_recordCheck;
		%let etls_recCheckExist = %eval(%sysfunc(exist(work.etls_match, DATA)) or 
			%sysfunc(exist(work.etls_match, VIEW)));

		%if (&etls_recCheckExist) %then %do;
			%local etls_syntaxcheck;
			%let etls_syntaxcheck = %sysfunc(getoption(syntaxcheck));

			/* Turn off syntaxcheck option to perform following steps  */
			options nosyntaxcheck;

			proc contents data = work.etls_match out = work.etls_contents(keep = nobs) noprint;
			run;

			data _null_;
				set work.etls_contents (obs = 1);
				call symput("etls_matchcnt", left(put(nobs,32.)));
			run;

			proc datasets lib = work nolist nowarn memtype = (data view);
				delete etls_contents;
			quit;

			/* Reset syntaxcheck option to previous setting  */
			options &etls_syntaxcheck;
		%end;
	%mend etls_recordCheck;
	%etls_recordCheck;

	/* Save record counts into macro: 
		etls_newcnt
	*/
	%let etls_recCheckExist = 0;
	%let etls_newcnt = 0;
	%macro etls_recordCheck;
		%let etls_recCheckExist = %eval(%sysfunc(exist(work.etls_newrcds, DATA)) or 
			%sysfunc(exist(work.etls_newrcds, VIEW)));

		%if (&etls_recCheckExist) %then %do;
			%local etls_syntaxcheck;
			%let etls_syntaxcheck = %sysfunc(getoption(syntaxcheck));

			/* Turn off syntaxcheck option to perform following steps  */
			options nosyntaxcheck;

			proc contents data = work.etls_newrcds out = work.etls_contents(keep = nobs) noprint;
			run;

			data _null_;
				set work.etls_contents (obs = 1);
				call symput("etls_newcnt", left(put(nobs,32.)));
			run;

			proc datasets lib = work nolist nowarn memtype = (data view);
				delete etls_contents;
			quit;

			/* Reset syntaxcheck option to previous setting  */
			options &etls_syntaxcheck;
		%end;
	%mend etls_recordCheck;
	%etls_recordCheck;

	%if %length(&type1changes.) > 0 %then %do;

		/* Save record counts into macro: 
			etls_type1cnt
		*/
		%let etls_recCheckExist = 0;
		%let etls_type1cnt = 0;
		%macro etls_recordCheck;
			%let etls_recCheckExist = %eval(%sysfunc(exist(work.etls_type1, DATA)) or 
				%sysfunc(exist(work.etls_type1, VIEW)));

			%if (&etls_recCheckExist) %then %do;
				%local etls_syntaxcheck;
				%let etls_syntaxcheck = %sysfunc(getoption(syntaxcheck));

				/* Turn off syntaxcheck option to perform following steps  */
				options nosyntaxcheck;

				proc contents data = work.etls_type1 out = work.etls_contents(keep = nobs) noprint;
				run;

				data _null_;
					set work.etls_contents (obs = 1);
					call symput("etls_type1cnt", left(put(nobs,32.)));
				run;

				proc datasets lib = work nolist nowarn memtype = (data view);
					delete etls_contents;
				quit;

				/* Reset syntaxcheck option to previous setting  */
				options &etls_syntaxcheck;
			%end;
		%mend etls_recordCheck;
		%etls_recordCheck;
	%end;

	/* Save record counts into macro: 
		etls_recordsBefore
	*/
	%let etls_recCheckExist = 0;
	%let etls_recordsBefore = 0;
	%macro etls_recordCheck;
		%let etls_recCheckExist = %eval(%sysfunc(exist(&output_table1., DATA)) or 
			%sysfunc(exist(&output_table1., VIEW)));

		%if (&etls_recCheckExist) %then %do;
			%local etls_syntaxcheck;
			%let etls_syntaxcheck = %sysfunc(getoption(syntaxcheck));

			/* Turn off syntaxcheck option to perform following steps  */
			options nosyntaxcheck;

			proc contents data = &output_table1. out = work.etls_contents(keep = nobs) noprint;
			run;

			data _null_;
				set work.etls_contents (obs = 1);
				call symput("etls_recordsBefore", left(put(nobs,32.)));
			run;

			proc datasets lib = work nolist nowarn memtype = (data view);
				delete etls_contents;
			quit;

			/* Reset syntaxcheck option to previous setting  */
			options &etls_syntaxcheck;
		%end;
	%mend etls_recordCheck;
	%etls_recordCheck;

	%let etls_table = %nrquote(%scan(&output_table1.,2,.));
	%let etls_lib   = %nrquote(%scan(&output_table1.,1,.));

	%if %length(&type1changes.) > 0 %then %do;

		/* Check to see if the update counts are greater than zero  */
		%if &etls_updatecnt le 0 and &etls_matchcnt le 0 and &etls_newcnt le 0 and &etls_type1cnt le 0 %then
			%goto scdldout;
	%end;
	%else %do;

		/* Check to see if the update counts are greater than zero  */
		%if &etls_updatecnt le 0 and &etls_matchcnt le 0 and &etls_newcnt le 0 %then
			%goto scdldout;
	%end;

	/*---- Start of target table update  ----*/
	%if &etls_updatecnt gt 0 %then %do;

		data &output_table1.;
			modify &output_table1.
				work.etls_close
				(rename = (ETLS_KEY = &generatedkey.))
				updatemode=nomissingcheck;
			by &generatedkey.;
			&enddate. = ETLS_CLSDATE;
			&currentind. = 'N';

			if %sysrc(_SOK) eq _iorc_ then
				replace;
			_iorc_ = 0;
			_error_ = 0;
		run;

	%end;
	%else %do;
		%put %str(NOTE: No records were closed on target table.);
	%end;

	%if %length(&type1changes.) > 0 %then %do;
		%if &etls_type1cnt gt 0 %then %do;

			data &output_table1.;
				modify &output_table1.
					work.etls_type1
					(rename = (ETLS_KEY = &generatedkey.))
					updatemode=nomissingcheck;
				by &generatedkey.;

				if %sysrc(_SOK) eq _iorc_ then
					replace;
				_iorc_ = 0;
				_error_ = 0;
			run;

		%end;
		%else %do;
			%put %str(NOTE: No target table type 1 update records were found.);
		%end;
	%end;

	/*---- Append the new records and matching datasets  ----*/
	%if &etls_matchcnt gt 0 %then %do;

		proc append base = &output_table1.

			data = work.etls_match force;
		run;

	%end;

	%if &etls_newcnt gt 0 %then %do;

		proc append base = &output_table1.

			data = work.etls_newrcds force;
		run;

	%end;
	%else %do;
		%put %str(NOTE: No new dimension records were added to target table.);
	%end;

	/* Delete the work tables  */
	proc datasets lib=work nolist nowarn memtype = (data view);
		delete etls_newrcds;
		delete etls_match;
		delete etls_close;

		%if %length(&type1changes.) > 0 %then %do;
			delete etls_type1;
		%end;

		delete etls_sortedxref;
		delete etls_source;
	quit;

	%goto scdldout;

%error:
	%let syscc = 9999;

%scdldout:

	/* Save record counts into macro: 
		etls_recordsAfter
	*/
	%let etls_recCheckExist = 0;
	%let etls_recordsAfter = 0;
	%macro etls_recordCheck;
		%let etls_recCheckExist = %eval(%sysfunc(exist(&output_table1., DATA)) or 
			%sysfunc(exist(&output_table1., VIEW)));

		%if (&etls_recCheckExist) %then %do;
			%local etls_syntaxcheck;
			%let etls_syntaxcheck = %sysfunc(getoption(syntaxcheck));

			/* Turn off syntaxcheck option to perform following steps  */
			options nosyntaxcheck;

			proc contents data = &output_table1. out = work.etls_contents(keep = nobs) noprint;
			run;

			data _null_;
				set work.etls_contents (obs = 1);
				call symput("etls_recordsAfter", left(put(nobs,32.)));
			run;

			proc datasets lib = work nolist nowarn memtype = (data view);
				delete etls_contents;
			quit;

			/* Reset syntaxcheck option to previous setting  */
			options &etls_syntaxcheck;
		%end;
	%mend etls_recordCheck;

	%etls_recordCheck;

	proc datasets lib = work nolist nowarn memtype = (data view);
		delete temp0;
	quit;

%mend scdloader;

%let businesskey=;
%let detectchanges=;
%let type1changes=;
%let loopcol=;

%macro Vars(var=);
	%let newVar=;

	%do i = 1 %to &&&var._count;
		%let newVar=%sysfunc(catx( ,&newVar &&&var._&i._name));
	%end;

	%put &newVar;
	%let &var = &newVar;
%mend;

%Vars(var=businesskey);
%Vars(var=detectchanges);
%Vars(var=type1changes);
%Vars(var=loopcol);

/* Execute the SCD Type 2 Loader  */
%macro scdexec( input_table1=
			,loopcol=);
	%if %length(&loopcol.) = 0 %then %do;
		%scdloader( begindate=&begindate.
			,enddate=&enddate.
			,etls_begdate=%unquote(&etls_begdate.)
			,etls_enddate=%unquote(&etls_enddate.)
			,businesskey=&businesskey.
			,generatedkey=&generatedkey.
			,currentind=&currentind.
			,detectchanges=&detectchanges.
			,type1changes=&type1changes.
			,input_table1=&input_table1.
			,output_table1=&output_table1.
			,closeout=&closeout.
			);
	%end;
	%else %do;

		proc sql noprint;
			select count(*) into :idx
				from dictionary.indexes
					where upcase(libname) = "%upcase(%scan(&input_table1.,1,.))"
						and upcase(memname) = "%upcase(%scan(&input_table1.,2,.))"
						and upcase(indxname) = "%upcase(&loopcol.)";
		quit;

		%if &idx. = 0 %then %do;

			proc datasets lib = %scan(&input_table1.,1,.) nolist;
				modify %scan(&input_table1.,2,.);
				index create &loopcol.;
			run;

			quit;

		%end;

		proc sort data = &input_table1. (keep=&loopcol.) nodupkey out = temp1;
			by &loopcol.;
		run;

		data _null_;
			set temp1;
			call execute('%nrstr(%scdloader(begindate=&begindate,enddate=&enddate,etls_begdate='!!strip(&loopcol)!!',etls_enddate=%unquote(&etls_enddate.),businesskey=&businesskey,generatedkey=&generatedkey,currentind=&currentind,detectchanges=&detectchanges,type1changes=&type1changes,input_table1=&input_table1,output_table1=&output_table1,closeout=&closeout.,loopcol=&loopcol,loopval='!!strip(&loopcol)!!'));');
		run;

		proc datasets lib = work nolist nowarn memtype = (data view);
			delete temp1;
		quit;

	%end;
%mend scdexec;

%scdexec( input_table1=&input_table1.
	,loopcol=&loopcol.)
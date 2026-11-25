/*set QKB locale for the step*/
%DQLOAD(DQLOCALE=(&_locale));

%macro step_dqcase(maxcol=5);
	/* set the definition number according to the locale. */
	%if &_locale = ENUSA %then %let defNum=170;
	%else %if &_locale = ENGBR %then %let defNum=160;
	%else %if &_locale = FRFRA %then %let defNum=210;
	%else %if &_locale = DEDEU %then %let defNum=220;
	%else %if &_locale = ITITA %then %let defNum=260;
	%else %if &_locale = ESESP %then %let defNum=400;
	%else %do;
		data _null_;
			put "Error: No Locale defined"; 
			abort;
		run;
	%end;	

	%do i=1 %to &maxcol;
		%if &&col&i._count gt 0 %then %do;
			%if &&def&i._&defNum = %then %do;
				data _null_;
					put "Error: No definition rule defined for Case Change &i.."; 
					abort;
				run;
			%end;

			%if &&outcol&i._name = %then %do;
				%let newname=%sysfunc(lowcase(&&col&i._1_name._CS));

				%if &&outcol&i._rawlength eq %then 
					%let varLength=&&col&i._1_rawlength;
				%else 
					%let varLength=&&outcol&i._rawlength;
				%let declareVar&i=%str(length &newname $&varLength);
				%let stmt&i=%str(&newname= dqCase(&&col&i._1_name., "&&def&i._&defNum", "&_locale"));
			%end;

			%else %do;
				%if %substr(&&outcol&i._name_base, 1, 1) = %nrquote(%%) %then %do;
					%if %length(&&outcol&i._name_base) = 1 %then 
						%let newname=%sysfunc(lowcase(&&col&i._1_name._CS));
					%else
						%let newname=%sysfunc(lowcase(&&col&i._1_name.%substr(&&outcol&i._name_base, 2)));				
	
					%if &&outcol&i._rawlength eq %then 
						%let varLength=&&col&i._1_rawlength;
					%else 
						%let varLength=&&outcol&i._rawlength;
					%let declareVar&i=%str(length &newname $&varLength);
					%let stmt&i=%str(&newname= dqCase(&&col&i._1_name., "&&def&i._&defNum", "&_locale"));
				%end;
				%else %do;
					%if &&outcol&i._rawlength eq %then 
						%let varLength=&&col&i._1_rawlength;
					%else 
						%let varLength=&&outcol&i._rawlength ;
					%let declareVar&i=%str(length &&outcol&i._name $&varLength);
					%let stmt&i=%str(&&outcol&i._name= dqCase(&&col&i._1_name., "&&def&i._&defNum", "&_locale"));
				%end ;
			%end;
		%end;
	%end;

	data &_outputtable1;
		set &_inputtable1;
		%do i=1 %to &maxcol;
			%if &&col&i._count gt 0 %then %do;
				&&declareVar&i;
			%end;
		%end ;	
		%do i=1 %to &maxcol;
			%if &&col&i._count gt 0 %then %do;
				&&stmt&i;
			%end;
		%end ;		
	run;
%mend step_dqcase;

%step_dqcase();
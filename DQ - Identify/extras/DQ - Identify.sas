/* SAS templated code goes here */
%macro usr_dqident(maxcol=5) ;
	%let loc= ;
	%do i=1 %to &maxcol ;
		%if &&col&i._count gt 0 %then %do ;

			%let QKBlocale = &&locale&i ;

			%if &QKBlocale = ENCAN %then %let k=1 ;
			%else %if &QKBlocale = ENUSA %then %let k=2 ;
			%else %if &QKBlocale = FRCAN %then %let k=3 ;
			%else %if &QKBlocale = FRFRA %then %let k=4 ;
			%else %if &QKBlocale = DEDEU %then %let k=5 ;
			%else %if &QKBlocale = ITITA %then %let k=6 ;
			%else %if &QKBlocale = ESESP %then %let k=7 ;
			%else %do ;
				%put WARNING: No Locale defined for Identification &i.. Setting ENUSA as default ; 

				%let QKBlocale = ENUSA;
				%let k=2 ;
			%end ;	

			%if %sysfunc(index(&loc,&QKBlocale)) = 0 %then %do ; 
				%let loc=&loc &QKBlocale ;
			%end ;

			%if &&def&i._&k = %then %do ;
				%put WARNING: No definition defined for Identification &i.. Setting Field Content (Global) as default ; 

				%let def&i._&k = Field Content (Global);  
			%end ;

			%if &&outcol&i._name = %then %do ;

				%let wsn=%sysfunc(index(&&col&i._1_name.,%str( ))) ;
				
				%if &wsn gt 0 %then %do ;
					%let newname=%sysfunc(putc(&&col&i._1_name_base,$50.)) ;
					%let newname=%str("&newname._ID"n);
				%end ;
				%else %do ;
					%let newname=&&col&i._1_name._ID ;
				%end ;

				%if &&outcol&i._rawlength eq %then %let dl=256 ;
				%else %let dl=&&outcol&i._rawlength ;
				%let lg&i=%str(length &newname $&dl..) ;
				%let mc&i=%str(&newname = dqIdentify(&&col&i._1_name. , "&&def&i._&k", "&qkblocale" )) ;
			%end ;
			%else %do ;
				%if &&outcol&i._rawlength eq %then %let dl=256 ;
				%else %let dl=&&outcol&i._rawlength ;
				%let lg&i=%str(length &&outcol&i._name $&dl..) ;
				%let mc&i=%str(&&outcol&i._name = dqIdentify(&&col&i._1_name. , "&&def&i._&k", "&qkblocale" )) ;
			%end ;
			
		%end ;
	%end ;

	%DQLOAD(DQLOCALE=(&loc));

	data &outputtable1 ;
		set &inputtable1 ;
		%do i=1 %to &maxcol ;
			%if &&col&i._count gt 0 %then %do ;
				&&lg&i ;
				&&mc&i ;
			%end ;
		%end ;	
	run ;
%mend ;
%usr_dqident() ;

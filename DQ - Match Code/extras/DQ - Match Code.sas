/* SAS templated code goes here */
%macro usr_dqmatch(maxcol=10) ;
   	%if %sysfunc(libref(SASDQREF)) %then %do ;
      	%if %sysfunc(libname(SASDQREF,!sasroot/../commonfiles/home/share/DMData)) %then %put %sysfunc(sysmsg()) ;                                                                                                               
    	  %else %put NOTE: SASDQREF library assigned to %sysfunc(pathname(SASDQREF)). ;   
   	%end ;
   	%else %put NOTE: SASDQREF library exists. ; 

	proc sql noprint ;
		select distinct dm_locale into:qkblocale
		from &dm_madef
		where dm_desc="&locale" 
	;quit;

	%put NOTE: Locale used &qkblocale ;

	%DQLOAD(DQLOCALE=(&qkblocale));
	%do i=1 %to &maxcol ;
		%if &&col&i._count gt 0 %then %do ;

			%if &&outcol&i._name = %then %do ;

				%let wsn=%sysfunc(index(&&col&i._1_name.,%str( ))) ;
				
				%if &wsn gt 0 %then %do ;
					%let newname=%sysfunc(putc(&&col&i._1_name_base,$50.)) ;
					%let newname=%str("&newname._MC"n);
				%end ;
				%else %do ;
					%let newname=&&col&i._1_name._MC ;
				%end ;

				%if &&outcol&i._rawlength eq %then %let dl=256 ;
				%else %let dl=&&outcol&i._rawlength ;
				%let lg&i=%str(length &newname $&dl..) ;
				%let mc&i=%str(&newname = dqMatch(&&col&i._1_name. , "&&def&i.", &&sens&i., "&qkblocale" )) ;
			%end ;
			%else %do ;
				%if &&outcol&i._rawlength eq %then %let dl=256 ;
				%else %let dl=&&outcol&i._rawlength ;
				%let lg&i=%str(length &&outcol&i._name $&dl..) ;
				%let mc&i=%str(&&outcol&i._name = dqMatch(&&col&i._1_name. , "&&def&i.", &&sens&i., "&qkblocale" )) ;
			%end ;
			
		%end ;
	%end ;
	data &outputtable1 ;
		set &inputtable1 ;
		%do i=1 %to &maxcol ;
			%if &&col&i._count gt 0 %then %do ;
				%if &&outcol&i._name ne &&col&i._1_name. %then %do ;
					&&lg&i ;
                %end ;
				&&mc&i ;
			%end ;
		%end ;	
	run ;
%mend ;
%usr_dqmatch() ;



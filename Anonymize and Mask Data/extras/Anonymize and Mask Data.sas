/* Create SASDQREF library in case it doesn't exist in the context where this custom step is being executed */

%macro checkSASDQREF ;

   %if %sysfunc(libref(SASDQREF)) %then %do ;
      %if %sysfunc(libname(SASDQREF,!sasroot/../commonfiles/home/share/DMData)) %then %put %sysfunc(sysmsg()) ;                                                                                                               
      %else %put NOTE: SASDQREF library assigned to %sysfunc(pathname(SASDQREF)). ;   
   %end ;
   %else %put NOTE: SASDQREF library exists. ;

%mend checkSASDQREF ;
%checkSASDQREF ;


/* Resolve selectedLocale to its 5-character QKBLocale */
proc sql ;
	select distinct DM_LOCALE into :QKBLocale
		from SASDQREF.DM_MKDEF
		where DM_DESC="&selectedLocale";
run ;
%put &=QKBLocale.;

/* Load Selected QKB Locale */
%DQLOAD(DQLOCALE=(&QKBlocale));
 

/* Apply Data Masking Standardization Definition */
data &outTable (drop=&incolumn_1_name); /* also specify the drop column in the output table metadata */
	set &inTable;
    /* also specify the new column name in the output table metadata */
	&maskedColumn_name=dqStandardize(&inColumn_1_name,"&selectedDefinition", "&QKBlocale");
run;

/* Cleanup: Removing intermediate tables and SAS macros and SAS macro variables */
%sysmacdelete checkSASDQREF; 

%if %symexist(QKBLocale)=1 %then %do; 
   %symdel QKBlocale;
%end;

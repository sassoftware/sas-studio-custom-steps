
/* use CAS action textParse.tpParse on freeform text   */

/* Note : SS : Need to consider the macro.  Pro : can be called from other places (if needed) .  Otherwise, is it really necessary?  Open code is now possible. */


/*-----------------------------------------------------------------------------------------*
   This macro creates a global macro variable called _usr_nameCaslib
   that contains the caslib name (aka. caslib-reference-name) associated with the libname 
   and assumes that the libname is using the CAS engine.

   As sysvalue has a length of 1024 chars, we use the trimmed option in proc sql
   to remove leading and trailing blanks in the caslib name.
*------------------------------------------------------------------------------------------*/

%macro _usr_getNameCaslib(_usr_LibrefUsingCasEngine); 

   %global _usr_nameCaslib;
   %let _usr_nameCaslib=;

   proc sql noprint;
      select sysvalue into :_usr_nameCaslib trimmed from dictionary.libnames
      where libname = upcase("&_usr_LibrefUsingCasEngine.") and upcase(sysname)="CASLIB";
   quit;

%mend _usr_getNameCaslib;

/*-----------------------------------------------------------------------------------------*
   Main macro, processes UI input and then invokes CAS action.
*------------------------------------------------------------------------------------------*/

%macro usr_entextr(max_entities=9) ;  

/* This section creates a comma-separated list of quoted strings from the list selection */

%let taglist=;  
%do i=1 %to &max_entities;
    %if %symexist(Entity_&i) %then 
        %if &taglist= %then  %let taglist = "&&Entity_&i.";
        %else  %let taglist= &taglist,"&&Entity_&i.";
%end ;

%let exclude_NounGroup=;
%if &checkbox1 = 0 %then %let exclude_NounGroup = and _Role_ ~= "nlpNounGroup"; 

/*-----------------------------------------------------------------------------------------*
   Check that input table is a CAS table and set error flag if not.
*------------------------------------------------------------------------------------------*/

%if &inputtable1_engine=CAS %then %do;
   %let _nee_error_flag=0;
   %_usr_getNameCaslib(&inputtable1_lib);
   %let inputtable1_caslib=&_usr_nameCaslib;
%end;
%else %do;
   %let _nee_error_flag=1;
   %put ERROR: Input table is not a CAS table.; 
%end;


%if &_nee_error_flag=0 %then %do;
/*-----------------------------------------------------------------------------------------*
   Only execute CAS action and post-processing if input is a CAS table. 
   The error_flag macro variable uses naming convention to try to make it unique: 
       - underscore followed by first char of each word in name of custom step
*------------------------------------------------------------------------------------------*/

   proc cas;       
      textParse.tpParse /                                         
         docId="&DocID_1_name"
         offset={name="POS_ENTITY_EXTRACT", replace=TRUE}
         outComplexTag=TRUE
         entities="STD"
   	     selectEntity={opType="KEEP", taglist={&taglist}}  
         table={caslib="&inputtable1_caslib",name="&inputtable1_name"}
         text="&Text_Column_1_name";
   run;

   %let activeCaslib=%sysfunc(GETSESSOPT(&_SESSREF_, CASLIB));
   /* Handle caslib name like CASUSER(userid) */
   %let activeCaslib=%sysfunc(scan(&activeCaslib, 1, %str(%() ));

   data &outputtable1;
       /*-----------------------------------------------------------------------------------------*
           Use data set drop= option to avoid reading unused columns
           Use data set where= option to avoid reading rows not needed
        *------------------------------------------------------------------------------------------*/
      set &activeCaslib..POS_ENTITY_EXTRACT( drop= _ComplexTag_ _Attribute_ _Parent_ _Sentence_ _Paragraph_ 
                                             where = (kupcase(_Role_) contains "NLP" &exclude_NounGroup)      ) ;
   run;
   
/* -----------------------------------------------------------------------------------------* 
    Remove intermediate tables 
      Note: By not specifying caslib in dropTable, the active caslib will be used.
*------------------------------------------------------------------------------------------ */
   
   proc cas;
      table.dropTable / name="POS_ENTITY_EXTRACT"  quiet=true;
   run; quit;

%end; /* if &_nee_errorflag=0 */

/*-----------------------------------------------------------------------------------------*
   Clean up user-defined macro variables and macro definitions.
*------------------------------------------------------------------------------------------*/

%sysmacdelete _usr_getNameCaslib;

%mend usr_entextr;
%usr_entextr() ;   
   
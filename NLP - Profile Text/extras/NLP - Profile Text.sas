/* SAS templated code goes here */

proc cas;

textManagement.profileText /
	documentId="&DOCID_1_NAME_BASE."
	text="&TEXTCOL_1_NAME_BASE."
	language="&language."
	casout={name="&CASOUT_PROFILE_NAME_BASE.", caslib="&CASOUT_PROFILE_LIB.", replace=True}
	documentout={name="&DOCUMENTOUT_NAME_BASE.", caslib="&DOCUMENTOUT_LIB.", replace=True}
	sentenceout={name="&SENTENCEOUT_NAME_BASE.", caslib="&SENTENCEOUT_LIB.", replace=True}
	intermediateout={name="&INTERMEDIATEOUT_NAME_BASE.", caslib="&INTERMEDIATEOUT_LIB.", replace=True}
	tokenout={name="&TOKENOUT_NAME_BASE.", caslib="&TOKENOUT_LIB.", replace=True}
    table={name="&inputtable1_name_base.", caslib="&inputtable1_lib."}
;

table.save / 
	table= {name="&CASOUT_PROFILE_NAME_BASE.", caslib="&CASOUT_PROFILE_LIB."}
	name="&CASOUT_PROFILE_NAME_BASE."
	caslib="&CASOUT_PROFILE_LIB."
	replace=True
;

table.tableExists  result=rc/
   name="&CASOUT_PROFILE_NAME_BASE.", caslib="&CASOUT_PROFILE_LIB."
;

do until (rc.exists=0);
   table.dropTable /
         name="&CASOUT_PROFILE_NAME_BASE."
		 caslib="&CASOUT_PROFILE_LIB."
         ;
   table.tableExists  result=rc/
		name="&CASOUT_PROFILE_NAME_BASE."
		caslib="&CASOUT_PROFILE_LIB."
		;
end;

;

table.loadTable /
	path="&CASOUT_PROFILE_NAME_BASE..sashdat"
	caslib="&CASOUT_PROFILE_LIB."
	casout={name="&CASOUT_PROFILE_NAME_BASE.", caslib="&CASOUT_PROFILE_LIB."}

;

;
	table.promote /
        name="&CASOUT_PROFILE_NAME_BASE."
        caslib="&CASOUT_PROFILE_LIB."
        drop=FALSE
        targetcaslib="&CASOUT_PROFILE_LIB."
    ;


/* Document Out */

table.save / 

	table= {name="&DOCUMENTOUT_NAME_BASE.", caslib="&DOCUMENTOUT_LIB."}
	name="&DOCUMENTOUT_NAME_BASE."
	caslib="&DOCUMENTOUT_LIB."
	replace=True
;

table.tableExists  result=rc/
   name="&DOCUMENTOUT_NAME_BASE.", caslib="&DOCUMENTOUT_LIB."
;
print rc;

do until (rc.exists=0);
   table.dropTable /
         name="&DOCUMENTOUT_NAME_BASE."
		 caslib="&DOCUMENTOUT_LIB."
         ;
   table.tableExists  result=rc/
		name="&DOCUMENTOUT_NAME_BASE."
		caslib="&DOCUMENTOUT_LIB."
		;
print rc;
end;

;

table.loadTable /
	path="&DOCUMENTOUT_NAME_BASE..sashdat"
	caslib="&DOCUMENTOUT_LIB."
	casout={name="&DOCUMENTOUT_NAME_BASE.", caslib="&DOCUMENTOUT_LIB."}

;

;
	table.promote /
        name="&DOCUMENTOUT_NAME_BASE."
        caslib="&DOCUMENTOUT_LIB."
        drop=FALSE
        targetcaslib="&DOCUMENTOUT_LIB."
    ;


/* Sentence Out */

table.save / 

	table= {name="&SENTENCEOUT_NAME_BASE.", caslib="&SENTENCEOUT_LIB."}
	name="&SENTENCEOUT_NAME_BASE."
	caslib="&SENTENCEOUT_LIB."
	replace=True
;

table.tableExists  result=rc/
   name="&SENTENCEOUT_NAME_BASE.", caslib="&SENTENCEOUT_LIB."
;
print rc;

do until (rc.exists=0);
   table.dropTable /
         name="&SENTENCEOUT_NAME_BASE."
		 caslib="&SENTENCEOUT_LIB."
         ;
   table.tableExists  result=rc/
		name="&SENTENCEOUT_NAME_BASE."
		caslib="&SENTENCEOUT_LIB."
		;
print rc;
end;

;

table.loadTable /
	path="&SENTENCEOUT_NAME_BASE..sashdat"
	caslib="&SENTENCEOUT_LIB."
	casout={name="&SENTENCEOUT_NAME_BASE.", caslib="&SENTENCEOUT_LIB."}

;

;
	table.promote /
        name="&SENTENCEOUT_NAME_BASE."
        caslib="&SENTENCEOUT_LIB."
        drop=FALSE
        targetcaslib="&SENTENCEOUT_LIB."
    ;

/* Intermediate Out */

table.save / 

	table= {name="&INTERMEDIATEOUT_NAME_BASE.", caslib="&INTERMEDIATEOUT_LIB."}
	name="&INTERMEDIATEOUT_NAME_BASE."
	caslib="&INTERMEDIATEOUT_LIB."
	replace=True
;

table.tableExists  result=rc/
   name="&INTERMEDIATEOUT_NAME_BASE.", caslib="&INTERMEDIATEOUT_LIB."
;
print rc;

do until (rc.exists=0);
   table.dropTable /
         name="&INTERMEDIATEOUT_NAME_BASE."
		 caslib="&INTERMEDIATEOUT_LIB."
         ;
   table.tableExists  result=rc/
		name="&INTERMEDIATEOUT_NAME_BASE."
		caslib="&INTERMEDIATEOUT_LIB."
		;
print rc;
end;

;

table.loadTable /
	path="&INTERMEDIATEOUT_NAME_BASE..sashdat"
	caslib="&INTERMEDIATEOUT_LIB."
	casout={name="&INTERMEDIATEOUT_NAME_BASE.", caslib="&INTERMEDIATEOUT_LIB."}

;

;
	table.promote /
        name="&INTERMEDIATEOUT_NAME_BASE."
        caslib="&INTERMEDIATEOUT_LIB."
        drop=FALSE
        targetcaslib="&INTERMEDIATEOUT_LIB."
    ;


/* Token Out */

table.save / 

	table= {name="&TOKENOUT_NAME_BASE.", caslib="&TOKENOUT_LIB."}
	name="&TOKENOUT_NAME_BASE."
	caslib="&TOKENOUT_LIB."
	replace=True
;

table.tableExists  result=rc/
   name="&TOKENOUT_NAME_BASE.", caslib="&TOKENOUT_LIB."
;
print rc;

do until (rc.exists=0);
   table.dropTable /
         name="&TOKENOUT_NAME_BASE."
		 caslib="&TOKENOUT_LIB."
         ;
   table.tableExists  result=rc/
		name="&TOKENOUT_NAME_BASE."
		caslib="&TOKENOUT_LIB."
		;
print rc;
end;

;

table.loadTable /
	path="&TOKENOUT_NAME_BASE..sashdat"
	caslib="&TOKENOUT_LIB."
	casout={name="&TOKENOUT_NAME_BASE.", caslib="&TOKENOUT_LIB."}

;

;
	table.promote /
        name="&TOKENOUT_NAME_BASE."
        caslib="&TOKENOUT_LIB."
        drop=FALSE
        targetcaslib="&TOKENOUT_LIB."
    ;




quit;
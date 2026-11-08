/***************************************************************************
* Custom Step: DQ Cluster Analysis
* --------------------------------------------------------------------------
* The Cluster Analysis node will compare pairs of rows within a single match 
* cluster to determine whether each pair is really a match. 
* You can use this step to analyse data clusters or to find out which 
* cluster rules was triggered when the data got clustered
* --------------------------------------------------------------------------
* Note: Macros starting with an underscore contain UI variable values
***************************************************************************/

/***************************************************************************/
/* Macro setRules()                                                        */ 
/* ----------------------------------------------------------------------- */
/* The macro will generate rules from the UI input rules and conditions    */
/* In the rule condition we compare a field from the first record with a   */
/* field from the second record. The fields from record one start with R1_ */
/* and the field from record two start with R2_ respectively               */
/* The rules will be executes in a data step                               */
/***************************************************************************/
%macro setRules();
	%local ru co;
	/* loop through all available rules and their conditions */
	%do ru=1 %to &_ru_cnt;
		R&ru.Score= 0;
		R&ru.Ind= 0;
		%if &cluster_rules = 0 %then %do;
			%do co=1 %to &&_ru_&ru._co_cnt;
				/* Rule code */
				R&ru.C&co= 0;
				IF R1_&&_ru_&ru._co_&co._rec_1_fld &&_ru_&ru._co_&co._compare R2_&&_ru_&ru._co_&co._rec_2_fld THEN do;
					R&ru.C&co= &&_ru_&ru._co_&co._score;
					R&ru.Ind= R&ru.Ind + 1;
				end;
				R&ru.Score= R&ru.Score + R&ru.C&co;
			%end;
		%end;
		%else %do;
			%do co=1 %to &&_clust_ru_&ru._count;
				IF R1_&&_clust_ru_&ru._&co._name = R2_&&_clust_ru_&ru._&co._name THEN do;
					R&ru.C&co= &&_ru_&ru._co_&co._score;
					R&ru.Ind= R&ru.Ind + 1;					
				end;			
			%end;
		%end;
		/* set the rule indicator to show if a rules was triggered */
		/* we set it to 1 (ture) when all conditions have fired */
		/* we need this when we evaluate which cluster rule got triggered */
		if R&ru.Ind =  &&_clust_ru_&ru._count then
			R&ru.Ind= 1;
		else
			R&ru.Ind= 0;
	%end;
%mend setRules;

/***************************************************************************/
/* Macro setTotalScore()                                                   */
/* ----------------------------------------------------------------------- */
/* A macro to generate code to add-up the total score for all rules        */
/***************************************************************************/
%macro setTotalScore();
	total_score= 0;
	%local ru;
	%do ru=1 %to &_ru_cnt;
		total_score= total_score + 	R&ru.Score;
	%end;
%mend setTotalScore;

/***************************************************************************/
/* Macro setSelfCompareOutput()                                                   */
/* ----------------------------------------------------------------------- */
/* A macro to generate code to set score fields to -1 when we compare rows */
/* with itself (row1 == row2)                                              */
/***************************************************************************/
%macro setSelfCompareOutput();
	%local ru co;
	%do ru=1 %to &_ru_cnt;
		R&ru.Score= -1;
		%do co=1 %to &&_ru_&ru._co_cnt;
			R&ru.C&co= -1;
		%end;
	%end;
	total_score= -1;
%mend setSelfCompareOutput;

/***************************************************************************/
/* Macro ruleIndCols()                                                     */
/* ----------------------------------------------------------------------- */
/* A macro to set rule indicator columns for outputin  SQL statement       */
/***************************************************************************/
%macro ruleIndCols();
	%local ru co;
	%do ru=1 %to &_ru_cnt;
		,R&ru
	%end;
%mend ruleIndCols;

/***************************************************************************/
/* Macro dropRowID()                                                       */
/* ----------------------------------------------------------------------- */
/* A macro to help dropping the column _ROW_ID if the table ID is used     */
/***************************************************************************/
%macro dropRowID();
	%if &_record_id_count > 0 %then %do;
		_ROW_ID
	%end;
%mend dropRowID;

/***************************************************************************/
/* Macro ruleTriggerResult()                                               */
/* ----------------------------------------------------------------------- */
/* A macro to aggregate rule trigger results to indicate which             */
/* rule got triggered - used for "Use rules as cluster rules"              */
/***************************************************************************/
%macro ruleTriggerResult();
	proc sql;
		create table _DQCA_CA_CR as
		select row1, 
			%local i;
			%let i= 1;
			%do %while (&i < (&_ru_cnt + 1));
				case
					when sum(R&i.Ind) >= 1 then 1 
					else 0
				end as R&i
				%if &i < &_ru_cnt %then %do;
					,
				%end;
			%let i=  %eval(&i+1);
			%end;
		from WORK._DQCA_CA_CLUSTERJOIN
		group by row1;
	run;
	quit;
%mend ruleTriggerResult;

/***************************************************************************/
/* Main - The Step execution starts here                                   */  
/***************************************************************************/
/* If the radio button in the UI is set to "Use rules for cluster analysis"*/
/* we explicetly switch off the checkbox cluster_rules*/
%if  &_option_rb = %nrquote(Use rules for cluster analysis) %then %do;
	%let cluster_rules= 0;
%end;
%else %do;
	%let cluster_rules= 1;
%end;

/* Add row number as artificial key to the table */
/* we need this as we may not know what the row ID is */
data WORK._DQCA_CA_DATA;
	set &_intable;
	_ROW_ID= _N_;
run;

/* --------------------------------------------------------------------------- */
/* get all column names from the incoming table (plus column _ROW_ID)*/
PROC SQL;
    CREATE TABLE _DQCA_CA_DATA_COLS AS
    SELECT NAME
      FROM DICTIONARY.COLUMNS
     WHERE upper(LIBNAME) = 'WORK'
       AND upper(MEMNAME) = '_DQCA_CA_DATA'
;
QUIT;

/* --------------------------------------------------------------------------- */
/* generate SQL column list and put in macro &selectlist */
/* when we join the table we want to select all columns from both tables */
/* therefore we add a prefix to the columns name R1 and R2 for record 1 and record 2 respectively */
/* E.g.: SELECT a.col1 as R1_col1, b.col1 as R2_col1 */
data _null_;
	set _DQCA_CA_DATA_COLS end=last;
	length selectlist $1000;
	retain selectlist;
	if last then do;
		selectlist= catt(selectlist, "a.", name, " as R1_", name, ", ");
		selectlist= catt(selectlist, "b.", name, " as R2_", name);
		call symput("selectlist", selectlist);
	end;
	else do;
		selectlist= catt(selectlist, "a.", name, " as R1_", name, ", ");
		selectlist= catt(selectlist, "b.", name, " as R2_", name, ", ");
	end;
run;

/* --------------------------------------------------------------------------- */
/* Join the table with itsef on cluster id */
/* filter out all rows joining with itself */
PROC SQL;
    CREATE TABLE WORK._DQCA_CA_CLUSTERJOIN AS
    SELECT &selectlist 
	  FROM WORK._DQCA_CA_DATA a
      JOIN WORK._DQCA_CA_DATA b ON a.&_clusterid = b.&_clusterid
     WHERE a._ROW_ID <> b._ROW_ID
  ORDER BY a.&_clusterid, a._ROW_ID
   ;
QUIT;

/* --------------------------------------------------------------------------- */
/* remove redundant rows as we got too much back from the SQL */
/* the result from the SQL gives us row1 -> row2 but also row2 -> row1 */
/* the is kind of the same and we filter out the unnecessary rows */
data WORK._DQCA_CA_CLUSTERJOIN (drop= ID_Lst1 ID_Lst2 oldCID);
	set WORK._DQCA_CA_CLUSTERJOIN;
		by R1_&_clusterid; /* group be cluster ID */

	length ID_Lst1 ID_Lst2 $1000;
	retain ID_Lst1 ID_Lst2 oldCID;

	if _n_ = 1 then
		oldCID= R1_&_clusterid;
	if oldCID ne R1_&_clusterid then do;
		oldCID= R1_&_clusterid;
		ID_Lst1= '';
		ID_Lst2= '';
	end;
	ID_Lst1= catx(' ', ID_Lst1, R1__ROW_ID);
	ID_Lst2= catx(' ', ID_Lst2, R2__ROW_ID);
/* if the output is for cluster analysis then we need to change the last row of the cluster */
/* so we can show the row in the output. Otherwise we lose it in the output */
%if &cluster_rules = 0 %then %do;
	if LAST.R1_&_clusterid = 1 then
		R1__ROW_ID= R2__ROW_ID;
	if findw(ID_Lst1, strip(R2__ROW_ID)) > 0 and findw(ID_Lst2, strip(R1__ROW_ID)) > 0 and LAST.R1_&_clusterid = 0 then
		delete;
%end;
/* if the output is for cluster analysis AND record ID column is set  */
%if &_record_id_count = 1 and &cluster_rules = 0 %then %do;
	if R1__ROW_ID = R2__ROW_ID then do;
		row1= R1_&_record_id_1_name;
		row2= R1_&_record_id_1_name;
	end;
	else do;
		row1= R1_&_record_id_1_name;
		row2= R2_&_record_id_1_name;
	end;
%end;
%else %do;
	rename R1__ROW_ID= row1 R2__ROW_ID= row2;
%end;
run;

/* --------------------------------------------------------------------------- */
/* Analyse Cluster - execute rules */
data WORK._DQCA_CA_CLUSTERJOIN;
	set WORK._DQCA_CA_CLUSTERJOIN;
	%setRules();
	%setTotalScore();
run;
data _null_;
length asd $1500.;
asd= "%setRules()";
put asd=;
run;
/* --------------------------------------------------------------------------- */
/* get the column names for the cloumns we want to output */
/* we want to output all columns from the input table plus cluster analysis columns */
/* we have the option in the UI to control the output score fields and generate the sql appopreately */
PROC SQL;
    CREATE TABLE _DQCA_CA_COLS AS
    SELECT NAME
      FROM DICTIONARY.COLUMNS
     WHERE upper(LIBNAME) = 'WORK'
       AND upper(MEMNAME) = '_DQCA_CA_CLUSTERJOIN'
	   AND upper(name) NOT LIKE 'R2\_%' escape '\'
%if &cluster_rules = 0 %then %do;
	   AND name NOT LIKE 'R_Ind'
%end;
%if &_show_cond_score = 0 %then %do;
	   AND upper(NAME) NOT LIKE 'R_C_'
%end;
%if &_show_rule_score = 0 %then %do;
	   AND NAME NOT LIKE 'R_Score'
%end;
%if &_show_total_score = 0 %then %do;
	   AND NAME NOT LIKE 'total_score'
%end;
;
QUIT;

/***************************************************************************/
/* Output data for cluster analysis                                        */
/* If &cluster_rules is false we output a cluster analysis result         */
/* showing each record compared with each record within a cluster (same as */
/* the cluster analysis node in DFX)                                       */
/***************************************************************************/
%if &cluster_rules = 0 %then %do;
	/* --------------------------------------------------------------------------- */
	/* generate select list to rename the columns to the original names */
	data _null_;
		set _DQCA_CA_COLS end=last;
		length keeplist renamelist $3000;
		length new_name $80;
		retain keeplist renamelist;

		keeplist= catx(" ", keeplist, name);

		if find(name, "R1_") = 1 then
			new_name= substrn(name, 4);
		else
			new_name= name;

		renamelist= catx(" ",renamelist, name, "=", new_name);

		if last then do;
			call symput("keeplist", keeplist);
			call symput("renamelist", renamelist);
		end;
	run;

	/* output data - drop row id if we use record id*/
	data &_outtable (drop= %dropRowID());
		set work._DQCA_ca_clusterjoin;
		if row1 = row2 then do;
			%setSelfCompareOutput();
		end;
		keep &keeplist;
		rename &renamelist;
	run;
%end;
/*******************************************************************************/
/* Output data for cluster rule indentification                                */
/* If &cluster_rules is ture then we treat  the rules like cluster rule and   */
/* output which rule was triggered for a record. If &cluster_rules is false we*/ 
/* output a cluster analysis result                                            */
/*******************************************************************************/
%else %do;
	/* generate list of column we want to output and put them into macro &selectlist*/
	data _null_;
		set _DQCA_CA_DATA_COLS end=last; /* we have put all col names in _DQCA_CA_DATA_COLS */
		length selectlist $1000;
		retain selectlist;
		/* as we have added _ROW_ID as artificial key we don't want to putput it */
		if name ~= '_ROW_ID' then do;
			if _n_ > 1 then
				selectlist= catt(selectlist, ", ");
			selectlist= catt(selectlist, "a.", name);
		end;
		if last then
			call symput("selectlist", selectlist);
	run;

	/* --------------------------------------------------------------------------- */
	/* aggregate rule trigger result to indicate which rule got triggered          */
	%ruleTriggerResult();

	/* --------------------------------------------------------------------------- */
	/* output data */
	/* join the triggered rules result with original (incoming) data */
	proc sql;
	create table &_outtable as
	select &selectlist. %ruleIndCols()
	from WORK._DQCA_CA_DATA a
	join WORK._DQCA_CA_CR b on a._ROW_ID = b.row1
	;
	quit;
%end;

/* --------------------------------------------------------------------------- */
/* clean up macros variables used in this step                                 */
/* --------------------------------------------------------------------------- */
%symdel cluster_rules;
%symdel selectlist;
 %if %symexist(keeplist)=1 %then %do; 
    %symdel keeplist;
 %end;
 %if %symexist(renamelist)=1 %then %do; 
    %symdel renamelist;
 %end;

/* --------------------------------------------------------------------------- */
/* clean up macros used in this step                                           */
/* --------------------------------------------------------------------------- */
%sysmacdelete setRules; 
%sysmacdelete setTotalScore;
%sysmacdelete setSelfCompareOutput;
%sysmacdelete ruleIndCols;
%sysmacdelete dropRowID;
%sysmacdelete ruleTriggerResult;

/* --------------------------------------------------------------------------- */
/* delete temp tables in this step                                             */
/* --------------------------------------------------------------------------- */
proc datasets lib=work noprint nowarn;
   delete _DQCA_CA_CR 
      _DQCA_CA_CLUSTERJOIN
      _DQCA_CA_DATA
      _DQCA_CA_DATA_COLS
      _DQCA_CA_COLS
      ;
run; quit; 
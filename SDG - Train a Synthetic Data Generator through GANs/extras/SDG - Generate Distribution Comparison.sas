data &inputtable2.;
	set &inputtable2.;
	TRAINFLAG=0;
run;

data CASUSER.merged_data;
	length Synthetic_data_flag varchar(*);
	set &inputtable1. &inputtable2.;
	If TRAINFLAG=0 then Synthetic_data_flag="Generated Data"; else Synthetic_data_flag="Original Data";
run;

%put _all_;

%let blankSeparatedList = %_flw_get_column_list(_flw_prefix=columnselector1);
%let commaSeparatedList = %_flw_get_column_list(_flw_prefix=columnselector1, _delim=%str(,));

data _null_;
	call symput("commaSeparatedList",'"'||tranwrd("&commaSeparatedList.",",",'","')||'"');
run;

%put &commaSeparatedList.;

%global varname;

%macro genDistPlot;

	%do i=1 %to %sysfunc(countw(&blankSeparatedList.));
	
		data _null_;
		call symput("varname",scan("&blankSeparatedList.", &i., " ","MO"));
		run;
	
	proc sgplot data=CASUSER.merged_data noautolegend;
	 title "Distribution of &varname.";
	 density &varname. / group=Synthetic_data_flag;
	run;
	
	%end;
	
%mend genDistPlot;

%genDistPlot;


proc cas;
	textmanagement.generateIds /
		table={name="merged_data", caslib="CASUSER"}
		casout={name="MERGED_DATA_ID", caslib="CASUSER", replace=True}
	
	;
	datastep.runCode /
		code="data CASUSER.MERGED_DATA_ID; set CASUSER.MERGED_DATA_ID; Synthetic_Data_Measure_Value='Value';run;";

quit;

proc cas;
	transpose.transpose /                                         
	   table={name="MERGED_DATA_ID", caslib="CASUSER", groupby={"_id_","Synthetic_data_flag"}}                     /*1*/
	   transpose={&commaSeparatedList.}                                  /*3*/
	   id={"Synthetic_Data_Measure_Value"}                                        
	   casOut={name="syn_compare_merged_data", caslib="PUBLIC", replace=true}  ;                   /*5*/

quit;



proc cas;
	table.save / 
	
		table= {name="syn_compare_merged_data", caslib="CASUSER"}
		name="syn_compare_merged_data"
		caslib="CASUSER"
		replace=True
	;
	
	table.tableExists  result=rc/
	   name="syn_compare_merged_data", caslib="CASUSER"
	;
	print rc;
	
	do until (rc.exists=0);
	   table.dropTable /
	         name="syn_compare_merged_data"
			 caslib="CASUSER"
	         ;
	   table.tableExists  result=rc/
			name="syn_compare_merged_data"
			caslib="CASUSER"
			;
	print rc;
	end;
	
	;
	
	table.loadTable /
		path="syn_compare_merged_data.sashdat"
		caslib="CASUSER"
		casout={name="syn_compare_merged_data", caslib="CASUSER", replace=True}
	
	;
	
	;
		table.promote /
	        name="syn_compare_merged_data"
	        caslib="CASUSER"
	        drop=FALSE
	        targetcaslib="CASUSER"
	    ;
	

quit;


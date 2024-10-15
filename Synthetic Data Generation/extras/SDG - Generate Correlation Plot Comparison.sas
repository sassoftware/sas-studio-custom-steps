
%let blankSeparatedList = %_flw_get_column_list(_flw_prefix=columnselector1);
%let commaSeparatedList = %_flw_get_column_list(_flw_prefix=columnselector1, _delim=%str(,));

data _null_;
	call symput("commaSeparatedList",'"'||tranwrd("&commaSeparatedList.",",",'","')||'"');
run;

%put &commaSeparatedList.;


proc cas;
   simple.correlation /
      inputs={&commaSeparatedList.}
	  simple=true
      table={name = "&inputtable1_name_base.", caslib="&inputtable1_lib."}
	  outPearson={name="train_corr_out1", caslib="CASUSER" ,replace="TRUE"};
run;


proc cas;
   simple.correlation /
      inputs={&commaSeparatedList.}  
	  simple=true
      table={name = "&inputtable2_name_base.", caslib="&inputtable2_lib."}
	  outPearson={name="synth_corr_out1", caslib="CASUSER" ,replace="TRUE"};
run;


data CASUSER.train_corr_out;
set CASUSER.train_corr_out1;
	if _N_>3;
	drop _TYPE_ ;
run;

data CASUSER.synth_corr_out;
set CASUSER.synth_corr_out1;
	if _N_>3;
	drop _TYPE_ ;
run;


  /* prep data for heat map */
data CASUSER.train_corr_plot;
  keep x y r;
  set CASUSER.train_corr_out;
  array v{*} _numeric_;
  x = _NAME_;
  do i = dim(v) to 1 by -1;
    y = vname(v(i));
    r = v(i);
    /* creates a lower triangular matrix */
    if (i<_n_) then
      r=.;
    output;
  end;
run;

  /* prep data for heat map */
data CASUSER.synth_corr_plot;
  keep x y r;
  set CASUSER.synth_corr_out;
  array v{*} _numeric_;
  x = _NAME_;
  do i = dim(v) to 1 by -1;
    y = vname(v(i));
    r = v(i);
    /* creates a lower triangular matrix */
    if (i<_n_) then
      r=.;
    output;
  end;
run;

proc template;
  define statgraph corrHeatmap;
   dynamic _Title;
    begingraph;
      entrytitle _Title;
      rangeattrmap name='map';
      /* select a series of colors that represent a "diverging"  */
      /* range of values: stronger on the ends, weaker in middle */
      /* Get ideas from http://colorbrewer.org                   */
      range -1 - 1 / rangecolormodel=(cxD8B365 cxF5F5F5 cx5AB4AC);
      endrangeattrmap;
      rangeattrvar var=r attrvar=r attrmap='map';
      layout overlay / 
        xaxisopts=(display=(line ticks tickvalues)) 
        yaxisopts=(display=(line ticks tickvalues));
        heatmapparm x = x y = y colorresponse = r / 
          xbinaxis=false ybinaxis=false
          name = "heatmap" display=all;
        continuouslegend "heatmap" / 
          orient = vertical location = outside title="Pearson Correlation";
      endlayout;
    endgraph;
  end;
run;


proc sgrender data=CASUSER.train_corr_plot template=corrHeatmap;
   dynamic _title="Corr matrix for real data";
run;


proc sgrender data=CASUSER.synth_corr_plot template=corrHeatmap;
   dynamic _title="Corr matrix for synthetic data";
run;


data CASUSER.synthetic_data_corr_plot;
	length Synthetic_data_flag varchar(*);
	set CASUSER.train_corr_plot(in=a) CASUSER.synth_corr_plot(in=b);
	If b then Synthetic_data_flag="Generated Data"; else Synthetic_data_flag="Original Data";
run;

proc cas;
	table.save / 
	
		table= {name="synthetic_data_corr_plot", caslib="CASUSER"}
		name="synthetic_data_corr_plot"
		caslib="CASUSER"
		replace=True
	;
	
	table.tableExists  result=rc/
	   name="synthetic_data_corr_plot", caslib="CASUSER"
	;
	print rc;
	
	do until (rc.exists=0);
	   table.dropTable /
	         name="synthetic_data_corr_plot"
			 caslib="CASUSER"
	         ;
	   table.tableExists  result=rc/
			name="synthetic_data_corr_plot"
			caslib="CASUSER"
			;
	print rc;
	end;
	
	;
	
	table.loadTable /
		path="synthetic_data_corr_plot.sashdat"
		caslib="CASUSER"
		casout={name="synthetic_data_corr_plot", caslib="CASUSER"}
	
	;
	
	;
		table.promote /
	        name="synthetic_data_corr_plot"
	        caslib="CASUSER"
	        drop=FALSE
	        targetcaslib="CASUSER"
	    ;
	
quit;


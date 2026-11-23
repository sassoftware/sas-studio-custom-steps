%macro CHECK();

	%let SHAPE = %scan("&ShapeFileSelector", 3, ":", "MO");
	
	%let CHECK = %scan("&ShapeFileSelector", 2, ":", "MO");

	%let TESTO1 = %scan("&SHAPE", 1, "/", "B");

	%if "&CHECK" = "sasserver" %then 
    	%do;
			%put NOTE: The .shp file selected is &TESTO1;
		%end;
   	%else %do;
			%put ERROR: The .shp file is not on the SAS Viya Compute file system. SAS Content is not supported.;
		%end;

	%SHPCNTNT(SHAPEFILEPATH=&SHAPE);

%mend CHECK;

%CHECK();



proc contents data=work.temp out=work.contents_temp;
   title  ‘The Contents of SHP file’;
run;

data &outputtable1;
	set work.temp;
run;

proc delete data=work.temp; run;
proc delete data=work.contents_temp; run;
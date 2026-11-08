data _null_;
	x="&insert_dirpath_img_";
	y=find(x, ':');
	z=substr(x, (find(x, ':')+1));
	call symput("temppath_lib_", z);
run;


/*-----------------------------------------------------------------------------------------*
Macro to check if a given libref belongs to a SAS or CAS engine.
/*------------------------------------------------------------------------------------------*/
%if "%upcase(&insert_outtab_name_engine)" ne "CAS" %then %do;

	data _null_;
		putlog "ERROR: The selected table is not a CAS table.";
		putlog "ERROR: Please select a library that points to a caslib.";
		abort 42;
	run;

%end;
%else %do;
	%let _tm_nameCaslib=%sysfunc(getlcaslib(&insert_outtab_name_lib));
	%put CASLIB name: &_tm_nameCaslib;
%end;

data _null_;
	location=scan("&insert_dirpath_img_.", 1, ':', 'MO');

	if location eq 'sascontent' then do;
		putlog "ERROR: Please ensure that the directory containing images is located in SAS Server not in SAS Content";
		abort 42;
	end;
run;

%macro chkinputimagechoice();
	%if "&_insert_loadimageschoice"="full_path_" %then %do;

		/* Create temporary caslib and libref for loading images */
		caslib loadImagesTempCaslib datasource=(srctype="path") path="&temppath_lib_"
		subdirs notactive;
		libname _loadtmp cas caslib="loadImagesTempCaslib";
	%end;
%mend;

libname &insert_outtab_name_lib cas;
%chkinputimagechoice;

/* Load images */
proc cas;
	verify_inputimagechoice="&_insert_loadimageschoice";

	if verify_inputimagechoice="full_path_" then do;
		session %sysfunc(getlsessref(_loadtmp));
	end;

	if &_insert_recursiveload=1 then verify_recursive_load=true;

	if &_insert_recursiveload=0 then verify_recursive_load=false;

	if &insert_decodeimages=1 then verify_decodeimages=true;

	if &insert_decodeimages=0 then verify_decodeimages=false;

	if &insert_chkreadpaths=0 then do;

		if &insert_labelcol_=1 then do;
			image.loadImages result=casOutInfo / caslib="loadImagesTempCaslib"
			decode=verify_decodeimages addColumns={"HEIGHT", "WIDTH"} 
				recurse=verify_recursive_load labelLevels=&insert_subdir_labels casOut={caslib="%sysfunc(getlcaslib(&insert_outtab_name_lib))", 
				name="&insert_outtab_name_name", replace=TRUE};
		end;

		if &insert_labelcol_=0 then do;
			image.loadImages result=casOutInfo / caslib="loadImagesTempCaslib"
			decode=verify_decodeimages addColumns={"HEIGHT", "WIDTH"} 
				recurse=verify_recursive_load
				casOut={caslib="%sysfunc(getlcaslib(&insert_outtab_name_lib))", 
				name="&insert_outtab_name_name", replace=TRUE};
		end;
	end;

	if &insert_chkreadpaths=1 then do;
		image.loadImages result=casOutInfo / 
			path="&insert_filepath_"caslib="loadImagesTempCaslib"
			decode=TRUE addColumns={"HEIGHT", "WIDTH"} recurse=TRUE labelLevels=&insert_subdir_labels casOut={caslib="%sysfunc(getlcaslib(&insert_outtab_name_lib))", 
			name="&insert_outtab_name_name", replace=TRUE};
	end;

	/* Export DICOM images */
	if &_dicomyesno_=1 and &insert_labelcol_=0 then do;
		bioMedImage.processBioMedImages / copyVars={"_path_", "_id_", "HEIGHT", 
			"WIDTH"} images={table={name="&insert_outtab_name_name", 
			caslib="%sysfunc(getlcaslib(&insert_outtab_name_lib))"}} 
			steps={{step={stepType="EXPORT"}}} 
			casOut={caslib="%sysfunc(getlcaslib(&insert_outtab_name_lib))", 
			name="&insert_outtab_name_name", replace=TRUE};
	end;

	if &_dicomyesno_=1 and &insert_labelcol_=1 then do;
		bioMedImage.processBioMedImages / copyVars={"_path_", "_label_", "_id_", 
			"HEIGHT", "WIDTH"} images={table={name="&insert_outtab_name_name", 
			caslib="%sysfunc(getlcaslib(&insert_outtab_name_lib))"}} 
			steps={{step={stepType="EXPORT"}}} 
			casOut={caslib="%sysfunc(getlcaslib(&insert_outtab_name_lib))", 
			name="&insert_outtab_name_name", replace=TRUE};
	end;

	if &_addidvar=1 then do;
		table.partition / table={name="&insert_outtab_name_name", 
			computedVars={{name="&_idvarname"}}, 
			computedVarsProgram="length &_idvarname $&_lengthofid;

											 &_idvarname=scan(_path_,-1,'/');&_idvarname=scan(&_idvarname,1,'.');"} 
			casout={name="&insert_outtab_name_name", 
			caslib="%sysfunc(getlcaslib(&insert_outtab_name_lib))", replace=TRUE};
		table.alterTable / name="&insert_outtab_name_name", 
			caslib="%sysfunc(getlcaslib(&insert_outtab_name_lib))"
			columns={{name="&_idvarname", format="$&_lengthofid."}};
	end;

	if &insert_randomimages_chk_=1 and &insert_labelcol_=1 then do;

		/* Randomly select images to display */
		nRows=max(casOutInfo.OutputCasTables[1, "Rows"], 1);
		_sampPct_=min(&insert_numimagetodis_/nRows*100, 100);
		sampling.srs / table={caslib="%sysfunc(getlcaslib(&insert_outtab_name_lib))", 
			name="&insert_outtab_name_name"}, sampPct=_sampPct_, 
			display={excludeAll=TRUE}, output={casOut={caslib="&insert_outtab_name_lib", 
			name="_tempDisplayTable_", replace=TRUE}, copyVars={"_path_" , "_label_" , 
			"_id_"}};
	end;

	if &insert_randomimages_chk_=1 and &insert_labelcol_=0 then do;

		/* Randomly select images to display */
		nRows=max(casOutInfo.OutputCasTables[1, "Rows"], 1);
		_sampPct_=min(&insert_numimagetodis_/nRows*100, 100);
		sampling.srs / table={caslib="%sysfunc(getlcaslib(&insert_outtab_name_lib))", 
			name="&insert_outtab_name_name"}, sampPct=_sampPct_, 
			display={excludeAll=TRUE}, output={casOut={caslib="&insert_outtab_name_lib", 
			name="_tempDisplayTable_", replace=TRUE}, copyVars={"_path_" , "_id_"}};
	end;
quit;

%macro chkvisualizeimages();
	%if &insert_choicedisplyimages=1 and &_dicomyesno_=0 %then %do;

		%if &insert_randomimages_chk_=1 %then %do;

			/* Display images */
			data &insert_outtab_name_lib.._tempDisplayTable_;
				set &insert_outtab_name_lib.._tempDisplayTable_ end=eof;
			_labelID_=cat(_label_, ' (_id_=', _id_, ')');

			if _n_=1 then do;
				dcl odsout obj();
				obj.layout_gridded(columns: &insert_columnnum_);
			end;
			obj.region();
			obj.format_text(text: _labelID_, just: "c", 
				style_attr: "font_size=&insert_imgtext_font..pt");
			obj.image(file: _path_, width: "&insert_img_width", 
				height: "&insert_img_height");

			if eof then do;
				obj.layout_end();
			end;
		run;

	%end;

	%if &insert_randomimages_chk_=0 %then %do;

		/* Display images */
		data &insert_outtab_name_lib.._tempDisplayTable_;
			set &insert_outtab_name_lib..&insert_outtab_name_name end=eof;
		_labelID_=cat(_label_, ' (_id_=', _id_, ')');

		if _n_=1 then do;
			dcl odsout obj();
			obj.layout_gridded(columns: &insert_columnnum_);
		end;
		obj.region();
		obj.format_text(text: _labelID_, just: "c", 
			style_attr: "font_size=&insert_imgtext_font..pt");
		obj.image(file: _path_, width: "&insert_img_width", 
			height: "&insert_img_height");

		if eof then do;
			obj.layout_end();
		end;
	run;

%end;
%end;
%mend;

%chkvisualizeimages;

/* Print file paths for the displayed images and drop the temporary table */
proc cas;
	if &insert_printpaths_=1 then do;
		session %sysfunc(getlsessref(&insert_outtab_name_lib));
		table.fetch / table={caslib="&insert_outtab_name_lib"
		name="_tempDisplayTable_"} fetchvars={'_path_', '_label_', '_id_'};
		table.dropTable / caslib="&insert_outtab_name_lib"
		name="_tempDisplayTable_";
	end;
quit;

/* Remove temporary caslib and libref */
caslib loadImagesTempCaslib drop;
libname _loadtmp;

/* libname &outputCaslib1; */
%SYMDEL temppath_lib_ _tm_nameCaslib;
%SYSMACDELETE chkinputimagechoice;
%SYSMACDELETE chkvisualizeimages;
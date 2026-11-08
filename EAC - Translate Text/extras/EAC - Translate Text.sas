* Call the DeepL API - takes in a ID to get the text that needs translating;
%macro _tt_translate(_tt_temp_ID);
	data _null_;
		set work._tt_tmp_out(keep=_tt_ID &textToTranslate_1_name_base. &langSel_1_name_base. where=(_tt_ID=&_tt_temp_ID.));

		_tt_encoded = strip(&textToTranslate_1_name_base.);
		call symputx('_tt_toTranslate', _tt_encoded);
		call symputx('_tt_source_lang', &langSel_1_name_base.);
	run;

	filename deepL temp;
	proc http
		url = "https://&subscriptionType..deepl.com/v2/translate"
		ct = 'application/x-www-form-urlencoded'
		in = form("target_lang" = "&targetLang."
				"source_lang" = "&_tt_source_lang."
				"text" = "&_tt_toTranslate.")
	    out = deepL;
	    headers
	        'Accept' = 'application/json'
			'Authorization' = "DeepL-Auth-Key %unquote(&authToken.)";
	run;
	libname deepL json;

	data _null_;
		if &SYS_PROCHTTP_STATUS_CODE. ge 400 then do;
			str = "ERROR: DeepL responded with &SYS_PROCHTTP_STATUS_CODE. for the Text &_tt_toTranslate.";
    		putlog str;
  		end;
	run;

	data work._tt_tmp_translated;
		length _tt_ID 8. &transColName_name_base. $32000.;
		label _tt_ID = 'Temporary ID variable for joining the data back to the results table'
			&transColName_name_base. = 'Contains the translated text';
		set deepL.translations(keep=text rename=(text=&transColName_name_base.));

		_tt_ID = &_tt_temp_ID.;
	run;

	libname deepL clear;
	filename deepL clear;

	proc append base=work._tt_translated data=work._tt_tmp_translated;
	run;
%mend _tt_translate;

* TEMP base table that will be dropped at the end;
data work._tt_translated;
	length _tt_ID 8. &transColName_name_base. $32000.;
	label _tt_ID = 'Temporary ID variable for joining the data back to the results table'
		&transColName_name_base. = 'Contains the translated text';
run;

* Call the macro and add the TEMP ID;
data work._tt_tmp_out(drop=arg);
	length _tt_ID 8.;
	set &inputTable.;
	
	_tt_ID = _n_;
	arg = '%nrstr(%_tt_translate('!! _tt_ID !!'));';
	call execute(arg);
run;

* Join the translated text with the original table;
proc sql;
	create table work._tt_tmp_out_2 as
		select a.*, b.&transColName_name_base.
			from work._tt_tmp_out as a
				left join work._tt_translated as b
					on a._tt_ID = b._tt_ID;
run;

* Write output for step user;
data &outTable.;
	set work._tt_tmp_out_2(drop=_tt_ID);
run;

* Clean up;
%sysmacdelete _tt_translate;
proc datasets library=work nolist;
	delete _tt_translated _tt_tmp_translated _tt_tmp_out _tt_tmp_out_2;
run;
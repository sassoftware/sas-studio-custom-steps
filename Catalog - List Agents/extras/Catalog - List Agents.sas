%let _la_viyaHost=%sysfunc(getoption(SERVICESBASEURL));

* Macro to recursivly get all SAS Information Catalog agents;
%macro _la_pagination(_la_start=0, _la_limit=10);
	%local
		_la_start
		_la_limit
		_la_ds_nobs
		_la_nvar
		_la_new_start;

	filename _la_agt temp;
	proc http
		method='get'
		url="&_la_viyaHost./catalog/bots?start=&_la_start%nrstr(&)limit=&_la_limit."
		oauth_bearer = sas_services
		out=_la_agt;
		headers 'Accept' = 'application/json';
	quit;
	
	libname _la_agt json;

	* Get the number of observations where one obs = one agent;
	proc sql noprint;
		select count(*) into :_la_ds_nobs trimmed
			from _la_agt.items;
	quit;

	* Get the number of columns;
	proc sql noprint;
	    select nvar into :_la_nvar trimmed
			from dictionary.tables where libname='_LA_AGT' and memname='ITEMS';
	quit;

	* Handle the first iteration and subsequent requests;
	%if &_la_start. eq 0 %then %do;
		data &outputtable1.;
			length id $36. name $256.;
			label id = 'ID of the SAS Information Catalog Agent'
				name = 'Name of the SAS Information Catalog Agent';
			set _la_agt.items(keep=id name);
		run;
	%end;
	%else %do;
		%if &_la_nvar. gt 2 %then %do;
			proc append base=&outputtable1. data=_la_agt.items(keep=id name);
			quit;
		%end;
	%end;

	libname _la_agt clear;
	filename _la_agt clear;

	* Check if a another iteration is needed;
	%if &_la_ds_nobs eq &_la_limit and &_la_nvar. gt 2 %then %do;
		%put NOTE: Getting more agents;
		%let _la_new_start = %eval(&_la_start+&_la_limit);
		%_la_pagination(_la_start=&_la_new_start, _la_limit=&_la_limit);
	%end;
%mend _la_pagination;

%_la_pagination();

* Clean up;
%symdel _la_viyaHost;
%sysmacdelete _la_pagination;
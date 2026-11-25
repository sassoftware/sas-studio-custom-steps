%let _ra_viyaHost = %sysfunc(getoption(SERVICESBASEURL));

* Trigger Agent run;
proc http
	method='put'
	url="&_ra_viyaHost./catalog/bots/&botID./state?value=running"
	oauth_bearer = sas_services;
	headers 'Accept' = 'text/plain';
quit;

* Macro to check the status of the agent run;
* Calls itself as long as the status is running;
%macro _ra_check_status();
	filename _ra_stt temp;
	proc http
		method='get'
		url="&_ra_viyaHost./catalog/bots/&botID./state"
		oauth_bearer = sas_services
		out=_ra_stt;
		headers 'Accept' = 'text/plain';
	quit;
	
	data _null_;
		length status $128.;
		infile _ra_stt;
		input status $;
	
		if status = 'running' then do;
			put 'NOTE: Waiting for agent run to finish.';
			* Wait for 30 seconds before making another call;
			call sleep(30, 1);
			call execute('%_ra_check_status()');
		end;
		else do;
			put 'NOTE: Agent run is finished.';
		end;
	run;
%mend _ra_check_status;

%if &isSync. %then %do;
	%_ra_check_status();
%end;

%if &isSync. and &displayResults. %then %do;
	filename _ra_hst temp;
	proc http
		method='get'
		url="&_ra_viyaHost./catalog/bots/&botID./history?limit=1"
		oauth_bearer = sas_services
		out=_ra_hst;
		headers 'Accept' = 'application/json';
	quit;

	libname _ra_hst json;

	data _null_;
		set _ra_hst.items_links(obs=1);
		call symputx('_ra_catalog_uri', substr(uri, 22, find(uri, '%') + 23));
	run;

	title "<a href='&_ra_viyaHost./SASInformationCatalog/?q=&_ra_catalog_uri.' target='_blank' rel='noopener noreferrer'>View Information on the Agent Run (right click > open in a new tab)</a>";
	proc print data=_ra_hst.items(drop=ordinal_root ordinal_items version) noobs;
	quit;
	title;

	libname _ra_hst clear;
	%symdel _ra_catalog_uri;
%end;

* Clean up;
%symdel _ra_viyaHost;
%sysmacdelete _ra_check_status;
filename _ra_stt clear;
* Get the Viya Host URL;
%let viyaHost=%sysfunc(getoption(SERVICESBASEURL));

* Extract the path + filename from the tagert folder;
* Also abort if the wrong type was selected;
data _null_;
	sasViyaJobFile = scan("&sasViyaJobFile.", 1, ':', 'MO');
	if upcase(sasViyaJobFile) ne 'SASCONTENT' then do;
		putlog 'ERROR: Please select a folder stored in SAS Content for the SAS Job location';
		abort;
	end;

	targetFolderType = scan("&targetFolder.", 1, ':', 'MO');
	if upcase(targetFolderType) ne 'SASSERVER' then do;
		putlog 'ERROR: Please select a folder stored in SAS Server as the target folder';
		abort;
	end;
	call symput("targetFolder",scan("&targetFolder.", 2, ':', 'MO'));
run;

* Macro to check the HTTP Status response;
%macro checkHTTPStatus(status_code, status_phrase);
	%local status_code
		status_phrase;

	* HTTP Status Handling;
	data _null_;
		if &status_code. eq 200 then
			do;
				putlog 'NOTE: The request was  successful.';
				putlog "NOTE: The HTTP Status Code is &status_code..";
				putlog "NOTE: That means: &status_phrase..";
			end;
		else
			do;
				putlog 'ERROR: The request was not successful. Please check the Job Definition path';
				putlog "ERROR: The HTTP Status Code is &status_code..";
				putlog "ERROR: That means: &status_phrase..";
				abort;
			end;
	run;
%mend checkHTTPStatus;

* JSON Request Data;
filename pathData temp;

* Remove sascontent from the File location - added by the File Selector Input;
* Create the Input JSON for the POST Call;
data _null_;
	length dataIn $32000. numberOfSlashes 8.;
	sasViyaJobFile = substr("&sasViyaJobFile.", find("&sasViyaJobFile.", ':') + 1);
	numberOfSlashes = count(sasViyaJobFile, '/');

	* Build the JSON Request Data;
	file pathData;
	dataIn = '{"items": [';

	* Separate the elements of the Path;
	_counter = 1;
	do while(_counter <= numberOfSlashes);
		if _counter = 1 then dataIn = strip(dataIn) || '"' || strip(scan(sasViyaJobFile, _counter, '/')) || '"';
		else dataIn = strip(dataIn) || ',"' || strip(scan(sasViyaJobFile, _counter, '/')) || '"';

		if _counter = numberOfSlashes then call symputx('_fileName', strip(scan(sasViyaJobFile, numberOfSlashes, '/')));

		_counter + 1;
	end;

	dataIn = strip(dataIn) || '], "contentType": "jobDefinition"}';

	* Write to the file;
	put dataIn;

	call symputx('sasViyaJobFile', sasViyaJobFile);
run;

* Create a temporary file;
filename outResp temp;
 
* Find the Folder Member URI of the Job;
proc http
	method='POST'
	url="&viyaHost./folders/paths"
	in=pathData
	oauth_bearer=sas_services
	out=outResp;
	headers 'Content-Type'=' application/vnd.sas.content.folder.path+json';
run;

%checkHTTPStatus(&SYS_PROCHTTP_STATUS_CODE., &SYS_PROCHTTP_STATUS_PHRASE.);

* Create a JSON library from response;
libname outResp json;

* Get the URI of the file;
data _null_;
	set outResp.links(obs=1);
	call symput('_fileDescriptor', trim(uri));
run;

* Clear file & lib to reuse;
filename pathData clear;
filename outResp clear;
libname outResp clear;

* Create a temporary file;
filename outResp temp;

* Get the file URI;
proc http
	method='GET'
	url="&viyaHost.&_fileDescriptor."
	oauth_bearer=sas_services
	out=outResp;
	headers 'Content-Type'=' application/json';
run;

%checkHTTPStatus(&SYS_PROCHTTP_STATUS_CODE., &SYS_PROCHTTP_STATUS_PHRASE.);

* Create a JSON library from response;
libname outResp json;

* Get the URI of the Job Definition;
data _null_;
	set outResp.alldata(where=(p1='uri'));
	call symput('_jobDefinition', trim(value));
run;

* Clear file & lib to reuse;
filename outResp clear;
libname outResp clear;

* Create a temporary file;
filename outResp temp;

* Get the jobDefinition;
proc http
	method='GET'
	url="&viyaHost.&_jobDefinition."
	oauth_bearer=sas_services
	out=outResp;
	headers 'Content-Type'=' application/json';
run;

%checkHTTPStatus(&SYS_PROCHTTP_STATUS_CODE., &SYS_PROCHTTP_STATUS_PHRASE.);

* Write complete job definition as json;
filename jbdef "&targetFolder./&_fileName..json";
	
data _null_;
	infile outResp;
	file jbdef;
	input;
	put _infile_;
run;
	
filename jbdef clear;

* Create a JSON library from response;
libname outResp json;

* Initialize the checks for different save types;
%let _hasParams = 0;
%let _hasCode = 0;
%let _hasForm = 0;
%let _hasXMLPrompt = 0;
%let _hasJSONPrompt = 0;

* Check what content is available to save;
data _null_;
	set outResp.alldata(keep=p1 value);

	if p1 = 'parameters' then call symput('_hasParams', 1);
	else if p1 = 'code' then call symput('_hasCode', 1);

	if value = 'form' then call symput('_hasForm', 1);
	else if value = 'prompts' then call symput('_hasXMLPrompt', 1);
	else if value = 'prompts_v2' then call symput('_hasJSONPrompt', 1);
run;

* Save the parameters to the folder;
%if &_hasParams. %then %do;
	filename params "&targetFolder./&_fileName..txt";
	
	data _null_;
		length outLine $32000.;
		set outResp.parameters(drop=ordinal_root ordinal_parameters version);
		file params;
		outLine = 'name: ' || name || '; defaultValue: ' || defaultValue || '; type: ' || type || '; required: ' || required;
		put outLine;
	run;
	
	filename params clear;
%end;

* Save the code to the folder;
%if &_hasCode. %then %do;
	filename code "&targetFolder./&_fileName..sas";
	
	data _null_;
		set outResp.alldata(where=(p1='code'));
		file code;
		put value;
	run;
	
	filename code clear;
%end;

* Save the form to the folder;
%if &_hasForm. %then %do;
	filename form "&targetFolder./&_fileName..html";
	
	data _null_;
		set outResp.properties(where=(name='form'));
		if length(value) > 1 then do;
			file form;
			put value;
		end;
		else do;
			call symput('_hasForm', 0);
		end;
	run;
	
	filename form clear;
%end;

* Save the XML prompt to the folder;
%if &_hasXMLPrompt. %then %do;
	filename xml "&targetFolder./&_fileName..xml";
	
	data _null_;
		set outResp.properties(where=(name='prompts'));
		if length(value) > 1 then do;
			file xml;
			put value;
		end;
		else do;
			call symput('_hasXMLPrompt', 0);
		end;
	run;
	
	filename xml clear;
%end;

* Save the JSON prompt to the folder;
%if &_hasJSONPrompt. %then %do;
	filename jsonP "&targetFolder./&_fileName._prompt.json";
	
	data _null_;
		set outResp.properties(where=(name='prompts_v2'));
		if length(value) > 1 then do;
			file jsonP;
			put value;
		end;
		else do;
			call symput('_hasJSONPrompt', 0);
		end;
	run;
	
	filename jsonP clear;
%end;

* Create a message for the user;
data work._ejm_result;
	length resultString $1000.;
	resultString = "All results were saved here: &targetFolder.";
	output;
	resultString = "The Job Definition was saved as: &_fileName..json";
	output;
	if &_hasParams. then do;
		resultString = "The Job Parameters were saved as: &_fileName..txt";
		output;
	end;
	if &_hasCode. then do;
		resultString = "The Job Code was saved as: &_fileName..sas";
		output;
	end;
	if &_hasForm. then do;
		resultString = "The Job Form was saved as: &_fileName..html";
		output;
	end;
	if &_hasXMLPrompt. then do;
		resultString = "The Job XML Prompt was saved as: &_fileName..xml";
		output;
	end;
	if &_hasJSONPrompt. then do;
		resultString = "The Job JSON Prompt was saved as: &_fileName._prompt.json";
		output;
	end;
run;

ods listing close;
ods html5;
title1 'Result files of the job metadata extraction';

proc report data=work._ejm_result noheader;
run;

title;
ods html5 close;

* Clean up;
filename outResp clear;
libname outResp clear;
%symdel _fileName _fileDescriptor _jobDefinition _hasParams _hasCode _hasForm _hasXMLPrompt _hasJSONPrompt;
%sysmacdelete checkHTTPStatus;
proc datasets library=work nolist;
	delete _ejm_result;
run;
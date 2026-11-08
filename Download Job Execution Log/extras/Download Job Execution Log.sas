
/*
	Extract the server type for server type checking.
*/
data _null_;
	call symputx("_serverType", strip(scan("&_targetlocation", 1, ':')));
run;
%put &=_serverType;

data _null_;
	call symputx("_targetdirectory", strip(scan("&_targetlocation", 2, ':')));
run;
%put NOTE: _targetdirectory: &_targetdirectory;

%let viyaHost =;
data _null_; 
	call symputx('viyaHost', reverse(substr(substr(reverse("&_BASEURL."), 2), find(substr(reverse("&_BASEURL."), 2), '/') + 1)));
run;
%put NOTE: viyaHost: &viyaHost;

/*
	Create for each Id a macro variable, to be used in the loop that calls the 'GetJobExecutionLog' macro. 
*/
%let nbr_ids = 0;
data _null_;
	set 
		&_inputTable end=last;
	call symputx('Id'||strip(put(_N_, 8.)), &_idColumn);
	if last then call symputx('nbr_ids', _N_);        
run;
%put NOTE: nbr_ids: &nbr_ids;

/*
	Create the output table.
*/
data &_output;
	attrib JobExecutionId length=$36.;
	attrib logFile length=$256.;
	attrib message length=$256.;
	stop;
run;

%let is_valid_json = 0;
%macro is_json_file(file_path);
	%local 
		file_ref 
		firstchar;

	/* 
		Open the file and read the first character.
		If that character is a '{', then we assume that the file is a json file.
	*/
	filename file_ref "&file_path";
	data _null_;
		infile 
			file_ref 
			firstobs=1 
			obs=1 
			truncover;
		
		input @1 firstchar $1.;
		if firstchar = '{' then 
			call symputx("is_valid_json", 1);
	run;
	filename file_ref clear;
%mend is_json_file;

%macro GetJobExecutionLog
(
	jobExecutionId=
);

	/*
		Initialize the following macro variables to be empty of 0.
	*/
	%let message =;
	%let is_valid_json = 0;
	
	/*
		Setup and execute the initial job execution information request from the specified endpoint.
	*/
	filename response temp;
	proc http
		url="&viyaHost./jobExecution/jobs/&jobExecutionId"
		out=response
		method="get"
			oauth_bearer = sas_services;	
		headers
			'Accept'='application/json';
	run;
	
	/*
		Validate the we've received a response file and that the root- and jobrequest tables exist within the response file.
	*/
	%if %sysfunc(fexist(response)) %then %do;
		libname resp json fileref=response;
		%if %sysfunc(exist(resp.root)) and %sysfunc(exist(resp.jobrequest)) %then %do;

			/*
				before trying to use the column 'logLocation', verify that it exists.
			*/
			%let columnExists = 0;
			%let dsid = %sysfunc(open(resp.root));
			%let columnExists = %sysfunc(varnum(&dsid, loglocation));
			%let rc = %sysfunc(close(&dsid));

			%if &columnExists > 0 %then %do;

				/*
					Retrieve the log file information from the response file.
				*/
				%let loglocation=;
				proc sql noprint;
					select logLocation into :loglocation from resp.root;
				quit;
				%put NOTE: loglocation: &loglocation;
			
				/*
					The column 'name' in the jobrequest table is not always available...
				*/
				%let columnExists = 0;
				%let dsid = %sysfunc(open(resp.jobrequest));
				%let columnExists = %sysfunc(varnum(&dsid, name));
				%let rc = %sysfunc(close(&dsid));

				%let logname =;
				%if &columnExists > 0 %then %do;	
					/*
						Create the logfile name, based on the convention used by the 'log file download' functionality used by the 
						environment manager.
					*/	

					proc sql noprint;
						select 
							strip(tranwrd(j.name, "/", "|")) || '_' || strip(r.createdBy) || '_' || strip(r.creationTimeStamp) || '.log' into :logname
						from
							resp.root as r inner join resp.jobrequest as j on r.ordinal_root = j.ordinal_root;	
					quit;
				%end;
				%else %do;
					/*
						The name column doesn't exist, give it a default name.
					*/

					proc sql noprint;
						select 
							'Unknown name' || '_' || strip(r.createdBy) || '_' || strip(r.creationTimeStamp) || '.log' into :logname
						from
							resp.root as r;	
					quit;
				%end;
				
				%let logname = %str(&logname);
				%put NOTE: logname: &logname;
				/*
					Setup the request for the log file and execute it.
				*/
				filename log temp;
				proc http
					url="&viyaHost./&loglocation./content"
					out=log
					method="get"
						oauth_bearer = sas_services;	
					headers
						'Accept'='application/json';
				run;
				/*
					Validate that we've recieved the log response file from the system.
				*/
				%if %sysfunc(fexist(log)) %then %do;

					/*
						Validate that the response file really is a json file.
					*/
					%let file_location = %sysfunc(pathname(log, fileref));
					%is_json_file(&file_location);
					%put is_valid_json: &is_valid_json;
						
					%if &is_valid_json eq 1 %then %do;

						/*
							The returned file really is a proper json file.
						*/
						libname log json fileref=log;
						%if %sysfunc(exist(log.items)) %then %do;

							/*
								Write the line column, from the items table, to a physical file.
							*/
							data _null_;
								set 
									log.items(keep=line);
								/*
									The resulting log file is written to the specified location and 
									has the defined file name.
								*/	
								file 
									"&_targetdirectory./&logname";
								put (_all_) (+0);
							run;
							data success;
								attrib JobExecutionId length=$36.;
								attrib logFile length=$256.;
								attrib message length=$256.;
						
								JobExecutionId = "&jobExecutionId";
								logFile = "&_targetdirectory./&logname";
								message = "";
								output;
							run;
							proc append base=&_output data=work.success force; run;
						%end;
						%else %do;
							/*
								We have a log response file, which is also a json file, but is doesn't have the 
								items table included...

								Lets have a look for the message column and give that back as feedback to the user.									
							*/
							%let columnExists = 0;
							%let dsid = %sysfunc(open(log.root));
							%let columnExists = %sysfunc(varnum(&dsid, message));
							%let rc = %sysfunc(close(&dsid));
						
							%if &columnExists > 0 %then %do;
								proc sql noprint;
									select
										message into :message
									from
										log.root;
								quit;
							%end;
							%else %do;
								/*
									If everything failse...
								*/
								%let message = ERROR: The items table does not exist for the log response file.;
							%end;
						%end;
						/*
							Clear the libary reference, if it exists.
						*/
						%if %sysfunc(libref(log)) EQ 0 %then %do;
							libname log clear;
						%end;
					%end;
					%else %do;
						/*
							The returned response file is not a JSON file. For now I've decided to copy that file with the specified 
							naming convention to the target directory.

							Note that the log reference is defined as temp and will be remove automatically.
						*/
						%let target_file_name = %bquote(&_targetdirectory./&logname);
						filename targetf "&target_file_name";
						data _null_;
							rc = fcopy('log', 'targetf');
						run;
						data success;
							attrib JobExecutionId length=$36.;
							attrib logFile length=$256.;
							attrib message length=$256.;
						
							JobExecutionId = "&jobExecutionId";
							logFile = "&target_file_name";
							message = "&message";
							output;
						run;
						proc append base=&_output data=work.success force; run;
					%end;
				%end;
				%else %do;
					%let message = ERROR: No log response file received.;
				%end;
			%end;
			%else %do;
				%let message = ERROR: The column 'logLocation' doesn not exist, in the initial response file. Unable to retrieve the log file.;
			%end;
		%end;
		%else %do;
			/*
				We have a response file, but no jobrequest table....

				Lets have a look for the message column and give that back as feedback to the user.	
			*/
			%let columnExists = 0;
			%let dsid = %sysfunc(open(resp.root));
			%let columnExists = %sysfunc(varnum(&dsid, message));
			%let rc = %sysfunc(close(&dsid));
							
			%if &columnExists > 0 %then %do;
				proc sql noprint;
					select
						message into :message
					from
						resp.root;
				quit;
			%end;
			%else %do;
				/*
					If the message column doesn't exist, give a default value back.
				*/
				%let message = ERROR: The root- and/or jobrequest table does not exist for the initial response file. Unable to retrieve the log file.;
			%end;
		%end;
		/*
			Clear the library reference, if it exists.
		*/
		%if %sysfunc(libref(resp)) EQ 0 %then %do;
			libname resp clear;
		%end;
	%end;
	%else %do;
		%let message = ERROR: No response file received.;
	%end;
	/*
		In case the message macro variable isn't empty, make that known for the end-user.
	*/
	%if (%superq(message) ne ) %then %do;
		data message;
			attrib JobExecutionId length=$36.;
			attrib logFile length=$256.;
			attrib message length=$256.;
						
			JobExecutionId = "&jobExecutionId";
			message = "&message";
			output;
		run;
		proc append base=&_output data=work.message force; run;
	%end;
%mend GetJobExecutionLog;

%macro calling_GetJobExecutionLog;
	/*
		For each id from the input table, call the 'GetJobExecutionLog' macro.
	*/
	%if &_serverType eq sasserver %then %do;
		%do index = 1 %to &nbr_ids;
			%put NOTE: Downloading the log file for Job execution Id: &&ID&index;
			%GetJobExecutionLog(jobExecutionId=&&ID&index);
		%end;
	%end;
	%else %do;
		%put ERROR: Please select a location on the SAS Server. SAS Content folders are not supported by this custom step;
		%abort exit;
	%end;
%mend calling_GetJobExecutionLog;

%calling_GetJobExecutionLog;

/*
	Remove all macro variables from memory.
*/
%symdel nbr_ids /NOWARN;
%symdel is_valid_json /NOWARN;

/*
	Remove all macros from memory.
*/
%SYSMACDELETE is_json_file / NOWARN;
%SYSMACDELETE GetJobExecutionLog / NOWARN;
%SYSMACDELETE calling_GetJobExecutionLog / NOWARN;
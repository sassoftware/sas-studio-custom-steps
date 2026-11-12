/*
    Information sources used:
        - https://go.documentation.sas.com/doc/en/infocatcdc/v_060/infocatgl/n13cxuzpgjzdpgn1p74ma6jmaumg.htm
        - https://developer.sas.com/rest-apis/glossary/importTerms
*/

data _null_;
	call symputx("_targetdirectory", strip(scan("&_targetlocation", 2, ':')));
run;

data _null_;
	call symputx("_csv", strip(scan("&_csvFile", 2, ':')));
run;

data _null_; 
	call symputx('viyaHost', kreverse(ksubstr(ksubstr(kreverse("&_BASEURL."), 2), kfind(ksubstr(kreverse("&_BASEURL."), 2), '/') + 1)));
run;

/*
    Only physical directories are supported at the moment.
    The following macro variables are used to verify that.
*/
data _null_;
	call symputx("_csvDirType", strip(scan("&_csvFile", 1, ':')));
run;
data _null_;
	call symputx("_targetdirType", strip(scan("&_targetlocation", 1, ':')));
run;

%macro loadCSV;

/*
    Define the REST API request status table.
*/
data &_output01;
    attrib id length=$36.;
   	attrib job_name length=$128.;
    attrib state length=$32.;
   	attrib start_dttm length=8 format=datetime22.3;
    attrib end_dttm length=8 format=datetime22.3;
    stop;
run;

/*
    Define the job execution log download status table.
*/
data &_output02;
	attrib id length=$36.;
	attrib logFile length=$256.;
	attrib message length=$256.;
	stop;
run;

%if &_csvDirType EQ sasserver %then %do;

    filename csv "&_csv";
    filename response temp;

    /*
        Configure and start the CSV import process.
    */
    proc http
        method="POST"
        URL="&viyaHost./glossary/importTerms"
        oauth_bearer = sas_services
        in=multi form(
            "termCSV"=csv,
        /*
            Set the updateExisting key based on the end-user's input.
        */
        %if &_termExists EQ _skip %then %do;        
            "updateExisting"="false"
        %end;
        %else %do;
            "updateExisting"="true"
        %end;
        )
        out=response;
        headers
            "Accept"="application/json, application/vnd.sas.job.execution.job+json, application/vnd.sas.error+json";
    run;

    /*
        Write the status row with information taken from the response file.
    */
    %macro writeStatusRow;
        %if %sysfunc(fexist(response)) %then %do;
            libname status json fileref=response;
            /*
                Create a status row.
            */
            proc sql noprint;
                insert into &_output01
                (
                    id,
                    job_name,
                    state,
                    start_dttm
                )
                select
                    a.id,
                    b.name,
                    a.state,
                    input(a.creationTimeStamp, E8601DZ.)
                from
                    status.root a inner join 
                    status.jobrequest b on a.ordinal_root = b.ordinal_root;
            quit;
        %end;
        %else %do;
            /*
                If there's no response file, abort the process.
            */
            %put ERROR: No response file encountered.;
            %abort exit;
        %end;
    %mend;
    %writeStatusRow;

    %macro updateStatus(
	    Id=
    );
	    /*
		    This process only makes sense when the output table exists.
	    */
	    %if %sysfunc(exist(&_output01, data)) %then %do;
    		/*
			    Setup and execute the HTTP request.
		    */
		    filename response temp;
    		proc http
	    		url="&viyahost./jobExecution/jobs/&Id"
		    	out=response
			    method="get"
				    oauth_bearer = sas_services;
    			headers
	    			'Accept'='application/json';
		    run;

    		/*
                Check if there's a response file.
            */
            %if %sysfunc(fexist(response)) %then %do;
	    		libname status json fileref=response;
		    	/*
			    	Update the output table with the response from the REST API.
				    Note that the root table will always contain one row.
    			*/
	    		proc sql noprint;
		    		update 
			    		&_output01
				    set 	
					    state = 
						    (
							    select 
								    kstrip(state) 
    							from 
	    							status.root
		    				),
			    		end_dttm = 
				    		(
					    		select 
						    		input(modifiedTimeStamp, E8601DZ.)
							    from
								    status.root
    						)
	    			where
		    			id = "&id";
			    quit;
			    libname status clear;
		    %end;
    		%else %do;
	    		/*
		    		No abort, might be a hick-up...
			    */
    			%put ERROR: Unable to update the status table. No response file encountered.;
	    	%end;
	    %end;
    	%else %do;
	    	%put ERROR: The status table, &_output01, does not exist.;
		    %abort exit;
	    %end;
    %mend;

    %macro checkForCompletion;
	    /*
		    Update for all processes the status and determain if all processes have finished.
	    */
	    %if %sysfunc(exist(&_output01, data)) %then %do;
    		%let still_running = -1;
	    	%let wait_cycles = 0;
		    %do %while (&still_running ne 0);
			    /*
				    Update the status for all running jobs.
    			*/
	    		data _null_;
		    		set
			    		&_output01
				    	(
					    	where=(kupcase(state) = 'RUNNING')
    					);
	    					call execute
		    				(
			    				cats
				    			(
					    			'%updateStatus(Id= %STR(',
						    		kSTRIP(id),
							    	'))'
							    )
						    );
			    run;
	
			    /*
				    Count the number of running jobs.
			    */
			    proc sql noprint;
				    select 
					    count(*) into :still_running TRIMMED
    				from 
	    				&_output01 
		    		where 
			    		kupcase(state) = 'RUNNING';
			    quit;
    			%put NOTE: Number of jobs that are running: &still_running;
	
    			/*
	    			Sleep for one second before checking for completion again.
		    	*/
			    data _null_;
				    slept = sleep(1, 1);
    			run;
	    		%let wait_cycles = %eval(&wait_cycles + 1);
		    %end;
    		%put NOTE: Total number of wait cycles of 1 second: &wait_cycles;
	    %end;
    	%else %do;
	    	%put ERROR: The status table, &_output01, does not exist.;
		    %abort exit;
    	%end;
    %mend;
    %checkForCompletion;

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
    %mend;

    /*
        The following macro is responsible for downloading the
        job execution log.
    */
    %macro GetJobExecutionLog(
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
	    							attrib id length=$36.;
		    						attrib logFile length=$256.;
			    					attrib message length=$256.;
                                    
    								id = "&jobExecutionId";
	    							logFile = "&_targetdirectory./&logname";
		    						message = "";
			    					output;
				    			run;
					    		proc append base=&_output02 data=work.success force; run;
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
		    							If everything fails...
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
	    						attrib id length=$36.;
		    					attrib logFile length=$256.;
			    				attrib message length=$256.;
                                
    							id = "&jobExecutionId";
	    						logFile = "&target_file_name";
		    					message = "&message";
			    				output;
				    		run;
					    	proc append base=&_output02 data=work.success force; run;
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
    			attrib id length=$36.;
	    		attrib logFile length=$256.;
		    	attrib message length=$256.;
						
    			id = "&jobExecutionId";
	    		message = "&message";
		    	output;
		    run;
		    proc append base=&_output02 data=work.message force; run;
	    %end;
    %mend;
%end;
%else %do;
    %put ERROR: Please select a file located on the SAS Server. SAS Content folders are not supported by this custom step.;
%end;
%mend;
%loadCSV;

%macro downloadLOG;
%if &_downloadLog EQ 1 %then %do;
    %if &_targetdirType EQ sasserver %then %do;
        /*
            The end-user specified to download the job execution log.
        */
        %put NOTE: Downloading the job execution log.;
        %let jobExecutionId=;
        proc sql noprint;
            select id into :jobExecutionId trimmed from &_output01;
        quit;
        %put &=jobExecutionId;
        
        %if %unquote(%str(%')&jobExecutionId%str(%')) ne '' %then %do;
            %GetJobExecutionLog(
	            jobExecutionId=&jobExecutionId
            );
        %end;
        %else %do;
            %put ERROR: No job execution id available. Unable to download the a log file.;
        %end;
    %end;
    %else %do;
        %put ERROR: Please select a location on the SAS Server. SAS Content folders are not supported by this custom step.;
    %end;    
%end;
%else %do;
    %put NOTE: Not downloading the job execution log.;
%end;
%mend;
%downloadLOG;

/*
	Remove all macro variables from memory.
*/
%symdel nbr_ids /NOWARN;
%symdel is_valid_json /NOWARN;
%symdel _targetdirectory /NOWARN;
%symdel _csv /NOWARN;

/*
	Remove all macros from memory.
*/
%SYSMACDELETE is_json_file / NOWARN;
%SYSMACDELETE GetJobExecutionLog / NOWARN;
%sysmacdelete writeStatusRow /NOWARN;
%sysmacdelete updateStatus /NOWARN;
%sysmacdelete checkForCompletion /NOWARN;
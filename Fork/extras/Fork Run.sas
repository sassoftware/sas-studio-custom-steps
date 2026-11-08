%let job_uri=;
%let nbr_job_rows=0;

/*
	Create the output table.
*/
data &_output;
	attrib id length=$36.;
	attrib job_name length=$128.;
	attrib state length=$32.;
	attrib start_dttm length=8 format=datetime22.3;
	stop;
run;

/*
	Create the value for the viyaHost macro variable.
*/
data _null_; 
	call symputx('viyaHost', kreverse(ksubstr(ksubstr(kreverse("&_BASEURL."), 2), kfind(ksubstr(kreverse("&_BASEURL."), 2), '/') + 1)));
run;

/*
	The following macro is there to retrieve the job definition uri, based on the (deployed) job name entered
	by the end-user.
*/
%macro get_job_uri
(
	job_name=	
);
	%if %unquote(%str(%')&job_name%str(%')) ne '' %then %do;

		/*
			Setup and execute the http request.
		*/
		filename joburi temp;
		proc http
			url = "&viyahost./jobExecution/jobRequests"
			out= joburi
			method='get'
				oauth_bearer = sas_services
				%if &job_name ne %then %do;
					query= ('filter' = "eq('name', '&job_name')");
				%end;
				%else %do;
					;
				%end;
			headers
				'Accept'= 'application/vnd.sas.collection+json';
		run;	

		/*
			Process the response file, if it exists.
		*/
		%if %sysfunc(fexist(joburi)) %then %do;

			libname joburi json;
			/*
				Check that the items table exists.
			*/
			%if %sysfunc(exist(joburi.items)) %then %do;
				/*
					Select the jobs for which the URI exists.

					Note that for this to work, the columns 'name' and 'jobDefinitionUri' need
					to exist in the response file!
				*/
				%let ds = %sysfunc(open(joburi.items));
				%if &ds > 0 %then %do;
					%let dsName = %sysfunc(varnum(&ds, name));
					%let dsUri = %sysfunc(varnum(&ds, jobDefinitionUri));
					%let rc = %sysfunc(close(&ds));

					%if &dsName and &dsUri %then %do;
						data job_uri;
							set joburi.items
							(
								keep = 
									name 
									jobDefinitionUri 
								where = 
								(
									jobDefinitionUri ~= ''
								)
							);
						run;
					
						libname joburi;
					%end;
					%else %do;
						%put ERROR: Importants columns do not exist in the response file. Aborting process.;
						%abort exit;
					%end;
				%end;
				%else %do;
					%put ERROR: Unable to open the 'items' array. Aborting process.;
					%abort exit;
				%end;	
			%end;
			%else %do;
				%put ERROR: The items array in the response file does not exist. Aborting process.;
				%abort exit;
			%end;
		%end;
		%else %do;
			%put ERROR: The response file does not exist. Aborting process.;
			%abort exit;
		%end;

		/*
			Assign the job uri to the 'job_uri' macro variable.
		*/
		%if %sysfunc(exist(work.job_uri)) %then %do;

			/*
				Count the number of jobs returned.
				Only continue in case the number equals to 1.
			*/
			data _null_;
				if 0 then set work.job_uri nobs=rows;
				call symputx('nbr_job_rows', rows);
			run;

			/*
				Abort in case the number of returned values isn't exactly one.
			*/
			%if &nbr_job_rows NE 1 %then %do;
				%put ERROR: &nbr_job_rows jobs encountered with name &job_name. Aborting process.;
				%abort exit;
			%end;
			%else %do;
				data _null_;
					set
						work.job_uri;
					call symputx("job_uri", kstrip(jobDefinitionUri));
				run;		
			%end;
		%end;
		%else %do;
			%put ERROR: job_uri table does not exist. Aborting process.;
			%abort exit;
		%end;
	%end;
	%else %do;
		%put ERROR: No deployed object name provided. Aborting process.;
		%abort exit;
	%end;
%mend;
%get_job_uri(
	job_name = &_jobname
);

%macro exec_job
(
	job_uri=
);

	%if %unquote(%str(%')&job_uri%str(%')) ne '' %then %do;

		/*
			Create the JSON file for the execute request.
		*/
		filename request temp;
		proc json out=request nosastags;
			write open object;
				write values "name" "&_jobname";
				write values "jobDefinitionUri" "&job_uri";
			write close;
		run;		
	
		/*
			Setup and execute the HTTP request.
		*/
		filename response temp;
		proc http
			url = "&viyahost./jobExecution/jobs?submitter=workflow"
			in = request
			out = response
			method='post'
				oauth_bearer = sas_services;
			headers
				'Content-Type'='application/vnd.sas.job.execution.job.request+json'
				'Accept'='application/vnd.sas.job.execution.job+json';
		run;

		%if %sysfunc(fexist(response)) %then %do;
			/*
				Add the state, should be 'running', of the current job to the execute_status table.
			
				Note that the column specification can differ. This will cause warnings during the PROC APPEND step.
				That is why the resulting table firstly needs to be created based on the internally defined status table.
			*/
			libname resp json fileref=response;
			data &_output(drop=creationTimeStamp);
				attrib job_name length=$128.;
				attrib start_dttm length=8 format=datetime22.3;
				attrib state length=$32.;
				set 
					&_output(obs=0)
				resp.root(keep=id state creationTimeStamp);

				start_dttm = input(creationTimeStamp, E8601DZ.);
				job_name = "&_jobname";
			run;

			libname resp;
		%end;
		%else %do;
			%put ERROR: The response file does not exist. Aborting process.;
			%abort exit;
		%end;
	%end;
	%else %do;
		%put ERROR: No URI provided. Unable to execute the deployed object. Aborting process.;
		%abort exit;
	%end;
%mend;

%exec_job(
	job_uri=&job_uri
);

/*
	Remove not needed macro variables.
*/
%symdel job_uri /nowarn;
%symdel nbr_job_rows /nowarn;

/*
	Remove not needed macros
*/
%sysmacdelete get_job_uri /nowarn;
%sysmacdelete exec_job /nowarn;
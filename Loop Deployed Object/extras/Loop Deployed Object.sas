/*
	Initialize the variables.
*/
%let nbr_job_rows = 0;
%let nbr_parameter_rows = 0;
%let nbr_rows = 0;
%let job_uri =;

/*
	Input for the input table validation.
	Count the number of rows. This number needs to be bigger then 0.
*/
data _NULL_;
	set 
		&_input_parameters end=last;
	if last then call symputx("nbr_parameter_rows", _n_);
run;

data _null_; 
	call symputx('viyaHost', kreverse(ksubstr(ksubstr(kreverse("&_BASEURL."), 2), kfind(ksubstr(kreverse("&_BASEURL."), 2), '/') + 1)));
run;

/*
	The following macro is responsible for retrieving the URI of the deployed flow.

	Note that the loop custom step is build around the assumption that the name of the job definition is unique and exists.
	In case it is not, the loop custom step will abort its operation.
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
				%put ERROR: The items table in the response file does not exist. Aborting process.;
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

/*
	Only start the process in case the parameter table contains more than 0 rows.
*/
%if &nbr_parameter_rows eq 0 %then %do;
	%put ERROR: Not enough parameters (&nbr_parameter_rows) to run the loop step. Aborting process.;
	%abort exit;
%end;
%else %do;
	/*
		The number of rows in the input table check out. Continue to run the process.
	*/
	data _null_; 
		call symputx('viyaHost', kreverse(ksubstr(ksubstr(kreverse("&_BASEURL."), 2), kfind(ksubstr(kreverse("&_BASEURL."), 2), '/') + 1)));
	run;

	/*
		The following macro is responsible for creating the JSON request for the job
		and the given set parameters/macro variables.
	*/
	%macro createJsonRequest(
		row=	
	);
		/*
			the value assigned to the macro variable 'process_name' is used to make the process visible in environment manager.
		*/
		%let process_name = Running '&_jobname' for input table row &row;
		data _null_;
			length 
				parameter $32767
				value $32767;

			/*
				Open the custom step input dataset.
			*/
			dsid = open("&_input_parameters");

			/*
				Note that the request file reference is defined out-side of this macro!
			*/	
			if (dsid > 0) then do;
				file request;
				put '{';
				put '"name": ' """&process_name""" ',';
				put '"jobDefinitionUri": ' """&job_uri""" ',';
				put '"arguments": {';
			
				/*
					Fetch the 'row'-th record.
				*/
				rc = fetchobs(dsid, &row);

				/*
					Retrieve the number of columns.
				*/
				columns = attrn(dsid,'nvars');
				
				/*
					For each column and value pair create an argument entry in the JSON file.
				*/
				do index = 1 to columns;
					/*
						Get the column name and the column type.
					*/
					vname = kstrip(varname(dsid, index));
					vtype = vartype(dsid, index);
				
					/*
						Depending on data type, handle the value appropriately.
					*/
					if (vtype~='C') then do;	
						/*
							Numeric values.
						*/
						value = put(getvarn(dsid, index), best32.);
						if index < columns then do;
							parameter = '"' || kstrip(vname) || '": "' || kstrip(value) || '",';
							put parameter;
						end;
						else do;
							parameter = '"' || kstrip(vname) || '": "' || kstrip(value) || '"';
							put parameter;
						end;
					end;
					else do;
						/*
							Character values.
						*/
						value = getvarc(dsid, index);

						if index < columns then do;
							parameter = '"' || kstrip(vname) || '": "' || kstrip(value) || '",';
							put parameter;
						end;				
						else do;
							parameter = '"' || kstrip(vname) || '": "' || kstrip(value) || '"';
							put parameter;
						end;
					end;
				end;
				put '}';
				put '}';
			end;
			else do;
				put "ERROR%QUOTE(:) Input table could not be opened.";
			end;
			dsid = close(dsid);
		run;
	%mend;

	/*
		The following macro is responsible for creating and assigning the input columns, and their properties, to the global macro variable 'column_line', to be 
		used in the step that creates the output table.
	*/
	%let columns_line=;
	%macro addColumns(
		ds=
	);
		/*
			Try to open the dataset.
		*/
		%let dsid = %sysfunc(open(&ds, i));
		%if (&dsid > 0) %then %do;

			/*
				Retrieve the number of columns.
			*/
			%let columns = %sysfunc(attrn(&dsid, nvars));

			/*
				For each column:
			*/
			%do i = 1 %to &columns;
				/*
					Retrieve the name, type, length and format.
				*/
				%let vname = %sysfunc(varname(&dsid, &i));
				%let vtype = %sysfunc(vartype(&dsid, &i));
				%let vlength = %sysfunc(varlen(&dsid, &i));
				%let vformat = %sysfunc(varfmt(&dsid, &i));
	
				/*
					Based on the column type and the existance of a format, create the column definition.
				*/
				%if &vtype EQ C %then %do;
					%if &vformat eq %then %do;
						%let columns_line = %str(&columns_line attrib &vname length=$&vlength;);
					%end;
					%else %do;
						%let columns_line = %str(&columns_line attrib &vname length=$&vlength format=&vformat;);
					%end;
				%end;
				%else %do;
					%if &vformat eq %then %do;
						%let columns_line = %str(&columns_line attrib &vname length=&vlength;);
					%end;
					%else %do;
						%let columns_line = %str(&columns_line attrib &vname length=&vlength format=&vformat;);
					%end;
				%end;	
			%end;	
			%let dsid = %sysfunc(close(&dsid));
		%end;
		%else %do;
			/*
				The table could not be opened. Specify the error message.
			*/
			%put %sysfunc(sysmsg());
			%let dsid = %sysfunc(close(&dsid));
		%end;
	%mend;
	%addColumns(
		ds=&_input_parameters
	);

	/*
		Create the status tables that will hold all execution statuses for all executed job requests.
		Based on this table you can create a polling mechanism to validate that each process has finished successfully.
	*/
	data &_output;
		attrib id length=$36.;
		attrib job_name length=$128.;
		/*
			Add input parameters/variables to the output table.
			
			Assigning the value to the macro variable, 'column_line', is performed by the 'addColumns' macro.
		*/
		&columns_line;
		attrib state length=$32.;
		attrib start_dttm length=8 format=datetime22.3;
		attrib end_dttm length=8 format=datetime22.3;
		stop;
	run;

	%macro addColumnValues(
		ds=,
		row=
	);

		%let values_line=;
		%let dsid = %sysfunc(open(&ds, i));
		%if (&dsid > 0) %then %do;

			%let columns = %sysfunc(attrn(&dsid, nvars));
			%let rc = %sysfunc(fetchobs(&dsid, &row));

			%do i = 1 %to &columns;
				%let vname = %sysfunc(varname(&dsid, &i));
				%let vtype = %sysfunc(vartype(&dsid, &i));

				%if &vtype EQ C %then %do;
					%let value = %BQUOTE(%sysfunc(getvarc(&dsid, &i)));
					%let values_line = %str(&values_line &vname=%str(%")&value%str(%"););
				%end;
				%else %do;
					%let value = %sysfunc(getvarn(&dsid, &i));
					%let values_line = %str(&values_line &vname=&value;);
				%end;
			%end;
			/*
				Assign the generated line to the macro variable so that it can be used in a data step.
			*/
			data _null_;
				call symputx('columnValues_line', strip("&Values_line"));
			run;
			%let dsid = %sysfunc(close(&dsid));
		%end;
		%else %do;
			%put %sysfunc(sysmsg());
			%let dsid = %sysfunc(close(&dsid));
		%end;
	%mend;	

	%macro exec_job
	(
		job_uri=,
		row=
	);

		%if %unquote(%str(%')&job_uri%str(%')) ne '' %then %do;

			/*
				In case the user asked for a delayed execution...
			*/		
			%if &_delayed eq 1 %then %do;
				%put NOTE: Delayed executing, waiting for &_delayedseconds seconds.;
				data _null_;
					sleeping = sleep(&_delayedseconds, 1);
				run;
			%end;

			/*
				Create the JSON request file.
			*/
			%let process_name = Flow instance for parameter table row &row;
			filename request temp;
			
			/*
				Create the JSON request.
				
				The file reference 'request' is used to create the resulting JSON file.
			*/
			%createJSONrequest(
				row=&row
			);

			/*
				Setup and execute the HTTP request.
			*/
			filename response temp;
			proc http
				url = "&viyahost./jobExecution/jobs?submitter=workflow"
				in = request
				out= response
				method='post'
					oauth_bearer = sas_services;
				headers
					'Content-Type'='application/vnd.sas.job.execution.job.request+json'
					'Accept'='application/vnd.sas.job.execution.job+json';
			run;

			%if %sysfunc(fexist(response)) %then %do;

				%let columnValues_line=;
				%addColumnValues(
					ds=&_input_parameters,
					row=&row
				);

				/*
					Add the state, should be 'running', of the current job to the execute_status table.
				
					Note that the column specification can differ. This will cause warnings during the PROC APPEND step.
					That is why the resulting table firstly needs to be created based on the internally defined status table.
				*/
				libname resp json fileref=response;
				data work.root(drop=creationTimeStamp);
					attrib job_name length=$128.;
					attrib end_dttm length=8 format=datetime22.3;	
					attrib start_dttm length=8 format=datetime22.3;
					set 
						&_output(obs=0)
						resp.root(keep=id state creationTimeStamp);

					start_dttm = input(creationTimeStamp, E8601DZ.);
					job_name = "&process_name";
					/*
						Add the current input parameters to the output/status table.
					*/
					&columnValues_line;
				run;
				proc append data=work.root base=&_output force; run;
				libname resp;
			%end;
			%else %do;
				%put ERROR: The response file does not exist. Aborting process.;
				%abort exit;
			%end;
		%end;
		%else %do;
			%put ERROR: No URI provided. Aborting process.;
			%abort exit;
		%end;
	%mend;

	%macro update_status
	(
		Id=
	);
		/*
			This process only makes sense when the execute_status table exists.
		*/
		%if %sysfunc(exist(&_output, data)) %then %do;
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

			%if %sysfunc(fexist(response)) %then %do;
				libname status json fileref=response;

				/*
					Update the output table with the values from the REST API.
					Note that the root table will always contain one row.
				*/
				proc sql noprint;
					update 
						&_output
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
			%put ERROR: The status table, &_output, does not exist.;
			%abort exit;
		%end;
	%mend;

	/*
		The following macro is responsible for:
		- Maintaining the job waiting queue.
		- Executing the jobs
		- Updating the status table.
	*/
	%macro exec_jobs;
		%put NOTE: Initial number of jobs in queue: &nbr_parameter_rows.;

		/*
			Initialize macro variables.
		*/
		%let index = 1;
		%do %while (&index le &nbr_parameter_rows);
			/*
				Check for the number running jobs, to be less or equal to
				the number of concurrent jobs.

				Note that in case that the _output table is empty, the macro variable 'running_jobs' is never reset. 
				That is the reason why the macro variable is initialized to 0 each time the following code is run.
			*/
			%let running_jobs = 0;
			data _null_;
				set 
					&_output(
						where=(kupcase(state)='RUNNING')
					) end=last;
				if last then call symput("running_jobs", _n_);
			run;
			%put NOTE: Number of running jobs: &running_jobs;
			
			/*
				If the number of running jobs is less then the amount of jobs allowed to run concurrenly,
				start a job and register it in the status table.
			*/
			%if (&running_jobs lt &concurrent_jobs) %then %do;
				%put NOTE: Adding new job from the queue;
				%exec_job(
					job_uri = &job_uri,
					row = &index
				);
				/*
					increment the index parameter, ready to start the next job. 
				*/
				%let index = %eval(&index + 1);	
			%end;

			/*
				Only update the status of jobs with state 'running'.
			*/
			data _null_;
				set
					&_output(where=(kupcase(state)='RUNNING'));

				call execute(
					cats(
						'%update_status(Id= %STR(',
						kSTRIP(id),
						'))'
					)
				);
			run;
			/*
				Wait 1/2 second for the next iteration.

				This will keep the log file size down.
			*/
			data _null_;
				slept = sleep(.50, 1);
			run;
		%end;
	%mend;
	%exec_jobs;	
%end;

/*
	The folllwing section is there to wait for the processes, just started, to be finished before continuing
	with the next (custom) step.
*/
%if &wait_for_processes %then %do;

	%macro check_for_completion;
		/*
			Update for all processes the status and determain if all processes have finished.
		*/
		%if %sysfunc(exist(&_output, data)) %then %do;
			%let still_running = -1;
			%let wait_cycles = 0;

			%do %while (&still_running ne 0);
				/*
					Update the status for all running jobs.
				*/
				data _null_;
					set
						&_output
						(
							where=(kupcase(state) = 'RUNNING')
						);

						call execute
						(
							cats
							(
								'%update_status(Id= %STR(',
								kSTRIP(id),
								'))'
							)
						);
				run;
		
				/*
					Count the number of jobs that are running.
				*/
				proc sql noprint;
					select 
						count(*) into :still_running 
					from 
						&_output 
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
			%put ERROR: The table status table, &_output, does not exist.;
			%abort exit;
		%end;
	%mend;
	%check_for_completion;

	/*
		Aborting in case of one or more processes failed only makes sense 
		if the custom step is set to wait for all processes to finish.
	*/
	%macro abort_on_failure;
		%let exception = 0;
		%if &abort_on_exception eq 1 %then %do;
			proc sql noprint;
				select 
					count(*) into :exception trimmed
				from 
					&_output 
				where 
					kupcase(state) ne 'COMPLETED';
			quit;
				
			%if &exception ne 0 %then %do;
				%put ERROR: &exception exception(s) encountered. Aborting process.;
				%abort exit;
			%end;
			%else %do;
				%put NOTE: No exceptions encountered. Continuing with the rest of the flow.;
			%end;
		%end;
	%mend;
	%abort_on_failure;
%end;

/*
	Remove all macro variables from memory.
*/
%symdel nbr_job_rows /NOWARN;
%symdel nbr_parameter_rows /NOWARN;
%symdel nbr_rows /NOWARN;
%symdel job_uri /NOWARN;
%symdel columns_line /NOWARN;
/*
	Remove all macros from memory.
*/
%SYSMACDELETE get_job_uri / NOWARN;
%SYSMACDELETE createJsonRequest / NOWARN;
%SYSMACDELETE addColumns / NOWARN;
%SYSMACDELETE addColumnValues / NOWARN;
%SYSMACDELETE exec_job / NOWARN;
%SYSMACDELETE update_status / NOWARN;
%SYSMACDELETE exec_jobs / NOWARN;
%SYSMACDELETE check_for_completion / NOWARN;
%SYSMACDELETE abort_on_failure / NOWARN;
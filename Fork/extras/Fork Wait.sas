/* options mprint mlogic symbolgen source notes; */

/*
	The maximum number of tables attached to this custom step.
*/
%let max_input_count = 8;

/*
	The actual number of input tables attached to the custom step.
*/
%let input_count=0;

/*
	Contains all input tables, separated by a '|' symbol.
*/
%let input_string=;

/*
	Default the value to 1/true.
	Used and set by the macros validateInputTables and getInputCount.
*/
%let validation_result = 1;

/*
	Define the viyaHost variable, to be used by the REST API call.	
*/
data _null_; 
	call symputx('viyaHost', kreverse(ksubstr(ksubstr(kreverse("&_BASEURL."), 2), kfind(ksubstr(kreverse("&_BASEURL."), 2), '/') + 1)));
run;

/*
	Create the output table
*/
data &_output;
	attrib id length=$36.;
	attrib job_name length=$128.;
	attrib state length=$32.;
	attrib start_dttm length=8 format=datetime22.3;
	attrib end_dttm length=8 format=datetime22.3;
	stop;
run;

/*
	Copy the content of the validated input table to the output table.
	Note that only non-existing rows are added to the output table.
*/
%macro copyInputContent
(
	inputTable
);
	
	/*
		Create a copy of the output table. You can't use, in case of SAS dataset usage, a table as 
		input and output at the same time.
	*/
	data work._temp;
		set
			&_output;
	run;

	/*
		Insert rows not already in the custom step's output table.
	*/
	proc sql;
		insert into &_output
		(
			id,
			job_name,
			state,
			start_dttm
		)
		select
			t1.id,
			t1.job_name,
			t1.state,
			t1.start_dttm
		from 
			&inputTable as t1 left outer join work._temp t2 on t1.id = t2.id
		where
			t2.id is null;			
	quit;
%mend;

/*
	This macro does the following:	
	- Count the number of tables attached to the custom step.
	- Create a '|' separated string with all attached physical table names, to be used by the validateInputTables macro.
*/
%macro getInputCount;
	%let index = 1;
	%do %while (&index le &max_input_count);
		%if %symexist(Fork_&index) %then %do;
			%let input_count = %eval(&input_count + 1);
			%let input_string = &input_string|%sysfunc(strip(&&Fork_&index));
		%end;
		%let index = %eval(&index + 1);
	%end;
	/*
		Remove the first '|' character from the input string.
		Note that this is only valid with more than 0 input tables.

		In case we have 0 input tables, we set the set the 'validation_result'
		macro variable to 0. This will cause the custom step to abort.
	*/
	%if &input_count gt 0 %then %do;
		%let input_string = %sysfunc(substr(&input_string, 2));
	%end;
	%else %do;
		%let validation_result = 0;
	%end;
%mend;
%getInputCount;

%put NOTE: Number of attached processes/tables: &input_count;
%put NOTE: Input string: &input_string;
%put NOTE: getInputCount validation result: &validation_result;

/*
	Validate the input tables for the existance of the four columns.
*/
%macro validateInputTables;

	%let index = 1;
	/*
		As long as there is a table and the validation for a table checks-out, continue.
		Note that in case the macro getInputCount return validation_result equals 0, the macro will abend.
	*/
	%do %while (%scan(&input_string, &index, '|') ne %str() and &validation_result);
		%let table = %scan(&input_string, &index, '|');
		%put NOTE: Validating table: &table;
		/*
			Check for the columns:
			1. ID
				The ID of the job execution id.
			2. JOB_NAME
				The name of the job execution.
			3. STATE
				The initial status of the job execution.
			4. START_DTTM
				The date and time the job execution started.
		*/
		%let ds = %sysfunc(open(&table));
		%if &ds > 0 %then %do;
			%let dsID = %sysfunc(varnum(&ds, ID));
			%let dsNAME = %sysfunc(varnum(&ds, JOB_NAME));
			%let dsSTATUS = %sysfunc(varnum(&ds, STATE));
			%let dsSTARTDT = %sysfunc(varnum(&ds, start_dttm));

			%if &dsID and &dsNAME and &dsSTATUS and &dsSTARTDT %then %do;
				%let validation_result = 1;
				%put NOTE: Validation for table &table succeeded.;
				/*
					The input table checks out. 
					Now copy the content of the input table to the output table so that
					it can be maintained there.
				*/
				%copyInputContent
				(
					inputTable= &table
				);
			%end;
			%else %do;
				%let validation_result = 0;
				%put NOTE: Validation for table &table failed.;
			%end;
		%end;
		%else %do;
			%let validation_result = 0;
			%put ERROR: Unable to open table &table for validation.;	
		%end;
		
		%let rc = %sysfunc(close(&ds));

		%let index = %eval(&index + 1);
	%end;
%mend;
%validateInputTables;

%put NOTE: Validation result: &validation_result;

/*
	
*/
%macro update_status
(
	Id=
);
	/*
		This process only makes sense when the output table exists.
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
					count(*) into :still_running TRIMMED
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
		%put ERROR: The status table, &_output, does not exist.;
		%abort exit;
	%end;
%mend;

/*
	The input tables have been verified, the contents has been copied.
	The custom step continues with waiting for all processes to be finished. (= NOT 'Running')
*/
%macro main;
	%if &validation_result %then %do;
		%check_for_completion;
	%end;
	%else %do;
		%put ERROR: Input validation failed. Aborting process.;
		%abort exit;
	%end;
%mend;
%main;

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

/*
	Remove not needed macro variables.
*/
%symdel max_input_count /nowarn;
%symdel input_count /nowarn;
%symdel input_string /nowarn;
%symdel validation_result /nowarn;

/*
	Remove not needed macros
*/
%sysmacdelete abort_on_failure /nowarn;
%sysmacdelete main /nowarn;
%sysmacdelete check_for_completion /nowarn;
%sysmacdelete update_status /nowarn;
%sysmacdelete validateInputTables /nowarn;
%sysmacdelete getInputCount /nowarn;
%sysmacdelete copyInputContent /nowarn;
* _sda_ is short for SAS Document Analysis;
data _null_;
/*Clean up whitespace around delimited list entries*/
%let _sda_report_batch_tag_list = %sysfunc(compbl(%quote(&_sda_report_batch_tag_list.)));
%let _sda_report_batch_tag_list = %sysfunc(tranwrd(%quote(&_sda_report_batch_tag_list.), %str(, ), %str(,)));
%let _sda_report_batch_tag_list = %sysfunc(tranwrd(%quote(&_sda_report_batch_tag_list.), %str( ,), %str(,)));

%let _sda_report_batch_sk_list = %sysfunc(compbl(%quote(&_sda_report_batch_sk_list.)));
%let _sda_report_batch_sk_list = %sysfunc(tranwrd(%quote(&_sda_report_batch_sk_list.), %str(, ), %str(,)));
%let _sda_report_batch_sk_list = %sysfunc(tranwrd(%quote(&_sda_report_batch_sk_list.), %str( ,), %str(,)));

* Get the Viya Host URL;
%let _sda_viya_host=%sysfunc(getoption(SERVICESBASEURL));

%let _sda_context_name_encoded=%sysfunc(urlencode(&_sda_launcher_context_name.));

/*Disable ssl bypass*/
%let _sda_bypass_ssl_security=0;

filename _sda_out temp; 

/*Proc HTTP Request*/
proc http method='GET' 
    url=%tslit(&_sda_viya_host./launcher/contexts?filter=eq(name,"&_sda_context_name_encoded."))
    oauth_bearer=sas_services out=_sda_out; 
    headers 'Accept'=' application/json'; 
    headers 'Content-Type'=' application/json';
    %if &_sda_bypass_ssl_security. %then %do;
        SSLPARMS "SSLREQCERT" = "ALLOW";
    %end;		
run;

%if %symexist(SYS_PROCHTTP_STATUS_CODE) %then %do;
	* HTTP Status Handling;
	data _null_; 
	    if &SYS_PROCHTTP_STATUS_CODE. lt 400 then do; 
	        putLog 'NOTE: The request to retrieve the launcher context ID was successful.'; 
	        putLog "NOTE: The HTTP Status Code is &SYS_PROCHTTP_STATUS_CODE.."; 
	        putLog "NOTE: That means: &SYS_PROCHTTP_STATUS_PHRASE.."; 
	    end; 
	    else do; 
	        putLog 'ERROR: The request to retrieve the launcher context ID was most likely not successful.'; 
	        putLog "ERROR: The HTTP Status Code is &SYS_PROCHTTP_STATUS_CODE.."; 
	        putLog "ERROR: That means: &SYS_PROCHTTP_STATUS_PHRASE.."; 
			abort 42;
	    end; 
	run;
%end;
%else %do;
	* HTTP Status Handling - response code not logged to macrovar;
	data _null_; 
	        putLog 'ERROR: The request to retrieve the launcher context ID was most likely not successful.'; 
	        putLog "ERROR: The HTTP Status Code is unknown."; 
			abort 42;
	run;
%end;

libname GET json fileref=_sda_out;

/*Load SDA Context ID to macrovar*/
data _null_;
	set GET.ITEMS;
	call symputx("_sda_launcher_context_id", strip(id));
run;

filename _sda_out clear;

%if "&_sda_launcher_context_id"="." or "&_sda_launcher_context_id" ="" %then %do;
	* HTTP Status Handling - response code not logged to macrovar;
	data _null_; 
	        putLog "ERROR: ID not found for launcher context: &_sda_launcher_context_name";
            putLog "ERROR: Please check that the launcher context is properly configured."; 
			abort 42;
	run;
%end;

* Preprocess macrovars to convert binary to boolean;
%if &_sda_report_include_header. %then %do; %let _sda_report_include_header = True; %end;
%else %do; %let _sda_report_include_header = False; %end;
%if &_sda_wait_for_completion. %then %do; %let _sda_wait_for_completion=True; %end;
%else %do; %let _sda_wait_for_completion = False; %end;
%if %symexist(_sda_max_wait_time_minutes)=0 %then %do; %let _sda_max_wait_time_minutes = 0; %end;

* Compose http request body message;
%let _sda_http_request_body=%str({ "name":"sda-produce-usage-report",
          "description":"Output SAS Document Analysis Usage Report",
           "command":"/usr/local/bin/python process/sda-ocr/scripts/%superq(_sda_command)",
           "contextId":"%superq(_sda_launcher_context_id)",
           "environment":{
                "REPORT_OUTPUT_FORMAT":"%superq(_sda_report_output_format)",
                "REPORT_INCLUDE_HEADER":"%superq(_sda_report_include_header)",
                "REPORT_BATCH_SK_LIST":"%superq(_sda_report_batch_sk_list)",
                "REPORT_BATCH_TAG_LIST":"%superq(_sda_report_batch_tag_list)",
                "REPORT_MIN_DT":"%superq(_sda_report_min_dt)",
                "REPORT_MAX_DT":"%superq(_sda_report_max_dt)"
            }, 
           "kubernetes": {"jobNamePrefix": "sda-execute-report-"} 
     });

filename _sda_out temp; 

* Proc HTTP Request;
proc http method='Post' 
    url="&_sda_viya_host./launcher/processes" 
    in=%tslit(&_SDA_HTTP_REQUEST_BODY)
    oauth_bearer=sas_services
    out=_sda_out; 
    headers 'Accept'='application/vnd.sas.launcher.process+json'; 
    headers 'Content-Type'='application/json';
    %if &_sda_bypass_ssl_security. %then %do;
        SSLPARMS "SSLREQCERT" = "ALLOW";
    %end;	
run; quit;

%if %symexist(SYS_PROCHTTP_STATUS_CODE) %then %do;
	* HTTP Status Handling;
	data _null_; 
	    if &SYS_PROCHTTP_STATUS_CODE. lt 400 then do; 
	        putLog 'NOTE: The request to launch the SDA process was successful.'; 
	        putLog "NOTE: The HTTP Status Code is &SYS_PROCHTTP_STATUS_CODE.."; 
	        putLog "NOTE: That means: &SYS_PROCHTTP_STATUS_PHRASE.."; 
	    end; 
	    else do; 
	        putLog 'ERROR: The request to launch the SDA process was most likely not successful.'; 
	        putLog "ERROR: The HTTP Status Code is &SYS_PROCHTTP_STATUS_CODE.."; 
	        putLog "ERROR: That means: &SYS_PROCHTTP_STATUS_PHRASE.."; 
			abort 42;
	    end; 
	run;
%end;
%else %do;
	* HTTP Status Handling - response code not logged to macrovar;
	data _null_; 
	        putLog 'ERROR: The request to launch the SDA process was most likely not successful.'; 
	        putLog "ERROR: The HTTP Status Code is unknown."; 
			abort 42;
	run;
%end;

%let _sda_process = '';
%let _sda_output_directory = '';
%let _sda_sas_launcher_process_id = '';

%if %sysfunc(fexist(_sda_out)) %then %do;
	libname _sda_out json;
	* Check if a output directory that differs from the default was provided;
	data _null_;
	    set _sda_out.alldata;
	    if upcase(P1)='ENVIRONMENT' then do;
	        if upcase(P2)='OUTPUT_DIRECTORY' then call symput('_sda_output_directory', cats(value));
	        if upcase(P2)='PROCESS' then call symput('_sda_process', cats(value));
			if upcase(P2)="SAS_LAUNCHER_PROCESS_ID" then call symputx("_sda_sas_launcher_process_id",cats(value),'g');
	    end;
	run;

	* Inform the user about the outcome of the process;
	data work._sda_message_output;
	    length sda_launcher_message $500;
	    if "&_sda_output_directory." ne '' and "&_sda_process." ne '' then do;
	        sda_launcher_message = 'Logs have been routed to ' || "&_sda_output_directory./&_sda_process./logs";
	        output;
	        sda_launcher_message = 'Output data has been routed to ' || "&_sda_output_directory./&_sda_process./reports";
	        output;
	    end;
	    else do;
	        sda_launcher_message = 'Data and logs have been routed to the default location specified during installation';
	        output;
	    end;
	run;

	* Print the launcher information for the user;
	proc print data=work._sda_message_output noObs label;
	    var sda_launcher_message;
		label sda_launcher_message="SDA Launcher Message";
	quit;

%end;
%else %do;
	data _null_; 
	        put 'ERROR: The PROC HTTP response JSON could not be found.';
			abort 42;
	run;
%end;

%global _sda_elapsed_time;

%macro _sda_check_process_status(_sda_start_time=0);
    %if &_sda_start_time = 0 %then %let _sda_start_time = %sysfunc(datetime());
    %let _sda_current_time = %sysfunc(datetime());
    %let _sda_elapsed_time = %sysfunc(round(%sysevalf((&_sda_current_time - &_sda_start_time)/60), 0.01)); /* Convert seconds to minutes */

    filename _sda_out clear;
    filename _sda_out temp;

    proc http
        method='get'
        url="&_sda_viya_host./launcher/processes/&_sda_sas_launcher_process_id./state"
        oauth_bearer = sas_services
        out=_sda_out;
        headers 'Accept' = 'text/plain';
    quit;

	data _null_;
		call sleep(5, 1);
	run;

	%if %sysfunc(fexist(_sda_out)) %then %do;
		%if %symexist(SYS_PROCHTTP_STATUS_CODE) %then %do;
		    %let _sda_process_failed = 0;
		    data _null_;
		        length status $128.;
		        infile _sda_out;
		        input status $;
		        if &SYS_PROCHTTP_STATUS_CODE. lt 400 then do;
		            if status = 'completed' then do;
		                putLog "NOTE: SDA process completed successfully.";
		            end;
		            else if status = 'failed' then do;
		                call symputx('_sda_process_failed', 1);
		            end;
		            else if %sysevalf(&_sda_elapsed_time >= &_sda_max_wait_time_minutes) and %sysevalf(&_sda_max_wait_time_minutes > 0) then do;
		                putLog "WARNING: Maximum wait time of &_sda_max_wait_time_minutes minutes reached. Last known process status = " status;
		            end;
		            else do;
		                * Wait for 5 seconds before making another call;
		                *putLog "NOTE: Process status = " status". Waiting for process to finish.";
		                call sleep(5, 1);
		                call execute('%_sda_check_process_status(_sda_start_time=&_sda_start_time)');
		            end;
		        end;
		        else do;
		            putLog "ERROR: The request to check the status of the SDA process was not successful."; 
		            putLog "ERROR: The HTTP Status Code is &SYS_PROCHTTP_STATUS_CODE.."; 
		            putLog "ERROR: That means: &SYS_PROCHTTP_STATUS_PHRASE.."; 
					abort 42;
		        end; 
		    run;

			* If the process failed, fetch the exit code and provide a descriptive error message;
			%if &_sda_process_failed = 1 %then %do;
				filename _sdaec temp;
				proc http
					method='GET'
					url="&_sda_viya_host./launcher/processes/&_sda_sas_launcher_process_id./exitCode"
					oauth_bearer=sas_services
					out=_sdaec;
					headers 'Accept' = 'text/plain';
				quit;

				data _null_;
					length _ec_str $8 _msg $256;
					_ec = .;
					_ec_str = '';
					if %sysfunc(fexist(_sdaec)) then do;
						infile _sdaec truncover;
						input _ec_str $;
						_ec = input(_ec_str, ?? best.);
					end;

					select;
						when (_ec = 10) _msg = "Invalid LOG_LEVEL configuration value.";
						when (_ec = 11) _msg = "Invalid or non-writable OUTPUT_DIRECTORY.";
						when (_ec = 12) _msg = "Invalid or non-writable LOGS_DIRECTORY.";
						when (_ec = 13) _msg = "Invalid NUM_THREADS value (must be a non-negative integer).";
						when (14 <= _ec <= 29) _msg = "Configuration error (pre-logger). Check the environment variables passed to the SDA launcher context.";
						when (30 <= _ec <= 49) _msg = "Configuration validation error. See SDA batch logs for details.";
						when (50 <= _ec <= 69) _msg = "Database error. See SDA batch logs for details.";
						when (70 <= _ec <= 89) _msg = "License error. See SDA batch logs for details.";
						when (90 <= _ec <= 109) _msg = "Batch process error. See SDA batch logs for details.";
						when (110 <= _ec <= 129) _msg = "File processing error. See SDA batch logs for details.";
						otherwise _msg = "See SDA batch logs for more information.";
					end;

					putLog "ERROR: SDA process failed (exit code " _ec_str +(-1) "). " _msg;
					abort 42;
				run;
				filename _sdaec clear;
			%end;
		%end;
		%else %do;
			* HTTP Status Handling - response code not logged to macrovar;
			data _null_; 
		            putLog "ERROR: The request to check the status of the SDA process was not successful."; 
			        putLog "ERROR: The HTTP Status Code is unknown."; 
					abort 42;
			run;
		%end;
	%end;
	%else %do;
		data _null_; 
		        putLog 'ERROR: The PROC HTTP response JSON could not be found.';
				abort 42;
		run;
	%end;
%mend _sda_check_process_status;

%if %str(&_sda_wait_for_completion.) = %str(True) %then %do;
    %_sda_check_process_status();
%end;

%put _sda_wait_for_completion IS &_sda_wait_for_completion;

* Inform the user about the outcome of the process;
data work._sda_message_output;
    length sda_process_message $500;
	if "&_sda_wait_for_completion." = "True" then do;
        sda_process_message = cat("Process executed synchronously in ","&_sda_elapsed_time."," minutes");
        output;
	end;
	else do;
        sda_process_message = 'Process executed asynchronously. Process may still be running in the background';
        output;
	end;
run;

* Print the process information for the user;
proc print data=work._sda_message_output noObs label;
    var sda_process_message;
	label sda_process_message="SDA Process Message";
quit;

* Clean up;
libname _sda_out clear;
filename _sda_out clear;
%symdel _sda_viya_host _sda_http_request_body _sda_process _sda_sas_launcher_process_id
		_sda_report_batch_sk_list _sda_report_batch_tag_list
		_sda_wait_for_completion _sda_elapsed_time;
proc datasets library=work noList;
    delete _sda_message_output;
run; quit;
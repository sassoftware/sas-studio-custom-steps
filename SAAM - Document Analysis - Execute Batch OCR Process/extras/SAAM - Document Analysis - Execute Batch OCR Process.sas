* _sda_ is short for Execute SDA Batch, where SDA stands for SAS Document Analysis;
data _null_;
    * Check that the user provided a source directory on the SAS server and not in SAS Content;
    mode = scan("&_sda_source_data_directory.", 1, ':', 'MO');
    if mode EQ 'sasserver' then do;
        call symputx('_sda_src_dirpath', scan("&_sda_source_data_directory.", 2, ':', 'MO'));
    end;
    else do;
        putLog 'ERROR: Please ensure that the selected source directory is on the SAS server.';
        abort 42;
    end;

    * Check that the batch tag is no longer than 50 characters;
	if length("&_sda_batch_tag") > 50 then do;
        putLog 'ERROR: Please ensure that the Batch Tag does not exceed 50 characters.';
        abort 42;
	end;
run;

* Optionally assign a deterministic name for the batch output folder.
* By default SDA names the batch folder with its runtime timestamp, which this step cannot
* know in advance. When BATCH_OUTPUT_FOLDER_NAME is sent, SDA creates the batch folder with
* exactly that name under {OUTPUT_DIRECTORY}/{PROCESS}/data/batches, so the resulting path
* can be reported back to the caller and consumed by downstream processes;
%macro build_batch_output_folder_name;
   %local assign;
   %global _sda_batch_output_folder_name _sda_batch_output_folder_name_kv _sda_batch_output_directory;
   %let _sda_batch_output_folder_name    = ;
   %let _sda_batch_output_folder_name_kv = ;
   %let _sda_batch_output_directory      = ;

   /* check box: 0 = unchecked (false), 1 = checked (true) */
   %let assign = 0;
   %if %symexist(_sda_assign_output_folder_name) %then %let assign = &_sda_assign_output_folder_name;
   %if %length(&assign) = 0 %then %let assign = 0;

   %if &assign = 1 %then %do;
      /* Name shape: sda-<yyyy-mm-dd>T<hhmmss>.<microseconds>, for example
         sda-2026-08-21T143512.520930. This is exactly the shape SDA uses for its own
         default folder name, just prefixed, so assigned folders read the same way and
         sort chronologically alongside them. The "sda-" prefix is what distinguishes an
         assigned folder from a default-named one, and the microsecond precision is what
         keeps two submissions from colliding - which SDA treats as a fatal error on this
         code path (unlike the default path, which tolerates an existing folder).
         The result satisfies the folder name rules SDA validates against: a single path
         segment of [A-Za-z0-9._-], 1-255 characters, no trailing dot, and not a Windows
         reserved device name */
      data _null_;
         length ts $32 nm $64 kv $256;
         ts = compress(put(datetime(), E8601DT26.6), ':');
         nm = 'sda-' || strip(ts);
         kv = '"BATCH_OUTPUT_FOLDER_NAME":"' || strip(nm) || '",';
         call symputx('_sda_batch_output_folder_name', nm, 'g');
         call symputx('_sda_batch_output_folder_name_kv', kv, 'g');
         putLog "NOTE: BATCH_OUTPUT_FOLDER_NAME = " nm;
      run;
      %let _sda_batch_output_folder_name = %superq(_sda_batch_output_folder_name);
      %let _sda_batch_output_folder_name_kv = %superq(_sda_batch_output_folder_name_kv);

   %end;
%mend build_batch_output_folder_name;
%build_batch_output_folder_name;


* Get the Viya Host URL;
%let _sda_viya_host=%sysfunc(getoption(SERVICESBASEURL));

/* Preprocess macrovars to convert binary to boolean */
%if &_sda_skip_re_ocr. %then %do;
	%let _sda_skip_re_ocr = True;
	%let _sda_force_ocr = False;
%end;
%else %do;
	%let _sda_skip_re_ocr = False;
	%let _sda_force_ocr = True;
%end;

%if &_sda_ms_ocr_model = custom %then %do;
	%let _sda_ms_ocr_model= &_sda_ms_custom_model;
%end;

%if &_sda_use_uuid_as_name. %then %do; %let _sda_use_uuid_as_name=True; %end;
%else %do; %let _sda_use_uuid_as_name = False; %end;

%if &_sda_delete_source_files. %then %do; %let _sda_delete_source_files=True; %end;
%else %do; %let _sda_delete_source_files = False; %end;

%if &_sda_wait_for_completion. %then %do; %let _sda_wait_for_completion=True; %end;
%else %do; %let _sda_wait_for_completion = False; %end;

%if &_sda_ocr_keep_line_breaks. %then %do; %let _sda_ocr_keep_line_breaks=True; %end;
%else %do; %let _sda_ocr_keep_line_breaks = False; %end;

%if &_sda_convert_pdf_to_images. %then %do; %let _sda_convert_pdf_to_images=True; %end;
%else %do; %let _sda_convert_pdf_to_images = False; %end;

%if %symexist(_sda_max_wait_time_minutes)=0 %then %do; %let _sda_max_wait_time_minutes = 0; %end;

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
	        putLog "ERROR: The request to retrieve the launcher context ID was most likely not successful.";
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

/* Construct HTTP request body */
%let _sda_http_request_body=%str({ "name":"sda-batch-ocr-process",
          "description":"Execute OCR Process Using SAS Document Analysis",
           "command":"/usr/local/bin/python process/sda-ocr/scripts/run_sda_batch.py",
           "contextId":"%superq(_sda_launcher_context_id)",
           "environment":{
                "SOURCE_DATA_DIRECTORY":"%superq(_sda_src_dirpath)",
                "OCR_ENGINE":"%superq(_sda_ocr_engine)",
                "SKIP_RE_OCR": "%superq(_sda_skip_re_ocr)",
                "MS_OCR_MODEL":"%superq(_sda_ms_ocr_model)",
                "FORCE_OCR": "%superq(_sda_force_ocr)",
                "LOG_LEVEL": "%superq(_sda_log_level)",
                "USE_UUID_AS_NAME": "%superq(_sda_use_uuid_as_name)",
                "DELETE_SOURCE_FILES": "%superq(_sda_delete_source_files)",
                "BATCH_TAG": "%superq(_sda_batch_tag)",
                &_sda_batch_output_folder_name_kv.
                "OCR_KEEP_LINE_BREAKS": "%superq(_sda_ocr_keep_line_breaks)",
                "CONVERT_PDF_TO_IMAGES": "%superq(_sda_convert_pdf_to_images)",
                "MAPPING_FILE_FORMAT": "%superq(_sda_mapping_file_format)"
            },
           "kubernetes": {"jobNamePrefix": "sda-execute-ocr-"}
     });

filename _sda_out temp;


* Start a SAS launcher process, which will in turn run the SDA process;
proc http
    method='POST'
    url = "&_sda_viya_host./launcher/processes"
    in = %tslit(%superq(_sda_http_request_body))
    oauth_bearer = sas_services
    out = _sda_out;
    headers 'Accept' = 'application/vnd.sas.launcher.process+json';
    headers 'Content-Type' = 'application/json';
    %if &_sda_bypass_ssl_security. %then %do;
        SSLPARMS "SSLREQCERT" = "ALLOW";
    %end;
quit;

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

%let _sda_process = sda-ocr;
%let _sda_output_directory = '';
%let _sda_sas_launcher_process_id = '';

%macro _sda_report_launcher_output;
%if %sysfunc(fexist(_sda_out)) %then %do;
	libname _sda_out json;
	* Check if a output directory that differs from the default was provided;
	data _null_;
	    set _sda_out.alldata;
	    if upcase(P1)='ENVIRONMENT' then do;
	        if upcase(P2)='OUTPUT_DIRECTORY' then call symput('_sda_output_directory', cats(value));
	        if upcase(P2)='PROCESS' then call symput('_sda_process', cats(value));
			if upcase(P2)="SAS_LAUNCHER_PROCESS_ID" then call symputx("_sda_sas_launcher_process_id",cats(value),'g');
			if upcase(P2)='BATCH_OUTPUT_FOLDER_NAME' then call symputx('_sda_batch_output_folder_name',cats(value),'g');
	    end;
	run;

	* Inform the user about the outcome of the process;
	data work._sda_message_output;
	    length sda_launcher_message $500 _sda_batch_dir $500;
	    if "&_sda_output_directory." ne '' and "&_sda_process." ne '' then do;
	        sda_launcher_message = 'Logs have been routed to ' || "&_sda_output_directory./&_sda_process./logs";
	        output;
	        sda_launcher_message = 'Output data has been routed to ' || "&_sda_output_directory./&_sda_process./data";
	        output;
	        * A deterministic folder name is the only case where the exact batch folder is
	          known to this step, so it is the only case where it can be reported;
	        if "&_sda_batch_output_folder_name" ne '' then do;
	            _sda_batch_dir = "&_sda_output_directory./&_sda_process./data/batches/&_sda_batch_output_folder_name";
	            call symputx('_sda_batch_output_directory', _sda_batch_dir, 'g');
	            sda_launcher_message = 'Batch output has been routed to ' || strip(_sda_batch_dir);
	            output;
	        end;
	    end;
	    else do;
	        sda_launcher_message = 'Data and logs have been routed to the default location specified during installation';
	        output;
	    end;
	    drop _sda_batch_dir;
	run;

	%if %length(%superq(_sda_batch_output_directory)) > 0 %then
		%put NOTE: SDA batch output directory = &_sda_batch_output_directory;

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
%mend _sda_report_launcher_output;
%_sda_report_launcher_output

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

	%let _sda_process_failed = 0;

	%if %sysfunc(fexist(_sda_out)) %then %do;
		%if %symexist(SYS_PROCHTTP_STATUS_CODE) %then %do;
		    data _null_;
		        length status $128.;
		        infile _sda_out;
		        input status $;
		        if &SYS_PROCHTTP_STATUS_CODE. lt 400 then do;
		            if status = 'completed' then do;
		                putLog "NOTE: SDA process completed successfully.";
		            end;
		            else if status = 'failed' then do;
		                call symputx('_sda_process_failed', '1');
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
* _sda_batch_output_folder_name and _sda_batch_output_directory are intentionally NOT
* deleted here - they are the step's output contract for downstream SAS processes;
%symdel _sda_batch_output_folder_name_kv _sda_viya_host _sda_http_request_body _sda_output_directory _sda_process _sda_sas_launcher_process_id
		_sda_skip_re_ocr _sda_use_uuid_as_name _sda_ms_ocr_model _sda_delete_source_files _sda_wait_for_completion
		_sda_mapping_file_format _sda_ocr_keep_line_breaks _sda_convert_pdf_to_images _sda_elapsed_time;
proc datasets library=work noList;
    delete _sda_message_output;
run; quit;

* Checking that all provided locations are in SAS Content;
data _null_;
    * Ensuring that the selected report is located in SAS Content;
    locationType = scan("&_crr_original_report.", 1, ':');
    justFileName = scan("&_crr_original_report.", -1, '/', 'MO');
    folderPath1 = scan("&_crr_original_report.", 2, ':', 'MO');
    folderPath2 = substr(folderPath1, 1, length(folderPath1) - length(justFileName) - 1);
    if lowCase(locationType) ne 'sascontent' then do;
       putLog 'ERROR: Please select a location in a SAS Content folder';
       abort;
    end;
    else do;
        call symputx('_crr_original_report_name', justFileName);
        call symputx('_crr_original_report_path', folderPath2);   
    end;

    * Ensuring that the selected location for the new report is located in SAS Content;
    if length("&_crr_new_report_loc.") > 1 then do;
        locationType2 = scan("&_crr_new_report_loc.", 1, ':');
        if lowCase(locationType2) ne 'sascontent' then do;
           putLog 'ERROR: Please select a location in a SAS Content folder for the new report location';
           abort;
        end;
        else do;
            newFolderPath = scan("&_crr_new_report_loc.", 2, ':', 'MO');
            call symputx('_crr_new_report_loc', newFolderPath);
        end;
    end;
    else do;
        * If no new location is selected, use the original report's location;
        call symputx('_crr_new_report_loc', folderPath2);   
    end;
run;

%macro _crr_check_replacement_data();
    %global _crr_replacement_data_casLib;
    %if &_crr_copy_or_replace. eq Replace %then %do;
        * Check that the replacement data is in CAS;
        %if &_crr_replacement_data_engine. eq CAS %then %do; 
            %let _crr_replacement_data_casLib = %sysfunc(getlcaslib(&_crr_replacement_data_lib));
        %end;
        %else %do;
            data _null_;
                putLog 'ERROR: The selected replacement data library does not point to a CASLib';
                abort;
            run;
        %end;
    %end;
    %mend _crr_check_replacement_data;

%let _crr_replacement_data_name = %scan(&_crr_replacement_data.,2,".");
%_crr_check_replacement_data()

%put &_crr_replacement_data_casLib.;
%put &_crr_replacement_data_name.;

* Check if a new name was provided;
%if "&_crr_name_update." eq "&_crr_original_report_name." %then %do;
    data _null_;
        putLog 'WARNING: New report name cannot match original name. Appended - Copy to name.';
    run;
    %let _crr_name_update = &_crr_original_report_name. - Copy;
%end;

* Append - Copy to name if no new name provided;
%if %length(&_crr_name_update.) eq 0 %then %do;
    %let _crr_name_update = &_crr_original_report_name. - Copy;
%end;


%let _crr_viyaHost = %sysFunc(getOption(servicesBaseURL));
filename _crr_out temp;
%let _crr_out_path = %sysfunc(quote(%sysfunc(pathName(_crr_out))));

* Retrieve the folder ID for the new report location;
* https://developer.sas.com/rest-apis/folders/getFolderItem;
proc http
    url = "&_crr_viyaHost./folders/folders/@item?path=&_crr_new_report_loc."
    method = 'Get'
    out = _crr_out
    oauth_bearer = sas_services;
    headers 
        'Accept' ='application/json, application/vnd.sas.collection+json, application/vnd.sas.error+json';
run;

* Check response;
data _null_;
    if &SYS_PROCHTTP_STATUS_CODE. ne 200 then do;
        putLog 'ERROR: Request was not successfull, please make sure you have selected a folder in SAS Content for the new report location.';
        abort;
    end;
run;

* Parse the folder ID from the response;
proc cas;
    set stdJSON;
    resp_file = readPath(&_crr_out_path.);
    resp_string = json2CASL(resp_file);
    new_folder_uri = '/folders/folders/' || resp_string.id;
    symputx('_crr_new_folder_uri', new_folder_uri, 'G');
run;

* Retrieve the folder ID for the original report location;
* https://developer.sas.com/rest-apis/folders/getFolderItem;
proc http
    url = "&_crr_viyaHost./folders/folders/@item?path=&_crr_original_report_path."
    method = 'Get'
    out = _crr_out
    oauth_bearer= sas_services;
    headers 
        'Accept' = 'application/json, application/vnd.sas.collection+json, application/vnd.sas.error+json';
run;

* Check response;
data _null_;
    if &SYS_PROCHTTP_STATUS_CODE. ne 200 then do;
        putLog 'ERROR: Request was not successfull, please make sure you have selected a folder in SAS Content for the source report location.';
        abort;
    end;
run;

* Parse the folder ID from the response;
proc cas;
    set stdJSON;
    resp_file = readPath(&_crr_out_path.);
    resp_string = json2CASL(resp_file);
    symputx('_crr_folder_uri', resp_string.id, 'G');
run;

* Retrieve the report ID of the original report;
* https://developer.sas.com/rest-apis/folders/getFolderMembers;
proc http
    url = "&_crr_viyaHost./folders/folders/&_crr_folder_uri./members?filter=and(eq(name,'&_crr_original_report_name.'),eq(contentType,'report'))"
    method = 'Get'
    out = _crr_out
    oauth_bearer = sas_services;
    headers 
        'Accept' = 'application/json, application/vnd.sas.collection+json, application/vnd.sas.error+json';
run;

* Check response;
data _null_;
    if &SYS_PROCHTTP_STATUS_CODE. ne 200 then do;
        putLog 'ERROR: Request was not successfull, please make sure you have selected a SAS Visual Analytics report.';
        abort;
    end;
run;

filename _crr_in temp;
%let _crr_in_path = %sysfunc(quote(%sysfunc(pathname(_crr_in))));

* Create the request body for the copy API call;
proc cas;
    set stdJSON;
    resp_file = readPath(&_crr_out_path.);
    resp_string = json2CASL(resp_file);

    do item over resp_string.items;
        report_uri = item.uri;
    end;
    
    report_id = scan(report_uri, 3, '/');
    symputx('_crr_original_report_id', report_id, 'G');
    symputx('_crr_original_report_uri', report_uri, 'G');

    in_data.resultFolder = "&_crr_new_folder_uri.";
    in_data.resultReportName = "&_crr_name_update.";
    in_data.resultNameConflict = 'replace';
    
    in_json = casl2JSON(in_data);
    in_json = compbl(in_json);
    
    file outfile &_crr_in_path.;
    print in_json;
run;

* Retrieve the content of the original report;
* https://developer.sas.com/rest-apis/reports/getContent;
proc http
    url = "&_crr_viyaHost.&_crr_original_report_uri./content"
    method = 'Get'
    out = _crr_out
    oauth_bearer = sas_services;
    headers 
        'Accept' = 'application/vnd.sas.report.content+json, application/vnd.sas.report.content+xml, application/vnd.sas.error+json';
run;

* Check response;
data _null_;
    if &SYS_PROCHTTP_STATUS_CODE. ne 200 then do;
        putLog 'ERROR: Request was not successfull, the content of the SAS Visual Analytics report could not be retrieved.';
        abort;
    end;
run;

* Retrieve the original data source information;
proc cas;
    set stdJSON;
    resp_file = readPath(&_crr_out_path.);
    resp_string = json2CASL(resp_file);
    
    original_table = resp_string.dataSources[1].casResource.table;
    original_library = resp_string.dataSources[1].casResource.library;
    original_server = resp_string.dataSources[1].casResource.server;
    
    symputx('_crr_original_table', original_table, 'G');
    symputx('_crr_original_library', original_library, 'G');
    symputx('_crr_original_server', original_server, 'G');
run;

* API call to copy the original report and save it in the new folder;
* https://developer.sas.com/rest-apis/visualAnalytics/updateReportCopy;
proc http 
    url = "&_crr_viyaHost./visualAnalytics/reports/&_crr_original_report_id./copy" 
    method = 'Put'
    in = _crr_in
    out = _crr_out
    oauth_bearer = sas_services;
    headers
        'Accept' = 'application/json, application/vnd.sas.report.operations.results+json, application/vnd.sas.report.operations.error+json, application/vnd.sas.error+json'
        'Content-Type' = 'application/json';
run;

* Check response and provide feedback;
data _null_;
    if &SYS_PROCHTTP_STATUS_CODE. ne 201 then do;
        putLog 'ERROR: Request was not successfull, a copy of the report could not be created.';
        putLog 'ERROR: Ensure that you have the necessary permissions to create reports in the selected folder.';
        abort;
    end;
    else do;
        putLog 'NOTE: A copy of the report has been successfully created.';
        putLog "NOTE: New Report Name: &_crr_name_update. in the folder: &_crr_new_report_loc..";
    end;
run;

* Data replacement if requested;
%if &_crr_copy_or_replace. eq Replace %then %do;
    filename _crr_cas temp;
    %let _crr_cas_path = %sysfunc(quote(%sysfunc(pathname(_crr_cas))));

    * Get the currently connected cas server;
    * https://developer.sas.com/rest-apis/casManagement/getServers;
    proc http
        url = "&_crr_viyaHost./casManagement/servers?filter=eq(host,'&_CASHOST_.')"
        method = 'Get'
        out = _crr_cas
        oauth_bearer = sas_services;
        headers 
            'Accept' = 'application/json, application/vnd.sas.collection+json';
    run;

    proc cas;
        set stdJSON;
        resp_file = readPath(&_crr_cas_path.);
        resp_string = json2CASL(resp_file);
        
        do item over resp_string.items;
            cas_server_name = item.name;
        end;
        
        symputx('_crr_replacement_casServer', cas_server_name, 'G');
    run;

    * Create the request body for the data replacement API call;
    proc cas;
        set stdJSON;
        resp_file = readPath(&_crr_out_path.);
        resp_string = json2CASL(resp_file);
        
        copy_report_id = resp_string.resultReportId;
        symputx('_crr_copy_report_id', copy_report_id, 'G');
        symputx('_crr_today', today(), 'G');

        in_data.resultNameConflict = 'replace';
        
        in_data.operations[1].changeData.originalData.cas.server = "&_crr_original_server.";
        in_data.operations[1].changeData.originalData.cas.library = "&_crr_original_library.";
        in_data.operations[1].changeData.originalData.cas.table = "&_crr_original_table.";
        
        in_data.operations[1].changeData.replacementData.cas.server = "&_crr_replacement_casServer.";
        in_data.operations[1].changeData.replacementData.cas.library = "&_crr_replacement_data_casLib.";
        in_data.operations[1].changeData.replacementData.cas.table = "&_crr_replacement_data_name.";
        in_data.operations[1].changeData.replacementLabel = "&replacement_data.";
        
        in_data.operations[1].changeData.forceReplace = true;

        print in_data;
        
        in_json = casl2JSON(in_data);
        in_json = compbl(in_json);
        
        file outfile &_crr_in_path.;
        print in_json;
    run;

    * Replace the data source in the copied report;
    * https://developer.sas.com/rest-apis/visualAnalytics/updateReport;
    proc http 
        url = "&_crr_viyaHost./visualAnalytics/reports/&_crr_copy_report_id." 
        method = 'Put'
        in = _crr_in
        out = _crr_out
        oauth_bearer = sas_services;
        headers
            'Accept' = 'application/json, application/vnd.sas.report.operations.results+json, application/vnd.sas.report.operations.error+json, application/vnd.sas.error+json'
            'Content-Type' = 'application/json'
            'If-Unmodified-Since' = "&_crr_today.";
    run;

    * Check response and provide feedback;
    data _null_;
    if &SYS_PROCHTTP_STATUS_CODE. ne 200 then do;
        putLog 'ERROR: Request was not successfull, a copy of the report could not be created.';
        putLog 'ERROR: Ensure that you have the necessary permissions to create reports in the selected folder.';
        abort;
    end;
    else do;
        putLog 'NOTE: The data source was successfully changed in the copied report.';
    end;
run;
%end;

* Clean up;
%symDel _crr_original_report_name _crr_original_report_path _crr_replacement_data_casLib _crr_viyaHost _crr_out_path _crr_new_folder_uri _crr_folder_uri _crr_in_path _crr_original_report_id _crr_original_report_uri _crr_original_table _crr_original_library _crr_original_server;
filename _crr_out clear;
filename _crr_in clear;
%if %symExist(_crr_replacement_data_casLib) %then %do;
    %symDel _crr_copy_report_id _crr_today _crr_cas_path _crr_replacement_casServer;
    filename _crr_cas clear;
%end;
%sysmacdelete _crr_check_replacement_data;
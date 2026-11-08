/*
    Explanation of abreviations in the code:
    - _grc_ is short for Get Report Content
    - RFP is short for Report Folder Path
    - FM is short for Folder Members
    - RCT is short for Report Content Temporary
    - RCP is short for Report Content Permanent
    - HO is short for Header Out
    - IJC is short for In Json Content
*/

* Utility macro to check the correct server type was selected + return the file path and file name as macro variables;
%macro _grc_util_check_selected_item(_grc_input_variable, _grc_target_server_type, _grc_path_variable, _grc_file_name_variable);
    %global &_grc_path_variable
        &_grc_file_name_variable;

    data _null_;
        justFileName = scan("&_grc_input_variable.", -1, '/', 'MO');
        folderPath1 = scan("&_grc_input_variable.", 2, ':', 'MO');
        folderPath2 = substr(folderPath1, 1, length(folderPath1) - length(justFileName) - 1);
        server_type = scan("&_grc_input_variable.", 1, ':', 'MO');

        * Handle the different required filename for SAS Content and SAS Server;
        if server_type = "&_grc_target_server_type." then do;
            call symput("&_grc_path_variable.", strip(folderPath2));
            call symput("&_grc_file_name_variable.", strip(justFileName));
        end;
        else do;
            errorMessage = 'ERROR: The file ' || strip(justFileName) || " is not located in &_grc_target_server_type.";
            putLog errorMessage;
            abort 42;
        end;
    run;
%mend _grc_util_check_selected_item;

* Utility macro to retrieve the URI of a SAS Visual Analytics report by providing its path in SAS Content and name;
%macro _grc_util_get_report_uri(_grc_folder_path, _grc_file_name_path);
    %global _grc_reportURI;

    * Find the source folder in SAS Content and retrieve its ID;
    filename _grc_RFP temp;

    * Documentation for the endpoint: https://developer.sas.com/rest-apis/folders/getFolderItem;
    proc http url = "&_grc_viyaHost./folders/folders/@item?path=&_grc_folder_path"
        method = 'Get'
        out = _grc_RFP
        oauth_bearer = sas_services;
        headers 'Accept' = 'application/json';
    run;

    libname _grc_RFP json;

    proc sql noPrint;
        select id into :_grc_reportParentFolderID
            from _grc_RFP.root;
    run; quit;

    * Filter the folder members to only the source report and retrieve its URI;
    filename _grc_FM temp;

    * Documentation for the endpoint https://developer.sas.com/rest-apis/folders/getFolderMembers;
    proc http url = "&_grc_viyaHost./folders/folders/&_grc_reportParentFolderID./members?filter=and(eq(name,'&_grc_file_name_path.'),eq(contentType,'report'))"
        method = 'Get'
        out = _grc_FM
        oauth_bearer = sas_services;
        headers 'Accept' = 'application/json';
    run;

    libname _grc_FM json;

    proc sql noPrint;
        select uri into :_grc_reportURI
            from _grc_FM.items;
    run; quit;

    * Clean up;
    libname _grc_RFP clear;
    filename _grc_RFP clear;
    libname _grc_FM clear;
    filename _grc_FM clear;
%mend _grc_util_get_report_uri;

* Utility macro to retrieve the ETag of a report;
%macro _grc_util_retrieve_etag();
    %global _grc_resource_etag;

    filename _grc_HO temp;

    proc http
        method = 'Get'
        url = "&_grc_viyaHost.&_grc_reportURI."
        oauth_bearer = sas_services
        headerOut = _grc_HO;
        headers 'Accept' = 'application/json';
    run; quit;

    * Check that the report was found and only then extract the ETag;
    %if &SYS_PROCHTTP_STATUS_CODE. EQ 200 %then %do;
        * Extract the ETag, this is needed to update the report;
        data _null_;
            length headerLine $256.;
            inFile _grc_HO delimiter='|' missover;
            input headerLine $;

            if substr(headerLine, 1, 4) EQ 'ETag' then do;
                headerLine = translate(substr(headerLine, 7), '', '"');
                eTag1 = '"' || headerLine || '"';
                eTag2 = "'" || eTag1 || "'";
                call symputx('_grc_resource_etag', compress(eTag2));
            end;
        run;
    %end;
    %else %do;
        %put ERROR: The report could not be found. The API responded with &SYS_PROCHTTP_STATUS_CODE.: SYS_PROCHTTP_STATUS_PHRASE.;
    %end;

    filename _grc_HO clear;
%mend _grc_util_retrieve_etag;

%macro _grc_main_macro();
    %local _grc_viyaHost;

    * Get the Viya Host URL;
    %let _grc_viyaHost=%sysfunc(getoption(SERVICESBASEURL));

    %if &_grc_mode_selector. eq getContent %then %do;
        %_grc_util_check_selected_item(&_grc_source_report, sascontent, _grc_source_path, _grc_source_file_name);
        %_grc_util_check_selected_item(&_grc_target_json, sasserver, _grc_target_path, _grc_target_file_name);
        %_grc_util_get_report_uri(&_grc_source_path, &_grc_source_file_name);
        
        * Copy the content of the report to the target json file;
        filename _grc_RCT temp;
        filename _grc_RCP "&_grc_target_path./&_grc_target_file_name.";

        * Docuemntation for the endpoint https://developer.sas.com/rest-apis/reports/updateContent;
        proc http url = "&_grc_viyaHost.&_grc_reportURI./content"
            method = 'Get'
            out = _grc_RCT
            oauth_bearer = sas_services;
            headers 'Accept' = 'application/vnd.sas.report.content+json';
        run;

        * Check response;
        data _null_;
            if &SYS_PROCHTTP_STATUS_CODE. ne 200 then do;
                str = 'ERROR: Request was not successfull, please make sure you have selected a SAS Visual Analytics report';
                put str;
                abort abend;
            end;
            else put 'NOTE: Request was successfull.';
        run;

        data _null_; 
            rc = jsonpp('_grc_RCT', '_grc_RCP'); 
        run;

        data work._grc_user_message;
            created_file = "&_grc_target_path./&_grc_target_file_name.";
            source_report = "&_grc_source_path./&_grc_source_file_name.";
        run;

        title 'The content of the selected report is available in your target location';
        proc print data=work._grc_user_message noObs;
        run; quit;
        title;

        * Clean up;
        proc datasets lib=work noList;
            delete _grc_user_message;
        run; quit;
        filename _grc_RCT clear;
        filename _grc_RCP clear;
        %symdel _grc_source_path _grc_source_file_name _grc_target_path _grc_target_file_name _grc_reportURI;
    %end;

    %if &_grc_mode_selector. eq updateContent %then %do;
        %_grc_util_check_selected_item(&_grc_source_json, sasserver, _grc_source_path, _grc_source_file_name);
        %_grc_util_check_selected_item(&_grc_target_report, sascontent, _grc_target_path, _grc_target_file_name);
        %_grc_util_get_report_uri(&_grc_target_path, &_grc_target_file_name);
        %_grc_util_retrieve_etag();

        filename _grc_IJC "&_grc_source_path./&_grc_source_file_name.";

        * Docuemntation for the endpoint https://developer.sas.com/rest-apis/reports/updateContent;
        proc http
            method = 'Put'
            url = "&_grc_viyaHost.&_grc_reportURI./content" 
            in = _grc_IJC
            oauth_bearer = sas_services;
            headers 'Accept' = 'application/json'
                'Content-Type' = 'application/vnd.sas.report.content+json'
                'If-Match' = &_grc_resource_etag.;
        run; quit;

        * Check response;
        data _null_;
            if &SYS_PROCHTTP_STATUS_CODE. ne 204 then do;
                str = 'ERROR: Request was not successfull, please make sure you have selected a SAS Visual Analytics report';
                put str;
                abort abend;
            end;
            else put 'NOTE: Request was successfull.';
        run;

        data work._grc_user_message;
            source_file = "&_grc_source_path./&_grc_source_file_name.";
            target_report = "&_grc_target_path./&_grc_target_file_name.";
        run;

        title 'The selected report has been updated with the content of the selected JSON';
        proc print data=work._grc_user_message noObs;
        run; quit;
        title;

        * Clean up;
        proc datasets lib=work noList;
            delete _grc_user_message;
        run; quit;
        filename _grc_IJC clear;
        %symdel _grc_source_path _grc_source_file_name _grc_target_path _grc_target_file_name _grc_reportURI _grc_resource_etag;
    %end;
%mend _grc_main_macro;

%_grc_main_macro()

* Clean up;
%sysmacdelete _grc_util_check_selected_item;
%sysmacdelete _grc_util_get_report_uri;
%sysmacdelete _grc_util_retrieve_etag;
%sysmacdelete _grc_main_macro;
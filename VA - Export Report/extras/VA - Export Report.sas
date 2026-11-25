/*
    The base URL for your SAS Viya installation.
*/
%let base_uri=%sysfunc(getoption(SERVICESBASEURL));

/*
    The following variables can be used to, optionally, add to your export file name.	
*/
%let timestamp = %sysfunc(compress(%sysfunc(time(), time8.), ':'));
%let datestamp = %sysfunc(date(), YYMMDDN8.);
%let dttmstamp = &datestamp._&timestamp;

/*
    From the _report and _packageDir macro variables create separate values for the following macro variables:
*/
data _null_;
    call symputx('reportName', kreverse(kscan(kreverse(kscan("&_report", 2, ':')), 1, '/')));
    call symputx("path", kreverse(ksubstr(kreverse(kscan("&_report", 2, ':')), kfind(kreverse(kscan("&_report", 2, ':')), '/'))));
    call symputx("packageDir", kscan("&_packageDir", 2, ':'));
    call symputx("dirType", kstrip(kscan("&_packageDir", 1, ':')));
run;

/*
    This version will only work when the export is stored on a physical file system.
*/
%if &dirType eq sasserver %then %do;

    /*
        Based on the 'path' macro variable retrieve the endpoint to give me the folder members/content.
    */
    filename ref temp;
    proc http
        url = "&base_uri./folders/folders/@item"
            query = ("path" = "&path")
            oauth_bearer = sas_services
        out= ref;
        headers
            'Accept'= 'application/vnd.sas.content.folder+json';
    run;
    libname ref json;

    /*
        From the links table, store the member end-point and the content type into macro variables.
    */
    proc sql noprint;
        select 
            href, 
            type into :endpoint, :type
        from 
            ref.links
        where 
            method = "GET" and 
            rel = "members";
    quit; 

    /*
        Retrieve the members/content within the directory

        Note the limit addition, which needs to be large enough to contain the requested report.
    */
    filename members temp; 
    proc http
        url = "&base_uri.%trim(&endpoint)?limit=150"
            oauth_bearer = sas_services
        out = members;
        headers
            "Accept"= "%trim(&type)+json";
    run; 
    libname members json;

    /*
        Get the reportId for the specified report.
    */
    proc sql noprint;
        select
            kstrip(kreverse(kscan(kreverse(uri), 1, '/'))) as reportId length=64 into :reportId TRIMMED
        from
            members.items
        where
            name = "&reportName";
    quit;

    /*
        End user feedback.
    */
    %macro request_status;
        %if &SYS_PROCHTTP_STATUS_CODE eq 200 %then %do;
            %put NOTE: Report export for "&reportName" successfully created.;
        %end;
        %else %do;
            %put ERROR: Report export creation for "&reportName" failed.;
            %put &=SYS_PROCHTTP_STATUS_CODE;
            %put &=SYS_PROCHTTP_STATUS_PHRASE;
        %end;
    %mend;

    /*
        The macro responsible for creating the export file.
    */
    %macro create_export;
        /*
            Create the resulting file name, without the extension. The extension will be
            added based on the exportType (zip, pdf, png or svg.)
        */
        %let export_file =;
        %if &_addition eq Date %then %do;
            %let export_file = &packageDir/&reportName._&datestamp;
        %end;
        %else %do;
            %if &_addition eq Timestamp %then %do;
                %let export_file = &packageDir/&reportName._&dttmstamp;
            %end;
            %else %do;
                %let export_file = &packageDir/&reportName;
            %end;
        %end;

        %if &_exportType eq Package %then %do;
            /*
                Ask Viya to create the export package for the requested report.

                API documentation: https://developer.sas.com/rest-apis/visualAnalytics/getExportedReportPackage
            */
            filename resp "&export_file..zip";
            proc http
                method='get'
                url = "&base_uri./visualAnalytics/reports/&reportId./package"
                oauth_bearer = sas_services
                out=resp;
                headers
                    'Accept'='application/zip, application/json, application/vnd.sas.error+json, aplication/json';
            run;
        %end;
        %else %do;
            %if &_exportType eq PDF %then %do;
                /*
                    Check the length of the coverPageText (cpt) variable. There's room for (2048 - 262 =) 1786 characters.
                    Note that the default length of the 'query' variable is 262 characters.
                */
                %let cptLength = %sysfunc(length("&_coverPageText"));

                %if &cptLength LE 1786 %then %do;

                    /*
                        Ask Viya to create a PDF for the requested report.

                        API documentation: https://developer.sas.com/rest-apis/visualAnalytics/getExportedReportPdf
                    */
                    %let query=;
                    data _null_;
                        attrib query length=$2048.;
                        query = cat
                        (
                            '(',
                            '"coverPageText"="', strip("&_coverPageText"), '"',
                            ' "includeCoverPage"=', "&_includeCoverPage",
                            ' "paperSize"="', strip("&_paperSize"), '"',
                            ' "showPageNumbers"=', "&_showPageNumbers",
                            ' "orientation"="', strip("&_orientation"), '"',
                            ' "expandClippedContent"=', "&_expandClippedContent",
                            ' "includeAppendix"=', "&_includeAppendix",
                            ' "includeDetailsTables"=', "&_includeDetailsTables",
                            ' "includeTableOfContents"=', "&_includeTableOfContents",
                            ' "showEmptyRowsAndColumns"=', "&_showEmptyRowsAndColumns",
                            ')'
                        );
    
                        call symputx
                        (
                            "query", strip(query)
                        );
                    run;

                    filename resp "&export_file..pdf";
                    proc http
                        method ='get'
                        url = "&base_uri./visualAnalytics/reports/&reportId./pdf"
                        oauth_bearer = sas_services
                        out = resp
                        query = &query;
                        headers
                            "Accept" = "application/pdf"
                            "Accept-Language" = "*"
                            "Accept-Locale" = "en-US";
                    run;
                %end;
                %else %do;
                    %put ERROR: The cover page text is too long. (&cptLength characters.);
                %end;
            %end;
            %else %do;
                /*
                    Make sure that the image size value is following the required pattern.
                    Note that the required pattern is taken from: https://developer.sas.com/rest-apis/visualAnalytics/getExportedReportImagePNG

                    Made sure that is also accepts spaces between the length- and hight specification.
                */
                %let sizeIsValid=0;
                data _null_;
                    if prxmatch("/[0-9]{2,6}px\s*,\s*[0-9]{2,6}px/", "&_size") > 0 then do;
                        call symputx("sizeIsValid", 1);
                    end;
                run;

                %if (&sizeIsValid) %then %do;
                    /*
                        The image size pattern for the image is valid.

                        The following section is responsible for the svg & png export.

                        API documentation:
                            https://developer.sas.com/rest-apis/visualAnalytics/getExportedReportImageSVG
                            https://developer.sas.com/rest-apis/visualAnalytics/getExportedReportImagePNG
                    */
                    %let query=;
                    data _null_;
                        attrib query length=$2048.;
                        query = cat
                        (
                            '(',
                            '"size"="', strip("&_size"), '"',
                            ')'
                        );
                        
                        call symputx
                        (
                            "query", strip(query)
                        );
                    run;
                    
                    /*
                        At this stage _exportType contains svg or png.
                    */
                    %let _exportType = %sysfunc(lowcase(&_exportType));

                    filename resp "&export_file..&_exportType";

                    /*
                        Do the actual request.
                    */
                    proc http
                        method ='get'
                        url = "&base_uri./visualAnalytics/reports/&reportId./&_exportType"
                        oauth_bearer = sas_services
                        out = resp
                        query = &query;
                        headers
                        %if &_exportType EQ png %then %do;
                            'Accept'='image/png, application/json, application/vnd.sas.error+json, aplication/json';
                        %end;
                        %else %do;
                            'Accept'='image/svg+xml, application/json, application/vnd.sas.error+json, aplication/json';
                        %end;
                    run;
                %end;
                %else %do;
                    %put ERROR: Please enter a valid image size! (Expected pattern: 9999px,9999px Received value: &_size);
                %end;
            %end;
        %end;

        /*
            Validate the return codes for the last HTTP(S) call and give feedback to the end-user in the LOG.
        */
        %request_status;
    %mend;
    
    /*
        Call the create_export macro and generated the requested export.
    */
    %create_export;
%end;
%else %do;
    %put ERROR: Please select a location on the SAS Server. SAS Content folders are not supported by this custom step;
%end;

/*
    Remove all macro variables from memory.
*/
%symdel base_uri /NOWARN;
%symdel timestamp /NOWARN;
%symdel datestamp /NOWARN;
%symdel dttmstamp /NOWARN;
%symdel reportName /NOWARN;
%symdel path /NOWARN;
%symdel packageDir /NOWARN;
%symdel reportId /NOWARN;
%symdel dirType /NOWARN;
%symdel cptLength /NOWARN;
%symdel query /NOWARN;
%symdel export_file /NOWARN;
%symdel sizeIsValid /NOWARN;

/*
    Remove all macros from memory.
*/
%SYSMACDELETE request_status / NOWARN;
%SYSMACDELETE create_export / NOWARN;
/*******************************************************************
    This step provides an easy integration with the getExplanation
      endpoint.

    gce - is shorthand for Get Column Explanation
*******************************************************************/

%if "&_gce_inputtable_isCas." NE "true" %then %do; 
    data _null_;
      putLog 'ERROR: The selected input library does not point to a CASlib';
      abort;
   run;
%end;

%macro _gce_casCheckSessionExists;
    %local _gce_casSessionExists;
    %global _gce_casSessionUUID;
    %* Check whether CAS session exist, and if so retrieve CAS session UUID;
    %if %sysfunc(symexist(_SESSREF_)) %then %do;
        %let _gce_casSessionExists= %sysfunc(sessfound(&_SESSREF_));
        %if &_gce_casSessionExists = 1 %then %do;
            proc cas;
                session.sessionId result = sessresults;
                call symputx("_gce_casSessionUUID", sessresults[1]);
            quit;
        %end;
        %else %do;
            data _null_;
                putLog 'ERROR: An active CAS session is required in order to run this step.';
                abort;
            run;
        %end;
    %end;
    %else %do;
        data _null_;
            putLog 'ERROR: An active CAS session is required in order to run this step.';
            abort;
         run;
    %end;
%mend _gce_casCheckSessionExists;
%_gce_casCheckSessionExists;

* Get CAS Server name;
data _null_;
    url = getCASURL();
    i = find(url, '/', 'i', 10);
    server = ksubstr(url, i + 1, length(url) -i - 5);
    call symputx('_gce_server', server);
run;

filename _gce_in temp;

data _null_;
    file _gce_in;
    put '{"cas": {';
    server = '"server": "' || "&_gce_server." || '",';
    put server;
    casLibName = getlcaslib("casuser");
    library  = compress('"library": "' || casLibName || '",');
    put library;
    table = '"table": "' || "&_gce_inputtable_name." || '",';
    put table;
    sessionID = '"sessionId": "' || "&_gce_casSessionUUID." || '"}';
    put sessionID;
    if &_gce_ivd. EQ 0 then do;
        put ',"includeVariableDescription": false';
    end;
    if &_gce_iod. EQ 1 then do;
        put ',"includeOutlierDescription": true';
    end;
    if &_gce_useMissing. EQ 0 then do;
        put ',"useMissing": false';
    end;
    if &_gce_ivsr. EQ 0 then do;
        put ',"includeVariableScreeningResults": false';
    end;
    if &_gce_time_count. EQ 1 then do;
        dateVariable = ',"dateVariable": "' || "&_gce_time." || '"';
        put dateVariable;
    end;
    target = ',"targetVariable": "' || "&_gce_target." || '"}';
    put target;
run;

* Get the Viya Host URL;
%let _gce_viyaHost=%sysfunc(getoption(SERVICESBASEURL)); 
filename _gce_out temp;

* API call to https://developer.sas.com/rest-apis/insights/getExplanation;
proc http url = "&_gce_viyaHost./insights/explain"
    method = 'Post'
    in = _gce_in
    out = _gce_out
    oauth_bearer = sas_services;
    headers 'Accept' = 'application/json'
        'Content-Type' = 'application/json';
run; quit;

data _null_;
    if &SYS_PROCHTTP_STATUS_CODE. ne 200 then do;
        putLog 'ERROR: Request was not successfull';
        abort;
    end;
run;

libname _gce_out json;

* Set line size to maximum to reduce warnings about the printed results;
%let _gce_defaultLineSize = %sysfunc(getoption(linesize));
options linesize=256;
title 'Screening result';
proc print data=_gce_out.root(drop=ordinal_root version) noObs;
run; quit;
title;

%if &_gce_ivsr. %then %do;
    proc sql noPrint;
        create table work._gce_result_tab as
            select a.columnName
                , a.label
                , b.*
                from _gce_out.variableScreeningResults as a
                    left join _gce_out.variableScreening_actionsTaken(keep=ordinal_variableScreeningResults actionsTaken:) as b
                        on a.ordinal_variableScreeningResults EQ b.ordinal_variableScreeningResults
    ;quit;

    data work._gce_result_tab;
        set work._gce_result_tab(where=(actionsTaken1 NE '') drop=ordinal_variableScreeningResults);
    run;

    title 'Actions performed on columns in the dataset';
    proc print data=work._gce_result_tab;
    run; quit;
    title;
%end;

* Clean up;
options linesize=&_gce_defaultLineSize.;
filename _gce_in clear;
libname _gce_out clear;
filename _gce_out clear;
%symdel _gce_casSessionUUID _gce_server _gce_viyaHost _gce_defaultLineSize;
%sysmacdelete _gce_casCheckSessionExists;
proc datasets lib=work noprint nowarn;
   delete _gce_result_tab;
run; quit;
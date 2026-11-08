* ijd stand for Indexing SAS Job Definitions;
* Macro to get all job definitions in Viya environment;
%macro _ijd_get_job_definitions(_ijd_start=0, _ijd_limit=250);
    %local _ijd_viyaHost;

    %let _ijd_viyaHost = %sysFunc(getOption(servicesBaseURL));

    filename _ijd_out temp;

    * https://developer.sas.com/rest-apis/jobDefinitions/getJobDefinitions;
    proc http
        method = 'Get'
        url = "&_ijd_viyaHost./jobDefinitions/definitions?start=&_ijd_start.%nrstr(&)limit=&_ijd_limit."
        oauth_bearer = sas_services
        out = _ijd_out;
        headers 'Accept' = 'application/json';
    run;

    libname _ijd_out json;

    * Get the number of observations where one obs = one job definition;
    proc sql noprint;
        select count(*) into :_ijd_ds_nobs trimmed from _ijd_out.items;
    quit;

    * Get the number of columns;
    proc sql noprint;
        select nvar into :_ijd_nvar trimmed from dictionary.tables where
            libname='_IJD_OUT' and memname='ITEMS';
    quit;

    * Handle the first iteration and subsequent requests;
    %if &_ijd_start. eq 0 %then %do;
        data work._ijd_job_definition_index_temp(rename=(cTS=ccreationTimeStamp mTS=modifiedTimeStamp));
            length id $36. name $1024. cTS mTS 8. createdBy modifiedBy $1024. type $64. description $32000. has_code code_line_count 8.;
            format cTS mTS datetime22.3;

            set _ijd_out.items(drop=ordinal_root version);

            cTS = input(creationTimeStamp, e8601dz26.);
            mTS = input(modifiedTimeStamp, e8601dz26.);

            if length(code) > 1 then do;
                has_code = 1;
                code_line_count = countw(code, '\n');
            end;
            else has_code = 0;

            drop creationTimeStamp modifiedTimeStamp code;
        run;

        data work._ijd_job_definition_params_temp;
            length parameter_name $64. parameter_type $64. parameter_label $32000. is_required 8. default_value $32000.;
            set _ijd_out.items_parameters(drop=ordinal_parameters version);

            parameter_name = name;
            parameter_type = type;
            parameter_label = label;
            is_required = required;
            default_value = defaultValue;

            drop name type label required defaultValue;
        run;

        data work._ijd_job_definition_props_temp;
            length property_name $64. property_value $32000. has_html_form has_xml_prompt has_json_prompt 8.;
            set _ijd_out.items_properties(drop=ordinal_properties);

            property_name = name;
            if name eq 'prompts_v2' then do;
                has_json_prompt = 1;
                property_value = 'Code not copied!';
            end;
            else if name eq 'prompts' then do;
                has_xml_prompt = 1;
                property_value = 'Code not copied!';
            end;
            else if name eq 'form' then do;
                has_html_form = 1;
                property_value = 'Code not copied!';
            end;
            else do;
                property_value = value;
            end;

            drop name value;
        run;
    %end;
    %else %do;
        %if &_ijd_nvar. gt 2 %then %do;
            data work._ijd_job_definition_index_tmp(rename=(cTS=ccreationTimeStamp mTS=modifiedTimeStamp));
                length id $36. name $1024. cTS mTS 8. createdBy modifiedBy $1024. type $64. description $32000. has_code code_line_count 8.;
                format cTS mTS datetime22.3;

                set _ijd_out.items(drop=ordinal_root version);

                ordinal_items = ordinal_items + (&_ijd_start. * &_ijd_limit.);

                cTS = input(creationTimeStamp, e8601dz26.);
                mTS = input(modifiedTimeStamp, e8601dz26.);

                if length(code) > 1 then do;
                    has_code = 1;
                    code_line_count = countw(code, '\n');
                end;
                else has_code = 0;

                drop creationTimeStamp modifiedTimeStamp code;
            run;

            data work._ijd_job_definition_params_tmp;
                length parameter_name $64. parameter_type $64. parameter_label $32000. is_required 8. default_value $32000.;
                set _ijd_out.items_parameters(drop=ordinal_parameters version);

                ordinal_items = ordinal_items + (&_ijd_start. * &_ijd_limit.);
                parameter_name = name;
                parameter_type = type;
                parameter_label = label;
                is_required = required;
                default_value = defaultValue;

                drop name type label required defaultValue;
            run;

            data work._ijd_job_definition_props_tmp;
                length property_name $64. property_value $32000. has_html_form has_xml_prompt has_json_prompt 8.;
                set _ijd_out.items_properties(drop=ordinal_properties);

                ordinal_items = ordinal_items + (&_ijd_start. * &_ijd_limit.);
                property_name = name;
                if name eq 'prompts_v2' then do;
                    has_json_prompt = 1;
                    property_value = 'Code not copied!';
                end;
                else if name eq 'prompts' then do;
                    has_xml_prompt = 1;
                    property_value = 'Code not copied!';
                end;
                else if name eq 'form' then do;
                    has_html_form = 1;
                    property_value = 'Code not copied!';
                end;
                else do;
                    property_value = value;
                end;

                drop name value;
            run;

            proc append base=work._ijd_job_definition_index_temp
                data=work._ijd_job_definition_index_tmp;
            quit;

            proc append base=work._ijd_job_definition_params_temp
                data=work._ijd_job_definition_params_tmp;
            quit;

            proc append base=work._ijd_job_definition_props_temp
                data=work._ijd_job_definition_props_tmp;
            quit;
        %end;
    %end;

    libname _ijd_out clear;
    filename _ijd_out clear;

    proc dataSets lib=work noList;
        delete _ijd_job_definition_index_tmp _ijd_job_definition_params_tmp _ijd_job_definition_props_tmp;
    quit;

    * Check if another iteration is needed;
    %if &_ijd_ds_nobs eq &_ijd_limit and &_ijd_nvar. gt 2 %then %do;
        %put NOTE: Getting more job definitions...;
        %let _ijd_new_start=%eval(&_ijd_start. + &_ijd_limit.);
        %_ijd_get_job_definitions(_ijd_start=&_ijd_new_start., _ijd_limit=&_ijd_limit.);
    %end;

%mend _ijd_get_job_definitions;

%_ijd_get_job_definitions();

* Drop the tables in CAS, if they exist and the user wants to promote;
%if &_ijd_outtable_1_engine. eq CAS && &_ijd_promote. eq 1 %then %do;
    %let _ijd_outtable_1_lib = %sysfunc(getlcaslib(&_ijd_outtable_1_lib));

    proc casUtil inCASLib = "&_ijd_outtable_1_lib.";
        dropTable casData = "&_ijd_outtable_1_name." quiet;
    quit;
%end;
%if &_ijd_outtable_2_engine. eq CAS && &_ijd_promote. eq 1 %then %do;
    %let _ijd_outtable_2_lib = %sysfunc(getlcaslib(&_ijd_outtable_2_lib));

    proc casUtil inCASLib = "&_ijd_outtable_2_lib.";
        dropTable casData = "&_ijd_outtable_2_name." quiet;
    quit;
%end;
%if &_ijd_outtable_3_engine. eq CAS && &_ijd_promote. eq 1 %then %do;
    %let _ijd_outtable_3_lib = %sysfunc(getlcaslib(&_ijd_outtable_3_lib));

    proc casUtil inCASLib = "&_ijd_outtable_3_lib.";
        dropTable casData = "&_ijd_outtable_3_name." quiet;
    quit;
%end;

* Combine parameter and property information with job definition id;
proc sql;
    create table &_ijd_outtable_2. as
        select b.id
            , a.parameter_name
            , a.parameter_type
            , a.parameter_label
            , a.is_required
            , a.default_value
            from work._ijd_job_definition_params_temp as a
                left join work._ijd_job_definition_index_temp as b
                    on a.ordinal_items = b.ordinal_items;
    
    create table work._ijd_parameter_count as
        select id, count(*) as parameter_count
            from &_ijd_outtable_2.
                group by id;

    create table &_ijd_outtable_3. as
        select b.id
            , a.property_name
            , a.property_value
            , a.has_json_prompt
            , a.has_xml_prompt
            , a.has_html_form
            from work._ijd_job_definition_props_temp as a
                left join work._ijd_job_definition_index_temp as b
                    on a.ordinal_items = b.ordinal_items;
quit;

* Sort by id for py group processing;
proc sort data=&_ijd_outtable_3. out=work._ijd_job_prop_sorted;
    by id;
run;

* Aggregate information about prompts and forms per job definition;
data work._ijd_job_prop_info;
    set work._ijd_job_prop_sorted;
    by id;

    retain json_prompt xml_prompt html_form;

    if first.id then do;
        json_prompt = 0;
        xml_prompt = 0;
        html_form = 0;
    end;

    if has_json_prompt = 1 then json_prompt = 1;
    if has_xml_prompt = 1 then xml_prompt = 1;
    if has_html_form = 1 then html_form = 1;

    if last.id then do;
        output;
        drop property_name property_value has_json_prompt has_xml_prompt has_html_form;
end;

* Create final job definition index with parameter counts and prompt/form info;
proc sql;
    create table &_ijd_outtable_1. as
        select a.*
            , coalesce(b.parameter_count, 0) as parameter_count
            , coalesce(c.json_prompt, 0) as has_json_prompt
            , coalesce(c.xml_prompt, 0) as has_xml_prompt
            , coalesce(c.html_form, 0) as has_html_form
            from work._ijd_job_definition_index_temp(drop=ordinal_items) as a
                left join work._ijd_parameter_count as b
                    on a.id = b.id
                left join work._ijd_job_prop_info as c
                    on a.id = c.id;
quit;

* Promote and save to CAS if needed;
%macro _ijd_promote_and_save_to_cas();
    %if &_ijd_outtable_1_engine. eq CAS %then %do;
        proc casUtil inCASLib = "&_ijd_outtable_1_lib." outCASLib = "&_ijd_outtable_1_lib.";
            %if &_ijd_promote. eq 1 %then %do;
                promote casData = "&_ijd_outtable_1_name.";
            %end;
            %if &_ijd_save. eq 1 %then %do;
                save casData = "&_ijd_outtable_1_name." casOut = "&_ijd_outtable_1_name." replace;
            %end;
        quit;
    %end;
    %if &_ijd_outtable_2_engine. eq CAS %then %do;
        proc casUtil inCASLib = "&_ijd_outtable_2_lib." outCASLib = "&_ijd_outtable_2_lib.";
            %if &_ijd_promote. eq 1 %then %do;
                promote casData = "&_ijd_outtable_2_name.";
            %end;
            %if &_ijd_save. eq 1 %then %do;
                save casData = "&_ijd_outtable_2_name." casOut = "&_ijd_outtable_2_name." replace;
            %end;
        quit;
    %end;
    %if &_ijd_outtable_3_engine. eq CAS %then %do;
        proc casUtil inCASLib = "&_ijd_outtable_3_lib." outCASLib = "&_ijd_outtable_3_lib.";
            %if &_ijd_promote. eq 1 %then %do;
                promote casData = "&_ijd_outtable_3_name.";
            %end;
            %if &_ijd_save. eq 1 %then %do;
                save casData = "&_ijd_outtable_3_name." casOut = "&_ijd_outtable_3_name." replace;
            %end;
        quit;
    %end;
%mend _ijd_promote_and_save_to_cas;

%_ijd_promote_and_save_to_cas();

* Clean up;
%sysmacdelete _ijd_get_job_definitions;
%sysmacdelete _ijd_promote_and_save_to_cas;
proc dataSets lib=work noList;
    delete _ijd_job_definition_params_temp _ijd_job_definition_props_temp _ijd_parameter_count _ijd_job_prop_info _ijd_job_prop_sorted _ijd_job_definition_index_temp;
quit;
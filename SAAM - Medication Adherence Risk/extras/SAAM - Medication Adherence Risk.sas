%macro run_model_code();
    %medad_gui_prep();

    %if &GUIprepreturn > 0 %then %do;
        %local workdir returnmsg;
        %let workdir=%sysfunc(pathname(WORK)) ;
/*      %Error_Messages; */
/*      %load_json_to_sas_simple(jsonf = &workdir./error_messages.json, */
/*          expected_name = ErrorMessages, */
/*          sasdsname = ErrorMessages); */
/*      %get_error_message(table= WORK.ErrorMessages, ID= GUI_PREP&GUIprepreturn., ReturnVal = GUIERROR); */

        %if &GUIprepreturn. = 1 %then %do;
            %hpimedadh_throw_error();
            %hpimedadh_catch_error(msgkey = med_adh_risk_step_variables_error_msg);
            %let &returnmsg = %hpimedadh_assign_smd_var(msgkey = med_adh_risk_step_variables_error_msg, IN_DATA_STEP = N);
        %end;

        %if &GUIprepreturn. = 2 %then %do;
            %hpimedadh_throw_error();
            %hpimedadh_catch_error(msgkey = med_adh_risk_step_storage_error_msg);
            %let &returnmsg = %hpimedadh_assign_smd_var(msgkey = med_adh_risk_step_storage_error_msg, IN_DATA_STEP = N);
        %end;

/*      %put &GUIERROR.; */
        %goto exitearly;
    %end;
    
    %medad_write_json(loc = &sasloc., folder = &jsonpath. , fname =  &keyID._JSON_INPUT ); 
    
    %predict_med_adherence(jsonf = &jsonpath./&keyID._JSON_INPUT.json, prerun = &p_prerun);
    
    %exitearly:
%mend run_model_code;

%run_model_code();

%sysmacdelete run_model_code / nowarn;
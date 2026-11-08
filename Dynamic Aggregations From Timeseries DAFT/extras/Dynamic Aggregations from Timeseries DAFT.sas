/******************************************************************************
                                        %adjust_option_setings_controlled
                                        ________
Helps to maintain option changes in a program flow.
______________________________________________________________________________

USAGE:                         %adjust_option_setings_controlled(aosc_option_seq = ,
                                                        aosc_temp_option_storage_ds = ,
                                                        aosc_running_mode = ,
                                                        aosc_validvarname_setting =
                                                        )
______________________________________________________________________________

DESCRIPTION:

When option changes occur (only single word options allowed), then this macro
helps to maintain the original option setting, so at the end, the system can
revert back to the original settings.
______________________________________________________________________________

INPUT PARAMETERS AND KEYWORDS:

    aosc_option_seq                    This can be a blank separated list of single word
                                    SAS options (e.g. like: source, notes, etc...).
                                    If empty nothing happens in CHANGE mode.
    aosc_temp_option_storage_ds     provide the full dataset name (e.g. work._aosc_setting_storage)
                                    where the original option values (of the ones that are
                                    provided in AOSC_OPTION_SEQ) are stored.
    aosc_running_mode                2 modes available:
                                    CHANGE: takes settings from AOSC_OPTION_SEQ and applies
                                            those
                                    RESET: if AOSC_TEMP_OPTION_STORAGE_DS exists, this mode
                                            will set options back according to content of
                                            this dataset.
    aosc_validvarname_setting         if not blank, validvarname will be set to the value
                                    as provided with this parameter
_________________________________________________________________________

CALLS: none.
______________________________________________________________________________

NOTES: (Initials, date, summary)

Stephan Weigandt    20220922  First officially Released Version
______________________________________________________________________________

*******************************************************************************/

%macro adjust_option_setings_controlled(
    aosc_option_seq = ,
    aosc_temp_option_storage_ds = work._aosc_temp_option_storage_ds,
    aosc_running_mode = ,
    aosc_validvarname_setting =
    );


    %if %upcase("&aosc_running_mode") = "CHANGE" %then
    %do;
        data &aosc_temp_option_storage_ds;
            length
                new_setting $24.
                original_setting $24.
                new_single_setting_seq $256.
                ;
            new_setting = "";
            original_setting = "";
            new_single_setting_seq = "";
            numberofsettings = 0;
            additional_option_setting = 0;
            if 0;
        run;

        %if "&aosc_option_seq" ne "" or
            "&aosc_validvarname_setting" ne "" %then
        %do;
            data &aosc_temp_option_storage_ds;
                length
                    new_setting $24.
                    original_setting $24.
                    new_single_setting_seq $256.
                    ;
                new_single_setting_seq = strip("&aosc_option_seq");
                %if "&aosc_validvarname_setting" ne "" %then
                %do;
                    original_setting = getoption("validvarname");
                    additional_option_setting = 1;
                    new_setting = "&aosc_validvarname_setting";
                    output;
                    call execute("option validvarname = "||new_Setting||";");
                %end;
                %if "&aosc_option_seq" ne "" %then
                %do;
                    numberofsettings = count(new_single_setting_seq, " ") + 1;
                    additional_option_setting = 0;
                    do i = 1 to numberofsettings;
                        new_setting = "";
                        new_setting = scan(new_single_setting_seq, i, " ");
                        if not missing(new_setting) then
                        do;
                            original_setting = getoption(new_setting);
                            output;
                            call execute("option "||new_Setting||";");
                        end;
                    end;
                %end;
            run;
        %end;
    %end;

    %if %upcase("&aosc_running_mode") = "RESET" %then
    %do;
        %if %sysfunc(exist(&aosc_temp_option_storage_ds)) %then
        %do;
            data _null_;
                set &aosc_temp_option_storage_ds;
                if additional_option_setting = 1 then
                do;
                    call execute("option validvarname = "||original_setting||";");
                end; else
                do;
                    call execute("option "||original_setting||";");
                end;
            run;
        %end;
    %end;
%mend adjust_option_setings_controlled;

/** FOR TESTING ***
option nomprint nosource notes ;
%let option_seq = mprint notes source;
%let running_mode = CHANGE;
%let validvarname_setting = any;

%put PRECHANGE;
%put VALIDVARNAME: %sysfunc(getoption(validvarname));
%put SOURCE: %sysfunc(getoption(source));
%put NOTES: %sysfunc(getoption(notes));
%put MPRINT: %sysfunc(getoption(mprint));

%adjust_option_setings_controlled(
    aosc_option_seq = &option_seq,
    aosc_running_mode = &running_mode,
    aosc_validvarname_setting = &validvarname_setting
    );

%put POSTCHANGE;
%put VALIDVARNAME: %sysfunc(getoption(validvarname));
%put SOURCE: %sysfunc(getoption(source));
%put NOTES: %sysfunc(getoption(notes));
%put MPRINT: %sysfunc(getoption(mprint));


%let running_mode = RESET;

%adjust_option_setings_controlled(
    aosc_running_mode = &running_mode
    );

%put POSTRESET;
%put VALIDVARNAME: %sysfunc(getoption(validvarname));
%put SOURCE: %sysfunc(getoption(source));
%put NOTES: %sysfunc(getoption(notes));
%put MPRINT: %sysfunc(getoption(mprint));



*********************/

/**
store current SAS options settings, so they can be reset
at the end of processing
**/


%adjust_option_setings_controlled(
    aosc_option_seq = &options_seq_ui,
    aosc_running_mode = CHANGE,
    aosc_validvarname_setting = any
    );

%let daft_delimiter = ;
%macro set_os_dependent_values(
    sodv_delimiter = daft_delimiter
    );
    %if %upcase(&SYSSCP) = WIN %then
    %do;
        %let &sodv_delimiter = \;
    %end; %else
    %do;
        %let &sodv_delimiter = /;
    %end;
%mend set_os_dependent_values;
%set_os_dependent_values(
    sodv_delimiter = daft_delimiter
    );


/******************************************************************************
                                        %wordcnt
                                        ________
Counts the words in a list
______________________________________________________________________________

USAGE:                         %wordcnt(list,delim)
______________________________________________________________________________

DESCRIPTION:

Finds the number of words/tokens in a string.  The user specifies a
delimiter e.g. # to identify what separates the words.  The macro should be
called in the following way:
e.g. %let x=%wordcnt(item1#item2 item2a#item3, '#').
After running the macro x will be assigned the value of wordcnt.
______________________________________________________________________________

INPUT PARAMETERS AND KEYWORDS:

  list            the name of the string.
  delim           the delimiter e.g. '#'.
_________________________________________________________________________

CALLS: none.
______________________________________________________________________________

NOTES: (Initials, date, summary)

Stephan Weigandt    20200406  First officially Released Version
______________________________________________________________________________

*******************************************************************************/
%macro wordcnt(
    list,
    delim
    )
    ;
    %local
        word
        wc_count;
    %let wc_count = 0;
    %if %quote(&list) ne %then
    %do;
        %let word = %scan(%quote(&list), 1, &delim);
        %let word = %quote(&word);
        %do %while (&word ne);
            %let wc_count = %eval(&wc_count + 1);
            %let word = %scan(%quote(&list), &wc_count+1, &delim);
            %let word = %quote(&word);
        %end;
    %end;
    &wc_count
%mend wordcnt;
/** FOR TESTING ***
option mprint source notes ;
%let item_seq = a b c#d$f g #h#i$j;
%let separator = '$' ;
%let separator = '#' ;
%let separator = ' ' ;
%let number_of_items = %wordcnt(&item_seq, &separator);
%put &=number_of_items;

*********************/
%macro load_final_data(
    lfd_libname = ,
    wof2l_final_table_name = ,
    lfd_target_libname = bttrball,
    lfd_environment_macro_var_name = run_environment
    );
    %let wof2l_final_table_name = %upcase(&wof2l_final_table_name);
    %if &&&lfd_environment_macro_var_name = CAS %then
    %do;
        proc casutil;
            droptable casdata = "&wof2l_final_table_name"
                        incaslib = "&lfd_target_libname" quiet;
            droptable casdata = "&wof2l_final_table_name"
                        incaslib = "&lfd_target_libname" quiet;
        quit;
    %end;
        data &lfd_target_libname..&wof2l_final_table_name;
            set &lfd_libname..&wof2l_final_table_name;
        run;
    %if &&&lfd_environment_macro_var_name = CAS %then
    %do;
        proc casutil;
            promote casdata="&wof2l_final_table_name"
                    incaslib="&lfd_target_libname"
                    outcaslib="&lfd_target_libname"
                    casout="&wof2l_final_table_name";
            save casdata="&wof2l_final_table_name"
                    incaslib="&lfd_target_libname"
                    outcaslib="&lfd_target_libname"
                    casout="&wof2l_final_table_name" replace;
        quit;

    %end;
%mend load_final_data;
/******************************************************************************

                                    %create_agg_by_period_by_lag
                                                ________

DESCRIPTION:

  This program creates aggregates by time period and also by lag.
  The resulting variables can be very helpful for forecasting and such.
______________________________________________________________________________

NOTES: (Initials, date, summary)

stweig        20211102  First officially Released Version
______________________________________________________________________________

*******************************************************************************/

%macro create_agg_by_period_by_lag_core(
    cabpblc_lag_aggregation_seq = ,
    cabpblc_lag_delay_seq = ,
    cabpblc_input_ds = ,
    cabpblc_output_ds = ,
    cabpblc_var_seq = ,
    cabpblc_debug_mode = 0,
    cabpblc_group_by = ,
    cabpblc_group_by_except_time = ,
    cabpblc_temp_libname = work
    );
    %local
        max_lag_value
        aggregation_count
        delay_count
        agg_counter
        aggregation
        delay_counter
        counter
        varname
        cabpbl_target_lib_engine
        run_environment
        last_of_ds_groupby_varname
        ;
    %let max_lag_value = 1;
    %let aggregation_count = %wordcnt(&cabpblc_lag_aggregation_seq, '#');
    %let delay_count = %wordcnt(&cabpblc_lag_delay_seq, '#');
    %let cabpblc_var_count = %wordcnt(&cabpblc_var_seq, '#');
    %do agg_counter = 1 %to &aggregation_count;
        %let aggregation = %scan(&cabpblc_lag_aggregation_seq,
                                    &agg_counter,
                                    '#');
        %do delay_counter = 1 %to &delay_count;
            %let delay = %scan(&cabpblc_lag_delay_seq, &delay_counter, '#');
            %let temp = %sysevalf(&aggregation + &delay + 1);
            %if &temp > &max_lag_value %then
            %do;
                %let max_lag_value = &temp;
            %end;
        %end;
    %end;

    %if &cabpblc_debug_mode = 1 %then
    %do;
        %put INFORMATION: Max history needed for calculations &=max_lag_value;
    %end;

    %local
        cabpblc_temp_libname_compute
        cabpbl_output_libname
        cabpbl_output_table_name
        ;
    %let cabpblc_temp_libname_compute = work;
    data &cabpblc_temp_libname_compute.._DAFT_table_pre_agg_lag;
        set &cabpblc_input_ds;
        /* by &cabpblc_group_by; */
    run;
    proc sort
        data = &cabpblc_temp_libname_compute.._DAFT_table_pre_agg_lag;
        by &cabpblc_group_by;
    quit;

    %let last_of_ds_groupby_varname = %scan(&cabpblc_group_by_except_time, -1);

    data &cabpblc_temp_libname_compute.._DAFT_table_agg_by_lag ;
        set &cabpblc_temp_libname_compute.._DAFT_table_pre_agg_lag;
            %do counter = 1 %to &cabpblc_var_count;
                %let varname = %scan(%scan(&cabpblc_var_seq,
                                            &counter,
                                            "#"),
                                        1,
                                        '$');
                &varname.L0 = &varname.;
                %do lag_counter = 1 %to &max_lag_value;
                    &varname.L&lag_counter = lag&lag_counter(&varname.);
                %end;
            %end;
    run;
    data &cabpblc_temp_libname_compute.._DAFT_table_agg_by_lag;
        set &cabpblc_temp_libname_compute.._DAFT_table_agg_by_lag;
        by &cabpblc_group_by_except_time;
        retain temp_counter 0;
        drop temp_counter;
        if first.&last_of_ds_groupby_varname then
        do;
            temp_counter = 0;
        end;
        temp_counter = temp_counter + 1;
            %do counter = 1 %to &cabpblc_var_count;
                %let varname = %scan(%scan(&cabpblc_var_seq,
                                            &counter,
                                            "#"),
                                        1,
                                        '$');
                %do lag_counter = 1 %to &max_lag_value;
                    if temp_counter <= &lag_counter then
                    do;
                        &varname.L&lag_counter = .;
                    end;
                %end;
            %end;
    run;

    %let cabpbl_output_table_name = %upcase(%scan(&cabpblc_output_ds, 2, '.'));
    %let cabpbl_output_libname = %scan(&cabpblc_output_ds, 1, '.');
    %let cabpbl_target_lib_engine = ; /* V9 or CAS */
    proc sql noprint;
        select distinct(engine)
        into :cabpbl_target_lib_engine
        from dictionary.libnames
        where upcase(libname) = "%upcase(&cabpbl_output_libname)"
        ;
    quit;

    %let cabpbl_target_lib_engine = %upcase(%trim(
                                        %left(&cabpbl_target_lib_engine)
                                        ));
    %if &cabpbl_target_lib_engine = CAS %then
    %do;
        proc casutil;
            droptable     casdata = "&cabpbl_output_table_name"
                        incaslib = "&cabpbl_output_libname" quiet;
            droptable     casdata = "&cabpbl_output_table_name"
                        incaslib = "&cabpbl_output_libname" quiet;
        quit;
    %end;

    data &cabpblc_output_ds ;
        set &cabpblc_temp_libname_compute.._DAFT_table_agg_by_lag;
        if _n_ > &max_lag_value;
        %if &cabpblc_debug_mode = 0 %then
        %do;
            drop
            %do counter = 1 %to &cabpblc_var_count;
                %let varname = %scan(%scan(&cabpblc_var_seq,
                                            &counter,
                                            "#"),
                                        1,
                                        '$');
                %let cabpblc_stat_function = %scan(%scan(&cabpblc_var_seq,
                                                            &counter,
                                                            "#"),
                                                        2,
                                                        '$');
                &varname.
                &varname.L0
                %do lag_counter = 1 %to &max_lag_value;
                    &varname.L&lag_counter
                %end;
            %end;
            ;
        %end;
        %if &cabpblc_debug_mode = 1 %then
        %do;
            %put INFORMATION: Now processing &=aggregation_count;
            %put INFORMATION: Now processing &=delay_count;
            %put INFORMATION: Now processing &=cabpblc_lag_aggregation_seq;
            %put INFORMATION: Now processing &=cabpblc_lag_delay_seq;
            %put INFORMATION: Now processing &=cabpblc_var_count;
            %put INFORMATION: Now processing &=cabpblc_var_seq;
        %end;
        %do agg_counter = 1 %to &aggregation_count;
            %let aggregation = %scan(&cabpblc_lag_aggregation_seq,
                                        &agg_counter,
                                        '#');
            %do delay_counter = 1 %to &delay_count;
                %let delay = %scan(&cabpblc_lag_delay_seq, &delay_counter, '#');
                %do counter = 1 %to &cabpblc_var_count;
                    %let varname = %scan(%scan(&cabpblc_var_seq,
                                                &counter,
                                                "#"),
                                            1,
                                            '$');
                    %let cabpblc_stat_function = %scan(%scan(&cabpblc_var_seq,
                                                                &counter,
                                                                "#"),
                                                            2,
                                                            '$');
                    %if %upcase(&cabpblc_stat_function) eq AVG %then
                    %do;
                        &varname.&aggregation.L&delay=mean(of &varname.L&delay-
                                    &varname.L%eval(&delay + &aggregation - 1));
                    %end; %else %if %upcase(&cabpblc_stat_function) eq AGG %then
                    %do;
                        &varname.&aggregation.L&delay = sum(of &varname.L&delay-
                                    &varname.L%eval(&delay + &aggregation - 1));
                    %end; %else
                    %if %upcase(&cabpblc_stat_function) eq ASIS %then
                    %do;
                        &varname._L&delay = &varname.L&delay;
                        &varname._L&delay = &varname.L&delay;
                    %end; %else
                    %do;
                        &varname.&aggregation.L&delay=&cabpblc_stat_function.(of
                                    &varname.L&delay-
                                    &varname.L%eval(&delay + &aggregation - 1));
                    %end;
                %end;
            %end;
        %end;
    run;


    %if &cabpbl_target_lib_engine = CAS %then
    %do;
        proc casutil;
            promote casdata="&cabpbl_output_table_name"
                    incaslib="&cabpbl_output_libname"
                    outcaslib="&cabpbl_output_libname"
                    casout="&cabpbl_output_table_name";
            save     casdata="&cabpbl_output_table_name"
                    incaslib="&cabpbl_output_libname"
                    outcaslib="&cabpbl_output_libname"
                    casout="&cabpbl_output_table_name" replace;
        quit;
    %end;

%mend create_agg_by_period_by_lag_core;

/******************************************************************************

                                    %create_agg_by_period_by_lag
                                                ________

DESCRIPTION:

  This program creates aggregates by time period and also by lag.
  The resulting variables can be very helpful for forecasting and such.

______________________________________________________________________________

NOTES: (Initials, date, summary)

stweig        20211102  First officially Released Version

*******************************************************************************/

%macro create_agg_by_period_by_lag(
    cabpbl_input_ds = ,
    cabpbl_output_ds = ,
    cabpbl_sum_vars_seq = ,
    cabpbl_avg_vars_seq = ,
    cabpbl_min_vars_seq = ,
    cabpbl_max_vars_seq = ,
    cabpbl_date_variable = ,
    cabpbl_time_granularity = ,
    cabpbl_agg_period_seq = ,
    cabpbl_lag_period_seq = ,
    cabpbl_temp_libname = work,
    cabpbl_entity_definition_seq = ,
    cabpbl_group_by = ,
    cabpbl_debug_mode = 0,
    cabpbl_keep_org_var_after_means = 0

    );

    %local
        cabpbl_var_seq
        cabpbl_counter
        cabpbl_temp_variable_name
        ;
    %let cabpbl_sumvar_postfix = _sum;
    %let cabpbl_avgvar_postfix = _mean;
    %let cabpbl_minvar_postfix = _min;
    %let cabpbl_maxvar_postfix = _max;

    %if &cabpbl_keep_org_var_after_means = 1 %then
    %do;
        %let cabpbl_sumvar_postfix = ;
        %let cabpbl_avgvar_postfix = ;
        %let cabpbl_minvar_postfix = ;
        %let cabpbl_maxvar_postfix = ;
    %end;

    %let cabpbl_sum_vars_count = %wordcnt(&cabpbl_sum_vars_seq, "#");
    %let cabpbl_avg_vars_count = %wordcnt(&cabpbl_avg_vars_seq, "#");
    %let cabpbl_min_vars_count = %wordcnt(&cabpbl_min_vars_seq, "#");
    %let cabpbl_max_vars_count = %wordcnt(&cabpbl_max_vars_seq, "#");
    %if &cabpbl_debug_mode = 1 %then
    %do;
        %put INFORMATION: Now processing &=cabpbl_input_ds;
        %put INFORMATION: Now processing &=cabpbl_output_ds;
        %put INFORMATION: Now processing &=cabpbl_entity_definition_seq;
        %put INFORMATION: Now processing &=cabpbl_temp_libname;
    %end;
    %let cabpbl_var_seq = ;
    %do cabpbl_counter = 1 %to &cabpbl_sum_vars_count;
        %let cabpbl_temp_variable_name = %scan(&cabpbl_sum_vars_seq,
                                                &cabpbl_counter,
                                                "#");
        %if "&cabpbl_var_seq" ne "" %then
        %do;
            %let cabpbl_var_seq = &cabpbl_var_seq#&cabpbl_temp_variable_name.&cabpbl_sumvar_postfix.$agg;
        %end; %else
        %do;
            %let cabpbl_var_seq = &cabpbl_temp_variable_name.&cabpbl_sumvar_postfix.$agg;
        %end;
    %end;
    %do cabpbl_counter = 1 %to &cabpbl_avg_vars_count;
        %let cabpbl_temp_variable_name = %scan(&cabpbl_avg_vars_seq,
                                                &cabpbl_counter,
                                                "#");
        %if "&cabpbl_var_seq" ne "" %then
        %do;
            %let cabpbl_var_seq = &cabpbl_var_seq#&cabpbl_temp_variable_name.&cabpbl_avgvar_postfix.$avg;
        %end; %else
        %do;
            %let cabpbl_var_seq = &cabpbl_temp_variable_name.&cabpbl_avgvar_postfix.$avg;
        %end;
    %end;
    %do cabpbl_counter = 1 %to &cabpbl_min_vars_count;
        %let cabpbl_temp_variable_name = %scan(&cabpbl_min_vars_seq,
                                                &cabpbl_counter,
                                                "#");
        %if "&cabpbl_var_seq" ne "" %then
        %do;
            %let cabpbl_var_seq = &cabpbl_var_seq#&cabpbl_temp_variable_name.&cabpbl_minvar_postfix.$min;
        %end; %else
        %do;
            %let cabpbl_var_seq = &cabpbl_temp_variable_name.&cabpbl_minvar_postfix.$min;
        %end;
    %end;
    %do cabpbl_counter = 1 %to &cabpbl_max_vars_count;
        %let cabpbl_temp_variable_name = %scan(&cabpbl_max_vars_seq,
                                                &cabpbl_counter,
                                                "#");
        %if "&cabpbl_var_seq" ne "" %then
        %do;
            %let cabpbl_var_seq = &cabpbl_var_seq#&cabpbl_temp_variable_name.&cabpbl_maxvar_postfix.$max;
        %end; %else
        %do;
            %let cabpbl_var_seq = &cabpbl_temp_variable_name.&cabpbl_maxvar_postfix.$max;
        %end;
    %end;

    %if &cabpbl_debug_mode = 1 %then
    %do;
        %put INFORMATION: Now processing &=cabpbl_maxvar_postfix;
        %put INFORMATION: Now processing &=cabpbl_minvar_postfix;
        %put INFORMATION: Now processing &=cabpbl_sum_vars_seq;
        %put INFORMATION: Now processing &=cabpbl_avg_vars_seq;
        %put INFORMATION: Now processing &=cabpbl_entity_definition_seq;
        %put INFORMATION: Now processing &=cabpbl_lag_period_seq;
        %put INFORMATION: Now processing &=cabpbl_agg_period_seq;
        %put INFORMATION: Now processing &=cabpbl_var_seq;
    %end;

    %create_agg_by_period_by_lag_core(
        cabpblc_lag_aggregation_seq = &cabpbl_agg_period_seq,
        cabpblc_lag_delay_seq = &cabpbl_lag_period_seq,
        cabpblc_input_ds = &cabpbl_input_ds,
        cabpblc_output_ds = &cabpbl_output_ds,
        cabpblc_var_seq = &cabpbl_var_seq,
        cabpblc_debug_mode = &cabpbl_debug_mode,
        cabpblc_group_by = &cabpbl_group_by,
        cabpblc_group_by_except_time = &cabpbl_entity_definition_seq,
        cabpblc_temp_libname = &cabpbl_temp_libname
        );


%mend create_agg_by_period_by_lag;

/******************************************************************************

                                        %create_cube_by_timeunit
                                                ________



______________________________________________________________________________


DESCRIPTION:

  this program creates a cube by timeunit and by location.

  It is also designed to work with a UI like the task environment.

______________________________________________________________________________


NOTES: (Initials, date, summary)

stweig        20211102  First officially Released Version
______________________________________________________________________________

*******************************************************************************/

%macro create_cube_by_timeunit(
    ccbt_input_ds = ,
    ccbt_output_ds = work._ccbt_DAFT_output_ds,
    ccbt_debug_mode = 0,
    ccbt_sum_variables_seq = ,
    ccbt_avg_variables_seq = ,
    ccbt_min_variables_seq = ,
    ccbt_max_variables_seq = ,
    ccbt_avg_variables_blk_seq = ,
    ccbt_sum_variables_blk_seq = ,
    ccbt_min_variables_blk_seq = ,
    ccbt_max_variables_blk_seq = ,
    ccbt_entity_definition_seq = ,
    ccbt_date_variable = ,
    ccbt_group_by = ,
    ccbt_time_granularity = ,
    ccbt_temp_libname = work,
    ccbt_agg_start_year = 2015,
    ccbt_agg_end_year = 2021,
    ccbt_keep_org_var_after_means = 0

    );



/***
take the weather data and prepare variables
so they are congruent and standardized, e.g.
making sure the date variable is standardized, etc. so it can be used later
for building the krons according to chosen granularity
***/
    data &ccbt_temp_libname.._DAFT_pre_cube;
        set &ccbt_input_ds;
/*        %if %upcase("&ccbt_temp_libname") eq "PUBLIC" %then*/
/*        %do;*/
/*            by &ccbt_group_by;*/
/*        %end;*/
        keep
            _DAFT_year
            _DAFT_&ccbt_time_granularity
            &ccbt_sum_variables_blk_seq
            &ccbt_avg_variables_blk_seq
            &ccbt_min_variables_blk_seq
            &ccbt_max_variables_blk_seq
            &ccbt_date_variable
            _DAFT_date_sas
            &ccbt_entity_definition_seq
            ;
        format _DAFT_date_sas date9.;
        /* %if &run_environment = CAS %then
        %do; */
            _DAFT_date_sas = &date_variable;
        /* %end; %else
        %do;
            _DAFT_date_sas = input(&date_variable, anydtdte10.);
        %end; */
        %if %upcase("&ccbt_time_granularity") ne "DAY" %then
        %do;
            _DAFT_&ccbt_time_granularity=&ccbt_time_granularity(_DAFT_date_sas);
        %end; %else
        %do;
            _DAFT_&ccbt_time_granularity = mod(juldate(_DAFT_date_sas),1000);
        %end;
        _DAFT_year = year(_DAFT_date_sas);
        if _DAFT_year >= &ccbt_agg_start_year and
            _DAFT_year <= &ccbt_agg_end_year;
    run;

%if %upcase("&ccbt_temp_libname") ne "PUBLIC" %then
%do;
    proc sort data = &ccbt_temp_libname.._DAFT_pre_cube;
        by &ccbt_group_by;
    run;
%end;

/**
build normalized cube
**/

/***
depending on the variables chosen by topic (sum, min or max), those
aggregated values are calculated by the group_by variables.
***/
    %let ccbt_sum_vars_count = %wordcnt(&ccbt_sum_variables_seq, "#");
    %let ccbt_avg_vars_count = %wordcnt(&ccbt_avg_variables_seq, "#");
    %let ccbt_min_vars_count = %wordcnt(&ccbt_min_variables_seq, "#");
    %let ccbt_max_vars_count = %wordcnt(&ccbt_max_variables_seq, "#");

    proc means data = &ccbt_temp_libname.._DAFT_pre_cube nolabels noprint;
        class &ccbt_group_by;
        output out = &ccbt_temp_libname.._DAFT_cube_base_&ccbt_time_granularity
        %if "&ccbt_sum_variables_seq" ne "" %then
        %do;
            sum(&ccbt_sum_variables_blk_seq)=
        %end;
        %if "&ccbt_avg_variables_seq" ne "" %then
        %do;
            mean(&ccbt_avg_variables_blk_seq)=
        %end;
        %if "&ccbt_min_variables_seq" ne "" %then
        %do;
            min(&ccbt_min_variables_blk_seq)=
        %end;
        %if "&ccbt_max_variables_seq" ne "" %then
        %do;
            max(&ccbt_max_variables_blk_seq)=
        %end;
            /autoname;
    quit;






%let ccbt_location_count = %wordcnt(&ccbt_entity_definition_seq, " ");
/***
drop variables and rows from the means output
that is not needed.
***/

    data &ccbt_output_ds
            %if &ccbt_keep_org_var_after_means = 1 %then
            %do;
            (rename = (
                %do ccbt_counter = 1 %to &ccbt_sum_vars_count;
                    %let ccbt_varname = %scan(&ccbt_sum_variables_seq,
                                                &ccbt_counter,
                                                "#");
                        &ccbt_varname._sum = &ccbt_varname.
                %end;
                %do ccbt_counter = 1 %to &ccbt_avg_vars_count;
                    %let ccbt_varname = %scan(&ccbt_avg_variables_seq,
                                                &ccbt_counter,
                                                "#");
                        &ccbt_varname._avg = &ccbt_varname.
                %end;
                %do ccbt_counter = 1 %to &ccbt_min_vars_count;
                    %let ccbt_varname = %scan(&ccbt_min_variables_seq,
                                                &ccbt_counter,
                                                "#");
                        &ccbt_varname._min = &ccbt_varname.
                %end;
                %do ccbt_counter = 1 %to &ccbt_max_vars_count;
                    %let ccbt_varname = %scan(&ccbt_max_variables_seq,
                                                &ccbt_counter,
                                                "#");
                        &ccbt_varname._max = &ccbt_varname.
                %end;
                    )
            )
            %end;
            ;
        set &ccbt_temp_libname.._DAFT_cube_base_&ccbt_time_granularity;
        drop
            _type_
            _freq_
            ;
        if not missing(_DAFT_year) and
        %do ccbt_counter = 1 %to &ccbt_location_count;
            %let ccbt_varname = %scan(&ccbt_entity_definition_seq,
                                        &ccbt_counter,
                                        " ");
            not missing(&ccbt_varname) and
        %end;
            not missing(_DAFT_&ccbt_time_granularity) then
        do;
            output &ccbt_output_ds;
        end;
    run;



%mend create_cube_by_timeunit;

%macro create_clean_varname_blk_seq(
    ccvbs_seq_name = ,
    ccvbs_original_seq = );
    %let &ccvbs_seq_name = ;
%put ccvbs_seq_name = &ccvbs_seq_name;
%put ccvbs_original_seq = &ccvbs_original_seq;
    %do ccvbs_counter = 1 %to %wordcnt(&ccvbs_original_seq, "#");
        %let ccvbs_seq_piece = %scan(&ccvbs_original_seq, &ccvbs_counter, "#");
        %put &=ccvbs_seq_piece;
        %let ccvbs_pos_start = %index(&ccvbs_seq_piece, %str(%'));
        %let ccvbs_pos_end = %index(&ccvbs_seq_piece, %str(%'n));
%put &=ccvbs_seq_piece &=ccvbs_pos_start &=ccvbs_pos_end;
        %if &ccvbs_pos_start ne 0 and
            &ccvbs_pos_end ne 0 %then
        %do;
            %let ccvbs_length_to_check = %length(&ccvbs_seq_piece);
            %let ccvbs_new_var_name = %sysfunc(tranwrd(%substr(&ccvbs_seq_piece,
                                                                2,
                                                                %eval(&ccvbs_length_to_check-3)),
                                                                %str( ),
                                                                %str(_)));
            %let ccvbs_new_var_name = %sysfunc(tranwrd(&ccvbs_new_var_name,
                                                        %str($),
                                                        %str(_)));
            %let ccvbs_new_var_name = %sysfunc(tranwrd(&ccvbs_new_var_name,
                                                        %str(%@),
                                                        %str(_)));
            %let ccvbs_new_var_name = %sysfunc(tranwrd(&ccvbs_new_var_name,
                                                        %str(%%),
                                                        %str(_)));
            %let ccvbs_new_var_name = %sysfunc(tranwrd(&ccvbs_new_var_name,
                                                        %str(%(),
                                                        %str(_)));
            %let ccvbs_new_var_name = %sysfunc(tranwrd(&ccvbs_new_var_name,
                                                        %str(%)),
                                                        %str(_)));
%put &=ccvbs_length_to_check  &=ccvbs_new_var_name;
        %end; %else
        %do;
            %let ccvbs_new_var_name = &ccvbs_seq_piece;
%put  &=ccvbs_new_var_name;
        %end;
        %let &ccvbs_seq_name = &&&ccvbs_seq_name &ccvbs_new_var_name;
    %end;
%mend create_clean_varname_blk_seq;
/******************************************************************************

                                    %create_data_views_execution
                                            ________


This wrapper can take any data set that is based on location variables
and date and creates aggregations by period by lag for specific time units.

It is also set up to create so called kron variables that give an indication how
a distribution compares to a norm distributed that is calculated
on the fly based on a norm time period (e.g. 6 years).

______________________________________________________________________________


______________________________________________________________________________

NOTES: (Initials, date, summary)

stweig        20211102  First officially Released Version

______________________________________________________________________________

*******************************************************************************/

%macro wrapper_create_lagged_aggrgtns(
    wcla_input_ds = ,
    wcla_output_ds = work._DAFT_output_ds,
    wcla_run_environment = CAS,
    wcla_debug_mode = 0,
    wcla_sum_variables_seq = ,
    wcla_avg_variables_seq = ,
    wcla_min_variables_seq = ,
    wcla_max_variables_seq = ,
    wcla_entity_definition_seq = ,
    wcla_date_variable = ,
    wcla_time_granularity = ,
    wcla_agg_period_seq = ,
    wcla_lag_period_seq = ,
    wcla_directory_separator = ,
    wcla_temp_libname = work,
    wcla_agg_start_year = 2015,
    wcla_agg_end_year = 2021,
    wcla_keep_org_var_after_means = 0
    );



/***
set group_by parameter for later.
_daft_year_ variable will be created automatically
***/
%local
    wcla_group_by_except_last
    wcla_group_by_last
    wcla_group_by
    wcla_location_count
    wcla_sum_vars_seq_blk
    wcla_avg_vars_seq_blk
    wcla_min_vars_seq_blk
    wcla_max_vars_seq_blk


    ;

/***
sequence information that comes in via the task UI needs to get
cleaned up, so it is standardized and comes as a sequence separated
by a blank (instead of separated by #)
provide the sequence name as defined in the task object
and the name of the macro variable
where the new standardized sequence is stored.
It especially deals with variable names that contain blanks.
So with that I have the original sequence plus a sequence with
the new variable names that are separated by blanks.
This allows better usage downstream.
***/

%let wcla_sum_vars_seq_blk = ;
%let wcla_avg_vars_seq_blk = ;
%let wcla_min_vars_seq_blk = ;
%let wcla_max_vars_seq_blk = ;
%let wcla_ent_def_seq_blk = ;

%create_clean_varname_blk_seq
    (
    ccvbs_seq_name = wcla_ent_def_seq_blk,
    ccvbs_original_seq = &wcla_entity_definition_seq
    );
%create_clean_varname_blk_seq
    (
    ccvbs_seq_name = wcla_sum_vars_seq_blk,
    ccvbs_original_seq = &wcla_sum_variables_seq
    );
%create_clean_varname_blk_seq
    (
    ccvbs_seq_name = wcla_avg_vars_seq_blk,
    ccvbs_original_seq = &wcla_avg_variables_seq
    );
%create_clean_varname_blk_seq
    (
    ccvbs_seq_name = wcla_min_vars_seq_blk,
    ccvbs_original_seq = &wcla_min_variables_seq
    );
%create_clean_varname_blk_seq
    (
    ccvbs_seq_name = wcla_max_vars_seq_blk,
    ccvbs_original_seq = &wcla_max_variables_seq
    );
%let wcla_group_by_except_last = &wcla_ent_def_seq_blk _daft_year;
%let wcla_group_by_last = _daft_&wcla_time_granularity;

%let wcla_group_by = &wcla_group_by_except_last &wcla_group_by_last;

%let wcla_location_count = %wordcnt(&wcla_entity_definition_seq, " ");

%if &debug_mode = 1 %then
%do;
    %put INFORMATION: Now processing &=wcla_sum_variables_seq;
    %put INFORMATION: Now processing &=wcla_avg_variables_seq;
    %put INFORMATION: Now processing &=wcla_min_variables_seq;
    %put INFORMATION: Now processing &=wcla_max_variables_seq;
    %put INFORMATION: Now processing &=wcla_avg_vars_seq_blk;
    %put INFORMATION: Now processing &=wcla_sum_vars_seq_blk;
    %put INFORMATION: Now processing &=wcla_min_vars_seq_blk;
    %put INFORMATION: Now processing &=wcla_max_vars_seq_blk;
    %put INFORMATION: Now processing &=wcla_entity_definition_seq;
    %put INFORMATION: Now processing &=wcla_ent_def_seq_blk;
    %put INFORMATION: Now processing &=wcla_group_by;
%end;



data &wcla_temp_libname.._DAFT_RAW_DATA_ADJUSTED (keep =
        &wcla_sum_vars_seq_blk
        &wcla_avg_vars_seq_blk
        &wcla_min_vars_seq_blk
        &wcla_max_vars_seq_blk
        &date_variable
        &wcla_ent_def_seq_blk
        );
    set &wcla_input_ds ;
    %do wcla_var_counter = 1 %to %wordcnt(&wcla_sum_vars_seq_blk, ' ');
        %let wcla_variable_new = %scan(&wcla_sum_vars_seq_blk,
                                        &wcla_var_counter,
                                        ' ');
        %let wcla_variable_old = %scan(&wcla_sum_variables_seq,
                                        &wcla_var_counter,
                                        "#");
        &wcla_variable_new = &wcla_variable_old;
    %end;
    %do wcla_var_counter = 1 %to %wordcnt(&wcla_avg_vars_seq_blk, ' ');
        %let wcla_variable_new = %scan(&wcla_avg_vars_seq_blk,
                                        &wcla_var_counter,
                                        ' ');
        %let wcla_variable_old = %scan(&wcla_avg_variables_seq,
                                        &wcla_var_counter,
                                        "#");
        &wcla_variable_new = &wcla_variable_old;
    %end;
    %do wcla_var_counter = 1 %to %wordcnt(&wcla_min_vars_seq_blk, ' ');
        %let wcla_variable_new = %scan(&wcla_min_vars_seq_blk,
                                        &wcla_var_counter,
                                        ' ');
        %let wcla_variable_old = %scan(&wcla_min_variables_seq,
                                        &wcla_var_counter,
                                        "#");
        &wcla_variable_new = &wcla_variable_old;
    %end;
    %do wcla_var_counter = 1 %to %wordcnt(&wcla_max_vars_seq_blk, ' ');
        %let wcla_variable_new = %scan(&wcla_max_vars_seq_blk,
                                        &wcla_var_counter,
                                        ' ');
        %let wcla_variable_old = %scan(&wcla_max_variables_seq,
                                        &wcla_var_counter,
                                        "#");
        &wcla_variable_new = &wcla_variable_old;
    %end;
    %do wcla_var_counter = 1 %to %wordcnt(&wcla_ent_def_seq_blk, ' ');
        %let wcla_variable_new = %scan(&wcla_ent_def_seq_blk,
                                        &wcla_var_counter,
                                        ' ');
        %let wcla_variable_old = %scan(&wcla_entity_definition_seq,
                                        &wcla_var_counter,
                                        "#");
        &wcla_variable_new = &wcla_variable_old;
    %end;
run;

%let wcla_avg_vars_seq = %sysfunc(tranwrd(&wcla_avg_vars_seq_blk,
                                            %str( ),
                                            %str(#)
                                            ));
%let wcla_sum_vars_seq = %sysfunc(tranwrd(&wcla_sum_vars_seq_blk,
                                            %str( ),
                                            %str(#)
                                            ));
%let wcla_min_vars_seq = %sysfunc(tranwrd(&wcla_min_vars_seq_blk,
                                            %str( ),
                                            %str(#)
                                            ));
%let wcla_max_vars_seq = %sysfunc(tranwrd(&wcla_max_vars_seq_blk,
                                            %str( ),
                                            %str(#)
                                            ));

%create_cube_by_timeunit(
    ccbt_input_ds = &wcla_temp_libname.._DAFT_RAW_DATA_ADJUSTED,
    ccbt_output_ds =
        &wcla_temp_libname.._DAFT_cube_base_clean_&wcla_time_granularity,
    ccbt_debug_mode = &wcla_debug_mode,
    ccbt_sum_variables_seq = &wcla_sum_vars_seq,
    ccbt_avg_variables_seq = &wcla_avg_vars_seq,
    ccbt_min_variables_seq = &wcla_min_vars_seq,
    ccbt_max_variables_seq = &wcla_max_vars_seq,
    ccbt_avg_variables_blk_seq = &wcla_avg_vars_seq_blk,
    ccbt_sum_variables_blk_seq = &wcla_sum_vars_seq_blk,
    ccbt_min_variables_blk_seq = &wcla_min_vars_seq_blk,
    ccbt_max_variables_blk_seq = &wcla_max_vars_seq_blk,
    ccbt_entity_definition_seq = &wcla_ent_def_seq_blk,
    ccbt_date_variable = &wcla_date_variable,
    ccbt_group_by = &wcla_group_by,
    ccbt_time_granularity = &wcla_time_granularity,
    ccbt_temp_libname = &wcla_temp_libname,
    ccbt_agg_start_year = &wcla_agg_start_year,
    ccbt_agg_end_year = &wcla_agg_end_year,
    ccbt_keep_org_var_after_means = &wcla_keep_org_var_after_means

    );
/***
depending on the variables chosen by topic (sum, min or max), those
aggregated values are calculated by the group_by variables.
***/

%create_agg_by_period_by_lag(
    cabpbl_input_ds =
        &wcla_temp_libname.._DAFT_cube_base_clean_&wcla_time_granularity,
    cabpbl_output_ds = &wcla_output_ds,
    cabpbl_sum_vars_seq = &wcla_sum_variables_seq,
    cabpbl_avg_vars_seq = &wcla_avg_variables_seq,
    cabpbl_min_vars_seq = &wcla_min_variables_seq,
    cabpbl_max_vars_seq = &wcla_max_variables_seq,
    cabpbl_date_variable = &wcla_date_variable,
    cabpbl_time_granularity = &wcla_time_granularity,
    cabpbl_agg_period_seq = &wcla_agg_period_seq,
    cabpbl_lag_period_seq = &wcla_lag_period_seq,
    cabpbl_temp_libname = &wcla_temp_libname,
    cabpbl_entity_definition_seq = &wcla_ent_def_seq_blk,
    cabpbl_group_by = &wcla_group_by,
    cabpbl_debug_mode = &wcla_debug_mode,
    cabpbl_keep_org_var_after_means = &wcla_keep_org_var_after_means

    );


%mend wrapper_create_lagged_aggrgtns;

%macro execute_all();

%let directory_separator = /;
%let write_log_into_file = &write_log_to_file_ui    ;
%let provide_default_log_path = ;
%let log_file_directory_source_ui = ;
%if "&log_file_path_ui" ne "" %then
%do;
    %let provide_default_log_path = %scan(&log_file_path_ui, 2, ":")/;
    %let log_file_directory_source_ui = %scan(&log_file_path_ui, 1, ":");
%end;


%let period_start_year = &period_start_year_ui;
%let period_end_year = &period_end_year_ui;
%let input_ds = &input_ds_ui;
%let output_ds = &outputtable_ui;
%let run_everything_in_CAS = &run_everything_in_CAS_ui;

%let target_lib_output_ds = %scan(&output_ds, 1, '.');
%let target_lib_engine = ; /* V9 or CAS */
proc sql noprint;
    select distinct(engine)
    into :target_lib_engine
    from dictionary.libnames
    where upcase(libname) = "%upcase(&target_lib_output_ds)"
    ;
quit;
%let run_environment = CAS;
%let debug_mode = &debug_mode_ui;

%let target_lib_engine = %upcase(%trim(%left(&target_lib_engine)));



%let temp_libname = Public;
%if &run_everything_in_CAS = 0 or
    &target_lib_engine = V9 %then
%do;
    %let temp_libname = work;
%end;

%let sum_variables_seq = ;
%do counter = 1 %to &sum_variables_seq_ui_count;
    %let sum_variables_seq = &sum_variables_seq &&sum_variables_seq_ui_&counter._name.#;
%end;

%let avg_variables_seq = ;
%do counter = 1 %to &avg_variables_seq_ui_count;
    %let avg_variables_seq = &avg_variables_seq &&avg_variables_seq_ui_&counter._name.#;
%end;

%let min_variables_seq = ;
%do counter = 1 %to &min_variables_seq_ui_count;
    %let min_variables_seq = &min_variables_seq &&min_variables_seq_ui_&counter._name.#;
%end;

%let max_variables_seq = ;
%do counter = 1 %to &max_variables_seq_ui_count;
    %let max_variables_seq = &max_variables_seq &&max_variables_seq_ui_&counter._name.#;
%end;

%let entity_definition_seq = ;
%do counter = 1 %to &entity_def_seq_ui_count;
    %let entity_definition_seq = &entity_definition_seq &&entity_def_seq_ui_&counter._name.#;
%end;

%let date_variable = &date_variable_ui_1_name;
%let time_granularity = &time_granularity_ui;
%let agg_period_seq = &agg_period_seq_ui;
%let lag_period_seq = &lag_period_seq_ui;
%if &debug_mode = 1 %then
%do;
    %put INFORMATION: Now processing &=target_lib_engine;
    %put INFORMATION: Now processing &=min_variables_seq;
    %put INFORMATION: Now processing &=sum_variables_seq;
    %put INFORMATION: Now processing &=avg_variables_seq;
    %put INFORMATION: Now processing &=entity_definition_seq;
    %put INFORMATION: Now processing &=max_variables_seq;
%end;


%if "%upcase(&log_file_directory_source_ui)" eq "SASSERVER" %then
%do;
    %let log_file_in_SAS_Content = 0;
%end; %else
%do;
    %let log_file_in_SAS_Content = 1;
%end;
%let write_log_to_file = &write_log_to_file_ui;

%if &write_log_to_file = 1 %then
%do;

    /**
    determine and set todays date
    **/
    data _null_;
        todaysdate = today();
        year = year(todaysdate);
        month = put(month(todaysdate), z2.);
        day = put(day(todaysdate), z2.);
        nowtime = time();
        hour = put(hour(nowtime), z2.);
        minute = put(minute(nowtime), z2.);
        put minute;
        timestamp = trim(left(year))||trim(left(month))||trim(left(day))||"_"||trim(left(hour))||trim(left(minute));
        call symput('timestamp', timestamp);
    run;
    %let timestamp = %trim(%left(&timestamp));


    %if &log_file_in_SAS_Content = 1 %then
    %do;
        filename logfile
            filesrvc
            folderpath = "&provide_default_log_path"
            filename = "wc_run_&timestamp.aggregations.log";
        filename printfl
            filesrvc
            folderpath = "&provide_default_log_path"
            filename = "wc_run_&timestamp.aggregations.out";
    %end; %else
    %do;
        filename logfile "&provide_default_log_path.wc_run_&timestamp.aggregations.log";
        filename printfl "&provide_default_log_path.wc_run_&timestamp.aggregations.out";
    %end;
    proc printto
        log=logfile new
        print=printfl new;
    quit;
%end;



%wrapper_create_lagged_aggrgtns(
    wcla_input_ds = &input_ds,
    wcla_output_ds = &output_ds,
    wcla_run_environment = CAS,
    wcla_debug_mode = &debug_mode,
    wcla_sum_variables_seq = &sum_variables_seq,
    wcla_avg_variables_seq = &avg_variables_seq,
    wcla_min_variables_seq = &min_variables_seq,
    wcla_max_variables_seq = &max_variables_seq,
    wcla_entity_definition_seq = &entity_definition_seq,
    wcla_date_variable = &date_variable,
    wcla_time_granularity = &time_granularity,
    wcla_agg_period_seq = &agg_period_seq,
    wcla_lag_period_seq = &lag_period_seq,
    wcla_directory_separator = &directory_separator,
    wcla_temp_libname = &temp_libname,
    wcla_agg_start_year = &period_start_year,
    wcla_agg_end_year = &period_end_year
    );


%if &write_log_to_file = 1 %then
%do;
    proc printto ;
    quit;
%end;

%mend execute_all;


%execute_all();

/**
Restore original SAS options settings
**/

%adjust_option_setings_controlled(
    aosc_running_mode = RESET
    );

%if &debug_mode_ui ne 1 %then
%do;
    proc datasets lib=work;
        delete
            _daft_:
            _aosc:
            ;
    quit;
%end;

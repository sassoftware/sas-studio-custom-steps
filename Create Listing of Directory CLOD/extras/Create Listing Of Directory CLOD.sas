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

%let clod_delimiter = ;
%macro set_os_dependent_values(
    sodv_delimiter = clod_delimiter
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
    sodv_delimiter = clod_delimiter
    );

/******************************************************************************

                                    %list_all_files
                                        ________

creates a list of files, based on the provided extensions, that are available
within a root directory. It automatically also checks all subdirectories.

______________________________________________________________________________

USAGE:                         see testing section on the bottom of this code

______________________________________________________________________________

DESCRIPTION:

This macro creates a SAS dataset that lists all files that can be found within a
root directory and all subdirectories under the provided root directory.
This can be applied to all available files (by choosing "*" as extension),
or for specific extensions.
______________________________________________________________________________

INPUT PARAMETERS AND KEYWORDS:

laf_root_dir                provide the top level directory from
                            where to search for files.
laf_extenstion_to_check     can be the wildcard "*" or
                            any extension, e.g. "CSV", "XLM" etc
                            (provide without quotes)
laf_output_ds_file_overview       provide SAS datasets providing
                                LIBNAME and SAS Dataset name
______________________________________________________________________________

NOTES: (Initials, date, summary)

Stephan Weigandt    20200406  First officially Released Version
Stephan Weigandt    20220610  expanded functionality to also cover
                              SAS Content objects
______________________________________________________________________________

*******************************************************************************/

%macro list_all_files(
    laf_root_dir,
    laf_extenstion_to_check,
    laf_output_ds_file_overview,
    laf_debug_mode = 0,
    laf_directory_separator = /,
    laf_traverse_directories = 1,
    laf_is_sas_content_directory = 0,
    laf_iteration_number = 0_0,
    laf_output_selection = 0
    );
    %local
        filrf
        rc
        did
        memcnt
        name
        lal_append_flag
        lal_length
        tot_obs
        table_append_seq
        laf_full_file_name
        i
        laf_debug_text_
        ;
	%let laf_root_dir = %sysfunc(dequote(&laf_root_dir));

    %let laf_debug_text_skipping = INFORMATION: Skipping due to extension:;
    %let laf_debug_text_scanning = INFORMATION: Scanning next directory:;

	data _null_;
		length laf_root_dir $4096.;
		laf_root_dir = strip(symget("laf_root_dir"));
		lengthstr = klength(laf_root_dir);
		endstr = ksubstr(laf_root_dir, lengthstr, 1);
		if endstr ne "/" then
			laf_root_dir = strip(laf_root_dir)||'/';
		call symput('laf_root_dir', strip(laf_root_dir));
		    put laf_root_dir;
	run;
/*     %let lal_length = %length(&laf_root_dir); */
/*     %if "%substr(%trim(%left(&laf_root_dir)), &lal_length, 1)" ne */
/*             "%trim(%left(&laf_directory_separator))" %then */
/*     %do; */
/*         %let laf_root_dir = %trim(%left(&laf_root_dir))&laf_directory_separator; */
/*     %end; */
    /**
        clean up work directory to prevent unwanted beahvior
    **/
    %if &laf_iteration_number = 0_0 %then
    %do;
        proc datasets lib= work;
            delete _LAF_spcl_list_files_:;
        quit;
    %end;
    %let laf_do_processing = 1;
    %if &laf_is_sas_content_directory = 0 %then
    %do;
        filename f&laf_iteration_number "&laf_root_dir";
    %end; %else
    %do;
        %let laf_rc = 1;
        data _null_;
            length fref $ 8 folderPath $ 1024;
            folderPath = "&laf_root_dir";
            fref="__isdir";
            rcf = filename(fref, ,
                            "filesrvc",
                            cats('folderpath=',quote(strip(folderPath)))
                            );
            put rcf;
            call symput ("laf_rc", strip(rcf));
        run;

        %if &laf_rc = 0 %then
        %do;
            filename f&laf_iteration_number filesrvc folderpath="&laf_root_dir";
        %end; %else
        %do;
            %let laf_do_processing = 0;
        %end;
    %end;
    %let laf_next_iteration = %eval(%scan(&laf_iteration_number, 1, '_') + 1);
    %let lal_append_flag = 0;
    %if %sysfunc(exist(work._LAF_spcl_list_files_&laf_iteration_number)) %then
    %do;
        data work._LAF_spcl_list_files_&laf_iteration_number._inter;
            set work._LAF_spcl_list_files_&laf_iteration_number
            %if %sysfunc(exist(
                        work._LAF_spcl_list_files_&laf_iteration_number._inter
                        )) %then
            %do;
                work._LAF_spcl_list_files_&laf_iteration_number._inter
            %end;
            ;
        run;
        %let lal_append_flag = 1;
    %end;
    data work._LAF_spcl_list_files_&laf_iteration_number ;
        keep
            directory_path
            full_file_name
            file_name
            is_in_SAS_Content_flag
            object_type
            ;
        length
            directory_path $768
            file_name $256
            full_file_name $1024
            arg1 $4096
			arg2 $4096
			arg3 $4096
			arg3b $4096
			arg4 $4096
            object_type $12
            ;
        is_in_SAS_Content_flag = &laf_is_sas_content_directory;
        directory_path = symget("laf_root_dir");
    %if &laf_do_processing = 1 %then
    %do;
        did = dopen("f&laf_iteration_number");
        mcount = dnum(did);
        /**
        check if directory exists or the correct area is chosen.
        if not set to 0 to prevent error message
        **/
        if missing(mcount) then
            mcount = 0;
        do i=1 to mcount;
            file_name = dread(did, i);
            fid = mopen(did, file_name);
            fileext = kfind(file_name,'.');
            extension = kscan(file_name, -1, '.');
            /* fid=0 means directory in most cases */
            full_file_name = STRIP(directory_path)||STRIP(file_name);
            if fid > 0 or fileext then
            do;
                if "&laf_extenstion_to_check" = "*" or
                kupcase(extension) = %upcase("&laf_extenstion_to_check") then
                do;
                    %if &laf_debug_mode %then
                    %do;
                        put "INFORMATION: Found following file:" full_file_name;
                    %end;
                    %if &laf_output_selection le 1 %then
                    %do;
                        object_type = "file";
                        output;
                    %end;
                end;
                %if &laf_debug_mode %then
                %do;
                    else
                    do;
                        put "&laf_debug_text_skipping" full_file_name;
                    end;
                %end;
            end;
/*             %if &laf_traverse_directories = 1 %then */
/*             %do; */
                else
                do;
                    %if &laf_debug_mode %then
                    %do;
                        put "&laf_debug_text_scanning" full_file_name;
                    %end;
                    %if &laf_output_selection ge 1 %then
                    %do;
                        object_type = "folder";
                        output;
                    %end;
                    arg1 = cats('%nrstr(%list_all_files(',
                                quote(strip(full_file_name)),
                                ", &laf_extenstion_to_check,"
                                );
                    arg2 = cats("&laf_output_ds_file_overview,
                                laf_debug_mode = &laf_debug_mode,"
                                );
                    arg3 = cats("laf_directory_separator =
                                    &laf_directory_separator,
                                laf_traverse_directories =
                                    &laf_traverse_directories,"
                                );
                    arg3b = cats("laf_output_selection =
                                    &laf_output_selection, "
                                );
                    arg4 = cats("laf_is_sas_content_directory =
                                    &laf_is_sas_content_directory,
                                laf_iteration_number =
                                    &laf_next_iteration._",i,"))"
                                );
                    call execute(strip(arg1)||
                                strip(arg2)||
                                strip(arg3)||
                                strip(arg3b)||
                                strip(arg4)
                                );
                end;
/*             %end; */
        end;
        rc = dclose(did);
    %end;
%else
    %do;
        full_file_name = STRIP(ksubstr(directory_path,
                                        1,
                                        klength(directory_path)-1)
                                );
        %if &laf_output_selection le 1 %then
        %do;
            object_type = "file";
            output;
        %end;
    %end;
    run;

    %let tot_obs = 0;
    proc sql noprint;
        select nobs into :tot_obs
        from dictionary.tables
        where kupcase(libname)='WORK' and
                kupcase(memname)="_LAF_SPCL_LIST_FILES_&laf_iteration_number";
    quit;
/*     %put total records = &tot_obs.; */
    %if &tot_obs = 0 %then
    %do;
        proc datasets lib= work;
            delete _LAF_SPCL_LIST_FILES_&laf_iteration_number;
        quit;
        %if lal_append_flag = 1 %then
        %do;
            data work._LAF_spcl_list_files_&laf_iteration_number.;
                set work._LAF_spcl_list_files_&laf_iteration_number._inter;
            run;
            proc datasets lib= work;
                delete _LAF_spcl_list_files_&laf_iteration_number._inter;
            quit;
        %end;
    %end; %else
    %do;
        %if lal_append_flag = 1 %then
        %do;
            data work._LAF_spcl_list_files_&laf_iteration_number.;
                set work._LAF_spcl_list_files_&laf_iteration_number.
                    work._LAF_spcl_list_files_&laf_iteration_number._inter;
            run;
            proc datasets lib= work;
                delete _LAF_spcl_list_files_&laf_iteration_number._inter;
            quit;
        %end;
    %end;

    /**
        Only execute the outer ring of the execution sequence, or said otherwise the very first occurence
    **/

    %if &laf_iteration_number = 0_0 %then
    %do;
        %if %sysfunc(exist(&laf_output_ds_file_overview)) %then %do;
            proc sql;
                delete from &laf_output_ds_file_overview;
            quit;
        %end;

        %let table_append_seq = ;
        %if &laf_traverse_directories = 1 %then
        %do;

                proc sql noprint;
                    select memname into :table_append_seq separated by " "
                    from dictionary.tables
                    where kupcase(libname)='WORK' and
                            kupcase(memname)contains"_LAF_SPCL_LIST_FILES_";
                quit;
        %end; %else
        %do;
                proc sql noprint;
                    select memname into :table_append_seq separated by " "
                    from dictionary.tables
                    where kupcase(libname)='WORK' and
                            kupcase(memname)contains"_LAF_SPCL_LIST_FILES_0_0";
                quit;
        %end;

        %if "&table_append_seq" ne "" %then
        %do;
            data work._laf_file_overview_sort;
                set &table_append_seq;
            run;
            proc sort data =work._laf_file_overview_sort;
                by full_file_name
                    descending object_type
                ;
            quit;

            data &laf_output_ds_file_overview;
                set work._laf_file_overview_sort;
                by full_file_name;
                if first.full_file_name ne last.full_file_name  then
                do;
                    object_type = "file";
                end;
                if first.full_file_name;
            run;
        %end;

    %end;

    %if &laf_do_processing = 1 %then
    %do;
        filename f&laf_iteration_number clear;
    %end;
%mend list_all_files;
/** FOR TESTING ***

option mprint source notes;
%let root_directory = /Users/<<MYUSERID>>/My Folder/SAS Videos;
%let is_content_dir = 0;
%let delimiter = \;
%let delimiter = /;
%let output_selection = 1;
%let extension = *;
%let overview_ds = work.file_overview;
%let traverse_directories = 1;
%list_all_files(
    &root_directory,
    &extension,
    &overview_ds,
    laf_traverse_directories = &traverse_directories,
    laf_debug_mode = 1,
    laf_directory_separator = /,
    laf_is_sas_content_directory = &is_content_dir,
    laf_output_selection = &output_selection
    );

*********************/

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
/**
  @file
  @brief <Your brief here>
  <h4> SAS Macros </h4>
**/
%macro execute_all();

    %let write_log_to_file = &write_log_into_file_ui;
    %if &write_log_to_file eq 1 %then
    %do;
        %let provide_default_log_path = %scan(&log_file_path_ui, 2, ":")/;
        %let log_file_directory_source_ui = %scan(&log_file_path_ui, 1, ":");

        %if "%upcase(&log_file_directory_source_ui)" eq "SASSERVER" %then
        %do;
            %let log_file_in_SAS_Content = 0;
        %end; %else
        %do;
            %let log_file_in_SAS_Content = 1;
        %end;

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
            timestamp = trim(left(year))||
                        trim(left(month))||
                        trim(left(day))||
                        "_"||
                        trim(left(hour))||
                        trim(left(minute));
            call symput('timestamp', timestamp);
        run;
        %let timestamp = %trim(%left(&timestamp));
        %if &debug_mode_ui = 1 %then
        %do;
            %put INFORMATION: Logfile location: &provide_default_log_path;
            %put INFORMATION: Logfile name : clod_run_&timestamp..log;
        %end;


        %if &log_file_in_SAS_Content = 1 %then
        %do;
            filename logfl
                filesrvc
                folderpath = "&provide_default_log_path"
                filename = "clod_run_&timestamp..log";
            filename printfl
                filesrvc
                folderpath = "&provide_default_log_path"
                filename = "clod_run_&timestamp..out";
        %end; %else
        %do;
            filename logfl "&provide_default_log_path.clod_run_&timestamp..log";
            filename printfl "&provide_default_log_path.clod_run_&timestamp..out";
        %end;
        proc printto
            log=logfl new
            print=printfl new;
        quit;
    %end;



/*     %put     &=debug_mode_ui    ; */
/*     %put     &=clod_traverse_directories_ui    ; */
/*     %put     &=extension_ui    ; */
/*     %put     &=root_directory_ui    ; */
/*     %put    &=log_file_path_ui; */
    %let target_libname_ui = &outputtable_ui_lib;
    %let output_dataset_name_ui = &outputtable_ui_name;
/*     %put     &=target_libname_ui    ; */
/*     %put     &=write_log_into_file_ui    ; */
/*     %put    &=output_dataset_name_ui; */
/*     %put    &=options_seq_ui; */
    %let root_directory = ;
    %let root_dir_src = ;

    data _null_;
        call symput('root_directory', quote(strip(scan(symget('root_directory_ui'), 2, ":"))));
        call symput('root_dir_src', strip(scan(symget('root_directory_ui'), 1, ":")));
    run;

    %let is_content_dir = 0;
    %if %upcase("&root_dir_src") eq "SASCONTENT" %then
    %do;
        %let is_content_dir = 1;
    %end;
/*     %put &=root_directory; */

    %let     target_libname    =    &target_libname_ui    ;
    %let     write_log_into_file    =    &write_log_into_file_ui    ;


    %let provide_default_log_path = ;
    %let log_file_directory_source_ui = ;
    %if "&log_file_path_ui" ne "" %then
    %do;
        %let provide_default_log_path = %scan(&log_file_path_ui, 2, ":")/;
        %let log_file_directory_source_ui = %scan(&log_file_path_ui, 1, ":");
    %end;
    %if "%upcase(&log_file_directory_source_ui)" eq "SASSERVER" %then
    %do;
        %let install_mode_in_SAS_Content = 0;
    %end; %else
    %do;
        %let install_mode_in_SAS_Content = 1;
    %end;
    %let target_environment = ;
    proc sql noprint;
        select distinct(engine)
        into :target_environment
        from dictionary.libnames
        where upcase(libname) = "%upcase(&target_libname_ui)"
        ;
    quit;

    %if %upcase(&target_environment) = CAS %then
    %do;
        %if &cas_promote_ui = 1 %then
        %do;
            proc casutil     incaslib="&target_libname_ui"
                            outcaslib="&target_libname_ui";
                droptable casdata = "&output_dataset_name_ui" quiet;
                droptable casdata = "&output_dataset_name_ui" quiet;
            quit;
        %end;
    %end;


    %let overview_ds = &target_libname_ui..&output_dataset_name_ui;
    %let traverse_directories = 1;
    %list_all_files(
        &root_directory,
        &extension_ui,
        &overview_ds,
        laf_traverse_directories = &clod_traverse_directories_ui,
        laf_debug_mode = &debug_mode_ui,
        laf_directory_separator = &clod_delimiter,
        laf_is_sas_content_directory = &is_content_dir,
        laf_output_selection = &output_selection_ui
        );

    %if %upcase(&target_environment) = CAS %then
    %do;
        %if &cas_promote_ui = 1 %then
        %do;
            proc casutil     incaslib="&target_libname_ui"
                            outcaslib="&target_libname_ui";
                promote casdata = "&output_dataset_name_ui"
                        casout="&output_dataset_name_ui";
                %if &cas_save_on_disk_ui = 1 %then
                %do;
                    save     casdata= "&output_dataset_name_ui"
                            casout="&output_dataset_name_ui" replace;
                %end;
            quit;

        %end;

    %end;

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
                _clod:
                _LAF_:
                _aosc:
                ;
        quit;
    %end;




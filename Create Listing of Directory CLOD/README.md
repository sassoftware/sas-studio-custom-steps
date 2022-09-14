# Create Listing Of Directory CLOD

* [Description](#description)
* [SAS Viya Version Support](#sas-viya-version-support)
* [User Interface](#user-interface)
* [Requirements](#requirements)
* [Usage](#usage)
* [Download Step File](#download-step-file)
* [Prompt UI](#prompt-ui)
* [Program](#program)

## Description

The "**Create Listing Of Directory CLOD**" Custom Step provides a full listing of what is all in a directory. 
Just chooose the parent/root directory and CLOD will create a dataset that then can be used for further processing. 

### Output Table Structure

The structure of the output table is:
DIRECTORY_PATH: path of the object found
FILE_NAME: object name (is either a file or a directory)
FULL_FILE_NAME: concatenation of DIRECTORY_PATH and FILE_NAME
OBJECT_TYPE: when the option "INCLUDES_DIRECTORY_IN_OUTPUT" is set to YES, then this field is included and is either set to "folder" or "file", depending on object type.
IS_IN_SAS_CONTENT_FLAG: is either 0 (if object is found in SAS Server) or 1 (if object is found in SAS Content)

### Parameter Overview

#### Provide Root Directory (can be from within SAS Server or SAS Content) - ROOT_DIRECTORY_UI

Provide the top level directory that CLOD should use to start looking for files and subfolders. CLOD will then traverse through the whole directory structure and find all the files and folders below this top level directory. 

If the root directory is in the SAS Server area, this has to start out with: sasserver: (e.g. example value for root_directory: sasserver:/mnt/desired/path/for/files_to_be_readin/from/SASServer/).

If the root directory is in the SAS Content area, this has to start out with: sascontent: (e.g. example value for root_directory: sascontent:/Public/desired_path_for/files/in/SASContent/).

#### Extension - EXTENSION_UI

Default value: *

if * is provided, all files are captured in the output. 
Otherwise, any text string can provided, which will be used as a filter for the ending of the files. So only files will be captured that fall into this filter. 

#### Target Libname (CAS or 94, needs to exist) - TARGET_LIBNAME_UI

This can be any existing library accessible to SAS Studio. 
If it is a CASLIB, the table will NOT be promoted or saved to disk. 
If that is desired, this would need to happen outside the custom step. 

#### Name of Output Dataset? - OUTPUT_DATASET_NAME_UI

Provide the output table name. 

#### Traverse Subdirectories? - CLOD_TRAVERSE_DIRECTORIES_UI

Suggested default value: Yes (1)

If Yes is selected, CLOD will traverse all directories that can be found under directory provided in "Root Directory" parameter.
If No is selected, CLOD will only look for files in selected directory. 

#### Include Directories in Output? - INCLUDE_DIRECTORIES_UI

Suggested default value: No (0)

If No is selected, the output dataset doesn't contain the actual directory names, but only the files that could be found. 
If Yes is selected, the actual directory names are also captured, and an additional column is added to the output table (OBJECT_TYPE), which is either set to "file" or "folder".

#### If a CAS library is selected, should table be promoted? - CAS_PROMOTE_UI

Suggested default value: No (0)
This selection is only applied if selected target library is a CAS library. 
If No is selected, the table is not promoted and stays only active for the local session.
If Yes is selected, CLOD will promote the table. 

#### Should promoted table be saved on disk? - CAS_SAVE_ON_DISK_UI

Suggested default value: No (0)
This selection is only applied if selected target library is a CAS library and output table is promoted. 
If No is selected, the table is not saved on disk.
If Yes is selected, CLOD will save table on disk and make it persistent. 

#### Debug Mode? - DEBUG_MODE_UI

Suggested default value: No (0)

If set to 1, CLOD writes out more information out to the log, that might be helpful for further investigations.

If set to 0, CLOD just writes out the default SAS log output, depending on the settings of the options mprint, source and notes.

#### Path for logfile creation - LOG_FILE_PATH_UI

suggested default value: empty/missing.

This parameter is only relevant when the parameter "WRITE_LOG_INTO_FILE_UI" is set to 1. 

Provide a default path for all runs: as soon as a path is provided, this path is being used for ALL runs.

If the log directory is in the SAS Server area, this has to start out with: sasserver: (e.g. example value for provide_default_log_path: sasserver:/mnt/desired/path/for/log_files_to_be_saved/on/SASServer/).

If the log directory is in the SAS Content area, this has to start out with: sascontent: (e.g. example value for provide_default_log_path: sascontent:/Public/desired_path_for/logfiles/in/SASContent/).

#### Write Log into File? - WRITE_LOG_INTO_FILE_UI

Suggested default value: No (0)

If set to 0, log is written into default SAS log location.

If set to 1, log is written to location as provided under the parameter "LOG_FILE_PATH_UI".

#### Provide options to be applied for this run (only single options allowed like mprint, nosource, etc). - OPTIONS_SEQ_UI

If provided those options will be applied to the execution of the code. 


## SAS Viya Version Support
Tested with 2020.1.5 or later

## User Interface

### Essential Tab

![](img/clod_essential_tab.PNG)

If you are happy with all the default settings, only adjust the parameters in the "Essentials" tab, e.g. select the fully automated mode (1) and provide the top level directory either from within SAS Server or now also from SAS Content (here only CSV or TXT files are processed in the fully automated mode) and click "Run" to start the journey.

### General Tab

![](img/clod_general_tab.PNG)

### Admin Tab

![](img/clod_admin_tab.PNG)

### About Tab

![](img/clod_about_tab.PNG)


## Requirements

* A CAS session established (in an autoexec or something else)
* The provided "Target Libname" under the "Essential" tab must exist.
* One or more CAS engine libraries (SAS libraries pointing to CASLIBs) to allow the definition of the target table

Example:

```sas

```

## Usage

### How to Run CLOD 
![](img/clod_run_with_defaults.gif)


## Change Log

Version 3.1


## Download Step File

[Data Ingestion Auto Pilot DIAP Light for External Files](./Data%20Ingestion%20Auto%20Pilot%20DIAP%20Light%20for%20External%20Files.step)

## Prompt UI

```json
{
	"showPageContentOnly": true,
	"pages": [
		{
			"id": "Essentials",
			"type": "page",
			"label": "Essentials",
			"children": [
				{
					"id": "root_directory_ui",
					"type": "path",
					"label": "Provide Root Directory (can be from within SAS Server or SAS Content)",
					"pathtype": "folder",
					"placeholder": "Select Root Directory",
					"required": true,
					"visible": ""
				},
				{
					"id": "Extension_ui",
					"type": "textfield",
					"label": "Extension",
					"placeholder": "",
					"required": true,
					"visible": ""
				},
				{
					"id": "target_libname_ui",
					"type": "textfield",
					"label": "Target Libname (CAS or 94, needs to exist)",
					"placeholder": "",
					"required": true,
					"visible": ""
				},
				{
					"id": "output_dataset_name_ui",
					"type": "textfield",
					"label": "Name of Output Dataset?",
					"placeholder": "",
					"required": true,
					"visible": ""
				}
			]
		},
		{
			"id": "General",
			"type": "page",
			"label": "General",
			"children": [
				{
					"id": "clod_traverse_directories_ui",
					"type": "radiogroup",
					"label": "Traverse Subdirectories?",
					"items": [
						{
							"value": "1",
							"label": "Yes"
						},
						{
							"value": "0",
							"label": "No"
						}
					],
					"visible": ""
				},
				{
					"id": "include_directories_ui",
					"type": "radiogroup",
					"label": "Include Directories in Output?",
					"items": [
						{
							"value": "1",
							"label": "Yes"
						},
						{
							"value": "0",
							"label": "No"
						}
					],
					"visible": ""
				},
				{
					"id": "cas_save_on_disk_ui",
					"type": "radiogroup",
					"label": "Should promoted table be saved on disk?",
					"items": [
						{
							"value": "1",
							"label": "Yes"
						},
						{
							"value": "0",
							"label": "No"
						}
					],
					"visible": [
						"$cas_promote_ui",
						"=",
						"1"
					]
				},
				{
					"id": "cas_promote_ui",
					"type": "radiogroup",
					"label": "If a CAS library is selected, should table be promoted?",
					"items": [
						{
							"value": "1",
							"label": "Yes"
						},
						{
							"value": "0",
							"label": "No"
						}
					],
					"visible": ""
				}
			]
		},
		{
			"id": "Admin",
			"type": "page",
			"label": "Admin",
			"children": [
				{
					"id": "debug_mode_ui",
					"type": "radiogroup",
					"label": "Debug Mode?",
					"items": [
						{
							"value": "1",
							"label": "Yes"
						},
						{
							"value": "0",
							"label": "No"
						}
					],
					"visible": ""
				},
				{
					"id": "log_file_path_ui",
					"type": "path",
					"label": "Path for logfile creation",
					"pathtype": "folder",
					"placeholder": "Please select a location for the log file!",
					"required": true,
					"visible": [
						"$write_log_into_file_ui",
						"=",
						"1"
					]
				},
				{
					"id": "write_log_into_file_ui",
					"type": "radiogroup",
					"label": "Write Log into File?",
					"items": [
						{
							"value": "1",
							"label": "Yes"
						},
						{
							"value": "0",
							"label": "No"
						}
					],
					"visible": ""
				},
				{
					"id": "options_seq_ui",
					"type": "textfield",
					"label": "Provide options to be applied for this run (only single options allowed like mprint, nosource, etc).",
					"placeholder": "",
					"required": false,
					"visible": ""
				}
			]
		},
		{
			"id": "About",
			"type": "page",
			"label": "About",
			"children": [
				{
					"id": "text1",
					"type": "text",
					"text": "CLOD: Create Listing Of Directory:\n\nCLOD lists all files and directories that can be found under a provided (root-) directory.\n\nIf you have any questions, suggestions, ideas or any unexpected behavior, please contact:\nstephan.weigandt@sas.com.\n\nHere is an overview of the available parameters:\n\n#### Provide Root Directory (can be from within SAS Server or SAS Content) - ROOT_DIRECTORY_UI\n\nProvide the top level directory that CLOD should use to start looking for files and subfolders. CLOD will then traverse through the whole directory structure and find all the files and folders below this top level directory. \n\nIf the root directory is in the SAS Server area, this has to start out with: sasserver: (e.g. example value for root_directory: sasserver:/mnt/desired/path/for/files_to_be_readin/from/SASServer/).\n\nIf the root directory is in the SAS Content area, this has to start out with: sascontent: (e.g. example value for root_directory: sascontent:/Public/desired_path_for/files/in/SASContent/).\n\n#### Extension - EXTENSION_UI\n\nDefault value: *\n\nif * is provided, all files are captured in the output. \nOtherwise, any text string can provided, which will be used as a filter for the ending of the files. So only files will be captured that fall into this filter. \n\n#### Target Libname (CAS or 94, needs to exist) - TARGET_LIBNAME_UI\n\nThis can be any existing library accessible to SAS Studio. \nIf it is a CASLIB, the table will NOT be promoted or saved to disk. \nIf that is desired, this would need to happen outside the custom step. \n\n#### Name of Output Dataset? - OUTPUT_DATASET_NAME_UI\n\nProvide the output table name. \n\n#### Traverse Subdirectories? - CLOD_TRAVERSE_DIRECTORIES_UI\n\nSuggested default value: Yes (1)\n\nIf Yes is selected, CLOD will traverse all directories that can be found under directory provided in \"Root Directory\" parameter.\nIf No is selected, CLOD will only look for files in selected directory. \n\n#### Include Directories in Output? - INCLUDE_DIRECTORIES_UI\n\nSuggested default value: No (0)\n\nIf No is selected, the output dataset doesn't contain the actual directory names, but only the files that could be found. \nIf Yes is selected, the actual directory names are also captured, and an additional column is added to the output table (OBJECT_TYPE), which is either set to \"file\" or \"folder\".\n\n#### If a CAS library is selected, should table be promoted? - CAS_PROMOTE_UI\n\nSuggested default value: No (0)\nThis selection is only applied if selected target library is a CAS library. \nIf No is selected, the table is not promoted and stays only active for the local session.\nIf Yes is selected, CLOD will promote the table. \n\n#### Should promoted table be saved on disk? - CAS_SAVE_ON_DISK_UI\n\nSuggested default value: No (0)\nThis selection is only applied if selected target library is a CAS library and output table is promoted. \nIf No is selected, the table is not saved on disk.\nIf Yes is selected, CLOD will save table on disk and make it persistent. \n\n#### Debug Mode? - DEBUG_MODE_UI\n\nSuggested default value: No (0)\n\nIf set to 1, CLOD writes out more information out to the log, that might be helpful for further investigations.\n\nIf set to 0, CLOD just writes out the default SAS log output, depending on the settings of the options mprint, source and notes.\n\n#### Path for logfile creation - LOG_FILE_PATH_UI\n\nsuggested default value: empty/missing.\n\nThis parameter is only relevant when the parameter \"WRITE_LOG_INTO_FILE_UI\" is set to 1. \n\nProvide a default path for all runs: as soon as a path is provided, this path is being used for ALL runs.\n\nIf the log directory is in the SAS Server area, this has to start out with: sasserver: (e.g. example value for provide_default_log_path: sasserver:/mnt/desired/path/for/log_files_to_be_saved/on/SASServer/).\n\nIf the log directory is in the SAS Content area, this has to start out with: sascontent: (e.g. example value for provide_default_log_path: sascontent:/Public/desired_path_for/logfiles/in/SASContent/).\n\n#### Write Log into File? - WRITE_LOG_INTO_FILE_UI\n\nSuggested default value: No (0)\n\nIf set to 0, log is written into default SAS log location.\n\nIf set to 1, log is written to location as provided under the parameter \"LOG_FILE_PATH_UI\".\n\n#### Provide options to be applied for this run (only single options allowed like mprint, nosource, etc). - OPTIONS_SEQ_UI\n\nIf provided those options will be applied to the execution of the code. \n\n",
					"visible": ""
				}
			]
		}
	],
	"values": {
		"root_directory_ui": "",
		"Extension_ui": "*",
		"target_libname_ui": "work",
		"output_dataset_name_ui": "directory_overview",
		"clod_traverse_directories_ui": {
			"value": "1",
			"label": "Yes"
		},
		"include_directories_ui": {
			"value": "0",
			"label": "No"
		},
		"cas_save_on_disk_ui": {
			"value": "0",
			"label": "No"
		},
		"cas_promote_ui": {
			"value": "0",
			"label": "No"
		},
		"debug_mode_ui": {
			"value": "0",
			"label": "No"
		},
		"log_file_path_ui": "",
		"write_log_into_file_ui": {
			"value": "0",
			"label": "No"
		},
		"options_seq_ui": "nonotes nomprint nosource"
	},
	"promptHierarchies": []
}
```

## Program

```sas
data work._clod_option_setting_storage;
	length
		new_setting $24.
		original_setting $24.
		new_setting_seq $256.
		;
	new_setting = "";
	original_setting = "";
	new_setting_seq = "";
	numberofsettings = 0;
	if 0;
run;
%let _clod_option_validvarname_org = %sysfunc(getoption(validvarname));
option validvarname = any;
%if "&options_seq_ui" ne "" %then
%do;
data _clod_option_setting_storage;
	length new_setting $24.;
	new_setting_seq = strip("&options_seq_ui");
	numberofsettings = count(new_setting_seq, " ") + 1;
	
	do i = 1 to numberofsettings;
		new_setting = "";
		new_setting = scan(new_setting_seq, i, " ");
		if not missing(new_setting) then
		do;
			original_setting = getoption(new_setting);
			call execute("option "||new_Setting||";");
	
			output;
		end;
	end;
	run;	
%end;
 
%let install_mode_in_SAS_Content = 0;
 
 
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
%mend;
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
root directory and all subdirectories under the provided root directory. This can be
applied to all available files (by choosing "*" as extension), or for specific extensions.
______________________________________________________________________________
 
 
INPUT PARAMETERS AND KEYWORDS:
 
laf_root_dir                  provide the top level directory from where to search for files.
laf_extenstion_to_check       can be the wildcard "*" or any extension, e.g. "CSV", "XLM" etc
								(provide without quotes)
laf_output_ds_file_overview   provide SAS datasets providing LIBNAME and SAS Dataset name
______________________________________________________________________________
 
NOTES: (Initials, date, summary)
 
Stephan Weigandt    20200406  First officially Released Version
Stephan Weigandt    20220610  expanded functionality to also cover SAS Content objects
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
	laf_include_directories = 0
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
		i;
 
 
	%let lal_length = %length(&laf_root_dir);
	%if "%substr(%trim(%left(&laf_root_dir)), &lal_length, 1)" ne "%trim(%left(&laf_directory_separator))" %then
	%do;
		%let laf_root_dir = %trim(%left(&laf_root_dir))&laf_directory_separator;
	%end;
	%if &laf_iteration_number = 0_0 %then
	%do;
		proc datasets lib= work;
			delete _DIAP_spcl_list_files_:;
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
			rcf = filename(fref, , "filesrvc", cats('folderpath=',quote(strip(folderPath))));
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
	%if %sysfunc(exist(work._DIAP_spcl_list_files_&laf_iteration_number)) %then
	%do;
		data work._DIAP_spcl_list_files_&laf_iteration_number._inter;
			set work._DIAP_spcl_list_files_&laf_iteration_number
			%if %sysfunc(exist(work._DIAP_spcl_list_files_&laf_iteration_number._inter)) %then
			%do;
				work._DIAP_spcl_list_files_&laf_iteration_number._inter
			%end;
			;
		run;
		%let lal_append_flag = 1;
	%end;
	data work._DIAP_spcl_list_files_&laf_iteration_number ;
		keep
			directory_path
			full_file_name	
			file_name
			is_in_SAS_Content_flag
			%if &laf_include_directories = 1 %then
			%do;
				object_type
			%end;
			;
		length
			directory_path $768
			file_name $256
			full_file_name $1024
			%if &laf_include_directories = 1 %then
			%do;
				object_type $12
			%end;
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
			fileext = find(file_name,'.');
			extension = scan(file_name, -1, '.');
			/* fid=0 means directory in most cases */
			full_file_name = STRIP(directory_path)||STRIP(file_name);
			if fid > 0 or fileext then
			do;
				if "&laf_extenstion_to_check" = "*" or	
				upcase(extension) = %upcase("&laf_extenstion_to_check") then
				do;
					%if &laf_debug_mode %then
					%do;
			        	put "INFORMATION: Found following file:" full_file_name;
					%end;
					%if &laf_include_directories = 1 %then
					%do;
						object_type = "file";
					%end;
					output;
				end;
				%if &laf_debug_mode %then
				%do;
					else
					do;
						put "INFORMATION: Skipping due to extension:" full_file_name;
					end;
				%end;
			end;
			%if &laf_traverse_directories = 1 %then
			%do;
				else
				do;
					%if &laf_debug_mode %then
					%do;
						put 'INFORMATION: Scanning next directory:' full_file_name;
					%end;
					%if &laf_include_directories = 1 %then
					%do;
						object_type = "folder";
						output;
					%end;					
					arg1 = cats('%nrstr(%list_all_files(', full_file_name, ", &laf_extenstion_to_check,");
					arg2 = cats("&laf_output_ds_file_overview,
					laf_debug_mode = &laf_debug_mode,");
					arg3 = cats("laf_directory_separator = &laf_directory_separator,
					laf_traverse_directories = &laf_traverse_directories,");
					arg3b = cats("laf_include_directories = &laf_include_directories, ");
					arg4 = cats("laf_is_sas_content_directory = &laf_is_sas_content_directory,
					laf_iteration_number = &laf_next_iteration._",i,"))");
					call execute(strip(arg1)||strip(arg2)||strip(arg3)||strip(arg3b)||strip(arg4));
 
 
				end;
			%end;
		end;
		rc = dclose(did);
	%end;
%else
	%do;
		full_file_name = STRIP(substr(directory_path, 1, length(directory_path)-1));
		%if &laf_include_directories = 1 %then
		%do;
			object_type = "file";
		%end;
 
		output;
	%end;
	run;
 
 
	%let tot_obs = 0;
	proc sql noprint;
		select nobs into :tot_obs
		from dictionary.tables
		where upcase(libname)='WORK' and upcase(memname)="_DIAP_SPCL_LIST_FILES_&laf_iteration_number";
	quit;
	%put total records = &tot_obs.;	
	%if &tot_obs = 0 %then
	%do;
		proc datasets lib= work;
			delete _DIAP_SPCL_LIST_FILES_&laf_iteration_number;
		quit;
		%if lal_append_flag = 1 %then
		%do;
			data work._DIAP_spcl_list_files_&laf_iteration_number.;
				set work._DIAP_spcl_list_files_&laf_iteration_number._inter;
			run;
			proc datasets lib= work;
				delete _DIAP_spcl_list_files_&laf_iteration_number._inter;
			quit;
		%end;
	%end; %else
	%do;
		%if lal_append_flag = 1 %then
		%do;
			data work._DIAP_spcl_list_files_&laf_iteration_number.;
				set work._DIAP_spcl_list_files_&laf_iteration_number.
					work._DIAP_spcl_list_files_&laf_iteration_number._inter;
			run;
			proc datasets lib= work;
				delete _DIAP_spcl_list_files_&laf_iteration_number._inter;
			quit;
		%end;
	%end;
	
	%if &laf_iteration_number = 0_0 %then
	%do;
		%let table_append_seq = ;
		proc sql noprint;
			select memname into :table_append_seq separated by " "
			from dictionary.tables
			where upcase(libname)='WORK' and upcase(memname)contains"_DIAP_SPCL_LIST_FILES_";
		quit;
		%if "&table_append_seq" ne "" %then
		%do;
			data work._laf_file_overview_sort;
				set &table_append_seq;
			run;
			proc sort data =work._laf_file_overview_sort;
				by full_file_name
				%if &laf_include_directories = 1 %then
				%do;
					descending object_type
				%end;				
				;
			quit;
			
			data &laf_output_ds_file_overview;
				set work._laf_file_overview_sort;
				by full_file_name;
				%if &laf_include_directories = 1 %then
				%do;
					if first.full_file_name ne last.full_file_name  then
					do;
					object_type = "file";
					end;
				%end;
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
%let delimiter = /;
%let delimiter = \;
%let include_directories = 1;
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
	laf_include_directories = &include_directories
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
called in the following way, e.g. %let x=%wordcnt(item1#item2 item2a#item3, '#').  After running
the macro x will be assigned the value of wordcnt.
______________________________________________________________________________
 
 
INPUT PARAMETERS AND KEYWORDS:
 
list            the name of the string.
delim           the delimiter e.g. '#'.
______________________________________________________________________________
 
 
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
		timestamp = trim(left(year))||trim(left(month))||trim(left(day))||"_"||trim(left(hour))||trim(left(minute));
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
 
 
 
%put 	&=debug_mode_ui	;
%put 	&=clod_traverse_directories_ui	;
%put 	&=extension_ui	;
%put 	&=root_directory_ui	;
%put    &=log_file_path_ui;
%put 	&=target_libname_ui	;
%put 	&=write_log_into_file_ui	;
%put    &=output_dataset_name_ui;
%put    &=options_seq_ui;
%let root_directory = %scan(&root_directory_ui, 2, ":");
%let root_dir_src = %upcase(%scan(&root_directory_ui, 1, ":"));
%let is_content_dir = 0;
%if %upcase("&root_dir_src") eq "SASCONTENT" %then
%do;
	%let is_content_dir = 1;
%end;
%put &=root_directory;
 
%let 	target_libname	=	&target_libname_ui	;
%let 	write_log_into_file	=	&write_log_into_file_ui	;
 
 
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
		proc casutil incaslib="&target_libname_ui" outcaslib="&target_libname_ui";
			droptable casdata = "&output_dataset_name_ui" quiet;
			droptable casdata = "&output_dataset_name_ui" quiet;
		quit;
	%end;
%end;
 
 
%let include_directories = 1;
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
	laf_include_directories = &include_directories_ui
	);
 
 
	
%if %upcase(&target_environment) = CAS %then
%do;
	%if &cas_promote_ui = 1 %then
	%do;
		proc casutil incaslib="&target_libname_ui" outcaslib="&target_libname_ui";
			promote casdata = "&output_dataset_name_ui" casout="&output_dataset_name_ui";
			%if &cas_save_on_disk_ui = 1 %then
			%do;
				save casdata= "&output_dataset_name_ui" casout="&output_dataset_name_ui" replace;
			%end;
		quit;
 
	%end;
 
%end;
 
%if &write_log_to_file = 1 %then
%do;
	proc printto ;
	quit;
%end;
 
%mend;
 
%execute_all();
 
data _null_;
	set _clod_option_setting_storage;
	call execute("option "||original_setting||";");
run;
 
option validvarname = &_clod_option_validvarname_org;

```

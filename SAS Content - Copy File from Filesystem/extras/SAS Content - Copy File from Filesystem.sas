/*-----------------------------------------------------------------------------------------*
   START MACRO DEFINITIONS.
*------------------------------------------------------------------------------------------*/

/* -----------------------------------------------------------------------------------------* 
   Error flag for capture during code execution.
*------------------------------------------------------------------------------------------ */

%global _cff_error_flag;
%let _cff_error_flag=0;


/* -----------------------------------------------------------------------------------------* 
   Global macro variable for the trigger to run this custom step. A value of 1 
   (the default) enables this custom step to run.  A value of 0 (provided by upstream code)
   sets this to disabled.
*------------------------------------------------------------------------------------------ */

%global _cff_run_trigger;

%if %sysevalf(%superq(_cff_run_trigger)=, boolean)  %then %do;

	%put NOTE: Trigger macro variable _cff_run_trigger does not exist. Creating it now.;
    %let _cff_run_trigger=1;

%end;


/* -----------------------------------------------------------------------------------------* 
   Macro to identify whether a given folder location provided from a 
   SAS Studio Custom Step folder selector happens to be a SAS Content folder
   or a folder on the filesystem (SAS Server).

   Inputs:
   1. pathReference: A path reference provided by the file or folder selector control in 
      a SAS Studio Custom step.

   Outputs:
   1. _path_identifier: Set inside macro, a global variable indicating the prefix of the 
      path provided.

*------------------------------------------------------------------------------------------ */

%macro _identify_content_or_server(pathReference);
   %global _path_identifier;
   data _null_;
      call symput("_path_identifier", scan("&pathReference.",1,":","MO"));
   run;
%mend _identify_content_or_server;


/* -----------------------------------------------------------------------------------------* 
   Macro to extract the path provided from a SAS Studio Custom Step file or folder selector.

   Inputs:
   1. pathReference: A path reference provided by the file or folder selector control in 
      a SAS Studio Custom step.

   Outputs:
   1. _sas_folder_path: Set inside macro, a global variable containing the path.

*------------------------------------------------------------------------------------------ */

%macro _extract_sas_folder_path(pathReference);
   %global _sas_folder_path;
   data _null_;
      call symput("_sas_folder_path", scan("&pathReference.",2,":","MO"));
   run;
%mend _extract_sas_folder_path;


/*-----------------------------------------------------------------------------------------*
    Macro to obtain the URI of a desired SAS Content folder if it exists.
    This macro will check a given path in SAS Content and set a macro variable to folder URI 
    if it exists, or a direction to the error code if not.
 
    Inputs:
       1. targetFolderContent: the full path of the folder to check for
 
    Outputs:
       1. targetFolderURI (global variable): set inside macro to the URI of the folder
       2. contentFolderExists (global variable): set to 0 if the folder does not exist, 1 if
         it does, and 99 in case of other conditions (such as HTTP request failure). 
         Note this is a side objective / additional objective of the current macro.

    Also available standalone at: 
    https://github.com/SundareshSankaran/sas_utility_programs/blob/main/code/Obtain%20SAS%20Content%20Folder%20URI/macro_obtain_sas_content_folder_uri.sas
*------------------------------------------------------------------------------------------*/

%macro _obtain_sas_content_folder_uri(targetFolderContent);

   %global targetFolderURI;
   %global contentFolderExists;

   /*-----------------------------------------------------------------------------------------*
     Create a JSON payload containing the folder to check for.
   *------------------------------------------------------------------------------------------*/
   %local targetPathJSON;

   data _null_;
      call symput("targetPathJSON",'{"items": ['||'"'||transtrn(strip(transtrn(&targetFolderContent.,"/","   ")),"   ",'","')||'"'||'], "contentType": "folder"}');
   run;

   filename pathData temp;
   filename outResp temp;

   data _null_;
      length inputData $32767.;
      inputData = symget("targetPathJSON");
      file pathData;
	  put inputData;
   run;

   /*-----------------------------------------------------------------------------------------*
     Call the /folders/paths endpoint to obtain the URI of the desired folder.
   *------------------------------------------------------------------------------------------*/
   %local viyaHost;
   %let viyaHost=%sysfunc(getoption(SERVICESBASEURL));

   %put NOTE: The Viya host resolves to &viyaHost.;

   proc http
	  method='POST'
	  url="&viyaHost./folders/paths"
	  in=pathData 
	oauth_bearer=sas_services
 	out=outResp;
    ;
	headers 'Content-Type'='application/vnd.sas.content.folder.path+json';
   quit;
   
   filename pathData clear;
   filename outResp clear;

   /*-----------------------------------------------------------------------------------------*
     In the event of a successful request, extract the URI
   *------------------------------------------------------------------------------------------*/

   %if "&SYS_PROCHTTP_STATUS_CODE."="200" %then %do;

      filename TEMPFNM filesrvc folderpath=&targetFolderContent.;

    /*-----------------------------------------------------------------------------------------*
      The Filename Filesrvc leads to an automatic macro variable which holds the URI.  This 
      will be assigned to the global variable.
    *------------------------------------------------------------------------------------------*/
      data _null_;
	     call symput("targetFolderURI", "&_FILESRVC_TEMPFNM_URI.");
         call symputx("contentFolderExists", 1);
      run;

      filename TEMPFNM clear;
      %symdel _FILESRVC_TEMPFNM_URI;

   %end;
   %else %do;

      data _null_;
         call symput("targetFolderURI", "Refer SYS_PROCHTTP_STATUS_CODE macro variable.");
         call symputx("_cff_error_flag",1);
      run;

      /*-----------------------------------------------------------------------------------------*
         Note that this macro also doubles up as a check for a desired folder inside 
         SAS Content.  While it's desirable to have separate code/macros for every single desired 
         operation, we are adding this additional output because it does not require significant 
         computation (beyond the code below).
      *------------------------------------------------------------------------------------------*/

      %if "&SYS_PROCHTTP_STATUS_CODE."="404" %then %do;

         %put NOTE: Folder is not found. ;
         data _null_;
            call symputx("contentFolderExists",0);
         run;

      %end;
      %else %do;

         %put ERROR: The HTTP request returned &SYS_PROCHTTP_STATUS_CODE. ;
         data _null_;
            call symputx("contentFolderExists",99);
         run;

      %end;
   %end;

%mend _obtain_sas_content_folder_uri;


/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE MACRO 
*------------------------------------------------------------------------------------------*/

%macro _cff_main_execution_code;

   %local sasFolderPath;
   %local parentFolderURI;

   /*-----------------------------------------------------------------------------------------*
      Reset values of existing global variables (targetFolderURI and contentFolderExists) to 
      zero, in case this custom step or macro had been used before.  Users may like to 
      save the values of these global variables prior to running this step.
   *------------------------------------------------------------------------------------------*/

   %if %symexist(targetFolderURI) %then %do;
      %let targetFolderURI=;
   %end;

   %if %symexist(contentFolderExists) %then %do;
      %let contentFolderExists=;
   %end;

   /*-----------------------------------------------------------------------------------------*
      Check if the folder path provided is in fact a SAS Content related path.
   *------------------------------------------------------------------------------------------*/

   %if &_cff_error_flag.=0 %then %do;
      %_identify_content_or_server(&sourceFile.);
      %if "&_path_identifier."="sasserver" %then %do;
         %put NOTE: The source file is provided from the filesystem and prefixed with &_path_identifier..;
      %end;
      %else %do;
         %let _cff_error_flag=1;
         %put ERROR: Path provided does not seem to be in the filesystem. Check your path. ;
      %end;
   %end;

   %if &_cff_error_flag.=0 %then %do;
      %_identify_content_or_server(&targetFolder.);
      %if "&_path_identifier."="sascontent" %then %do;
         %put NOTE: The path provided is prefixed with &_path_identifier. ;
      %end;
      %else %do;
         %let _cff_error_flag=1;
         %put ERROR: Path provided does not seem to be a SAS Content folder. Check your path. ;
      %end;
   %end;

   /*-----------------------------------------------------------------------------------------*
      Check if the given target folder actually exists.
   *------------------------------------------------------------------------------------------*/

   %if &_cff_error_flag. = 0 %then %do;

      %_extract_sas_folder_path(&targetFolder.);
      %let sasFolderPath=&_sas_folder_path.;
      %symdel _sas_folder_path;

      %_obtain_sas_content_folder_uri("&sasFolderPath.");

      %if &contentFolderExists.=0 %then %do;

         %put ERROR: The target folder does not exist on SAS Content. Create the folder upstream.;
         %let _cff_error_flag=1;
 
      %end;    
      %else %if &contentFolderExists.=99 %then %do;

         %put ERROR: Something went wrong during folder check. Refer SYS_PROCHTTP_STATUS_CODE macro variable as directed.;
         %let _cff_error_flag=1;
 
      %end;   

   %end;

   %if &_cff_error_flag. = 0 %then %do;
        %put NOTE: Value of error: &_cff_error_flag.;
      
      /*-----------------------------------------------------------------------------------------*
         Create a sourceFilePath variable
      *------------------------------------------------------------------------------------------*/
      %_extract_sas_folder_path(&sourceFile.);
      %let sourceFilePath=&_sas_folder_path.;
      %let _sas_folder_path=;

      /*-----------------------------------------------------------------------------------------*
         Create source file reference.  Use direct recfm=n
      *------------------------------------------------------------------------------------------*/

      filename srcfile "&sourceFilePath." recfm=n;

      /*-----------------------------------------------------------------------------------------*
         Create a targetFilePath variable.  Then extract targetFileName from sourceFilePath
         to use the same name in the filename option.
      *------------------------------------------------------------------------------------------*/
      %_extract_sas_folder_path(&targetFolder.);
      %let targetFilePath=&_sas_folder_path.;
      %let _sas_folder_path=;

      %let targetFileName=%sysfunc(substr(&sourceFilePath.,%sysfunc(index(&sourceFilePath.,%sysfunc(scan("&sourceFilePath.",-1,"/"))))));

      /*-----------------------------------------------------------------------------------------*
         Create destination file reference.  Use direct recfm=n
      *------------------------------------------------------------------------------------------*/

      filename destfile filesrvc folderpath="&targetFilePath." filename="&targetFileName." recfm=n;

      /*-----------------------------------------------------------------------------------------*
         Copy the file using the fcopy() function.
      *------------------------------------------------------------------------------------------*/
      data _null_;
         rc=fcopy("srcfile","destfile");
         msg=sysmsg();
         put rc=;
         put msg=;
         call symputx("_cff_error_flag",rc);
      run;

      %if &_cff_error_flag.=0 %then %do;
         %put NOTE: The file has been successfully copied.;
         %put NOTE: Check &targetFilePath. for &targetFileName.;
      %end;
      %else %do;
         %put ERROR: Something went wrong during file copy.  Check log for messages.;
      %end;

   %end;



%mend _cff_main_execution_code;

/*-----------------------------------------------------------------------------------------*
   END MACRO DEFINITIONS.
*------------------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE
   The execution code is controlled by the trigger variable defined in this custom step. This
   trigger variable is in an "enabled" (value of 1) state by default, but in some cases, as 
   dictated by logic, could be set to a "disabled" (value of 0) state.
*------------------------------------------------------------------------------------------*/

%if &_cff_run_trigger. = 1 %then %do;

   %_cff_main_execution_code;

%end;
%if &_cff_run_trigger. = 0 %then %do;

   %put NOTE: This step has been disabled.  Nothing to do.;

%end;


/*-----------------------------------------------------------------------------------------*
   Clean up existing declarations, macro variables and macro definitions.
*------------------------------------------------------------------------------------------*/

%if %sysfunc(fileref(srcfile)) < 1 %then %do;
   filename srcfile clear;
%end;
%if %sysfunc(fileref(destfile)) < 1 %then %do;
   filename destfile clear;
%end;

%if %symexist(_cff_error_flag) %then %do;
   %symdel _cff_error_flag;
%end;
%if %symexist(sasFolderPath) %then %do;
   %symdel sasFolderPath;
%end;
%if %symexist(_cff_run_trigger) %then %do;
   %symdel _cff_run_trigger;
%end;
%if %symexist(targetFilePath) %then %do;
   %symdel targetFilePath;
%end;
%if %symexist(targetFileName) %then %do;
   %symdel targetFileName;
%end;
%if %symexist(sourceFilePath) %then %do;
   %symdel sourceFilePath;
%end;


%sysmacdelete _identify_content_or_server;
%sysmacdelete _extract_sas_folder_path;
%sysmacdelete _obtain_sas_content_folder_uri;
%sysmacdelete _cff_main_execution_code;
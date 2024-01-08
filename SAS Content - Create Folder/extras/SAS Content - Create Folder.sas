/* templated code goes here*/;

/*-----------------------------------------------------------------------------------------*
   START MACRO DEFINITIONS.
*------------------------------------------------------------------------------------------*/

/* -----------------------------------------------------------------------------------------* 
   Error flag for capture during code execution.
*------------------------------------------------------------------------------------------ */

%global _cf_error_flag;
%let _cf_error_flag=0;


/* -----------------------------------------------------------------------------------------* 
   Global macro variable for the trigger to run this custom step. A value of 1 
   (the default) enables this custom step to run.  A value of 0 (provided by upstream code)
   sets this to disabled.
*------------------------------------------------------------------------------------------ */

%global _cf_run_trigger;

%if %sysevalf(%superq(_cf_run_trigger)=, boolean)  %then %do;

	%put NOTE: Trigger macro variable _cf_run_trigger does not exist. Creating it now.;
    %let _cf_run_trigger=1;

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
      call symput("_path_identifier", scan(&pathReference.,1,":","MO"));
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
      call symput("_sas_folder_path", scan(&pathReference.,2,":","MO"));
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
         call symputx("_cf_error_flag",1);
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
   This macro will create a desired SAS Content folder based on given parameter.
   Inputs:
      1. parentFolderURI: URI of the parent folder to the desired folder
      2. folderName: Desired name for the folder to be created

   Outputs:
      1. targetFolderURI: Global variable containing URI of the folder that gets created.
      2. folderCreated: Indicates that the folder got created (1) or not (0).

   The system macro variable  SYS_PROCHTTP_STATUS_CODE is surfaced within the log for 
   debugging.
*------------------------------------------------------------------------------------------*/

%macro _create_sas_content_folder(parentFolderURI,folderName);

   /*-----------------------------------------------------------------------------------------*
     Create a JSON payload containing the folder to check for.
   *------------------------------------------------------------------------------------------*/

   %global folderCreated;
   %global targetFolderURI;
   %local targetPathJSON;
   %local folderNameNew;
   %local viyaHost;
   %local newFolderPath;

   data _null_;
      call symput("targetPathJSON",'{"name": "'||&folderName.||'","type": "folder"}');
      call symput("folderNameNew",compress(&folderName.,'"'));
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

   %let viyaHost=%sysfunc(getoption(SERVICESBASEURL));

   %put NOTE: The Viya host resolves to &viyaHost.;

   proc http
	  method='POST'
	  url="&viyaHost./folders/folders?parentFolderUri=&parentFolderUri."
	  in=pathData 
	oauth_bearer=sas_services
	out=outResp;
    ;
	headers 'Content-Type'='application/vnd.sas.content.folder+json';
    headers 'Accept'='application/vnd.sas.content.folder+json';
   quit;

   filename pathData clear;
   filename outResp clear;
   
   %if "&SYS_PROCHTTP_STATUS_CODE."="201" %then %do;

      %put NOTE: Folder has been created.;
      %let newFolderPath=%sysfunc(scan("&parentFolder./&folderNameNew.",2,":"));

      filename TEMPFNM filesrvc folderpath="&newFolderPath.";

    /*-----------------------------------------------------------------------------------------*
      The Filename Filesrvc leads to an automatic macro variable which holds the URI.  This 
      will be assigned to the global variable.
    *------------------------------------------------------------------------------------------*/
      data _null_;
	     call symput("targetFolderURI", "&_FILESRVC_TEMPFNM_URI.");
         call symputx("folderCreated", 1);
      run;

      filename TEMPFNM clear;
      %symdel _FILESRVC_TEMPFNM_URI;

   %end;
   %else %if "&SYS_PROCHTTP_STATUS_CODE."="409" %then %do;
      
      %put ERROR: Folder already exists. Check location or name.;
      %put ERROR: The SYS_PROCHTTP_STATUS_CODE. macro variable is &SYS_PROCHTTP_STATUS_CODE.;

      data _null_;
	     call symput("targetFolderURI", " ");
         call symputx("folderCreated", 0);
         call symputx("_cf_error_flag",1);
      run;

   %end;
   %else %do;
      %put ERROR: The SYS_PROCHTTP_STATUS_CODE. macro variable is &SYS_PROCHTTP_STATUS_CODE.;
      data _null_;
	     call symput("targetFolderURI", " ");
         call symputx("folderCreated", 0);
         call symputx("_cf_error_flag",1);
      run;
   %end;

%mend _create_sas_content_folder;


/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE MACRO 
*------------------------------------------------------------------------------------------*/

%macro _cf_main_execution_code;

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

   %if %symexist(folderCreated) %then %do;
      %let folderCreated=;
   %end;

   /*-----------------------------------------------------------------------------------------*
      Check if the folder path provided is in fact a SAS Content related path.
   *------------------------------------------------------------------------------------------*/

   %_identify_content_or_server("&parentFolder.");

   %if "&_path_identifier."="sascontent" %then %do;
      %put NOTE: The path provided is prefixed with &_path_identifier. ;
   %end;
   %else %do;
      %let _cf_error_flag=1;
      %put ERROR: Path provided does not seem to be a SAS Content folder. Check your path. ;
   %end;

   %if &_cf_error_flag. = 0 %then %do;

   /*-----------------------------------------------------------------------------------------*
      Extract the folder path from the path reference provided.
   *------------------------------------------------------------------------------------------*/

      %_extract_sas_folder_path("&parentFolder.");
      %let sasFolderPath=&_sas_folder_path.;
      %symdel _sas_folder_path;

      %_obtain_sas_content_folder_uri("&sasFolderPath.");

   %end;

   %if &_cf_error_flag. = 0 %then %do;
      
      %let parentFolderURI = &targetFolderURI.;
      %_create_sas_content_folder(&parentFolderURI.,"&folderName.");
      
   %end;

%mend _cf_main_execution_code;

/*-----------------------------------------------------------------------------------------*
   END MACRO DEFINITIONS.
*------------------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE
   The execution code is controlled by the trigger variable defined in this custom step. This
   trigger variable is in an "enabled" (value of 1) state by default, but in some cases, as 
   dictated by logic, could be set to a "disabled" (value of 0) state.
*------------------------------------------------------------------------------------------*/

%if &_cf_run_trigger. = 1 %then %do;

   %_cf_main_execution_code;

%end;
%if &_cf_run_trigger. = 0 %then %do;

   %put NOTE: This step has been disabled.  Nothing to do.;

%end;


/*-----------------------------------------------------------------------------------------*
   Clean up existing macro variables and macro definitions.
*------------------------------------------------------------------------------------------*/
%if %symexist(_cf_error_flag) %then %do;
   %symdel _cf_error_flag;
%end;
%if %symexist(sasFolderPath) %then %do;
   %symdel sasFolderPath;
%end;
%if %symexist(_cf_run_trigger) %then %do;
   %symdel _cf_run_trigger;
%end;

%sysmacdelete _identify_content_or_server;
%sysmacdelete _extract_sas_folder_path;
%sysmacdelete _obtain_sas_content_folder_uri;
%sysmacdelete _create_sas_content_folder;
%sysmacdelete _cf_main_execution_code;
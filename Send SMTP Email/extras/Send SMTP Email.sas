/* SAS templated code goes here */

/* -------------------------------------------------------------------------------------------* 
   Send SMTP Email

   v 3.0.0 (06FEB2025)

   This program enables SAS Studio users to send an email message and is meant for use within  
   a SAS Studio Custom Step. Please modify requisite macro variables (hint: use the debug section 
   as a reference) to test run this through other interfaces, such as a SAS Program editor or the SAS 
    extension for Visual Studio Code.

   Mary Kathryn Queen (MaryKathryn.Queen@sas.com)  
   Sundaresh Sankaran (sundaresh.sankaran@sas.com|sundaresh.sankaran@gmail.com)
   
*-------------------------------------------------------------------------------------------- */
/*-----------------------------------------------------------------------------------------*
   DEBUG Section
   Code under the debug section SHOULD ALWAYS remain commented unless you are tinkering with  
   or testing the step!
*------------------------------------------------------------------------------------------*/

/* Provide test values for the parameters */

/* Coming soon */;

/*-----------------------------------------------------------------------------------------*
   MACROS
*------------------------------------------------------------------------------------------*/
/* -------------------------------------------------------------------------------------------* 
   Macro to initialize a run-time trigger global macro variable to run SAS Studio Custom Steps. 
   A value of 1 (the default) enables this custom step to run.  A value of 0 (provided by 
   upstream code) sets this to disabled.

   Input:
   1. triggerName: The name of the runtime trigger you wish to create. Ensure you provide a 
      unique value to this parameter since it will be declared as a global variable.

   Output:
   2. &triggerName : A global variable which takes the name provided to triggerName.
*-------------------------------------------------------------------------------------------- */

%macro _create_runtime_trigger(triggerName);

   %global &triggerName.;

   %if %sysevalf(%superq(&triggerName.)=, boolean)  %then %do;
  
      %put NOTE: Trigger macro variable &triggerName. does not exist. Creating it now.;
      %let &triggerName.=1;

   %end;

%mend _create_runtime_trigger;

/* -----------------------------------------------------------------------------------------* 
   Macro to create an error flag for capture during code execution.

   Input:
      1. errorFlagName: The name of the error flag you wish to create. Ensure you provide a 
         unique value to this parameter since it will be declared as a global variable.
      2. errorFlagDesc: A description to add to the error flag.

    Output:
      1. &errorFlagName : A global variable which takes the name provided to errorFlagName.
      2. &errorFlagDesc : A global variable which takes the name provided to errorFlagDesc.
*------------------------------------------------------------------------------------------ */

%macro _create_error_flag(errorFlagName, errorFlagDesc);

   %global &errorFlagName.;
   %let  &errorFlagName.=0;
   %global &errorFlagDesc.;

%mend _create_error_flag;

/* -----------------------------------------------------------------------------------------* 
   Macro to identify whether a given file or folder location provided from a 
   SAS Studio Custom Step folder selector happens to be a SAS Content folder
   or a folder on the filesystem (SAS Server).

   Input:
   1. pathReference: A path reference provided by the file or folder selector control in 
      a SAS Studio Custom step.

   Output:
   1. _path_identifier: Set inside macro, a global variable indicating the prefix of the 
      path provided.

   Also available at: https://raw.githubusercontent.com/SundareshSankaran/sas_utility_programs/main/code/Identify%20SAS%20Content%20or%20Server/macro_identify_sas_content_server.sas

*------------------------------------------------------------------------------------------ */

%macro _identify_content_or_server(pathReference);
   %global _path_identifier;
   data _null_;
      call symput("_path_identifier", scan("&pathReference.",1,":","MO"));
   run;
   %put NOTE: _path_identifier is &_path_identifier. ;
%mend _identify_content_or_server;


/* -----------------------------------------------------------------------------------------* 
   Macro to extract the path provided from a SAS Studio Custom Step file or folder selector.

   Input:
   1. pathReference: A path reference provided by the file or folder selector control in 
      a SAS Studio Custom step.

   Output:
   1. _sas_folder_path: Set inside macro, a global variable containing the path.

   Also available at: https://raw.githubusercontent.com/SundareshSankaran/sas_utility_programs/main/code/Extract%20SAS%20Folder%20Path/macro_extract_sas_folder_path.sas

*------------------------------------------------------------------------------------------ */

%macro _extract_sas_folder_path(pathReference);

   %global _sas_folder_path;

   data _null_;
      call symput("_sas_folder_path", scan("&pathReference.",2,":","MO"));
   run;

%mend _extract_sas_folder_path;

/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE MACRO 

   _sse prefix stands for Send SMTP Email
*------------------------------------------------------------------------------------------*/

%macro _sse_execution_code;

   /* Set email options */
   options emailsys=smtp emailhost=&smtpHost emailport=&smtpPort ;
	
%mend _sse_execution_code;



/* if emailBody_count is empty (doesnt exist) create it and create emailBody_1 */
%global emailBody_count ;
%if &emailBody_count eq %then %do ; 
	%let emailBody_count=1 ;
	%let emailBody_1=&emailBody ;
%end ;


/* Format input information if multiple email addresses entered */
data _null_ ;
    newEmailTo=cats(transtrn(strip(compbl(translate("&emailTo"," ",",")))," ",'" "')) ;
    call symput('emailTo',strip(newEmailTo)) ;
    newEmailCC=cats(transtrn(strip(compbl(translate("&emailCC"," ",",")))," ",'" "')) ;
    call symput('emailCC',strip(newEmailCC)) ;
    newEmailBCC=cats(transtrn(strip(compbl(translate("&emailBCC"," ",",")))," ",'" "')) ;
    call symput('emailBCC',strip(newEmailBCC)) ;
run ;


/* Format and send email */
filename outmail email
	from="&emailFrom"
 	to=("&emailTo")
	cc=("&emailCC")
	bcc=("&emailBCC")
	subject="&emailSubject"
 	importance="&importance" /* Low Normal High.  Default is Normal */
	/* If ReadReceipt option is checked */
	%if &readReceipt %then %do ;
		readreceipt
	%end ;
 	ct="text/html"
;


/* Build the body of the email */
data _null_ ;
	file outmail ;
	put "<html><body>" ;
    put "<p style='color: #&textColor'>" ;
	do i = 1 to &emailBody_count ;
        if symget("emailBody_" || strip(put(i,12.))) eq '' then do ;
			text=cats("<br>") ;
        end ;
        else do ;
			text=cats(symget("emailBody_" || strip(put(i,12.))),"<br>") ;
		end ;
		put text ;
	end ;
    put "</p>" ;
	put "</body></html>" ;
run ;


/* Clear macro */
%symdel emailBody_count ;
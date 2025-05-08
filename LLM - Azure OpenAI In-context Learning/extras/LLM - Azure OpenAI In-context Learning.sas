/* SAS templated code goes here */

/* -------------------------------------------------------------------------------------------* 
   LLM - Azure OpenAI In-context Learning
   
   v 1.0.0 (24MAR2025)

   This program interacts with an Azure OpenAI Large Language Model (LLM) service to process 
   instructions on specified input data and is designed to run within a SAS Studio Custom 
   Step. Please modify requisite macro variables (hint: use the debug section as a reference) 
   to run this using other interfaces, such as a SAS Program editor or the SAS Extension 
   for Visual Studio Code.

   Sundaresh Sankaran (sundaresh.sankaran@sas.com|sundaresh.sankaran@gmail.com)
   Crystal Baker (crystal.baker@sas.com)
*-------------------------------------------------------------------------------------------- */

/*-----------------------------------------------------------------------------------------*
   DEBUG Section
   Code under the debug section SHOULD ALWAYS remain commented unless you are tinkering with  
   or testing the step!
*------------------------------------------------------------------------------------------*/

/* Provide test values for the parameters */

/* cas ss;  
caslib _all_ assign;  */

/* data PUBLIC.JOBCODES; */
/*    set SAMPSIO.JOBCODES; */
/* run; */
/* data WORK.JOBCODES; */
/*    set SAMPSIO.JOBCODES; */
/* run; */

/*
data _null_;
   call symput('inputData',"%sysget(inputData)");
   call symput('__systemPrompt', "%sysget(_systemPrompt)");
   call symput('userPrompt', "%sysget(userPrompt)");
   call symput('userExample', "%sysget(userExample)");
   call symput('docId', "%sysget(docId)");
   call symput('textCol', "%sysget(textCol)");
   call symput('azureKeyLocation', "%sysget(azureKeyLocation)");
   call symput('azureOpenAIEndpoint', "%sysget(azureOpenAIEndpoint)");
   call symput('azureRegion', "%sysget(azureRegion)");
   call symput('openAIVersion', "%sysget(openAIVersion)");
   call symput('outputTable', "%sysget(outputTable)");
   call symput('genModelDeployment', "%sysget(genModelDeployment)");
   call symputx('temperature', %sysget(temperature));
run;

data _null_;
   call symput('inputData_lib', scan("&inputData", 1, "."));
   call symput('inputData_name', scan("&inputData", 2, "."));
run;

data _null_;
   call symput('outputTable_lib', scan("&outputTable", 1, "."));
   call symput('outputTable_name', scan("&outputTable", 2, "."));
run; 

*/

/*-----------------------------------------------------------------------------------------*
   END DEBUG Section
*------------------------------------------------------------------------------------------*/


/*-----------------------------------------------------------------------------------------*
   Python Block Definition
*------------------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------------*
   The following block of code has been created for the purpose of allowing proc python 
   to execute within a macro. Execution within a macro allows for other checks to be carried 
   out through SAS prior to handing off to the Python step.

   In this example, a temporary file is created containing the requisite Python commands, which 
   are then executed through infile reference.

   Note that Python code is pasted as-is and may be out of line with the SAS indentation followed.

*------------------------------------------------------------------------------------------*/

filename aiclcode temp;

data _null_;

   length line $32767;               * max SAS character size ;
   infile datalines4 truncover pad;
   input ;   
   file aiclcode;
   line = strip(_infile_);           * line without leading and trailing blanks ;
   l1 = length(trimn(_infile_));     * length of line without trailing blanks ;
   l2 = length(line);                * length of line without leading and trailing blanks ;
   first_position=l1-l2+1;           * position where the line should start (alignment) ;
   if (line eq ' ') then put @1;     * empty line ;
   else put @first_position line;    * line without leading and trailing blanks correctly aligned ;

   datalines4;
############################################################################################################
#   Obtain values from UI
############################################################################################################
input_data_ref = SAS.symget('inputData')
output_table = SAS.symget('outputTable')
input_data_lib = SAS.symget('inputData_lib')
output_table_lib = SAS.symget('outputTable_lib')
input_data_name = SAS.symget('inputData_name')
output_table_name = SAS.symget('outputTable_name')
system_prompt = SAS.symget('_systemPrompt')
text_col = SAS.symget('textCol')
doc_id = SAS.symget('docId')
user_prompt = SAS.symget('userPrompt')
user_example = SAS.symget('userExample')

# Numeric Model parameters
def convert_value(value, target_type):
    """Convert non-empty strings to a specific type, else return None."""
    return target_type(value) if value != '' else None

# Model parameters (all strings initially)
parameters = {
    "temperature": SAS.symget('temperature'),
    "max_tokens": SAS.symget('maxTokens'),
    "top_p": SAS.symget('topP'),
    "frequency_penalty": SAS.symget('frequencyPenalty'),
    "presence_penalty": SAS.symget('presencePenalty')
}

# Type mapping for conversion
type_mapping = {
    "temperature": float,
    "max_tokens": int,
    "top_p": float,
    "frequency_penalty": float,
    "presence_penalty": float
}

# Apply conversions dynamically
parameters = {k: convert_value(v, type_mapping[k]) for k, v in parameters.items()}

# Unpack into variables
temperature, max_tokens, top_p, frequency_penalty, presence_penalty = parameters.values()
deployment_name = SAS.symget('genModelDeployment')
azure_key = SAS.symget('azure_key')
azure_openai_endpoint = SAS.symget('azureOpenAIEndpoint')
azure_region = SAS.symget('azureRegion')
azure_openai_version = SAS.symget('openAIVersion')
_aicl_error_flag = SAS.symget('_aicl_error_flag')
_aicl_error_desc = SAS.symget('_aicl_error_desc')
_ip_sas_cas_flag = SAS.symget('_ip_sas_cas_flag')
_op_sas_cas_flag = SAS.symget('_op_sas_cas_flag')
inputData_caslib = SAS.symget('inputData_caslib')
outputTable_caslib = SAS.symget('outputTable_caslib')
sess_uuid = SAS.symget('_current_uuid_') 
cas_host = SAS.symget("_CASHOST_")
cas_port = SAS.symget("_CASPORT_")
cas_session_exists = int(SAS.symget("casSessionExists"))

# Check if input table is CAS or SAS table and create a dataframe accordingly
if _ip_sas_cas_flag.strip().lower() == 'cas':
   import swat 
   import os
   
   # Add certificate location to operating system list of trusted certs 
   os.environ['CAS_CLIENT_SSL_CA_LIST']=os.environ['SSLCALISTLOC']
   
   # There is an active cas session
   if cas_session_exists == 1: 
      SAS.logMessage(f'Connection exists. Session UUID is {sess_uuid}')
      conn = swat.CAS(hostname=cas_host, port=cas_port, password=os.environ['SAS_SERVICES_TOKEN'], session=sess_uuid)
      new_cas_session = 0
   else:
      SAS.logMessage("New connection made to CAS through swat")
      conn = swat.CAS(hostname=cas_host, port=cas_port, password=os.environ['SAS_SERVICES_TOKEN'])
      cas_session_exists = 1
      new_cas_session = 1
   if conn: 
         SAS.logMessage("Connection established.")
         input_data = conn.CASTable(name = input_data_name, caslib=input_data_lib).to_frame()
elif _ip_sas_cas_flag.strip().lower() == 'sas':  
   SAS.logMessage("Input table is SAS dataset")
   input_data = SAS.sd2df(dataset=input_data_ref)
else:
   SAS.symput('_aicl_error_flag', 1)
   SAS.symput('_aicl_error_desc', 'Unable to associate input table with either SAS or CAS. Check the input table provided.')


############################################################################################################
#   Functions
############################################################################################################

import os
from openai import AzureOpenAI
import pandas as pd
import copy

class SASAzureOpenAILLM():
    def __init__(self,client = None, azure_openai_endpoint = None, deployment_name= None,azure_key = None,
                 azure_openai_version = None, temperature = None, max_tokens = None, top_p = None, 
                 frequency_penalty = None, presence_penalty = None):
        self.client = client
        self.azure_openai_endpoint = azure_openai_endpoint
        self.deployment_name = deployment_name
        self.azure_key = azure_key
        self.azure_openai_version = azure_openai_version
        self.prompt = []
        self.temperature = temperature
        self.max_tokens = max_tokens
        self.top_p = top_p
        self.frequency_penalty = frequency_penalty
        self.presence_penalty = presence_penalty

    def set_client(self, azure_openai_endpoint = None, azure_key = None, azure_openai_version= None):
       if azure_openai_endpoint is None:
          try:
           azure_openai_endpoint= os.environ["AZURE_OPENAI_ENDPOINT"] 
          except KeyError:
            raise ValueError("Endpoint must be provided or set in AZURE_OPENAI_ENDPOINT environment variable")
       if azure_key is None:
            try:
                 azure_key = os.environ["AZURE_OPENAI_AZURE_KEY"]
            except KeyError:
                 raise ValueError("API key must be provided or set in AZURE_OPENAI_AZURE_KEY environment variable")
       if azure_openai_version is None:
          try:
             azure_openai_version = os.environ["AZURE_OPENAI_API_VERSION"]
          except KeyError:
             raise ValueError("API version must be provided or set in AZURE_OPENAI_API_VERSION environment variable")   
          
       self.client = AzureOpenAI(api_key = azure_key,  api_version = azure_openai_version, azure_endpoint = azure_openai_endpoint)

    
    def get_client(self):
        if self.client is None:
            raise ValueError("Client not set. Please set the client using set_client method")
        return self.client

    def set_prompt(self, system_prompt = None, user_prompt = None, example = None):
        if system_prompt == None: 
            system_prompt = "You are a helpful assistant. Using the provided context, respond with the answer only."
        if user_prompt == None:
            user_prompt = "Echo the context."
        if example is None:
             self.prompt = [
             {
                 "role": "system",
                 "content": system_prompt
             },
             {
                 "role": "user",
                 "content": f"{user_prompt}\n" 
             }
             ]
        else:
             self.prompt = [
             {
                 "role": "system",
                 "content": system_prompt
             },
             {
                 "role": "user",
                 "content": f"{user_prompt}\nExample(s): {example}\n"
             }
             ]
    
    def get_prompt(self):
        return "".join((self.prompt[0]["content"], self.prompt[1]["content"]))
    
    def get_response(self, context = None, client = None, deployment_name = None, prompt = None,
                 system_prompt = None, user_prompt = None, example = None,temperature=None,
                 max_tokens=None, top_p=None, frequency_penalty=None, presence_penalty=None):  
        # Generate new base prompt
        self.set_prompt(system_prompt, user_prompt, example)
        
        # Assign llm parameters
        client = client if client is not None else self.client
        deployment_name = deployment_name if deployment_name is not None else self.deployment_name
        prompt = prompt if prompt is not None else self.prompt
        temperature = temperature if temperature is not None else self.temperature
        max_tokens = max_tokens if max_tokens is not None else self.max_tokens
        top_p = top_p if top_p is not None else self.top_p
        frequency_penalty = frequency_penalty if frequency_penalty is not None else self.frequency_penalty
        presence_penalty = presence_penalty if presence_penalty is not None else self.presence_penalty

        # Append context if available
        if context is None or len(context) == 0:
            print("No context provided")
            return ""
        else: 
            prompt[1]["content"] = prompt[1]["content"] + f"Context: {context}"
            completion = client.chat.completions.create(
                model = deployment_name,
                messages = prompt,
                temperature = temperature,
                max_tokens = max_tokens,
                top_p = top_p,
                frequency_penalty = frequency_penalty,
                presence_penalty = presence_penalty
            )
        return completion.choices[0].message.content
        
def execute(azure_openai_endpoint=None, azure_key=None, azure_openai_version=None, system_prompt=None, user_prompt=None, example=None, input_data=None, deployment_name = None, text_col=None,
            temperature = None, max_tokens = None, top_p = None, frequency_penalty = None, presence_penalty = None): 
   model = SASAzureOpenAILLM(temperature=temperature, max_tokens=max_tokens, top_p=top_p, frequency_penalty=frequency_penalty, presence_penalty=presence_penalty)
   model.set_client(azure_openai_endpoint, azure_key, azure_openai_version)
   input_data["response"] = input_data[text_col].apply(model.get_response, deployment_name=deployment_name, system_prompt=system_prompt, user_prompt=user_prompt, example=example) 
   return input_data

output_df = execute(azure_openai_endpoint=azure_openai_endpoint,azure_key = azure_key, azure_openai_version=azure_openai_version, system_prompt=system_prompt, 
                 user_prompt = user_prompt, example=user_example,input_data=input_data, deployment_name = deployment_name, text_col = text_col,
                 temperature=temperature, max_tokens=max_tokens, top_p=top_p, frequency_penalty=frequency_penalty, presence_penalty=presence_penalty)
   

# Check if output table is CAS
if _op_sas_cas_flag.strip().lower() == 'cas':
   import swat 
   import os
   SAS.logMessage("Output table specified as CAS")
   
   # Add certificate location to operating system list of trusted certs 
   os.environ['CAS_CLIENT_SSL_CA_LIST']=os.environ['SSLCALISTLOC']
   
   # There is an active cas session
   if cas_session_exists == 1: 
      if sess_uuid:
         SAS.logMessage(f'Connection exists. Session UUID is {sess_uuid}')
         conn = swat.CAS(hostname=cas_host, port=cas_port, password=os.environ['SAS_SERVICES_TOKEN'], session=sess_uuid)
      elif conn:
         SAS.logMessage(f'Connection exists.')
   else:
      SAS.logMessage("New connection made to CAS through swat")
      conn = swat.CAS(hostname=cas_host, port=cas_port, password=os.environ['SAS_SERVICES_TOKEN'])
      cas_session_exists = 1
      new_cas_session = 1
   if conn: 
         conn.upload_frame(output_df, casout = {'name':output_table_name, 
                                          'caslib':outputTable_caslib, 
                                          'replace':True})
         if new_cas_session == 1:
            SAS.logMessage("Persisting file prior to closing connection.")
            r = conn.table.tableExists(name=output_table_name,caslib=outputTable_caslib)
            if r.exists==2:
               conn.table.droptable(name=output_table_name,caslib=outputTable_caslib)
               sdfVarSaved = conn.table.save(conn.CASTable(name=output_table_name,caslib=outputTable_caslib), name =output_table_name, caslib=outputTable_caslib, replace = True)
            else:
               sdfVarSaved = conn.table.save(conn.CASTable(name=output_table_name,caslib=outputTable_caslib), name =output_table_name, caslib=outputTable_caslib, replace = True)
            SAS.logMessage("Terminating the connection.")
            conn.session.endsession()
elif _op_sas_cas_flag.strip().lower() == 'sas':  
   output_data = SAS.df2sd(output_df, output_table)
else:
   SAS.symput('_aicl_error_flag', 1)
   SAS.symput('_aicl_error_desc', 'Unable to associate output table with either SAS or CAS. Check the output table provided.')
   
;;;;
run;   

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

/*-----------------------------------------------------------------------------------------*
   Macro to capture indicator and UUIDof any currently active CAS session.
   UUID is not expensive and can be used in future to consider graceful reconnect.

   Input:
   1. errorFlagName: name of an error flag that gets populated in case the connection is 
                     not active. Provide this value in quotes when executing the macro.
                     Define this as a global macro variable in order to use downstream.
   2. errorFlagDesc: Name of a macro variable which can hold a descriptive message output
                     from the check.
                     
   Output:
   1. Informational note as required. We explicitly don't provide an error note since 
      there is an easy recourse(of being able to connect to CAS)
   2. UUID of the session: macro variable which gets created if a session exists.
   3. errorFlagName: populated
   4. errorFlagDesc: populated
*------------------------------------------------------------------------------------------*/

%macro _env_cas_checkSession(errorFlagName, errorFlagDesc);
    %global casSessionExists;
    %let casSessionExists= 0;
    %put NOTE: Checking for an active CAS session. ;
    %if %sysfunc(symexist(_current_uuid_)) %then %do;
       %symdel _current_uuid_;
    %end;
    %if %sysfunc(symexist(_SESSREF_)) %then %do;
      %let casSessionExists= %sysfunc(sessfound(&_SESSREF_.));
      %put NOTE: CAS Session indicator - &casSessionExists. ;
      %if &casSessionExists.=1 %then %do;
         %global _current_uuid_;
         %let _current_uuid_=;   
         proc cas;
            session.sessionId result = sessresults;
            call symputx("_current_uuid_", sessresults[1]);
         quit;
         %put NOTE: A CAS session &_SESSREF_. is currently active with UUID &_current_uuid_. ;
         data _null_;
            call symputx("&errorFlagName.", 0);
            call symput("&errorFlagDesc.", "CAS session is active.");
         run;
      %end;
      %else %do;
         %put NOTE: Unable to find a currently active CAS session. Reconnect or connect to a CAS session upstream. ;
         data _null_;
            call symputx("&errorFlagName.", 0);
            call symput("&errorFlagDesc.", "Unable to find a currently active CAS session. Reconnect or connect to a CAS session upstream.");
        run;
      %end;
   %end;
   %else %do;
      %put NOTE: No active CAS session ;
      data _null_;
        call symputx("&errorFlagName.", 0);
        call symput("&errorFlagDesc.", "No active CAS session. Connect to a CAS session upstream.");
      run;
   %end;

%mend _env_cas_checkSession;  

/*-----------------------------------------------------------------------------------------*
   Caslib for a Libname macro
   
   This macro creates a global macro variable called _usr_nameCaslib
   that contains the caslib name (aka. caslib-reference-name) associated with the libname
   and assumes that the libname is using the CAS engine.
 
   As sysvalue has a length of 1024 chars, we use the trimmed option in proc sql
   to remove leading and trailing blanks in the caslib name.
   
   From macro provided by Wilbram Hazejager (wilbram.hazejager@sas.com)

   Inputs:
   - _usr_LibrefUsingCasEngine : A library reference provided by the user which is based 
                                 on a CAS engine.
   
   Outputs:
   - _usr_nameCaslib : Global macro variable containing the caslib name.
*------------------------------------------------------------------------------------------*/
 
%macro _usr_getNameCaslib(_usr_LibrefUsingCasEngine);
 
   %global _usr_nameCaslib;
   %let _usr_nameCaslib=;
 
   proc sql noprint;
      select sysvalue into :_usr_nameCaslib trimmed from dictionary.libnames
      where libname = upcase("&_usr_LibrefUsingCasEngine.") and upcase(sysname)="CASLIB";
   quit;

   /*--------------------------------------------------------------------------------------*
      Note that we output a NOTE instead of an ERROR for the below condition since the 
      execution context determines whether this is an error or just an informational note.
   *---------------------------------------------------------------------------------------*/
   %if "&_usr_nameCaslib." = "" %then %put NOTE: The caslib name for the &_usr_LibrefUsingCasEngine. is blank.;
 
%mend _usr_getNameCaslib;


/*-----------------------------------------------------------------------------------------*
   Macro to check if a given libref belongs to a SAS or CAS engine.

   Input:
   1. sasCasLibref: a libref to be checked. Do not quote.
   2. tableEngine: a flag to hold the table Engine value.
   3. errorFlagName: a flag to populate an error code with.
   4. errorFlagDesc: a flag to describe the error if one occurs.
   5. sessionExists: an indicator (1) whether an active CAS session exists.  If not(0),
                     it will be created.
                     
   Output:
   1. tableEngine: populated with SAS or CAS
   2. errorFlagName: populated with 1 if an error and 0 if not
   3. errorFlagDesc: populated in case of an error
*------------------------------------------------------------------------------------------*/

%macro _sas_or_cas(sasCasLibref, tableEngine, errorFlagName, errorFlagDesc, sessionExists);

   %if &sessionExists. = 0 %then %do;
      cas _temp_ss_ ;
      caslib _ALL_ assign;
   %end;

    proc sql noprint;
        select distinct Engine into:&&tableEngine. from dictionary.libnames where libname = upcase("&sasCasLibref.");
    quit;

    %put "&&&tableEngine.";

    %if %sysfunc(compress("&&&tableEngine.")) = "V9" %THEN %DO;
        data _null_;
            call symput("&tableEngine.","SAS");
            call symputx("&errorFlagName.",0);
            call symput("&errorFlagDesc.","");
        run;
    %end;
    %else %if %sysfunc(compress("&&&tableEngine.")) = "CAS" %THEN %DO;
        data _null_;
            call symputx("&errorFlagName.",0);
            call symput("&errorFlagDesc.","");
        run;
    %END;
    %else %do;
        data _null_;
            call symputx("&errorFlagName.",1);
            call symput("&errorFlagDesc.","Unable to associate libref with either SAS or CAS. Check the input libref provided.");
        run;
    %end;

   %if &sessionExists. = 0 %then %do;
      cas _temp_ss_ terminate;
   %end;
    
%mend _sas_or_cas;

/* -----------------------------------------------------------------------------------------* 
   Macro to identify whether a given folder location provided from a 
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

   _aicl prefix stands for Azure In-context Learning
*------------------------------------------------------------------------------------------*/
%macro _aicl_execution_code;

   %_create_error_flag(_aicl_error_flag, _aicl_error_desc);

/*-----------------------------------------------------------------------------------------*
    Check for a CAS session
*------------------------------------------------------------------------------------------*/
   %if &_aicl_error_flag. = 0 %then %do;
      %_env_cas_checkSession(_aicl_error_flag, _aicl_error_desc);
      %put NOTE: CAS session flag shows &casSessionExists. ;
   %end;

/*-----------------------------------------------------------------------------------------*
    Check for Input table engine name.
*------------------------------------------------------------------------------------------*/
   %if &_aicl_error_flag. = 0 %then %do;
      %let _ip_sas_cas_flag=;
      %_sas_or_cas(&inputData_lib., _ip_sas_cas_flag, _aicl_error_flag, _aicl_error_desc, &casSessionExists.)
      %put NOTE: Input Table Engine - &_ip_sas_cas_flag. ;
   %end;

/*-----------------------------------------------------------------------------------------*
    If Input table is in CAS, obtain the caslib name.
*------------------------------------------------------------------------------------------*/
   %if &_aicl_error_flag. = 0 %then %do;
      %if %sysfunc(compress("&_ip_sas_cas_flag.")) = "CAS" %then %do;
         %if &casSessionExists.=1 %then %do;
            %_usr_getNameCaslib(&inputData_lib.);
         %end;
         %else %do;
            cas _temp_ss_session_;
            caslib _ALL_ assign;
            %_usr_getNameCaslib(&inputData_lib.);
            cas _temp_ss_session_ terminate;
         %end;

         %put NOTE: CASLIB name for &_ip_sas_cas_flag. - &_usr_nameCaslib. ;
         %let inputData_caslib = &_usr_nameCaslib.;
         %let _usr_nameCaslib =;
      %end;
   %end;

/*-----------------------------------------------------------------------------------------*
    Check for Output table engine name.
*------------------------------------------------------------------------------------------*/
   %if &_aicl_error_flag. = 0 %then %do;
      %let _op_sas_cas_flag=;
      %_sas_or_cas(&outputTable_lib., _op_sas_cas_flag, _aicl_error_flag, _aicl_error_desc, &casSessionExists.)
      %put NOTE: Output Table Engine - &_op_sas_cas_flag. ;
   %end;

/*-----------------------------------------------------------------------------------------*
    If Output table is in CAS, obtain the caslib name.
*------------------------------------------------------------------------------------------*/
   %if &_aicl_error_flag. = 0 %then %do;
      %if %sysfunc(compress("&_op_sas_cas_flag.")) = "CAS" %then %do;
         %if &casSessionExists.=1 %then %do;
            %_usr_getNameCaslib(&outputTable_lib.);
         %end;
         %else %do;
            cas _temp_ss_session_;
            caslib _ALL_ assign;
            %_usr_getNameCaslib(&outputTable_lib.);
            cas _temp_ss_session_ terminate;
         %end;
         
         %put NOTE: CASLIB name for &_op_sas_cas_flag. - &_usr_nameCaslib. ;
         %let outputTable_caslib = &_usr_nameCaslib.;
         %let _usr_nameCaslib =;
      %end;
   %end;

/*-----------------------------------------------------------------------------------------*
   Check if path for Azure Key Location  happens to be a filesystem (SAS Server) path. 
*------------------------------------------------------------------------------------------*/
   %if &_aicl_error_flag. = 0 %then %do;

      %_identify_content_or_server(&azureKeyLocation.);

      %if "&_path_identifier."="sasserver" %then %do;
         %put NOTE: Folder location prefixed with &_path_identifier. is on the SAS Server.;
      %end;

      %else %do;

         %let _aicl_error_flag=1;
         %put ERROR: Please select a valid file on the SAS Server (filesystem) containing your Azure OpenAI key.  Key should be in a secure location within filesystem. ;
         data _null_;
            call symputx("_aicl_error_desc", "Please select a valid file on the SAS Server (filesystem) containing your Azure OpenAI key.  Key should be in a secure location within filesystem.");
         run;
      
      %end;

   %end;

   %if &_aicl_error_flag. = 0 %then %do;

      %_extract_sas_folder_path(&azureKeyLocation.);

      %if "&_sas_folder_path." = "" %then %do;

         %let _aicl_error_flag = 1;
         %let _aicl_error_desc = The answer bank provided is empty, please select a valid path  ;
         %put ERROR: &_aor_error_desc. ;

      %end;

   %end;

   %if &_aicl_error_flag. = 0 %then %do;

      %let _key_location = ;
      %let _key_location = &_sas_folder_path.;
      %let _sas_folder_path=;

   %end;

   %if &_aicl_error_flag. = 0 %then %do;

      data _null_;
         infile "&_key_location." lrecl=1000;
         input @;
         call symput("azure_key",_INFILE_);
      run;
 
   %end;

/*-----------------------------------------------------------------------------------------*
    Proceed for Python call
*------------------------------------------------------------------------------------------*/
   %if &_aicl_error_flag. = 0 %then %do;

      proc python infile=aiclcode;
      run;

   %end;



%mend _aicl_execution_code;

/*-----------------------------------------------------------------------------------------*
   END MACROS
*------------------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE
*------------------------------------------------------------------------------------------*/
   
/*-----------------------------------------------------------------------------------------*
   Create Runtime Trigger
*------------------------------------------------------------------------------------------*/
%_create_runtime_trigger(_aicl_run_trigger);

/*-----------------------------------------------------------------------------------------*
   Execute 
*------------------------------------------------------------------------------------------*/

%if &_aicl_run_trigger. = 1 %then %do;

   %_aicl_execution_code;

%end;

%if &_aicl_run_trigger. = 0 %then %do;

   %put NOTE: This step has been disabled.  Nothing to do.;

%end;


%put NOTE: Final summary;
%put NOTE: Status of error flag - &_aicl_error_flag. ;
%put &_aicl_error_desc.;
%put NOTE: Error desc - &_aicl_error_desc. ;

/*-----------------------------------------------------------------------------------------*
   END EXECUTION CODE
*------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------*
   Clean up existing macro variables and macro definitions.
*------------------------------------------------------------------------------------------*/

%if %symexist(_aicl_run_trigger) %then %do;
   %symdel _aicl_run_trigger;
%end;
%if %symexist(_aicl_error_flag) %then %do;
   %symdel _aicl_error_flag;
%end;
%if %symexist(_aicl_error_desc) %then %do;
   %symdel _aicl_error_desc;
%end;
%if %symexist(casSessionExists) %then %do;
   %symdel casSessionExists;
%end;
%if %symexist(_current_uuid_) %then %do;
   %symdel _current_uuid_;
%end;

%sysmacdelete _create_runtime_trigger;
%sysmacdelete _create_error_flag;
%sysmacdelete _env_cas_checkSession;
%sysmacdelete _usr_getNameCaslib;
%sysmacdelete _identify_content_or_server;
%sysmacdelete _extract_sas_folder_path;
%sysmacdelete _sas_or_cas;
%sysmacdelete _aicl_execution_code;

/*-----------------------------------------------------------------------------------------*
   DEBUG Section
   Code under the debug section SHOULD ALWAYS remain commented unless you are tinkering with  
   or testing the step!
*------------------------------------------------------------------------------------------*/
/*
cas ss terminate;;
*/;
/*-----------------------------------------------------------------------------------------*
   END DEBUG Section
*------------------------------------------------------------------------------------------*/

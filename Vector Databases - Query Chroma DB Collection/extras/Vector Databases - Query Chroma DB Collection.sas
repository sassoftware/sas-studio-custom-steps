/* templated code goes here*/;

/* -----------------------------------------------------------------------------------------* 
   Vector Databases - Query Chroma DB Collection

   Version: 1.0 (30JAN2024)
   Created: Sundaresh Sankaran(sundaresh.sankaran@sas.com)
    
*------------------------------------------------------------------------------------------ */

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
filename qcdcode temp;

data _null_;

   infile datalines4 truncover pad;
   input ;   
   file qcdcode;
   put @1 _infile_;
   datalines4;

#############################################################################################
#
#  Obtain values from UI or other SAS macro variables
#
#############################################################################################

cas_host_path       = SAS.symget("casHostPath")
cas_host_port       = SAS.symget("casHostPort")
persistent_path     = SAS.symget("persistentPath")

sessuuid            = SAS.symget("_current_uuid_")
embedded_table_name = "_tmp_"+SAS.symget("outputTable_name_base")
embedded_table_lib  = SAS.symget("outputCaslib")
query_column        = SAS.symget("queryColumn")

output_table_name   = SAS.symget("outputTable_name_base")
output_table_lib    = SAS.symget("outputCaslib")
input_table_name    = SAS.symget("inputTable_name_base")
input_table_lib     = SAS.symget("inputCaslib")

collection_name     = SAS.symget("collectionName")
embedding_pattern   = SAS.symget("embeddingPattern")
number_of_results   = int(SAS.symget("numberOfResults"))
promote_table       = int(SAS.symget("promoteTable"))
promote_flag        = True if promote_table == 1 else False
replace_flag        = False if promote_flag else True


#############################################################################################
#
#  The pysqlite3 import allows for the code to also run in (some) older Python (or sqlite) versions.
#
#############################################################################################

__import__('pysqlite3')
import sys
sys.modules['sqlite3'] = sys.modules.pop('pysqlite3')

#############################################################################################
#
#  Refer https://docs.trychroma.com/telemetry for details.  Recommend to opt out of anonymized 
#  unless you can confidently configure permissions on the Python build location (admin-level).
#
#############################################################################################

os.environ['ANONYMIZED_TELEMETRY'] = "False"

#############################################################################################
#
#  Connect to CAS through the swat package
#
#############################################################################################

import os
import swat

os.environ['CAS_CLIENT_SSL_CA_LIST']=os.environ['SSLCALISTLOC']
SAS.logMessage("Session UUID is {}".format(sessuuid))   

conn = swat.CAS(hostname=cas_host_path,port=cas_host_port, password=os.environ['SAS_SERVICES_TOKEN'],session=sessuuid)
SAS.logMessage("Connection to CAS suceeded.")   


#############################################################################################
#
#  Import chromadb
#
#############################################################################################

import chromadb


#############################################################################################
#
#  Connect to a Chroma server (refer About for notes about this delineation)
#
#############################################################################################

chroma_client = chromadb.PersistentClient(path=persistent_path)

SAS.logMessage("Chroma client alive at: {}".format(chroma_client.heartbeat()))

collection = chroma_client.get_collection(name=collection_name)

SAS.logMessage("Collection: {} documents at present".format(collection.count()))

#############################################################################################
#
#  Refer to the table containing embeddings and create a list of embeddings
#
#############################################################################################

import pandas

tbl=conn.CASTable(name=embedded_table_name,caslib=embedded_table_lib)

df = pandas.DataFrame()
df['Embeddings'] = (
    tbl.to_frame().filter(like=embedding_pattern)
      .apply(lambda row: row.dropna().tolist(), axis=1)
)

embedding_list = df['Embeddings'].tolist()

#############################################################################################
#
#  Query the collection passing embeddings as an argument
#
#############################################################################################

results = collection.query(
    query_embeddings=embedding_list,
    n_results=number_of_results)

results["Query_Text"] = [[query for i in range(0,number_of_results)] for query in tbl[query_column]]


#############################################################################################
#
#  Create a dataframe from the results
#
#############################################################################################

res_df = pandas.DataFrame({"Query_Text":[q for t in results["Query_Text"] for q in t],"ids":[i for d in results["ids"] for i in d], "distances":[d for s in results["distances"] for d in s], "documents":[doc for ment in results["documents"] for doc in ment]})

#############################################################################################
#
#  Load to a CAS table and promote as per user specification
#
#############################################################################################

if promote_flag:
   table_exists_flag = conn.CASTable(name=output_table_name, caslib=output_table_lib).exists()
   if table_exists_flag:
      try:
         tmp_copy = conn.CASTable(name=output_table_name, caslib=output_table_lib).copyTable(casout={"name":output_table_name+"_tmp", "caslib":output_table_lib, "replace":True})
         conn.CASTable(name=output_table_name, caslib=output_table_lib).dropTable()
      except Exception as e:
         SAS.logMessages(e,"ERROR")
cas_table = conn.CASTable(name=output_table_name, caslib=output_table_lib, replace=replace_flag, promote=promote_flag)
cas_table.from_dict(data=res_df, connection=conn, casout=cas_table)
conn.CASTable(name=embedded_table_name,caslib=embedded_table_lib).dropTable()

SAS.logMessage("Table loaded with results from query")

;;;;
   

run;

/*-----------------------------------------------------------------------------------------*
   START MACRO DEFINITIONS.
*------------------------------------------------------------------------------------------*/

/* -----------------------------------------------------------------------------------------* 
   Macro to create an error flag for capture during code execution.

   Input:
      1. errorFlagName: The name of the error flag you wish to create. Ensure you provide a 
         unique value to this parameter since it will be declared as a global variable.

    Output:
      2. &errorFlagName : A global variable which takes the name provided to errorFlagName.

   Also available at: 
   https://github.com/SundareshSankaran/sas_utility_programs/blob/main/code/Error%20Flag%20Creation/macro_create_error_flag.sas
*------------------------------------------------------------------------------------------ */


%macro _create_error_flag(errorFlagName);

   %global &errorFlagName.;
   %let  &errorFlagName.=0;

%mend _create_error_flag;



/* -------------------------------------------------------------------------------------------* 
   Macro to initialize a run-time trigger global macro variable to run SAS Studio Custom Steps. 
   A value of 1 (the default) enables this custom step to run.  A value of 0 (provided by 
   upstream code) sets this to disabled.

   Input:
   1. triggerName: The name of the runtime trigger you wish to create. Ensure you provide a 
      unique value to this parameter since it will be declared as a global variable.

   Output:
   2. &triggerName : A global variable which takes the name provided to triggerName.
   
   Also available at:
   https://github.com/SundareshSankaran/sas_utility_programs/blob/main/code/Create_Run_Time_Trigger/macro_create_runtime_trigger.sas
*-------------------------------------------------------------------------------------------- */

%macro _create_runtime_trigger(triggerName);

   %global &triggerName.;

   %if %sysevalf(%superq(&triggerName.)=, boolean)  %then %do;
  
      %put NOTE: Trigger macro variable &triggerName. does not exist. Creating it now.;
      %let &triggerName.=1;

   %end;

%mend _create_runtime_trigger;


/*-----------------------------------------------------------------------------------------*
   Macro variable to capture indicator of a currently active CAS session
*------------------------------------------------------------------------------------------*/

%global casSessionExists;
%global _current_uuid_;


/*-----------------------------------------------------------------------------------------*
   Macro to capture indicator and UUIDof any currently active CAS session.
   UUID is not expensive and can be used in future to consider graceful reconnect.

   Input:
   1. errorFlagName: name of an error flag that gets populated in case the connection is 
                     not active. Provide this value in quotes when executing the macro.
                     Define this as a global macro variable in order to use downstream.
   
   Output:
   1. Informational note as required. We explicitly don't provide an error note since 
      there is an easy recourse(of being able to connect to CAS)
   2. UUID of the session: macro variable which gets created if a session exists.

   Also available at: https://raw.githubusercontent.com/SundareshSankaran/sas_utility_programs/main/code/Check_For_Python/macro_python_check.sas
*------------------------------------------------------------------------------------------*/

%macro _env_cas_checkSession(errorFlagName);
    %if %sysfunc(symexist(_current_uuid_)) %then %do;
       %symdel _current_uuid_;
    %end;
    %if %sysfunc(symexist(_SESSREF_)) %then %do;
      %let casSessionExists= %sysfunc(sessfound(&_SESSREF_.));
      %if &casSessionExists.=1 %then %do;
         %global _current_uuid_;
         %let _current_uuid_=;   
         proc cas;
            session.sessionId result = sessresults;
            call symputx("_current_uuid_", sessresults[1]);
         quit;
         %put NOTE: A CAS session &_SESSREF_. is currently active with UUID &_current_uuid_. ;
      %end;
      %else %do;
         %put NOTE: Unable to find a currently active CAS session ;
         data _null_;
            call symputx(&errorFlagName., 1);
        run;
      %end;
   %end;
   %else %do;
      %put NOTE: No active CAS session ;
      data _null_;
        call symputx(&errorFlagName., 1);
      run;
   %end;
%mend _env_cas_checkSession;


/*-----------------------------------------------------------------------------------------*
   This macro creates a global macro variable called _usr_nameCaslib
   that contains the caslib name (aka. caslib-reference-name) associated with the libname 
   and assumes that the libname is using the CAS engine.

   As sysvalue has a length of 1024 chars, we use the trimmed option in proc sql
   to remove leading and trailing blanks in the caslib name.
   From macro provided by Wilbram Hazejager
*------------------------------------------------------------------------------------------*/

%macro _usr_getNameCaslib(_usr_LibrefUsingCasEngine); 

   %global _usr_nameCaslib;
   %let _usr_nameCaslib=;

   proc sql noprint;
      select sysvalue into :_usr_nameCaslib trimmed from dictionary.libnames
      where libname = upcase("&_usr_LibrefUsingCasEngine.") and upcase(sysname)="CASLIB";
   quit;

%mend _usr_getNameCaslib;

/* -------------------------------------------------------------------------------------------* 
    Macro to check whether compute session where this program runs is aware of a path to Python.
    Identification done through the PROC_PYPATH environment variable. If Python is found, a macro 
    variable is created with the path.  If not, an error message is output and an error flag 
    specified by user is flagged with a 1 (to indicate an error).  Flag can be used in downstream
    code if specified as a global variable.

	This macro will be updated with a more robust check for Python environments in future.

    Input:
    1. errorFlagName: Provide this with quotes when executing the macro. Name of an error flag macro 
                      variable. Specify this variable as global so that it can be used downstream.
    Output:
    1. PROC_PYPATH : A global variable which contains the path where Python can be found.
    2. Informational or error message as applicable written to log.
    3. errorFlagName macro variable modified if necessary.
    
    Also available at: https://raw.githubusercontent.com/SundareshSankaran/sas_utility_programs/main/code/Check_For_Python/macro_python_check.sas
 *-------------------------------------------------------------------------------------------- */

 %macro _env_check_python(errorFlagName);

     %global PROC_PYPATH;

     data _null_;
        proc_pypath = sysget('PROC_PYPATH');
        if proc_pypath = "" then do;
           call symputx(&errorFlagName.,1);
        end;
        else do;
           call symput("PROC_PYPATH", proc_pypath);
        end;
     run;

     %if "&PROC_PYPATH." = "" %then %do;
           %put ERROR: Python is not available or configured in this compute session ;
     %end;
     %else %do;
           %put NOTE: Python is available in this compute session;
     %end;

  %mend _env_check_python;

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
*------------------------------------------------------------------------------------------*/

%macro _qcd_main_execution_code;

/*-----------------------------------------------------------------------------------------*
   Create an error flag. 
*------------------------------------------------------------------------------------------*/

   %_create_error_flag(_qcd_error_flag);


/*-----------------------------------------------------------------------------------------*
   Check if Python's available in the environment. 
*------------------------------------------------------------------------------------------*/

   %_env_check_python("_qcd_error_flag");

/*-----------------------------------------------------------------------------------------*
   Check if an active CAS session exists. 
*------------------------------------------------------------------------------------------*/

   %global casSessionExists;

   %if &_qcd_error_flag.=0 %then %do;
      %_env_cas_checkSession("_qcd_error_flag");
   %end;

/*-----------------------------------------------------------------------------------------*
   Check Input table libref to ensure it points to a valid caslib.
*------------------------------------------------------------------------------------------*/

   %if &_qcd_error_flag. = 0 %then %do;

      %global inputCaslib;
   
      %_usr_getNameCaslib(&inputTable_lib.);
      %let inputCaslib=&_usr_nameCaslib.;
      %put NOTE: &inputCaslib. is the caslib for the input table.;
      %let _usr_nameCaslib=;

      %if "&inputCaslib." = "" %then %do;
         %put ERROR: Library selected for input table needs to point to a caslib. ;
         %let _qcd_error_flag=1;
      %end;

   %end;

/*-----------------------------------------------------------------------------------------*
   Check Output table libref to ensure it points to a valid caslib.
*------------------------------------------------------------------------------------------*/

   %if &_qcd_error_flag. = 0 %then %do;

      %global outputCaslib;
   
      %_usr_getNameCaslib(&outputTable_lib.);
      %let outputCaslib=&_usr_nameCaslib.;
      %put NOTE: &outputCaslib. is the caslib for the output table.;
      %let _usr_nameCaslib=;

      %if "&outputCaslib." = "" %then %do;
         %put ERROR: Library selected for output table needs to point to a caslib. ;
         %let _qcd_error_flag=1;
      %end;

   %end;



/*-----------------------------------------------------------------------------------------*
   Check if path provided happens to be a filesystem (SAS Server) or SAS Content path. 
   Prior to that, check if a path has in fact been provided.
*------------------------------------------------------------------------------------------*/

   %if &_qcd_error_flag. = 0 %then %do;

      %if "&persistentPathName."="" %then %do;
            %let _qcd_error_flag=1;
            %put ERROR: Please provide a valid path for the collection.  In order to query the collection, you need to know where it is located. ;
      %end;
      %else %do;
         %_identify_content_or_server(&persistentPathName.);
         %if "&_path_identifier."="sasserver" %then %do;
            %put NOTE: Folder location prefixed with &_path_identifier. is on the SAS Server.;
         %end;
         %else %do;
            %let _qcd_error_flag=1;
            %put ERROR: Please select a valid folder on the SAS Server where the database resides. ;
         %end;
      %end;

   %end;

/*-----------------------------------------------------------------------------------------*
   Extract path from the UI macro variable provided.
*------------------------------------------------------------------------------------------*/
   %if &_qcd_error_flag. = 0 %then %do;
      %_extract_sas_folder_path(&persistentPathName.);
      %let persistentPath = &_sas_folder_path.;
      %let _sas_folder_path=;
   %end;

/*-----------------------------------------------------------------------------------------*
   Generate embeddings for the query text with the specified model
*------------------------------------------------------------------------------------------*/
   %if &_qcd_error_flag. = 0 %then %do;

      proc cas;

         astore_table_lib  = symget("astoreTable_lib");
         astore_table_name = symget("astoreTable_name");
         input_table_lib   = symget("inputTable_lib");
         input_table_name  = symget("inputTable_name_base"); 
         output_table_lib  = symget("outputTable_lib");
         output_table_name = symget("outputTable_name_base"); 
         query_variable    = symget("queryColumn");


         loadactionset "astore";
      	 astore.describe result=astore_results /
            rstore={caslib=astore_table_lib, name=astore_table_name}
         ;

         text_var= astore_results['InputVariables'][1]['Name'];

         table.copyTable /
            table  = {name = input_table_name, caslib = input_table_lib},
            casout = {name ="_tmp_"||input_table_name, caslib=output_table_lib, replace=True}
         ;

         table.alterTable /
            caslib = output_table_lib,
            name   = "_tmp_"||input_table_name,
            columns= {{name=query_variable, rename=text_var}}
         ;

	     astore.score /
            table={caslib=output_table_lib, name="_tmp_"||input_table_name},
            rstore={caslib=astore_table_lib, name=astore_table_name},
            out={caslib=output_table_lib, name="_tmp_"||output_table_name, replace=TRUE}
            copyVars={text_var};
         ;       

         table.alterTable /
            caslib = output_table_lib,
            name   = "_tmp_"||output_table_name,
            columns= {{name=text_var, rename=query_variable}}
         ;

         table.dropTable / 
            name="_tmp_"||input_table_name, 
            caslib=output_table_lib
         ;

      quit;

   %end;


/*-----------------------------------------------------------------------------------------*
   Run Python block (accepts inputs and loads documents along with embeddings)
*------------------------------------------------------------------------------------------*/
   %if &_qcd_error_flag. = 0 %then %do;

      proc python infile = qcdcode;
      quit;

      filename qcdcode clear;

   %end;

%mend _qcd_main_execution_code;

/*-----------------------------------------------------------------------------------------*
   END MACRO DEFINITIONS
*------------------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE
   The execution code is controlled by the trigger variable defined in this custom step. This
   trigger variable is in an "enabled" (value of 1) state by default, but in some cases, as 
   dictated by logic, could be set to a "disabled" (value of 0) state.
*------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------*
   Create run-time trigger. 
*------------------------------------------------------------------------------------------*/

%_create_runtime_trigger(_qcd_run_trigger);

%if &_qcd_run_trigger. = 1 %then %do;

   %_qcd_main_execution_code;

%end;

%if &_qcd_run_trigger. = 0 %then %do;

   %put NOTE: This step has been disabled.  Nothing to do.;

%end;


/*-----------------------------------------------------------------------------------------*
   Clean up existing macro variables and macro definitions.
*------------------------------------------------------------------------------------------*/
%if %symexist(_qcd_error_flag) %then %do;
   %symdel _qcd_error_flag;
%end;

%if %symexist(casSessionExists) %then %do;
   %symdel casSessionExists;
%end;

%if %symexist(inputCaslib) %then %do;
   %symdel inputCaslib;
%end;

%if %symexist(outputCaslib) %then %do;
   %symdel outputCaslib;
%end;

%if %symexist(PROC_PYPATH) %then %do;
   %symdel PROC_PYPATH;
%end;

%if %symexist(_current_uuid_) %then %do;
   %symdel _current_uuid_;
%end;

%if %symexist(_sas_folder_path) %then %do;
   %symdel _sas_folder_path;
%end;

%if %symexist(_path_identifier) %then %do;
   %symdel _path_identifier;
%end;

%if %symexist(_qcd_run_trigger) %then %do;
   %symdel _qcd_run_trigger;
%end;


/*-----------------------------------------------------------------------------------------*
   Clean up existing macro variables and macro definitions.
*------------------------------------------------------------------------------------------*/
%sysmacdelete _qcd_main_execution_code;
%sysmacdelete _env_check_python;
%sysmacdelete _usr_getNameCaslib;
%sysmacdelete _env_cas_checkSession;
%sysmacdelete _extract_sas_folder_path;
%sysmacdelete _identify_content_or_server;
%sysmacdelete _create_runtime_trigger;
%sysmacdelete _create_error_flag;


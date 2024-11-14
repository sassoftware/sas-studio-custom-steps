/* SAS templated code goes here */

/*-----------------------------------------------------------------------------------------*
   Large Language Models (LLM) - Azure OpenAI Retrieval Augmented Generation(RAG)
   Version: 1.3.3 (14NOV2024)

   This custom step uses a Retrieval Augmented Generation (RAG) approach to provide right 
   context to an Azure OpenAI Large Language Model (LLM) for answering a question.  

   Contact: Samiul.Haque@sas.com
            Sundaresh.Sankaran@sas.com / Sundaresh.Sankaran@gmail.com
            Renato.Luppi@sas.com

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
filename aorcode temp;

data _null_;

   length line $32767;               * max SAS character size ;
   infile datalines4 truncover pad;
   input ;   
   file aorcode;
   line = strip(_infile_);           * line without leading and trailing blanks ;
   l1 = length(trimn(_infile_));     * length of line without trailing blanks ;
   l2 = length(line);                * length of line without leading and trailing blanks ;
   first_position=l1-l2+1;           * position where the line should start (alignment) ;
   if (line eq ' ') then put @1;     * empty line ;
   else put @first_position line;    * line without leading and trailing blanks correctly aligned ;

   datalines4;
#############################################################################################
#
#   Obtain values from UI
#
#############################################################################################

_aor_error_flag = int(SAS.symget('_aor_error_flag'))
_aor_error_desc = SAS.symget('_aor_error_desc')
data_path = SAS.symget('_data_location')
chroma_path = SAS.symget('_persistent_path')
collection_name =  SAS.symget("collectionName")
system_prompt = SAS.symget("varSystemPrompt")
query_text=SAS.symget('questionText')
embedding_model_deployment = SAS.symget("embeddingModelDeployment")
gen_model_deployment = SAS.symget("genModelDeployment")
folder_file_selector = SAS.symget('folder_or_file_selector')
num_k = int(SAS.symget('numK'))
temperature = float(SAS.symget('temperature'))
output_table = SAS.symget('outputTable')

   
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
#  Import packages
#
#############################################################################################

try:
   from langchain.document_loaders import DirectoryLoader
   from langchain.text_splitter import RecursiveCharacterTextSplitter
   from langchain.schema import Document
   from langchain.vectorstores.chroma import Chroma
   from langchain.prompts import ChatPromptTemplate
   from langchain_openai import AzureChatOpenAI
   from langchain_openai import AzureOpenAIEmbeddings
   
   import os
   import shutil
   import chromadb
   import pandas 

except ImportError as e:
   _aor_error_flag = 1
   _aor_error_desc = str(e)
   SAS.logMessage(_aor_error_desc,"error")
   SAS.symput("_aor_error_flag",_aor_error_flag)
   SAS.symput("_aor_error_desc",_aor_error_desc)

#############################################################################################
#
#  Refer https://docs.trychroma.com/telemetry for details.  Recommend to opt out of anonymized 
#  unless you can confidently configure permissions on the Python build location (admin-level).
#
#############################################################################################

os.environ['ANONYMIZED_TELEMETRY'] = "False"

#############################################################################################
#
#   Set environment variables for Azure OpenAI
#
#############################################################################################

os.environ["AZURE_OPENAI_API_KEY"]= SAS.symget("AZURE_OPENAI_KEY")
os.environ["AZURE_OPENAI_ENDPOINT"]= SAS.symget("azureOpenAIEndpoint")
os.environ["OPENAI_API_VERSION"] = SAS.symget("OpenAIVersion")

#############################################################################################
#
#   Helper functions
#
#############################################################################################

def load_documents(isFolder):
   '''Reads in all documents or a single pdf doc using PyPDF or directory loader'''

   SAS.logMessage(f"Answer bank located at {data_path}")
   SAS.logMessage(f"Data source is {isFolder}")

   if isFolder=="folder":
      from langchain_community.document_loaders import PyPDFLoader
      loader = DirectoryLoader(data_path,glob="*.pdf",loader_cls=PyPDFLoader)
   elif isFolder=="pdf":
      from langchain_community.document_loaders import PyPDFLoader
      loader=PyPDFLoader(data_path)
   elif isFolder=="sas":
      sas_dataset = SAS.symget("inputTable")
      pdf_sas = SAS.sd2df(dataset=sas_dataset)
      text_source = SAS.symget('textSource')
      from langchain_community.document_loaders import DataFrameLoader
      loader = DataFrameLoader(pdf_sas, page_content_column=text_source)
      SAS.logMessage("SAS dataset loaded")
   elif isFolder=="pandas":
      pdf_name = SAS.symget('dataFrameName')
      text_source = SAS.symget('textSource')
      from langchain_community.document_loaders import DataFrameLoader
      loader = DataFrameLoader(globals()[pdf_name], page_content_column=text_source)
      SAS.logMessage("Pandas data frame loaded")
   elif isFolder=="csv":
      text_source = SAS.symget('textSource')
      from langchain_community.document_loaders.csv_loader import CSVLoader
      loader=CSVLoader(file_path = data_path, source_column = text_source)
   else:
      _aor_error_flag = 1
      _aor_error_desc = "Provided file should be either PDF or CSV"
      
   documents=loader.load_and_split()
   SAS.logMessage("Load and split complete")
   return documents

def save_to_chroma(chunks: list[Document]):
   ''' Loads data to Chroma DB '''

   embedding_method= AzureOpenAIEmbeddings( azure_deployment=embedding_model_deployment, openai_api_version=os.environ["OPENAI_API_VERSION"])
   db = Chroma.from_documents( documents = chunks, embedding = embedding_method, client = chroma_client, collection_name = collection_name, persist_directory=chroma_path )
   db.persist()
   print(f"Saved {len(chunks)} chunks to {chroma_path}.")


SAS.logMessage(chroma_path)

#############################################################################################
#
#   Establish a Chroma connection
#
#############################################################################################

chroma_client = chromadb.PersistentClient(path=chroma_path)

collections = [item.name for item in [name for name in chroma_client.list_collections()]]

SAS.logMessage("Collections listed at this path:")

for collection in collections:
   SAS.logMessage(collection)

if folder_file_selector == "existing":

   if not(collection_name in collections):
      _aor_error_flag = 1
      _aor_error_desc = f"{collection_name} is not in the list of collections in Chroma"
      SAS.logMessage(_aor_error_desc,"error")
      SAS.symput("_aor_error_flag",_aor_error_flag)
      SAS.symput("_aor_error_desc",_aor_error_desc)

if _aor_error_flag == 0:

   try:
      chroma_client.get_or_create_collection(name=collection_name)

   except Exception as e:
      _aor_error_flag = 1
      _aor_error_desc = str(e)
      SAS.logMessage(_aor_error_desc,"error")
      SAS.symput("_aor_error_flag",_aor_error_flag)
      SAS.symput("_aor_error_desc",_aor_error_desc)

#############################################################################################
#
#   Load answer bank to a document object & chunk them
#
#############################################################################################


if _aor_error_flag == 0 and not(folder_file_selector=="existing"):

   try: 
      doc = load_documents(folder_file_selector)
      print(doc)

   except Exception as e:
      _aor_error_flag = 1
      _aor_error_desc = str(e)
      SAS.logMessage(_aor_error_desc,"error")
      SAS.symput("_aor_error_flag",_aor_error_flag)
      SAS.symput("_aor_error_desc",_aor_error_desc)
 
   try:
      text_splitter = RecursiveCharacterTextSplitter(
         chunk_size=1000,
         chunk_overlap=500,
         length_function=len,
         add_start_index=True
      )

   except Exception as e:
      _aor_error_flag = 1
      _aor_error_desc = str(e)
      SAS.logMessage(_aor_error_desc,"error")
      SAS.symput("_aor_error_flag",_aor_error_flag)
      SAS.symput("_aor_error_desc",_aor_error_desc)

   try:
      chunks=text_splitter.split_documents(doc)
      SAS.logMessage("Answers loaded to document object")

   except Exception as e:
      _aor_error_flag = 1
      _aor_error_desc = str(e)
      SAS.logMessage(_aor_error_desc,"error")
      SAS.symput("_aor_error_flag",_aor_error_flag)
      SAS.symput("_aor_error_desc",_aor_error_desc)


#############################################################################################
#
#   Load to Chroma
#
#############################################################################################

   try:
      save_to_chroma(chunks)
      print(f"Saved {len(chunks)} chunks to {chroma_path}.")

   except Exception as e:
      _aor_error_flag = 1
      _aor_error_desc = str(e)
      SAS.logMessage(_aor_error_desc,"error")
      SAS.symput("_aor_error_flag",_aor_error_flag)
      SAS.symput("_aor_error_desc",_aor_error_desc)

if _aor_error_flag == 0:

   try:
      embedding_function = AzureOpenAIEmbeddings(
         azure_deployment = embedding_model_deployment,
         openai_api_version = os.environ["OPENAI_API_VERSION"],
      )

   except Exception as e:
      _aor_error_flag = 1
      _aor_error_desc = str(e)
      SAS.logMessage(_aor_error_desc,"error")
      SAS.symput("_aor_error_flag",_aor_error_flag)
      SAS.symput("_aor_error_desc",_aor_error_desc)

if _aor_error_flag == 0:

   try:
      db = Chroma(persist_directory=chroma_path, embedding_function=embedding_function,collection_name=collection_name, collection_metadata={"hnsw:space": "cosine"})
      SAS.logMessage("Answers loaded to Chroma")

   except Exception as e:
      _aor_error_flag = 1
      _aor_error_desc = str(e)
      SAS.logMessage(_aor_error_desc,"error")
      SAS.symput("_aor_error_flag",_aor_error_flag)
      SAS.symput("_aor_error_desc",_aor_error_desc)


#############################################################################################
#
#   Retrieve results
#
#############################################################################################

   try:
      results = db.similarity_search_with_relevance_scores(query_text, k=num_k)

   except Exception as e:
      _aor_error_flag = 1
      _aor_error_desc = str(e)
      SAS.logMessage(_aor_error_desc,"error")
      SAS.symput("_aor_error_flag",_aor_error_flag)
      SAS.symput("_aor_error_desc",_aor_error_desc)

   if results:
      context_text = "\n\n---\n\n".join([doc.page_content for doc, _score in results])
      results_final = []
   
      for doc,score in results:
         _results_dict = {**doc.metadata, "page_content":doc.page_content, "score":score }
         results_final.append(_results_dict)

      if output_table:
         pdf = pandas.DataFrame().from_dict(results_final)
         SAS.df2sd(pdf,dataset=output_table)
   
if _aor_error_flag == 0:

   try:
      prompt_template = ChatPromptTemplate.from_template(system_prompt)
      prompt = prompt_template.format(context=context_text, question=query_text)

   except Exception as e:
      _aor_error_flag = 1
      _aor_error_desc = str(e)
      SAS.logMessage(_aor_error_desc,"error")
      SAS.symput("_aor_error_flag",_aor_error_flag)
      SAS.symput("_aor_error_desc",_aor_error_desc)

#############################################################################################
#
#   Execute prompt with provided context
#
#############################################################################################

if _aor_error_flag == 0:

   try:
      model = AzureChatOpenAI(azure_deployment=gen_model_deployment, temperature=temperature,)
      response_text = model.invoke(prompt)

   except Exception as e:
      _aor_error_flag = 1
      _aor_error_desc = str(e)
      SAS.logMessage(_aor_error_desc,"error")
      SAS.symput("_aor_error_flag",_aor_error_flag)
      SAS.symput("_aor_error_desc",_aor_error_desc)


#############################################################################################
#
#   Send results to write to ODS output
#
#############################################################################################

if _aor_error_flag == 0:

   try:
      sources = [doc.metadata.get("source", None) for doc, _score in results]
      formatted_response = f"Response: {response_text.content}\nSources: {sources}"
      print(formatted_response)
      SAS.symput('_response_value',response_text.content)

   except Exception as e:
      _aor_error_flag = 1
      _aor_error_desc = str(e)
      SAS.logMessage(_aor_error_desc,"error")
      SAS.symput("_aor_error_flag",_aor_error_flag)
      SAS.symput("_aor_error_desc",_aor_error_desc)

;;;;
   

run;


/*-----------------------------------------------------------------------------------------*
   START MACRO DEFINITIONS.
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

   Also at: https://github.com/SundareshSankaran/sas_utility_programs/blob/main/code/Create_Run_Time_Trigger/macro_create_runtime_trigger.sas
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
      2. errorFlagDesc: The name of an error flag description variable to hold the error 
         description.

    Output:
      1. &errorFlagName : A global variable which takes the name provided to errorFlagName.
      2. &errorFlagDesc : A global variable which takes the name provided to errorFlagDesc.

   Also available at: 
   https://github.com/SundareshSankaran/sas_utility_programs/blob/main/code/Error%20Flag%20Creation/macro_create_error_flag.sas
*------------------------------------------------------------------------------------------ */

%macro _create_error_flag(errorFlagName, errorFlagDesc);

   %global &errorFlagName.;
   %global &errorFlagDesc.;
   %let &errorFlagName.=0;
   %let &errorFlagDesc. = No errors reported so far;
   
%mend _create_error_flag;

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


/* ------------------------------------------------------------------------------------------------* 
   Macro to check whether a path to Python is available to a compute 
   session where this program runs.  Detailed macro available at 
   https://github.com/SundareshSankaran/sas_utility_programs/blob/main/code/Check_For_Python/macro_python_check.sas

   If you already know you are running this code in a Compute server session, you can call the 
   %_env_check_python_compute macro directly, as done here.

   Sundaresh Sankaran, 20FEB2024
*----------------------------------------------------------------------------------------------------- */

%macro _env_check_python_compute(errorFlagName, errorFlagDesc);

   %global PROC_PYPATH;

   data _null_;

      /* ----------------------------------------------------------------------------------------------* 
         Obtain system options and store them inside macro variables.
      *----------------------------------------------------------------------------------------------- */
      proc_pypath = sysget('PROC_PYPATH');
      viya_lockdown_user_methods = sysget('VIYA_LOCKDOWN_USER_METHODS');
      compute_enable = sysget('COMPUTESERVER_LOCKDOWN_ENABLE');
      does_file_at_pypath_exist=fileexist(proc_pypath);

      /* ----------------------------------------------------------------------------------------------* 
         Let's start from the end
         Check if PROC_PYPATH exists
      *----------------------------------------------------------------------------------------------- */

      if proc_pypath = "" then do;
         call symputx(&errorFlagName.,1);
         call symput(&errorFlagDesc., "PROC_PYPATH environment variable not populated, indicating that Python may not have been configured.");
      end;

      else do;

         /* -------------------------------------------------------------------------------------------* 
            Check if PROC_PYPATH points to a valid file
         *-------------------------------------------------------------------------------------------- */

         if does_file_at_pypath_exist = 0 then do;
            call symputx(&errorFlagName.,1);
            call symput(&errorFlagDesc., "The file referred by PROC_PYPATH does not exist, indicating path to Python may have been configured incorrectly.");             
         end;

         else do;

            /* -----------------------------------------------------------------------------------------* 
               Check if COMPUTESERVER_LOCKDOWN_ENABLE = 0, indicating a permissive (and potentially 
               insecure) environment.
            *------------------------------------------------------------------------------------------ */

            if compute_enable = '1' then do;

               /* --------------------------------------------------------------------------------------* 
                  Check if PYTHON and SOCKET appear in viya_lockdown_user_methods.
                  There's an additional PYTHON_EMBED option which is included as a strict check (enabling 
                  Python to run in a submit block).
               *--------------------------------------------------------------------------------------- */

               if index(lowcase(viya_lockdown_user_methods),"python") > 0 and index(lowcase(viya_lockdown_user_methods),"socket") > 0 and index(lowcase(viya_lockdown_user_methods),"python_embed") > 0 then do;
                  call symput("PROC_PYPATH", proc_pypath);
                  call symputx(&errorFlagName.,0);
                  call symput(&errorFlagDesc., "A path to Python is available in this compute session and Python use is part of Viya enabled methods.") ;
               end;

               else do;
                  call symputx(&errorFlagName.,1);
                  call symput(&errorFlagDesc., "Required access methods to run Python don't seem to form part of the user methods allowed in Viya. Please take steps to enable PYTHON, PYTHON_EMBED and SOCKET");             
               end;

            end;

            else do;
               call symput("PROC_PYPATH", proc_pypath);
               call symputx(&errorFlagName.,0);
               call symput(&errorFlagDesc., "A path to Python is available in this compute session and COMPUTESERVER_LOCKDOWN_ENABLE is disabled. While you can run Python, note that setting COMPUTESERVER_LOCKDOWN_ENABLE to 0 is not recommended.");
            end;

         end;

      end;

   run;

%mend _env_check_python_compute;


/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE MACRO 

   _aor prefix stands for Azure OpenAI RAG
*------------------------------------------------------------------------------------------*/

%macro _aor_execution_code;

   %put NOTE: Starting main execution code;

   %global _response_value;

/*-----------------------------------------------------------------------------------------*
   Create an error flag. 
*------------------------------------------------------------------------------------------*/

   %_create_error_flag(_aor_error_flag, _aor_error_desc);

   %put NOTE: Error flag created;

/*-----------------------------------------------------------------------------------------*
   Check if Python's available in the environment. 
*------------------------------------------------------------------------------------------*/

   %_env_check_python_compute("_aor_error_flag","_aor_error_desc");

   %if &_aor_error_flag.=1 %then %do;
      %put ERROR: &_aor_error_desc. ;
   %end;

   %put NOTE: Python check complete;

/*-----------------------------------------------------------------------------------------*
   Check if path for Chroma DB provided happens to be a filesystem (SAS Server) or SAS 
   Content path. Prior to that, insert /tmp as a placeholder in case this field has not 
   been entered.
*------------------------------------------------------------------------------------------*/

   %if &_aor_error_flag. = 0 %then %do;

      %if "&persistentPathName."="" %then %do;
         %let persistentPathName=sasserver:/tmp;
      %end;

      %else %do;
         %_identify_content_or_server(&persistentPathName.);

         %if "&_path_identifier."="sasserver" %then %do;
            %put NOTE: Folder location prefixed with &_path_identifier. is on the SAS Server.;
         %end;

         %else %do;

            %let _aor_error_flag=1;
            %put ERROR: Please select a valid folder on the SAS Server (filesystem) for persisting the database. ;

         %end;

      %end;

   %end;

   %if &_aor_error_flag. = 0 %then %do;

      %_extract_sas_folder_path(&persistentPathName.);

      %if "&_sas_folder_path." = "" %then %do;

         %let _aor_error_flag=1;
         %let _aor_error_desc = The persistent path provided is empty, please select a valid path  ;
         %put ERROR: &_aor_error_desc. ;

      %end;

   %end;

   %if &_aor_error_flag. = 0 %then %do;

      %global _persistent_path;
      %let _persistent_path = &_sas_folder_path;
      %let _sas_folder_path=;

   %end;

/*-----------------------------------------------------------------------------------------*
   Check if path for Azure Key Location  happens to be a filesystem (SAS Server) opath. 
*------------------------------------------------------------------------------------------*/
   %if &_aor_error_flag. = 0 %then %do;

      %_identify_content_or_server(&azureKeyLocation.);

      %if "&_path_identifier."="sasserver" %then %do;
         %put NOTE: Folder location prefixed with &_path_identifier. is on the SAS Server.;
      %end;

      %else %do;

         %let _aor_error_flag=1;
         %put ERROR: Please select a valid file on the SAS Server (filesystem) containing your Azure OpenAI key.  Key should be in a secure location within filesystem. ;

      %end;

   %end;

   %if &_aor_error_flag. = 0 %then %do;

      %_extract_sas_folder_path(&azureKeyLocation.);

      %if "&_sas_folder_path." = "" %then %do;

         %let _aor_error_flag=1;
         %let _aor_error_desc = The answer bank provided is empty, please select a valid path  ;
         %put ERROR: &_aor_error_desc. ;

      %end;

   %end;

   %if &_aor_error_flag. = 0 %then %do;

      %global _key_location;
      %let _key_location = &_sas_folder_path;
      %let _sas_folder_path=;

   %end;

   %if &_aor_error_flag. = 0 %then %do;

      data _null_;
         infile "&_key_location." lrecl=1000;
         input @;
         call symput("AZURE_OPENAI_KEY",_INFILE_);
      run;
 
   %end;

/*-----------------------------------------------------------------------------------------*
   Check if a file or folder has been selected and assign value to a common variable 
*------------------------------------------------------------------------------------------*/

   %if "&folder_or_file_selector." = "existing" %then %do;
      %put NOTE: Existing collection found ;
   %end;

   %else %do;

      %if &_aor_error_flag. = 0 %then %do;

         %global _answer_path;

         %if "&folder_or_file_selector." = "pdf" %then %do;
            %let _answer_path = &answerBankFile.;
         %end;

         %else %if "&folder_or_file_selector." = "csv" %then %do;
            %let _answer_path = &answerBankFile.;
         %end;

         %else %if "&folder_or_file_selector." = "folder" %then %do;
            %let _answer_path = &answerBankFolder.;
         %end;
      
      %end;

/*-----------------------------------------------------------------------------------------*
   Separate out pandas from other sources owing to its in-memory nature 
*------------------------------------------------------------------------------------------*/

      %if "&folder_or_file_selector." = "pandas" %then %do;
             
      %end;
      %else %if "&folder_or_file_selector." = "sas" %then %do;
             
      %end;
      %else %do;

         %_identify_content_or_server(&_answer_path.);

         %if "&_path_identifier."="sasserver" %then %do;
            %put NOTE: Location prefixed with &_path_identifier. is on the SAS Server.;
         %end;

         %else %do;

            %let _aor_error_flag=1;
            %let _aor_error_desc = Please select a valid file or folder on the SAS Server (filesystem) containing your answer bank.  ;
            %put ERROR: &_aor_error_desc. ;

         %end;

         %if &_aor_error_flag. = 0 %then %do;

            %_extract_sas_folder_path(&_answer_path.);

            %if "&_sas_folder_path." = "" %then %do;

               %let _aor_error_flag=1;
               %let _aor_error_desc = The answer bank provided is empty, please select a valid path  ;
               %put ERROR: &_aor_error_desc. ;

            %end;

         %end;

         %if &_aor_error_flag. = 0 %then %do;

            %global _data_location;
            %let _data_location = &_sas_folder_path;
            %let _sas_folder_path=;

         %end;

      %end;
   
   %end;

   %if &_aor_error_flag. = 0 %then %do;

      %if "&azureRegion." = "" %then %do;
         %let azureRegion=eastus2;
      %end;

   %end;

/*-----------------------------------------------------------------------------------------*
   Run Python block (accepts inputs and loads documents along with embeddings)
*------------------------------------------------------------------------------------------*/

   %if &_aor_error_flag. = 0 %then %do;

      proc python infile = aorcode;
      quit;

      filename aorcode clear;

   %end;

/*-----------------------------------------------------------------------------------------*
   Print results to ODS html
*------------------------------------------------------------------------------------------*/

   %if &_aor_error_flag. = 0 %then %do;

      filename rwiOut ".";
      ods html close;
      ods html path=rwiOut file="UnformatText.html";
    
      title "Question: &questionText.";
   
      data _null_;
       
         dcl odsout obj();
         obj.format_text(data: " %bquote(&_response_value.) "); 
     
      run;
   
      ods html close;
      ods html; 

   %end;

   %if &_aor_error_flag. = 0 %then %do;

      %if "&outputTable."="" %then %do;
         %put NOTE: No output table specified. ;
      %end;

      %else %do;

         data &outputTable.;
            length Question $32767. LLM_Answer $32767.;
            set &outputTable.;
            Question = "&questionText.";
            LLM_Answer = "%bquote(&_response_value.)";
         run;

      %end;

   %end;

%mend _aor_execution_code;


/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE
   The execution code is controlled by the trigger variable defined in this custom step. This
   trigger variable is in an "enabled" (value of 1) state by default, but in some cases, as 
   dictated by logic, could be set to a "disabled" (value of 0) state.
*------------------------------------------------------------------------------------------*/
/*-----------------------------------------------------------------------------------------*
   Create run-time trigger. 
*------------------------------------------------------------------------------------------*/

%_create_runtime_trigger(_aor_run_trigger);

/*-----------------------------------------------------------------------------------------*
   Execute 
*------------------------------------------------------------------------------------------*/

%if &_aor_run_trigger. = 1 %then %do;

   %_aor_execution_code;

%end;

%if &_aor_run_trigger. = 0 %then %do;

   %put NOTE: This step has been disabled.  Nothing to do.;

%end;


%put NOTE: Final summary;
%put NOTE: Status of error flag - &_aor_error_flag. ;
%put NOTE: Error desc - &_aor_error_desc. ;


/*-----------------------------------------------------------------------------------------*
   Clean up existing macro variables and macro definitions.
*------------------------------------------------------------------------------------------*/

%if %symexist(_answer_path) %then %do;
   %symdel _answer_path;
%end;

%if %symexist(_aor_run_trigger) %then %do;
   %symdel _aor_run_trigger;
%end;

%if %symexist(_path_identifier) %then %do;
   %symdel _path_identifier;
%end;

%if %symexist(_sas_folder_path) %then %do;
   %symdel _sas_folder_path;
%end;

%if %symexist(_response_value) %then %do;
   %symdel _response_value;
%end;

%if %symexist(_persistent_path) %then %do;
   %symdel _persistent_path;
%end;

%if %symexist(_key_location) %then %do;
   %symdel _key_location;
%end;

%if %symexist(_answer_path) %then %do;
   %symdel _answer_path;
%end;

%if %symexist(_data_location) %then %do;
   %symdel _data_location;
%end;

%if %symexist(_aor_error_flag) %then %do;
   %symdel _aor_error_flag;
%end;

%if %symexist(_aor_error_desc) %then %do;
   %symdel _aor_error_desc;
%end;

%if %symexist(PROC_PYPATH) %then %do;
   %symdel PROC_PYPATH;
%end;

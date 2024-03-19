# LLM - Azure OpenAI-based Retrieval Augmented Generation (RAG)

This custom step uses a Retrieval Augmented Generation (RAG) approach to provide right context to an Azure OpenAI Large Language Model (LLM) for purposes of answering a question.  

LLMs require context to provide relevant answers, especially for questions based on a local body of knowledge or document corpus.  

A RAG approach, explained in simple terms, retrieves relevant data from a knowledge base and provides the same to an LLM to use as context.  Results based on RAG are expected to reduce LLM hallucinations (i.e. an LLM provides irrelevant or false answers).  This custom step queries a Chromadb vector store and passes retrieved documents to an Azure OpenAI service.   

**IMPORTANT:** Be aware that this custom step uses an Azure OpenAI service that results in data being sent over to the service.  Ensure you use this only in accordance with your organization's policies on calling external LLMs.

## A general idea

This animated gif provides a basic idea: 

![LLM - Azure OpenAI RAG](./img/Azure_OpenAI.gif)

----
## Table of Contents
1. [Assumptions](#assumptions)
2. [Requirements](#requirements)
3. [Parameters](#parameters)
   1. [Input Parameters](#input-parameters)
   2. [Configuration](#configuration)
   3. [Output Specifications](#output-specifications)
4. [Run-time Control](#run-time-control)
5. [Documentation](#documentation)
6. [SAS Program](#sas-program)
7. [Installation and Usage](#installation--usage)
8. [Created/Contact](#createdcontact)
9. [Change Log](#change-log)
----
## Assumptions

Current assumptions for this initial versions (future versions may improve upon the same):

1. Users  choose either an existing Chroma DB vector database collection or load PDF files to an existing or new Chroma DB collection.

2. Users may load all PDFs in a directory on the SAS Server (filesystem), or select a PDF of their choice.

3. The code assumes use of a Chroma DB vector store.  Users may choose to replace this with other vector stores supported by the langchain framework by modifying the underlying code.

4. The step uses the langchain LLM framework.

5. PDFs (containing text) are currently the only loadable file format in this step.  Users are however free to ingest various other document types into a Chroma DB collection beforehand, using the ["Vector Databases - Hydrate Chroma DB collection"](https://github.com/sassoftware/sas-studio-custom-steps/tree/main/Vector%20Databases%20-%20Hydrate%20Chroma%20DB%20Collection) SAS Studio Custom Step (refer documentation)

6. User has already configured Azure OpenAI to deploy both an embedding function and LLM service, or knows the deployment names. 

-----

## Requirements

1. A SAS Viya 4 environment version 2024.01 or later.

2. Python:  Python version 3.10 is recommended to avoid package support or dependency issues.

3. Python packages to be installed:

   1. [langchain](https://pypi.org/project/langchain/)
   2. [langchain-community](https://pypi.org/project/langchain-community/)
   3. [langchain-openai](https://pypi.org/project/langchain-openai/)
   4. [PyPDF](https://pypi.org/project/pypdf/)
   5. [sentence-transformers](https://pypi.org/project/sentence-transformers/)
   6. [chromadb](https://pypi.org/project/chromadb/)
   7. [pysqlite-binary](https://pypi.org/project/pysqlite-binary/)

4. Valid Azure OpenAI service with embedding & large language models deployed.  [Refer here for instructions](https://learn.microsoft.com/en-us/azure/ai-services/openai/quickstart?tabs=command-line%2Cpython-new&pivots=programming-language-studio) 


----
## Parameters
----
### Input Parameters

1. **Source file location** (optional, default is Context already loaded): In case you wish to present new source files to use as context,  choose either selecting a folder or file. Otherwise, provide the name of an existing vector store collection in Configuration.

2. **Question** (text area, required): Provide your question to the LLM. Note that this will be added to additional system prompt, to create a prompt that will be passed to the LLM.

----
### Configuration 

1. **Embedding model** (text field, required):  provide the name of your Azure OpenAI deployment of an OpenAI embedding model. For convenience, it's suggested to use the same name as the model you wish to use. For example, if your OpenAI embedding model happens to be text-embedding-3-small, use the same name for your deployment. 

2. **Vector store persistent path** (text field, defaults to /tmp if blank): provide a path to a ChromaDB database.  If blank, this defaults to /tmp on the filesystem. 

3. **Chroma DB collection name** (text field): provide name of the Chroma DB collection you wish to use.  If the collection does not exist, a new one will be created. Ensure you have write access to the persistent area.

4. **Text generation model** (text field, required): provide the name of an Azure OpenAI text generation deployment.  For convenience, you may choose to use the same name as the OpenAI LLM. Example, gpt-35-turbo to gpt-35-turbo.

5. **Azure OpenAI service details** (file selector for key and text fields, required): provide a path to your Azure OpenAI access key.  Ensure this key is saved within a text file in a secure location on the filesystem.  Users are responsible for providing their keys to use this service.  In addition, also refer to your Azure OpenAI service to obtain the service endpoint and region.

----
### Output Specifications

Results (the answer from the LLM) are printed by default to the output window.

1. **Context size** (numeric stepper, default 10): select how many similar results from the vector store should be retrieved and provided as context to the LLM.  Note that a higher number results in more tokens provided as part of the prompt.

 2. **Output table** (output port, option): attach either a CAS table or sas7bdat to the output port of this node to hold results.  These results contain the LLM's answer, the original question and supporting retrieved results. 

----
## Run-time Control

Note: Run-time control is optional.  You may choose whether to execute the main code of this step or not, based on upstream conditions set by earlier SAS programs.  This includes nodes run prior to this custom step earlier in a SAS Studio Flow, or a previous program in the same session.

Refer this blog (https://communities.sas.com/t5/SAS-Communities-Library/Switch-on-switch-off-run-time-control-of-SAS-Studio-Custom-Steps/ta-p/885526) for more details on the concept.

The following macro variable,
```sas
_aor_run_trigger
```

will initialize with a value of 1 by default, indicating an "enabled" status and allowing the custom step to run.

If you wish to control execution of this custom step, include code in an upstream SAS program to set this variable to 0.  This "disables" execution of the custom step.

To "disable" this step, run the following code upstream:

```sas
%global _aor_run_trigger;
%let _aor_run_trigger =0;
```

To "enable" this step again, run the following (it's assumed that this has already been set as a global variable):

```sas
%let _aor_run_trigger =1;
```


IMPORTANT: Be aware that disabling this step means that none of its main execution code will run, and any  downstream code which was dependent on this code may fail.  Change this setting only if it aligns with the objective of your SAS Studio program.

----
## Documentation

1.  [Azure OpenAI service](https://learn.microsoft.com/en-us/azure/ai-services/openai/)

2. [Documentation for the chromadb Python package](https://docs.trychroma.com)

3.  [Documentation for the "Vector Databases - Hydrate Chroma DB collection" SAS Studio Custom Step](https://github.com/sassoftware/sas-studio-custom-steps/tree/main/Vector%20Databases%20-%20Hydrate%20Chroma%20DB%20Collection)

4. [An important note regarding sqlite](https://docs.trychroma.com/troubleshooting#sqlite)

5. [SAS Communities article on configuring Viya for Python integration](https://communities.sas.com/t5/SAS-Communities-Library/Configuring-SAS-Viya-for-Python-Integration/ta-p/847459)

6. [The SAS Viya Platform Deployment Guide (refer to SAS Configurator for Open Source within)](https://go.documentation.sas.com/doc/en/itopscdc/default/itopssr/p1n66p7u2cm8fjn13yeggzbxcqqg.htm?fromDefault=#p19cpvrrjw3lurn135ih46tjm7oi )

7.  [Options for persistent clients and client connections in Chroma](https://docs.trychroma.com/usage-guide)

8. [Langchain Python documentation](https://python.langchain.com/docs/get_started/introduction)

----
## SAS Program

Refer [here](./extras/LLM%20-%20Azure%20Open%20AI%20RAG.sas) for the SAS program used by the step.  You'd find this useful for situations where you wish to execute this step through non-SAS Studio Custom Step interfaces such as the [SAS Extension for Visual Studio Code](https://github.com/sassoftware/vscode-sas-extension), with minor modifications. 

----
## Installation & Usage

- Refer to the [steps listed here](https://github.com/sassoftware/sas-studio-custom-steps#getting-started---making-a-custom-step-from-this-repository-available-in-sas-studio).

----
## Created/contact: 

1. Samiul Haque (samiul.haque@sas.com)
2. Sundaresh Sankaran (sundaresh.sankaran@sas.com)

----
## Change Log

* Version 1.0 (17MAR2024) 
    * Initial version
# Optical Character Recognition(OCR) - Azure AI Document Intelligence Table Extraction
======================================================================================

This custom step extracts tables contained in PDFs and images using [Microsoft Azure's Document Intelligence cloud AI services](https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/?view=doc-intel-3.1.0). Azure AI Document Intelligence was formerly known as Form Recognizer.

Organizations require seamless extraction and analysis of structured tabular information embedded in documents. Use this step to help tackle challenges that occur when dealing with data in document formats.

Note that the Azure AI Document Intelligence service is capable of extracting other elements via OCR, all of which shall be gradually surfaced in this custom step.  You can access the SAS program (provided separately) and modify the same even now, if required (refer [here](#sas-program)).
 
 
## A general idea (below picture's an animated gif)

![OCR - Azure AI Document Intelligence Table Extraction](./img/OCR%20-%20Azure%20AI%20Document%20Intelligence%20Table%20Extraction.gif)

## SAS Viya Version Support
Tested in Viya 4, Stable 2023.09

## Requirements

1. A SAS Viya 4 environment (monthly release 2023.09 or later) with SAS Studio Flows.

2. Python (version 3.7 or later) installed and accessible to proc python within SAS Viya.

3. The following Python packages need to be installed.  Note that version numbers where specified may be subject to change as per Azure.

   - azure-ai-formrecognizer==3.3.0 
   - azure-core 
   - pandas

4. Preferable / recommended:  Make use of the SAS Configurator for Open Source (also commonly known as sas-pyconfig) to install and configure Python access from SAS Viya.  Refer SAS Viya Deployment Guide (monthly stable 2023.08 onwards) for instructions on the same. Documentation provided below.

5. An Azure subscription and an active Azure AI Services or Document Intelligence resource.  You can create the same through an Azure portal or CLI.

6. Once your resource is ready, retrieve your Azure endpoint and access key for use within the UI.


## Parameters

### Input Parameters:

- Document URL (text field, required): provide a path to a URL where your document resides.  The document could be either a PDF or an image format as allowed by Azure.  Refer the Azure quickstart (as mentioned in documentation) for any additional details on the types of documents.

Note that ALL table elements identified in the document will be extracted as a single call. You may choose to filter tables to keep downstream.

### Output Specifications:

1. Output table destination (drop-down list, SAS Dataset is the default): choose between outputting your table extracts to SAS datasets or JSON files as per your desired process

2. Output list table (output port, optional): in case you have selected SAS Datasets, provide an output table to this port.  As noted on the UI, this table holds information on the extracts, not the actual extract. For potentially multiple tables extracted, this also serves as a name pattern.

   1.  Select a name that's short and can serve as a pattern.  For example, a name of WORK.OCREXTRACT leads to multiple exracted tables written to WORK.OCREXTRACT_1, WORK.OCREXTRACT_2, .... WORK.OCREXTRACT_<N>, depending on the number of tables in the document.
   2. Note that the location (libname) of this table serves as the destination of the extracted tables themselves

3. JSON file (file selector, optional): in case you've selected JSON as the output destination, provide a valid path to a JSON file which will hold the results of the extracts.

### Configuration (tab)
1. Path to a file containing your Document Intelligence key (file selector, required): save your key in a secure location (i.e. accessible only to designated users) and provide this path 

2. Azure AI Document Intelligence endpoint (text field, required): refer to the Microsoft Azure resource you had created to obtain this value

## Run-time control

**Note that this is optional.**  In some scenarios, you may wish to dynamically control whether this custom step runs or simply "passes through" without doing anything, in a SAS Studio session. The following macro variable is set to initialize with a value of 1 by default, indicating an "enabled" status and allowing the custom step to run.

Refer this [blog](https://communities.sas.com/t5/SAS-Communities-Library/Switch-on-switch-off-run-time-control-of-SAS-Studio-Custom-Steps/ta-p/885526) for more details on the concept.

```sas
/* To demonstrate the default value of the trigger macro variable */;

&_eto_run_trigger.=1;
```

If you wish to control execution of this custom step programmatically (within a session, including execution of a SAS Studio Flow), make sure that an upstream SAS program sets the macro variable to 0.  Setting the value to 0 "disables" the execution of this custom step.

For example, to "disable" this step, run the following code upstream:

```sas
%global _eto_run_trigger;
%let _eto_run_trigger=0;
```

To "enable" this step again, run the following (it's assumed that this has already been set as a global variable):

```sas
%let _eto_run_trigger=1;
```

**Important:** Be aware that disabling this step means that none of its main execution code will run, and any  downstream code which was dependent on this code may fail.  Change this setting only if it aligns with the objective of your SAS Studio program.


## Documentation:

1. [Azure example for accessing the Document Intelligence via Python](https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/quickstarts/get-started-sdks-rest-api?view=doc-intel-3.1.0&tabs=ga%2Cv2-0&pivots=programming-language-python)

2. [A general article / blog on Azure AI Document Intelligence (previously known as Form Recognizer)](https://techcommunity.microsoft.com/t5/azure-ai-services-blog/enhanced-table-extraction-from-documents-with-form-recognizer/ba-p/2058011
)
3. [Scott McCauley's article on configuring Viya for Python integration](https://communities.sas.com/t5/SAS-Communities-Library/Configuring-SAS-Viya-for-Python-Integration/ta-p/847459)

4. [The SAS Viya Platform Deployment Guide (refer to SAS Configurator for Open Source within)](https://go.documentation.sas.com/doc/en/itopscdc/default/itopssr/p1n66p7u2cm8fjn13yeggzbxcqqg.htm?fromDefault=#p19cpvrrjw3lurn135ih46tjm7oi) 


## SAS Program

Refer [here](./extras/OCR%20-%20Azure%20AI%20Document%20Intelligence%20Table%20Extraction.sas) for the SAS program used by the step.  You'd find this useful for situations where you wish to execute this step through non-SAS Studio Custom Step interfaces such as the [SAS Extension for Visual Studio Code](https://github.com/sassoftware/vscode-sas-extension), with minor modifications. 


## Installation & Usage
- Refer to the [steps listed here](https://github.com/sassoftware/sas-studio-custom-steps#getting-started---making-a-custom-step-from-this-repository-available-in-sas-studio).

## Created / contact : 

- Sundaresh Sankaran (sundaresh.sankaran@sas.com)

## Change Log

Version 1.0 (02JAN2024) 
* Submitted to GitHub

Version 0.1 (11OCT2023) 
* Initial Step Creation
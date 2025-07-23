# Custom Steps in SAS Studio: Guidelines for AI Assistants

## Overview of Custom Steps

A Custom Step in SAS Studio is essentially a JSON file with two main components:
1. **Prompt UI**: Defines the inputs and outputs used by the custom step.
2. **Program**: Contains the logic applied to process the inputs and generate the outputs. This logic can be written in SAS code (using macro variables for inputs and outputs) or in Python (inside a `PROC PYTHON` block).

---

## Prompt UI

The **Prompt UI** is a JSON block that defines the user interface for the custom step. It specifies the inputs and outputs that the user will interact with when running the step.

---

## Program

The **Program** component contains the logic that processes the inputs and generates the outputs. This logic can be written in:

- **SAS Code**: Use macro variables to reference the inputs and outputs.
- **Python Code**: Write logic inside a `PROC PYTHON` block, converting SAS macro variables to Python variables.

---

## Python File Paths

When writing Python programs, always handle file paths correctly:

1. Remove prefixes like `sasserver:` or `sascontent:` to ensure the code runs seamlessly.
2. Use `os.chdir()` to set the working directory to the directory of the input or output file before processing files.

---

## Custom Step Examples

### Custom Step Example 1: Ranking Columns in SAS

This example demonstrates a custom step that ranks a column in an input table. The user selects:

- An input table.
- A column to rank.
- An output table.

#### Prompt UI 1

```json
{
	"showPageContentOnly": true,
	"pages": [
		{
			"id": "inPage",
			"type": "page",
			"label": "Rank Options",
			"children": [
				{
					"id": "inTable",
					"type": "inputtable",
					"label": "Select input table:",
					"required": true
				},
				{
					"id": "rankBy",
					"type": "columnselector",
					"label": "Select a column to rank:",
					"table": "inTable",
					"columntype": "n",
					"min": 1,
					"max": 1,
					"include": null
				},
				{
					"id": "outTable",
					"type": "outputtable",
					"label": "Specify the output table:",
					"required": true
				},
				{
					"id": "createNewVariables",
					"type": "checkbox",
					"label": "Create a new column for the ranked column"
				}
			]
		}
	]
}
```

#### Program 1

```sas
proc rank data=&inTable out=&outTable;
   var &rankBy_1_name;
   %if %createNewVariables = 1 %then do;
      ranks rank_&rankBy_1_name;
   %end;
run;
```

### Full Step Code 1

```json
```json
{
	"creationTimeStamp": "2025-02-07T01:45:52.147821Z",
	"createdBy": "sasadm",
	"modifiedTimeStamp": "2025-02-07T01:48:42.582069Z",
	"modifiedBy": "sasadm",
	"id": "09308a34-a85b-4767-94f0-5968a9329b23",
	"name": "help_1.step",
	"displayName": "help_1.step",
	"localDisplayName": "help_1.step",
	"links": [
		{
			"method": "GET",
			"rel": "self",
			"href": "/dataFlows/steps/09308a34-a85b-4767-94f0-5968a9329b23",
			"uri": "/dataFlows/steps/09308a34-a85b-4767-94f0-5968a9329b23",
			"type": "application/vnd.sas.data.flow.step"
		},
		{
			"method": "GET",
			"rel": "alternate",
			"href": "/dataFlows/steps/09308a34-a85b-4767-94f0-5968a9329b23",
			"uri": "/dataFlows/steps/09308a34-a85b-4767-94f0-5968a9329b23",
			"type": "application/vnd.sas.data.flow.step.summary"
		},
		{
			"method": "GET",
			"rel": "up",
			"href": "/dataFlows/steps",
			"uri": "/dataFlows/steps",
			"type": "application/vnd.sas.collection",
			"itemType": "application/vnd.sas.data.flow.step.summary"
		},
		{
			"method": "PUT",
			"rel": "update",
			"href": "/dataFlows/steps/09308a34-a85b-4767-94f0-5968a9329b23",
			"uri": "/dataFlows/steps/09308a34-a85b-4767-94f0-5968a9329b23",
			"type": "application/vnd.sas.data.flow.step",
			"responseType": "application/vnd.sas.data.flow.step"
		},
		{
			"method": "DELETE",
			"rel": "delete",
			"href": "/dataFlows/steps/09308a34-a85b-4767-94f0-5968a9329b23",
			"uri": "/dataFlows/steps/09308a34-a85b-4767-94f0-5968a9329b23"
		},
		{
			"method": "POST",
			"rel": "copy",
			"href": "/dataFlows/steps/09308a34-a85b-4767-94f0-5968a9329b23/copy",
			"uri": "/dataFlows/steps/09308a34-a85b-4767-94f0-5968a9329b23/copy",
			"responseType": "application/vnd.sas.data.flow.step"
		},
		{
			"method": "GET",
			"rel": "transferExport",
			"href": "/dataFlows/steps/09308a34-a85b-4767-94f0-5968a9329b23",
			"uri": "/dataFlows/steps/09308a34-a85b-4767-94f0-5968a9329b23",
			"responseType": "application/vnd.sas.transfer.object"
		},
		{
			"method": "PUT",
			"rel": "transferImportUpdate",
			"href": "/dataFlows/steps/09308a34-a85b-4767-94f0-5968a9329b23",
			"uri": "/dataFlows/steps/09308a34-a85b-4767-94f0-5968a9329b23",
			"type": "application/vnd.sas.transfer.object",
			"responseType": "application/vnd.sas.summary"
		}
	],
	"metadataVersion": 0,
	"version": 2,
	"type": "code",
	"flowMetadata": {
		"inputPorts": [
			{
				"name": "inTable",
				"displayName": "inTable",
				"localDisplayName": "inTable",
				"minEntries": 1,
				"maxEntries": 1,
				"defaultEntries": 0,
				"type": "table"
			}
		],
		"outputPorts": [
			{
				"name": "outTable",
				"displayName": "outTable",
				"localDisplayName": "outTable",
				"minEntries": 1,
				"maxEntries": 1,
				"defaultEntries": 0,
				"type": "table",
				"requiresStructure": false,
				"supportsView": false
			}
		]
	},
	"ui": "{\n\t\"showPageContentOnly\": true,\n\t\"pages\": [\n\t\t{\n\t\t\t\"id\": \"inPage\",\n\t\t\t\"type\": \"page\",\n\t\t\t\"label\": \"Rank Options\",\n\t\t\t\"children\": [\n\t\t\t\t{\n\t\t\t\t\t\"id\": \"inTable\",\n\t\t\t\t\t\"type\": \"inputtable\",\n\t\t\t\t\t\"label\": \"Select input table:\",\n\t\t\t\t\t\"required\": true\n\t\t\t\t},\n\t\t\t\t{\n\t\t\t\t\t\"id\": \"rankBy\",\n\t\t\t\t\t\"type\": \"columnselector\",\n\t\t\t\t\t\"label\": \"Select a column to rank:\",\n\t\t\t\t\t\"table\": \"inTable\",\n\t\t\t\t\t\"columntype\": \"n\",\n\t\t\t\t\t\"min\": 1,\n\t\t\t\t\t\"max\": 1,\n\t\t\t\t\t\"include\": null\n\t\t\t\t},\n\t\t\t\t{\n\t\t\t\t\t\"id\": \"outTable\",\n\t\t\t\t\t\"type\": \"outputtable\",\n\t\t\t\t\t\"label\": \"Specify the output table:\",\n\t\t\t\t\t\"required\": true\n\t\t\t\t},\n\t\t\t\t{\n\t\t\t\t\t\"id\": \"createNewVariables\",\n\t\t\t\t\t\"type\": \"checkbox\",\n\t\t\t\t\t\"label\": \"Create a new column for the ranked column\"\n\t\t\t\t}\n\t\t\t]\n\t\t}\n\t],\n\t\"syntaxversion\": \"1.3.0\"\n}",
	"localUi": "{\"pages\":[{\"children\":[{\"id\":\"inTable\",\"label\":\"Select input table:\",\"required\":true,\"type\":\"inputtable\"},{\"columntype\":\"n\",\"id\":\"rankBy\",\"include\":null,\"label\":\"Select a column to rank:\",\"max\":1,\"min\":1,\"table\":\"inTable\",\"type\":\"columnselector\"},{\"id\":\"outTable\",\"label\":\"Specify the output table:\",\"required\":true,\"type\":\"outputtable\"},{\"id\":\"createNewVariables\",\"label\":\"Create a new column for the ranked column\",\"type\":\"checkbox\"}],\"id\":\"inPage\",\"label\":\"Rank Options\",\"type\":\"page\"}],\"showPageContentOnly\":true,\"syntaxversion\":\"1.3.0\"}",
	"templates": {
		"SAS": "/* SAS templated code goes here */\nproc rank data=&inTable out-%outTable;\n\tvar &rankBy_1_name;\n\t%if %createNewVariables =1 %then do;\n\t\tranks rank_&rankBy_1_name;\n\t%end;\nrun;"
	}
}
```

### Custom Step Example 2: Documenting SAS Studio Flows with Azure OpenAI

This example demonstrates a custom step that processes a .flw file, sends its content to an Azure OpenAI endpoint, and generates documentation for the flow.

Inputs:

- `.flw` file (SAS Studio flow file).
- folder location where `.env` file is stored (Azure OpenAI configuration).
- `system_message.txt` (system message for the API).

Outputs:

- `.txt` file containing the generated documentation in Markdown format.

#### Prompt UI 2


```json
{
	"showPageContentOnly": true,
	"pages": [
		{
			"id": "pageOptions",
			"type": "page",
			"label": "Options",
			"children": [
				{
					"id": "titleText",
					"type": "text",
					"text": "Generate SAS Studio flows documentation with Azure OpenAI",
					"visible": ""
				},
				{
					"id": "inputsSection",
					"type": "section",
					"label": "Inputs",
					"open": true,
					"visible": "",
					"children": []
				},
				{
					"id": "inputsText",
					"type": "text",
					"text": "Inputs: Choose the flow to be documented (.flw file), the connection configuration for your Azure OpenAI model  (.env file with key variables), the large language model system message, instructing how to document (system_message.txt file).",
					"visible": "",
					"indent": 1
				},
				{
					"id": "input_file",
					"type": "path",
					"label": "Select the flow to be documented (.flw file):",
					"pathtype": "file",
					"placeholder": "Car_Make_with_SubFlows.flw",
					"required": false,
					"visible": "",
					"indent": 1
				},
				{
					"id": "env_file_folder",
					"type": "path",
					"label": "Folder where the .env file is stored:",
					"pathtype": "folder",
					"placeholder": "/azuredm/code",
					"required": false,
					"visible": "",
					"indent": 1
				},
				{
					"id": "messages",
					"type": "path",
					"label": "File where the LLM system message is stored:",
					"pathtype": "file",
					"placeholder": "system_message.txt",
					"required": false,
					"visible": "",
					"indent": 1
				},
				{
					"id": "outputsSection",
					"type": "section",
					"label": "Outputs",
					"open": true,
					"visible": "",
					"children": []
				},
				{
					"id": "outputext",
					"type": "text",
					"text": "Output: choose the output file where the flow documentation is written (.txt file).",
					"visible": "",
					"indent": 1
				},
				{
					"id": "output_file",
					"type": "path",
					"label": "Write the output to (.txt file):",
					"pathtype": "file",
					"placeholder": "Car_Make_with_SubFlows_.txt",
					"required": false,
					"visible": "",
					"indent": 1
				}
			]
		},
		{
			"id": "about",
			"type": "page",
			"label": "About",
			"children": [
				{
					"id": "text3",
					"type": "text",
					"text": "LLM - Document Flows with Azure OpenAI.step\n================================\nThis custom step processes a selected SAS Studio .flw file, sends its content to an Azure OpenAI endpoint, and generates documentation for the flow. The output is written in Markdown saved to a .txt file.\n",
					"visible": ""
				},
				{
					"id": "prerequisitesSection",
					"type": "section",
					"label": "Pre-requisites",
					"open": true,
					"visible": "",
					"children": []
				},
				{
					"id": "prerequisitesText",
					"type": "text",
					"text": "1. Access to an Azure subscription.\n2. An Azure OpenAI resource deployed.\n3. A model deployed, such as GPT-4o.\nTested with GPT-4o API version 2024-05-01 and SAS Viya LTS 2024.09.",
					"visible": "",
					"indent": 1
				},
				{
					"id": "documentationSection",
					"type": "section",
					"label": "Documentation",
					"open": true,
					"visible": "",
					"children": []
				},
				{
					"id": "documentationText",
					"type": "text",
					"text": "\nInputs:\n1. Flow File (.flw): The path to the SAS Studio flow file to be documented.\n2. Environment File Folder (.env): The folder containing the .env file for Azure OpenAI configuration.\n3. System Message File (system_message.txt): A .txt file containing the system message for the OpenAI API.\n\nOutput:\n1. The .txt file where the documentation will be saved. The file contains Markdown-formatted text.\n\nHow It Works:\n1. The .flw file content is read and prepared for processing.\n2. A system message is read from the messages file.\n3. The .env file is loaded to retrieve Azure OpenAI credentials and endpoint details.\n4. The .flw file content and system message are sent to the Azure OpenAI API for processing.\n5. The API response, which contains the generated documentation, is saved to the specified .txt output file.\n\nSteps:\n1. Choose the inputs.\n2. Specify the .txt file to save the documentation.\n3. Run the step to generate the documentation.\n\n--- system_message.txt sample file --- \nYou are an AI assistant specialized in documenting SAS Studio flows (flw files) for Governance and Compliance purposes. Your task is to analyze a SAS Studio flow, including its visual representation (image) and the underlying code, to generate detailed and precise documentation. Follow these steps:\n\nSummary: Start with a high-level summary of the SAS Studio flow. Include:\nThe purpose of the flow.\nKey inputs (datasets or files used).\nKey outputs (datasets or files generated).\nA brief description of the transformations or processes applied.\nStep-by-Step Explanation: Break down the flow into individual steps and explain:\nThe purpose of each step.\nInputs and outputs for the step.\nAny transformations, joins, filters, or aggregations applied.\nDetailed Column Mapping Table: Create a table titled \"Detailed Column Mapping for Each Step in the Flow\". For each step:\nList all columns involved.\nSpecify their names before and after the step.\nHighlight any changes applied to the columns (e.g., renaming, transformations, additions, deletions).\nUse the following table format:\nStep\tColumn Name\tChanges (e.g., renamed, transformed, added, deleted)\tDescription of Change (if applicable)\nStep Name/ID\tColumn_Name_1\tRenamed to New_Column_Name_1\tColumn renamed for consistency\nStep Name/ID\tColumn_Name_2\tTransformed\tApplied log transformation\nStep Name/ID\tColumn_Name_3\tDeleted\tColumn removed as it is no longer needed\n\nGovernance and Compliance Notes: Add a section at the end to highlight:\nAny potential compliance concerns (e.g., PII data transformations, data lineage issues).\nSuggestions for improving documentation or flow design for better governance.",
					"visible": "",
					"indent": 1
				},
				{
					"id": "changelogSection",
					"type": "section",
					"label": "Changelog",
					"open": true,
					"visible": "",
					"children": []
				},
				{
					"id": "changelogText",
					"type": "text",
					"text": "* Version 1.0 (07FEB2025)\n- Initial version",
					"visible": "",
					"indent": 1
				}
			]
		}
	],
	"values": {
		"input_file": "",
		"env_file_folder": "",
		"messages": "",
		"output_file": ""
	}
}
```

#### Program 2

```sas

/* Run the Python code within PROC PYTHON */
proc python;
   submit;

# The following contains the Python Code to be written inside a PROC PYTHON.

import os
from dotenv import load_dotenv
import requests

# Get variables from SAS
env_file_folder = SAS.symget('env_file_folder')
input_file = SAS.symget('input_file')
output_file = SAS.symget('output_file')
messages = SAS.symget('messages')

# Override for testing
#env_file_folder = 'sasserver:/azuredm/code'
#input_file = 'sasserver:/azuredm/code/flows/Car_Make_with_SubFlows.flw'
#output_file = 'sasserver:/azuredm/code/Car_Make_with_SubFlows_.txt'
#messages = 'sasserver:/azuredm/code/system_message.txt'

# Extract from SAS variables to resolve to Python paths
env_file_folder = env_file_folder.replace('sasserver:', '')
input_file = input_file.replace('sasserver:', '')
output_file = output_file.replace('sasserver:', '')
messages = messages.replace('sasserver:', '')

# For debugging only
print("env_file_folder:", env_file_folder)
print("input_file:", input_file)
print("output_file:", output_file)
print("messages:", messages)

# Folder where .env file is stored
os.chdir(env_file_folder)

def process_file(input_file, output_file):
    try:
        # Read the input file
        with open(input_file, 'r', encoding='utf-8') as f:
            content = f.read()

        # Print the length of the string to verify
        print(f"The length of the SAS Studio flow as a string is: {len(content)}")

        # Read LLM system message
        with open(messages, 'r', encoding="utf8") as file:
            system_message = file.read()

        # Get configuration settings
        load_dotenv()
        azure_oai_endpoint = os.getenv("AZURE_OAI_ENDPOINT")
        azure_oai_key = os.getenv("AZURE_OAI_KEY")
        azure_oai_deployment = os.getenv("AZURE_OAI_DEPLOYMENT")
        azure_oai_model = azure_oai_deployment
        api_version = '2024-05-01-preview'  # this might change in the future

        # Request Header
        headers = {
            "Content-Type": "application/json",
            "api-key": azure_oai_key,
        }

        # Payload for the request
        payload = {
            "messages": [
                {
                    "role": "system",
                    "content": [
                        {
                            "type": "text",
                            "text": f"{system_message}\n"
                        }
                    ]
                },
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": f"Document the following SAS Studio flow. FLW file content: --- {content} ---"
                        }
                    ]
                },
            ],
            "temperature": 0.5,
            "top_p": 0.9,
            "max_tokens": 2500
        }

        ENDPOINT = f"{azure_oai_endpoint}openai/deployments/{azure_oai_model}/chat/completions?api-version={api_version}"

        # Send the request
        try:
            response = requests.post(ENDPOINT, headers=headers, json=payload)
            response.raise_for_status()  # Will raise an HTTPError if the HTTP request returned an unsuccessful status code
        except requests.RequestException as e:
            raise SystemExit(f"Failed to make the request. Error: {e}")

        # Handle the response as needed (e.g., print or process)
        response_data = response.json()

        # Extract the text content
        # This will vary based on the APIs JSON structure
        text_content = response_data['choices'][0]['message']['content']
        print("\n Response: \n" + text_content + "\n")

        # Write the response to a file
        with open(output_file, mode="w", encoding="utf8") as results_file:
            results_file.write(text_content)

        print(f"\nResponse written to {output_file}\n")

    except Exception as e:
        error_message = f"Error: {e}"
        print(error_message)
        # Pass the error message back to SAS log
        SAS.submit(f'data _null_; put "{error_message}"; run;')

# Run the processing function
try:
    process_file(input_file, output_file)
except Exception as e:
    error_message = f"Error: {e}"
    print(error_message)
    # Pass the error message back to SAS log
    SAS.submit(f'data _null_; put "{error_message}"; run;')

endsubmit;
run;
```

#### Full Step Code 2

```json
{
	"type": "code",
	"name": "LLM - Document Flows with Azure OpenAI.step",
	"displayName": "LLM - Document Flows with Azure OpenAI.step",
	"description": "",
	"templates": {
		"SAS": "\n/* Run the Python code within PROC PYTHON */\nproc python;\n   submit;\n\n# The following contains the Python Code to be written inside a PROC PYTHON.\n\nimport os\nfrom dotenv import load_dotenv\nimport requests\n\n# Get variables from SAS\nenv_file_folder = SAS.symget('env_file_folder')\ninput_file = SAS.symget('input_file')\noutput_file = SAS.symget('output_file')\nmessages = SAS.symget('messages')\n\n# Override for testing\n#env_file_folder = 'sasserver:/azuredm/code'\n#input_file = 'sasserver:/azuredm/code/flows/Car_Make_with_SubFlows.flw'\n#output_file = 'sasserver:/azuredm/code/Car_Make_with_SubFlows_.txt'\n#messages = 'sasserver:/azuredm/code/system_message.txt'\n\n# Extract from SAS variables to resolve to Python paths\nenv_file_folder = env_file_folder.replace('sasserver:', '')\ninput_file = input_file.replace('sasserver:', '')\noutput_file = output_file.replace('sasserver:', '')\nmessages = messages.replace('sasserver:', '')\n\n# For debugging only\nprint(\"env_file_folder:\", env_file_folder)\nprint(\"input_file:\", input_file)\nprint(\"output_file:\", output_file)\nprint(\"messages:\", messages)\n\n# Folder where .env file is stored\nos.chdir(env_file_folder)\n\ndef process_file(input_file, output_file):\n    try:\n        # Read the input file\n        with open(input_file, 'r', encoding='utf-8') as f:\n            content = f.read()\n\n        # Print the length of the string to verify\n        print(f\"The length of the SAS Studio flow as a string is: {len(content)}\")\n\n        # Read LLM system message\n        with open(messages, 'r', encoding=\"utf8\") as file:\n            system_message = file.read()\n\n        # Get configuration settings\n        load_dotenv()\n        azure_oai_endpoint = os.getenv(\"AZURE_OAI_ENDPOINT\")\n        azure_oai_key = os.getenv(\"AZURE_OAI_KEY\")\n        azure_oai_deployment = os.getenv(\"AZURE_OAI_DEPLOYMENT\")\n        azure_oai_model = azure_oai_deployment\n        api_version = '2024-05-01-preview'  # this might change in the future\n\n        # Request Header\n        headers = {\n            \"Content-Type\": \"application/json\",\n            \"api-key\": azure_oai_key,\n        }\n\n        # Payload for the request\n        payload = {\n            \"messages\": [\n                {\n                    \"role\": \"system\",\n                    \"content\": [\n                        {\n                            \"type\": \"text\",\n                            \"text\": f\"{system_message}\\n\"\n                        }\n                    ]\n                },\n                {\n                    \"role\": \"user\",\n                    \"content\": [\n                        {\n                            \"type\": \"text\",\n                            \"text\": f\"Document the following SAS Studio flow. FLW file content: --- {content} ---\"\n                        }\n                    ]\n                },\n            ],\n            \"temperature\": 0.5,\n            \"top_p\": 0.9,\n            \"max_tokens\": 2500\n        }\n\n        ENDPOINT = f\"{azure_oai_endpoint}openai/deployments/{azure_oai_model}/chat/completions?api-version={api_version}\"\n\n        # Send the request\n        try:\n            response = requests.post(ENDPOINT, headers=headers, json=payload)\n            response.raise_for_status()  # Will raise an HTTPError if the HTTP request returned an unsuccessful status code\n        except requests.RequestException as e:\n            raise SystemExit(f\"Failed to make the request. Error: {e}\")\n\n        # Handle the response as needed (e.g., print or process)\n        response_data = response.json()\n\n        # Extract the text content\n        # This will vary based on the APIs JSON structure\n        text_content = response_data['choices'][0]['message']['content']\n        print(\"\\n Response: \\n\" + text_content + \"\\n\")\n\n        # Write the response to a file\n        with open(output_file, mode=\"w\", encoding=\"utf8\") as results_file:\n            results_file.write(text_content)\n\n        print(f\"\\nResponse written to {output_file}\\n\")\n\n    except Exception as e:\n        error_message = f\"Error: {e}\"\n        print(error_message)\n        # Pass the error message back to SAS log\n        SAS.submit(f'data _null_; put \"{error_message}\"; run;')\n\n# Run the processing function\ntry:\n    process_file(input_file, output_file)\nexcept Exception as e:\n    error_message = f\"Error: {e}\"\n    print(error_message)\n    # Pass the error message back to SAS log\n    SAS.submit(f'data _null_; put \"{error_message}\"; run;')\n\nendsubmit;\nrun;"
	},
	"properties": {},
	"ui": "{\n\t\"showPageContentOnly\": true,\n\t\"pages\": [\n\t\t{\n\t\t\t\"id\": \"pageOptions\",\n\t\t\t\"type\": \"page\",\n\t\t\t\"label\": \"Options\",\n\t\t\t\"children\": [\n\t\t\t\t{\n\t\t\t\t\t\"id\": \"titleText\",\n\t\t\t\t\t\"type\": \"text\",\n\t\t\t\t\t\"text\": \"Generate SAS Studio flows documentation with Azure OpenAI\",\n\t\t\t\t\t\"visible\": \"\"\n\t\t\t\t},\n\t\t\t\t{\n\t\t\t\t\t\"id\": \"inputsSection\",\n\t\t\t\t\t\"type\": \"section\",\n\t\t\t\t\t\"label\": \"Inputs\",\n\t\t\t\t\t\"open\": true,\n\t\t\t\t\t\"visible\": \"\",\n\t\t\t\t\t\"children\": []\n\t\t\t\t},\n\t\t\t\t{\n\t\t\t\t\t\"id\": \"inputsText\",\n\t\t\t\t\t\"type\": \"text\",\n\t\t\t\t\t\"text\": \"Inputs: Choose the flow to be documented (.flw file), the connection configuration for your Azure OpenAI model  (.env file with key variables), the large language model system message, instructing how to document (system_message.txt file).\",\n\t\t\t\t\t\"visible\": \"\",\n\t\t\t\t\t\"indent\": 1\n\t\t\t\t},\n\t\t\t\t{\n\t\t\t\t\t\"id\": \"input_file\",\n\t\t\t\t\t\"type\": \"path\",\n\t\t\t\t\t\"label\": \"Select the flow to be documented (.flw file):\",\n\t\t\t\t\t\"pathtype\": \"file\",\n\t\t\t\t\t\"placeholder\": \"Car_Make_with_SubFlows.flw\",\n\t\t\t\t\t\"required\": false,\n\t\t\t\t\t\"visible\": \"\",\n\t\t\t\t\t\"indent\": 1\n\t\t\t\t},\n\t\t\t\t{\n\t\t\t\t\t\"id\": \"env_file_folder\",\n\t\t\t\t\t\"type\": \"path\",\n\t\t\t\t\t\"label\": \"Folder where the .env file is stored:\",\n\t\t\t\t\t\"pathtype\": \"folder\",\n\t\t\t\t\t\"placeholder\": \"/azuredm/code\",\n\t\t\t\t\t\"required\": false,\n\t\t\t\t\t\"visible\": \"\",\n\t\t\t\t\t\"indent\": 1\n\t\t\t\t},\n\t\t\t\t{\n\t\t\t\t\t\"id\": \"messages\",\n\t\t\t\t\t\"type\": \"path\",\n\t\t\t\t\t\"label\": \"File where the LLM system message is stored:\",\n\t\t\t\t\t\"pathtype\": \"file\",\n\t\t\t\t\t\"placeholder\": \"system_message.txt\",\n\t\t\t\t\t\"required\": false,\n\t\t\t\t\t\"visible\": \"\",\n\t\t\t\t\t\"indent\": 1\n\t\t\t\t},\n\t\t\t\t{\n\t\t\t\t\t\"id\": \"outputsSection\",\n\t\t\t\t\t\"type\": \"section\",\n\t\t\t\t\t\"label\": \"Outputs\",\n\t\t\t\t\t\"open\": true,\n\t\t\t\t\t\"visible\": \"\",\n\t\t\t\t\t\"children\": []\n\t\t\t\t},\n\t\t\t\t{\n\t\t\t\t\t\"id\": \"outputext\",\n\t\t\t\t\t\"type\": \"text\",\n\t\t\t\t\t\"text\": \"Output: choose the output file where the flow documentation is written (.txt file).\",\n\t\t\t\t\t\"visible\": \"\",\n\t\t\t\t\t\"indent\": 1\n\t\t\t\t},\n\t\t\t\t{\n\t\t\t\t\t\"id\": \"output_file\",\n\t\t\t\t\t\"type\": \"path\",\n\t\t\t\t\t\"label\": \"Write the output to (.txt file):\",\n\t\t\t\t\t\"pathtype\": \"file\",\n\t\t\t\t\t\"placeholder\": \"Car_Make_with_SubFlows_.txt\",\n\t\t\t\t\t\"required\": false,\n\t\t\t\t\t\"visible\": \"\",\n\t\t\t\t\t\"indent\": 1\n\t\t\t\t}\n\t\t\t]\n\t\t},\n\t\t{\n\t\t\t\"id\": \"about\",\n\t\t\t\"type\": \"page\",\n\t\t\t\"label\": \"About\",\n\t\t\t\"children\": [\n\t\t\t\t{\n\t\t\t\t\t\"id\": \"text3\",\n\t\t\t\t\t\"type\": \"text\",\n\t\t\t\t\t\"text\": \"LLM - Document Flows with Azure OpenAI.step\\n================================\\nThis custom step processes a selected SAS Studio .flw file, sends its content to an Azure OpenAI endpoint, and generates documentation for the flow. The output is written in Markdown saved to a .txt file.\\n\",\n\t\t\t\t\t\"visible\": \"\"\n\t\t\t\t},\n\t\t\t\t{\n\t\t\t\t\t\"id\": \"prerequisitesSection\",\n\t\t\t\t\t\"type\": \"section\",\n\t\t\t\t\t\"label\": \"Pre-requisites\",\n\t\t\t\t\t\"open\": true,\n\t\t\t\t\t\"visible\": \"\",\n\t\t\t\t\t\"children\": []\n\t\t\t\t},\n\t\t\t\t{\n\t\t\t\t\t\"id\": \"prerequisitesText\",\n\t\t\t\t\t\"type\": \"text\",\n\t\t\t\t\t\"text\": \"1. Access to an Azure subscription.\\n2. An Azure OpenAI resource deployed.\\n3. A model deployed, such as GPT-4o.\\nTested with GPT-4o API version 2024-05-01 and SAS Viya LTS 2024.09.\",\n\t\t\t\t\t\"visible\": \"\",\n\t\t\t\t\t\"indent\": 1\n\t\t\t\t},\n\t\t\t\t{\n\t\t\t\t\t\"id\": \"documentationSection\",\n\t\t\t\t\t\"type\": \"section\",\n\t\t\t\t\t\"label\": \"Documentation\",\n\t\t\t\t\t\"open\": true,\n\t\t\t\t\t\"visible\": \"\",\n\t\t\t\t\t\"children\": []\n\t\t\t\t},\n\t\t\t\t{\n\t\t\t\t\t\"id\": \"documentationText\",\n\t\t\t\t\t\"type\": \"text\",\n\t\t\t\t\t\"text\": \"\\nInputs:\\n1. Flow File (.flw): The path to the SAS Studio flow file to be documented.\\n2. Environment File Folder (.env): The folder containing the .env file for Azure OpenAI configuration.\\n3. System Message File (system_message.txt): A .txt file containing the system message for the OpenAI API.\\n\\nOutput:\\n1. The .txt file where the documentation will be saved. The file contains Markdown-formatted text.\\n\\nHow It Works:\\n1. The .flw file content is read and prepared for processing.\\n2. A system message is read from the messages file.\\n3. The .env file is loaded to retrieve Azure OpenAI credentials and endpoint details.\\n4. The .flw file content and system message are sent to the Azure OpenAI API for processing.\\n5. The API response, which contains the generated documentation, is saved to the specified .txt output file.\\n\\nSteps:\\n1. Choose the inputs.\\n2. Specify the .txt file to save the documentation.\\n3. Run the step to generate the documentation.\\n\\n--- system_message.txt sample file --- \\nYou are an AI assistant specialized in documenting SAS Studio flows (flw files) for Governance and Compliance purposes. Your task is to analyze a SAS Studio flow, including its visual representation (image) and the underlying code, to generate detailed and precise documentation. Follow these steps:\\n\\nSummary: Start with a high-level summary of the SAS Studio flow. Include:\\nThe purpose of the flow.\\nKey inputs (datasets or files used).\\nKey outputs (datasets or files generated).\\nA brief description of the transformations or processes applied.\\nStep-by-Step Explanation: Break down the flow into individual steps and explain:\\nThe purpose of each step.\\nInputs and outputs for the step.\\nAny transformations, joins, filters, or aggregations applied.\\nDetailed Column Mapping Table: Create a table titled \\\"Detailed Column Mapping for Each Step in the Flow\\\". For each step:\\nList all columns involved.\\nSpecify their names before and after the step.\\nHighlight any changes applied to the columns (e.g., renaming, transformations, additions, deletions).\\nUse the following table format:\\nStep\\tColumn Name\\tChanges (e.g., renamed, transformed, added, deleted)\\tDescription of Change (if applicable)\\nStep Name/ID\\tColumn_Name_1\\tRenamed to New_Column_Name_1\\tColumn renamed for consistency\\nStep Name/ID\\tColumn_Name_2\\tTransformed\\tApplied log transformation\\nStep Name/ID\\tColumn_Name_3\\tDeleted\\tColumn removed as it is no longer needed\\n\\nGovernance and Compliance Notes: Add a section at the end to highlight:\\nAny potential compliance concerns (e.g., PII data transformations, data lineage issues).\\nSuggestions for improving documentation or flow design for better governance.\",\n\t\t\t\t\t\"visible\": \"\",\n\t\t\t\t\t\"indent\": 1\n\t\t\t\t},\n\t\t\t\t{\n\t\t\t\t\t\"id\": \"changelogSection\",\n\t\t\t\t\t\"type\": \"section\",\n\t\t\t\t\t\"label\": \"Changelog\",\n\t\t\t\t\t\"open\": true,\n\t\t\t\t\t\"visible\": \"\",\n\t\t\t\t\t\"children\": []\n\t\t\t\t},\n\t\t\t\t{\n\t\t\t\t\t\"id\": \"changelogText\",\n\t\t\t\t\t\"type\": \"text\",\n\t\t\t\t\t\"text\": \"* Version 1.0 (07FEB2025)\\n- Initial version\",\n\t\t\t\t\t\"visible\": \"\",\n\t\t\t\t\t\"indent\": 1\n\t\t\t\t}\n\t\t\t]\n\t\t}\n\t],\n\t\"syntaxversion\": \"1.3.0\",\n\t\"values\": {\n\t\t\"input_file\": \"\",\n\t\t\"env_file_folder\": \"\",\n\t\t\"messages\": \"\",\n\t\t\"output_file\": \"\"\n\t}\n}",
	"flowMetadata": {
		"inputPorts": [],
		"outputPorts": []
	}
}
```

## Prompt UI List

Here’s a list of elements you can use in the Prompt UI: inputtable, outputtable, path, checkbox, dropdown, text, etc.


```json
{
	"showPageContentOnly": true,
	"pages": [
		{
			"id": "pageOptions",
			"type": "page",
			"label": "Options",
			"children": [
				{
					"id": "fileorfolderselector1",
					"type": "path",
					"label": "This is a input or output folder selector",
					"pathtype": "folder",
					"placeholder": "/gelcontent",
					"required": false,
					"visible": ""
				},
				{
					"id": "fileorfolderselector1_1",
					"type": "path",
					"label": "This is a input or output file selector",
					"pathtype": "file",
					"placeholder": "/gelcontent/file.txt",
					"required": false,
					"visible": ""
				},
				{
					"id": "textarea1",
					"type": "textarea",
					"label": "This is a text area",
					"placeholder": "some written text",
					"required": false,
					"visible": ""
				},
				{
					"id": "inputfield1",
					"type": "textfield",
					"label": "This is a text field",
					"placeholder": "input_text",
					"required": false,
					"visible": ""
				},
				{
					"id": "inputfield1_1",
					"type": "numberfield",
					"label": "This is a numeric field",
					"placeholder": "",
					"required": false,
					"max": 1008,
					"min": 0,
					"excludemin": false,
					"excludemax": false,
					"visible": ""
				},
				{
					"id": "link1",
					"type": "link",
					"label": "This is a link",
					"url": "https://documentation.sas.com/doc/en/sasstudiocdc/v_059/webeditorcdc/webeditorsteps/n007efeloqjzqkn1sr9ij1o3ispz.htm",
					"visible": ""
				},
				{
					"id": "dropdown1",
					"type": "dropdown",
					"label": "This is a Drop-down list",
					"items": [
						{
							"value": "option_1"
						},
						{
							"value": "option_2"
						}
					],
					"required": false,
					"placeholder": "",
					"visible": ""
				},
				{
					"id": "datetime1",
					"type": "datetime",
					"label": "This is a Date and time picker",
					"required": false,
					"visible": "",
					"min": "",
					"max": "",
					"subtype": "datetime"
				},
				{
					"id": "list1",
					"type": "list",
					"items": [
						{
							"value": "element_1"
						},
						{
							"value": "element_2"
						}
					],
					"label": "This is a list",
					"max": null,
					"min": null,
					"visible": ""
				},
				{
					"id": "optiontable1",
					"type": "optiontable",
					"label": "This is an option table",
					"required": false,
					"tabletype": "authorboth",
					"initialrowcount": 1,
					"min": null,
					"max": null,
					"showcolumnlabels": true,
					"columns": [
						{
							"id": "inputfield1",
							"type": "numberfield",
							"required": false,
							"placeholder": "",
							"value": null,
							"integer": false,
							"max": null,
							"min": null,
							"excludemax": false,
							"excludemin": false,
							"label": "Input field label 1"
						}
					],
					"repeatref": null
				},
				{
					"id": "text1",
					"type": "text",
					"text": "This is informational text.",
					"visible": ""
				},
				{
					"id": "inputtable1",
					"type": "inputtable",
					"label": "This is an input table",
					"required": true,
					"placeholder": "",
					"visible": ""
				},
				{
					"id": "columnselector1",
					"type": "columnselector",
					"label": "This is Column selector",
					"include": null,
					"order": false,
					"columntype": "a",
					"max": null,
					"min": null,
					"visible": "",
					"table": "inputtable1"
				},
				{
					"id": "newcolumn1",
					"type": "newcolumn",
					"label": "This is a new column",
					"required": false,
					"placeholder": "",
					"hideproperties": false,
					"readonly": false
				},
				{
					"id": "outputtable1",
					"type": "outputtable",
					"label": "This is an output table",
					"required": true,
					"placeholder": "WORK.MYTABLE",
					"visible": ""
				}
			]
		}
	],
	"values": {
		"fileorfolderselector1": "",
		"fileorfolderselector1_1": "",
		"textarea1": "",
		"inputfield1": "",
		"inputfield1_1": null,
		"dropdown1": null,
		"datetime1": "",
		"list1": [],
		"optiontable1": null,
		"inputtable1": {
			"library": "SASHELP",
			"table": "CLASS"
		},
		"columnselector1": [],
		"newcolumn1": {},
		"outputtable1": {
			"library": "",
			"table": ""
		}
	}
}
```

## User Instructions

When creating a custom step, users should:

- Specify the inputs and outputs.
- Define the logic in either SAS or Python.
- Indicate whether they need the **full .step code**, the Prompt UI, or the Program.

### Full Step Code

If requested to provide the full .step file, extract only the JSON block that starts with `{"type": "code", "name": "cs2.step"` and ends with the corresponding closing brace `}`. Do not include any additional explanation, text, or formatting. Return only the JSON content.

### Standards

- Include a page labeled **Options** for controls.
- Include an **About** page explaining the purpose of the custom step.


## Note

> Tested with gpt-4o, version 2024-11-20.
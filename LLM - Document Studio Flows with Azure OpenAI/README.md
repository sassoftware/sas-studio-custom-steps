
# LLM - Document Flows with Azure OpenAI Custom Step

## Description

The "LLM - Document Flows with Azure OpenAI" custom step uses Azure OpenAI’s large language models, such as GPT-4o, to automatically create documentation for a SAS Studio flow.

## Video and Blog Post

* [Automate SAS Studio Flows Documentation with Azure OpenAI in a Custom Step](https://communities.sas.com/t5/SAS-Communities-Library/Automate-SAS-Studio-Flows-Documentation-with-Azure-OpenAI-in-a/ta-p/959009).

## How It Works

1. Reads and prepares the .flw file content.
2. Loads a system message from the messages file.
3. Retrieves Azure OpenAI credentials and endpoint details from the .env file.
4. Sends the .flw file content and system message to the Azure OpenAI API.
5. Saves the API response (generated documentation) to a specified .txt output file.

Steps:

1. Add the custom step to a SAS Studio flow.
2. Choose the inputs.
3. Specify the output, the .txt file for the documentation.
4. Run the flow.

The LLM uses 2500 tokens for documentation by default. Adjust the parameter `"max_tokens": 2500` in the Python program to change this limit.

## Prerequisites

### 1. SAS Viya

a. A working SAS Viya environment with Python installed and configured. Tested on SAS Viya LTS version 2024.09 and Stable version 2025.01.
b. Required Python libraries:

  - `python-dotenv`: Loads environment variables from `.env` file.
  - `requests`: Sends API requests to Azure OpenAI.

c. Display Hidden Files: Enable hidden file visibility in SAS Studio via Options > Preferences > General > check Display hidden files.

### 2. Azure OpenAI Resource

- **Azure Subscription**: Active subscription required.
- **Deployed GPT-4o Model**: Set up an Azure OpenAI resource and deploy a GPT-4o model. Details needed:
  - Endpoint URL
  - API Key
  - Deployment Name

### 3. Environment Configuration (.env File)

Create a `.env` file with:

```plaintext
AZURE_OAI_ENDPOINT='https://my_endpoint.openai.azure.com/' # change my_prefix
AZURE_OAI_KEY='my_api_key' # change my_key
AZURE_OAI_DEPLOYMENT='gpt-4o' # change to match your deployment name
```

Example available at [extras/.env.sample.txt](extras/.env.sample.txt).

### 4. System Message File

A `system_message.txt` file shapes the documentation by guiding the LLM. It defines structure, detail level, and focus areas. Example available at [extras/system_message.txt](extras/system_message.txt).

### 5. Output Location

Specify a file path for the generated documentation. Ensure write permissions.

---

## User Interface

### Options Tab

![Options](img/LLM%20-%20Document%20Flows%20with%20Azure%20OpenAI%20-%20Options.png)

### About Tab

![About](img/LLM%20-%20Document%20Flows%20with%20Azure%20OpenAI%20-%20About.png)

## Usage

1. Add the custom step to a SAS Studio flow.

2. On the Options tab:

   ![Usage example](img/LLM%20-%20Document%20Flows%20with%20Azure%20OpenAI%20-%20example.png)

### Inputs and Outputs

#### Required Inputs

1. **Flow to be documented (.flw file)**: Full path to the SAS Studio flow file to be documented. Example: document `Flow.flw` stored in `sasserver:/azuredm/code/Flow.flw`.
2. **Folder for the .env file**: Directory containing the `.env` file for the Azure OpenAI connection.
3. **File for LLM system message (system_message.txt)**: Path to the `system_message.txt` file containing the system message.

#### Required Outputs

1. **Output file (.txt)**: Path to save the SAS Studio flow documentation. The file contains Markdown-formatted text.

---

Run the SAS Studio flow.

### Expected Results

- Documentation saved in a .txt file.

  ![Expected Result A](img/LLM%20-%20Document%20Flows%20with%20Azure%20OpenAI%20-%20Expected%20Result%20A.png)

  ![Expected Result B](img/LLM%20-%20Document%20Flows%20with%20Azure%20OpenAI%20-%20Expected%20Result%20B.png)

- The file contains Markdown. View it with a Markdown viewer, e.g., Visual Studio Code.

  ![Expected Result C](img/LLM%20-%20Document%20Flows%20with%20Azure%20OpenAI%20-%20Expected%20Result%20C.png)

  ![Expected Result D](img/LLM%20-%20Document%20Flows%20with%20Azure%20OpenAI%20-%20Expected%20Result%20D.png)

---

## Change Log

* Version 1.1 (29JUN2025):

    * Implemented reviewer suggestions.

* Version 1.0 (09APR2025):

    * Initial version.

<!-- DCO Remediation Commit for Bogdan Teleuca <bogdan.teleuca@sas.com>

I, Bogdan Teleuca <bogdan.teleuca@sas.com>, hereby add my Signed-off-by to this commit: 795fa3edd94c81767366d793dfa6ab232d7f3179

Signed-off-by: Bogdan Teleuca <bogdan.teleuca@sas.com>   -->

<!-- DCO Remediation Commit for Bogdan Teleuca <bogdan.teleuca@sas.com>

I, Bogdan Teleuca <bogdan.teleuca@sas.com>, hereby add my Signed-off-by to this commit: 20e801a345df4f7a205f5259fd01619133e4c018
I, Bogdan Teleuca <bogdan.teleuca@sas.com>, hereby add my Signed-off-by to this commit: 91f85802491ce013eb55798d67b85837790e7aea

Signed-off-by: Bogdan Teleuca <bogdan.teleuca@sas.com> -->

<!-- DCO Remediation Commit for bteleuca <bogdan.teleuca@gmail.com>

I, bteleuca <bogdan.teleuca@gmail.com>, hereby add my Signed-off-by to this commit: c410690a6e255a1cad04a2ad7350c22f3d77b2e4
I, bteleuca <bogdan.teleuca@gmail.com>, hereby add my Signed-off-by to this commit: bdd96f1407f9f104118b8a57f6725e1fbc3f9e29
I, bteleuca <bogdan.teleuca@gmail.com>, hereby add my Signed-off-by to this commit: 0e2d6cae6af26f4133ec622a987b32ce60f48ca7

Signed-off-by: bteleuca <bogdan.teleuca@gmail.com> -->
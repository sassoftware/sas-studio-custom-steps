# LLM - Custom Step Generator with Azure OpenAI

## Description

The LLM Custom Step Generator is a tool that leverages Azure OpenAI’s GPT-4o to automatically create fully functional custom steps for SAS Studio flows. By providing a detailed prompt describing the desired logic, along with configuration files for accessing the Azure OpenAI API, the generator produces a tailored custom step file.

This file includes the necessary code (in Python or SAS), input/output configurations, and a user interface for integration into flows. The generator simplifies and accelerates the creation of custom steps, enabling users to automate complex tasks like data anonymization, table merging, or advanced data summarization with minimal effort.

## Video and Blog Post

Watch the video and read the post [LLM Custom Step Generator in SAS Studios](https://communities.sas.com/t5/SAS-Communities-Library/LLM-Custom-Step-Generator-in-SAS-Studio/ta-p/961986) to find out more.


## Pre-requisites

To successfully use the LLM Custom Step Generator, ensure the following prerequisites are in place:

### 1. Azure OpenAI Resource

- **Azure Subscription**: An active Azure subscription is required to create and manage OpenAI resources.
- **Deployed GPT-4o Model**: Set up an Azure OpenAI resource and deploy a GPT-4o model. Note the following details for integration:
  - Endpoint URL
  - API Key
  - Deployment Name

## 2. Environment Configuration (.env File)

- Create a `.env` file to store environment variables needed for API access. This file should include:

```plaintext
AZURE_OAI_ENDPOINT='https://my_endpoint.openai.azure.com/'
AZURE_OAI_KEY='your_api_key'
AZURE_OAI_DEPLOYMENT='gpt-4'
```

You can find an example in [extras/.env.sample.txt](extras/.env.sample.txt).

## 3. System Message File

- A system message file provides context to the LLM for generating custom steps. It should include:
  - A description of what a custom step is.
  - Examples of custom step logic written in Python and SAS.
  - Guidelines for structuring the output (e.g., prompt UI, program, and `.step` file).
- This file acts as an "instruction manual" for the LLM, ensuring accurate and relevant output.

You can find an example in [extras/cs2_system_message_new.md](extras/cs2_system_message_new.md).

## 4. Python Dependencies

- Install the following Python libraries in the Python instance accessed in SAS Studio, to enable interaction with the Azure OpenAI API:
  - `python-dotenv`: To load environment variables from the `.env` file.
  - `requests`: To send API requests to the Azure OpenAI service.

## 5. Output Location

- Specify a directory or file path where the generated custom step code will be saved. Ensure the location has appropriate write permissions.

## 6. SAS Studio Environment

- A working SAS Studio environment is required to upload and test the generated custom step file (`.step`). The custom step was tested with SAS Viya LTS 2025.03 and Stable 2024.09.

## 7. Detailed Prompt

- Provide a clear and comprehensive description of the custom step logic, including:
  - **Inputs**: Specify the data or files the custom step will use.
  - **Outputs**: Define the expected output, such as a file or data set.
  - **Desired Functionality**: Clearly describe the logic or process the custom step should perform.
- This prompt serves as the key input for the LLM to generate the custom step.

---

## User Interface

* ### Options tab ###

    ![Options](img/LLM%20-%20Custom%20Step%20Generator%20-%20Options.png)

* ### About tab ###

   ![About](img/LLM%20-%20Custom%20Step%20Generator%20-%20About.png)

## Requirements

Tested on Viya version LTS 2025.03 and Stable 2024.09.

## Usage

The **LLM Custom Step Generator** is a tool that leverages Azure OpenAI's GPT-4o to create custom steps for SAS Studio workflows. These custom steps can automate tasks such as data processing, transformation, or documentation generation.

This tab provides instructions on how to use the generator, along with details about the expected inputs and outputs.

---

Steps:

1. **Prepare the Environment**:
   - Ensure you have access to an Azure OpenAI resource and the necessary `.env` file for configuration.
   - Install required Python dependencies (`python-dotenv`, `requests`).

2. **Define the Prompt**:
   - Write a detailed description of the custom step logic, including:
     - Inputs (e.g., data files, table names).
     - Outputs (e.g., result files, tables).
     - The specific functionality or logic to be implemented (e.g., anonymization, merging, summarization).
   - Example Prompt:
     *"Create a custom step that reads an input CSV file, anonymizes personal data, and outputs the result to another CSV file. Provide the Prompt UI, the Python program, and the full `.step` file."*
    - Example Prompt:
    *"Create a custom step using SAS logic.
    The step has two table inputs, for example SASDM.PRDSAL2 and SASDM.PRDSAL3.
    The logic will merge the two tables. Then it will summarize the product sales by YEAR, MONTH, PRODUCT and sum up the ACTUAL sales. It will then create another data set NATIONAL_SALES in SASDM listing by YEAR, MONTH create a new column CHAMPION_PRODUCT equal with the top selling product."*

3. **Run the Generator**:
   - Execute the generator with your prompt and configuration files.
   - The generator will produce the custom step code in approximately 15–30 seconds.

4. **Save the Output**:
   - Save the generated code as a `.step` file.
   - Upload the `.step` file to your SAS Studio environment.

5. **Test the Custom Step**:
   - Add the custom step to a workflow.
   - Configure the step by selecting the appropriate inputs and outputs.
   - Run the workflow to verify the results.

### Usage Example

Custom Step options filled:

  ![](img/LLM%20-%20Custom%20Step%20Generator%20-%20Python%20example.png)

---

## Outputs

- **Generated Custom Step File**:
  - A `.step` file containing:
    - The program logic (e.g., Python or SAS code).
    - The user interface (Prompt UI) for configuring inputs and outputs.
- **Expected Results**:
  - A functional custom step that can be integrated into SAS Studio flows to perform the specified task.

---

## Notes

- Ensure that the `.step` file is tested in a controlled environment before deploying it to production workflows.
- For troubleshooting, review the generated code and the input prompt for any inaccuracies or missing details.
- The quality of the output depends on the clarity and specificity of the provided prompt.

---

## Change Log

* Version 1.1 (29JUN2025)
    * Reviewer suggestions.
* Version 1.0 (14FEB2025)
    * Initial version

<!-- DCO Remediation Commit for Bogdan Teleuca <bogdan.teleuca@sas.com>

I, Bogdan Teleuca <bogdan.teleuca@sas.com>, hereby add my Signed-off-by to this commit: eccafa3b97a067447bb8ba9d2935d444a99a1c0d

Signed-off-by: Bogdan Teleuca <bogdan.teleuca@sas.com>   -->

<!--
DCO Remediation Commit for Bogdan Teleuca <bogdan.teleuca@sas.com>

I, Bogdan Teleuca <bogdan.teleuca@sas.com>, hereby add my Signed-off-by to this commit: 21cdbac5f97137ffa55a86a64e23500f4b79489f
I, Bogdan Teleuca <bogdan.teleuca@sas.com>, hereby add my Signed-off-by to this commit: c15cc1fc9005882d4c01c7ca852e34072ada719b
I, Bogdan Teleuca <bogdan.teleuca@sas.com>, hereby add my Signed-off-by to this commit: 37157f4239d99fe975c1bbe15532afeee1822c5e
I, Bogdan Teleuca <bogdan.teleuca@sas.com>, hereby add my Signed-off-by to this commit: bfadd7eba3b7392a0db9fdd73cd7ab951faec722
I, Bogdan Teleuca <bogdan.teleuca@sas.com>, hereby add my Signed-off-by to this commit: 0e251a31ae07bee9d9959a15116dabb3cab28405
I, Bogdan Teleuca <bogdan.teleuca@sas.com>, hereby add my Signed-off-by to this commit: c410690a6e255a1cad04a2ad7350c22f3d77b2e4
I, Bogdan Teleuca <bogdan.teleuca@sas.com>, hereby add my Signed-off-by to this commit: bdd96f1407f9f104118b8a57f6725e1fbc3f9e29
I, Bogdan Teleuca <bogdan.teleuca@sas.com>, hereby add my Signed-off-by to this commit: 0e2d6cae6af26f4133ec622a987b32ce60f48ca7

Signed-off-by: Bogdan Teleuca <bogdan.teleuca@sas.com>

DCO Remediation Commit for bteleuca <bogdan.teleuca@gmail.com>

I, bteleuca <bogdan.teleuca@gmail.com>, hereby add my Signed-off-by to this commit: c410690a6e255a1cad04a2ad7350c22f3d77b2e4
I, bteleuca <bogdan.teleuca@gmail.com>, hereby add my Signed-off-by to this commit: bdd96f1407f9f104118b8a57f6725e1fbc3f9e29
I, bteleuca <bogdan.teleuca@gmail.com>, hereby add my Signed-off-by to this commit: 0e2d6cae6af26f4133ec622a987b32ce60f48ca7

Signed-off-by: bteleuca <bogdan.teleuca@gmail.com>

-->
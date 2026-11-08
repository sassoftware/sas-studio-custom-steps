/* SAS templated code goes here */
/* Run the Python code within PROC PYTHON */
proc python;
   submit;

# Import required libraries
import os
from dotenv import load_dotenv
import requests

# Get variables from SAS
step_description = SAS.symget('step_description')
env_file_folder = SAS.symget('envfile_folderSelector')
output_file = SAS.symget('output_step_fileSelector')
messages = SAS.symget('msgfile_fileSelector')

# Remove prefixes like 'sasserver:' from the output file path
env_file_folder = env_file_folder.replace('sasserver:', '')
messages = messages.replace('sasserver:', '')
output_file = output_file.replace('sasserver:', '')

# Change to the directory where the .env file is stored
# Replace this with the correct path if needed
os.chdir(env_file_folder)

# Load Azure OpenAI credentials from the .env file
load_dotenv()
azure_oai_endpoint = os.getenv("AZURE_OAI_ENDPOINT")
azure_oai_key = os.getenv("AZURE_OAI_KEY")
azure_oai_deployment = os.getenv("AZURE_OAI_DEPLOYMENT")
azure_oai_model = azure_oai_deployment
api_version = '2025-01-01-preview'

# Read LLM system message
with open(messages, 'r', encoding="utf8") as file:
    system_message = file.read()

# Define the payload for the OpenAI API
payload = {
    "messages": [
        {"role": "system", "content": system_message},
        {"role": "user", "content": step_description}
    ],
    "temperature": 0.5,
    "top_p": 0.9,
    "max_tokens": 3500
}

# Set the API endpoint
ENDPOINT = f"{azure_oai_endpoint}openai/deployments/{azure_oai_model}/chat/completions?api-version={api_version}"

# Define headers for the request
headers = {
    "Content-Type": "application/json",
    "api-key": azure_oai_key
}

# Send the request to Azure OpenAI
try:
    response = requests.post(ENDPOINT, headers=headers, json=payload)
    response.raise_for_status()
    response_data = response.json()

    # Extract the generated step file content
    step_file_content = response_data['choices'][0]['message']['content']

    # Write the content to the output file
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(step_file_content)

    print(f"Custom step file successfully written to: {output_file}")

except requests.RequestException as e:
    print(f"Error communicating with Azure OpenAI: {e}")
except Exception as e:
    print(f"An error occurred: {e}")
    SAS.submit(f'data _null_; put "{error_message}"; run;')

endsubmit;
run;
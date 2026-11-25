
/* Run the Python code within PROC PYTHON */  
proc python;  
   submit;  

# The following contains the Python Code to be written inside a PROC PYTHON.

import os
from dotenv import load_dotenv
import requests

# Get variables from SAS
input_file = SAS.symget('input_file')
env_file_folder = SAS.symget('env_filefolderSelector')
messages = SAS.symget('msgfile_fileSelector')
output_file = SAS.symget('output_step_fileSelector')

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
        api_version = '2025-01-01-preview'  # this might change in the future  
  
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
        # SAS.submit(f'data _null_; put "{error_message}"; run;')

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
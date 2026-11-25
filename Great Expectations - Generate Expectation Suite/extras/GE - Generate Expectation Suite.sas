%macro set_up();

%global dataPath folder disk;
%let dataPath = %sysfunc(getoption(work));

%mend set_up;

%set_up();

proc python;
   submit;

import great_expectations as gx
import pandas as pd
from great_expectations.core.yaml_handler import YAMLHandler
import json
from great_expectations.data_context.types.base import (
        DataContextConfig,
        InMemoryStoreBackendDefaults
   )
from great_expectations.data_context import EphemeralDataContext
import os

# set up data context
project_config = DataContextConfig(
   store_backend_defaults=InMemoryStoreBackendDefaults()
)
context = EphemeralDataContext(project_config=project_config)

# get data
if len(SAS.symget("excludeCol")) > 0:
   df = SAS.sd2df(SAS.symget("inTable") + '(drop=' + SAS.symget("excludeCol") + ')')
else:
   df = SAS.sd2df(SAS.symget("inTable"))

# get path to working directory
path_to_dir = SAS.symget("dataPath")
os.chdir(path_to_dir)

# set up datasource
yaml = YAMLHandler()

datasource_yaml = f"""
name: my_datasource
class_name: Datasource
module_name: great_expectations.datasource
execution_engine:
  module_name: great_expectations.execution_engine
  class_name: PandasExecutionEngine
data_connectors:
    my_runtime_data_connector:
        class_name: RuntimeDataConnector
        batch_identifiers:
            - id
"""

# add datasource to data context
context.add_datasource(**yaml.load(datasource_yaml))

# create runtime batch request (needed for pandas data source)
from great_expectations.core.batch import RuntimeBatchRequest
runtime_batch_request = RuntimeBatchRequest(
   datasource_name="my_datasource",
   data_connector_name="my_runtime_data_connector",
   data_asset_name="insert_your_data_asset_name_here",
   runtime_parameters={"batch_data": df},
   batch_identifiers={
      "id": "1",
   },
)

# check if batch request works
context.get_batch_list(batch_request=runtime_batch_request)

# get suite name from custom step
suite_name = SAS.symget("suiteName")

# create expectation suite
expectation_suite_name = suite_name
context.add_or_update_expectation_suite(expectation_suite_name=expectation_suite_name)
validator = context.get_validator(
   batch_request=runtime_batch_request, 
   expectation_suite_name=expectation_suite_name
)

# run data assistant to create expectations
data_assistant_result = context.assistants.onboarding.run(
   batch_request=runtime_batch_request
)

# get and save expectations
expectation_suite = data_assistant_result.get_expectation_suite(
   expectation_suite_name=expectation_suite_name
)
context.add_or_update_expectation_suite(expectation_suite=expectation_suite)

context = context.convert_to_file_context()

# make output table
formatted_data = {}
data = expectation_suite['expectations']
for entry in data:
   expectation = entry.get('expectation_type')
   if 'table' not in expectation:
      kwargs = entry.get('kwargs')
      column = kwargs.get('column')
   else:
      column = 'Table Expectation'
   if expectation in formatted_data:
      formatted_data[expectation].append(column)
   else:
      formatted_data[expectation] = []
      formatted_data[expectation].append(column)

for entry in formatted_data:
   formatted_data[entry] = ', '.join(map(str, formatted_data[entry]))

out_df = pd.DataFrame(list(formatted_data.items()), columns=['expectation', 'columns'])
SAS.df2sd(out_df, SAS.symget("out_expectations"))

# get location in usable format, is input as drive:/path/to/output and need to be /path/to/output
location = SAS.symget("location")
disk = location.split(":")[0]
folder = location[location.find(":")+1:]
SAS.symput("folder",folder)
SAS.symput("disk",disk)
   endsubmit;
run;

%macro clean_up();
/* move .json and .yml files to user specified location */

%if "&disk" eq "sascontent" %then %do;
   filename desti filesrvc folderPath="&folder" Filename="great_expectations.yml";
%end;
%else %do;
   filename desti "&folder./great_expectations.yml";
%end;
filename source "%sysfunc(getoption(work))/great_expectations/great_expectations.yml";
%let rc = %sysfunc(fcopy(source, desti));
filename desti clear;
filename source clear;
%if "&disk" eq "sascontent" %then %do;
   filename desti filesrvc folderPath="&folder" Filename="&suiteName..json";
%end;
%else %do;
   filename desti "&folder./&suiteName..json";
%end;
filename source "%sysfunc(getoption(work))/great_expectations/expectations/&suiteName..json";
%let rc = %sysfunc(fcopy(source, desti));
filename desti clear;
filename source clear;

%mend clean_up;

%clean_up();

proc python;
   submit;
# delete the generated great_expectations directory
import os, shutil
folder = SAS.symget("dataPath")+'/great_expectations'
for filename in os.listdir(folder):
   file_path = os.path.join(folder, filename)
   try:
      if os.path.isfile(file_path) or os.path.islink(file_path):
         os.unlink(file_path)
      elif os.path.isdir(file_path):
         shutil.rmtree(file_path)
   except Exception as e:
      print('Failed to delete %s. Reason: %s' % (file_path, e))
shutil.rmtree(folder)
   endsubmit;
run;


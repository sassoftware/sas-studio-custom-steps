%macro set_up_dirs();

%global dataPath folder disk;
%let dataPath = %sysfunc(getoption(work));

/* Great Expectations expects a specific directory structure, we create it here */
options dlcreatedir;
libname newdir "&dataPath./great_expectations";
libname check "&dataPath./great_expectations/checkpoints";
libname exp "&dataPath./great_expectations/expectations";
libname plug "&dataPath./great_expectations/plugins";
libname prof "&dataPath./great_expectations/profilers";
libname uncom "&dataPath./great_expectations/uncommitted";

/* now immediately cleanup these fake libname definitions so the user does not seem them in the UI, etc. */ 
libname newdir CLEAR;
libname check CLEAR;
libname exp CLEAR;
libname plug CLEAR;
libname prof CLEAR;
libname uncom CLEAR;


/* now turn off the dlcreatedir option */
options nodlcreatedir;

%mend set_up_dirs;

%set_up_dirs();

proc python;
   submit;
# get location in usable format, is input as drive:/path/to/output and need to be /path/to/output
location = SAS.symget("location")
folder = location[location.find(":")+1:]
disk = location.split(":")[0]
SAS.symput("folder",folder)
SAS.symput("disk",disk)
   endsubmit;
run;

%macro migrate_files();
%if "&disk" eq "sascontent" %then %do;
   filename source filesrvc folderPath="&folder" Filename="great_expectations.yml";
%end;
%else %do;
   filename source "&folder./great_expectations.yml";
%end;
filename desti "%sysfunc(getoption(work))/great_expectations/great_expectations.yml";
%let rc = %sysfunc(fcopy(source, desti));
filename source clear;
filename desti clear;
%if "&disk" eq "sascontent" %then %do;
   filename source filesrvc folderPath="&folder" Filename="&suiteName..json";
%end;
%else %do;
   filename source "&folder./&suiteName..json";
%end;
filename desti "%sysfunc(getoption(work))/great_expectations/expectations/&suiteName..json";
%let rc = %sysfunc(fcopy(source, desti));
filename desti clear;
filename source clear;
%mend migrate_files;

%migrate_files();

proc python;
   submit;

import great_expectations as gx
import os
import pandas as pd
import numpy as np
from great_expectations.core.batch import RuntimeBatchRequest
from great_expectations.core.yaml_handler import YAMLHandler
import json
import datetime

# get time of run
dt = datetime.datetime.now()
dtime = dt.strftime('%m-%d-%Y %H:%M:%S')

# change this to match path to directory
path_to_dir = SAS.symget('dataPath') # will need to change to location? may not be able to change to location...

# set up data context
context = gx.get_context(context_root_dir = path_to_dir + '/great_expectations')

# get data
df = SAS.sd2df(SAS.symget("inputTable"));

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

# set up variables for batch request
suite_name = SAS.symget("suiteName")
data_asset_name = 'your_data_asset_name'
batch_id = '1' # from batch request that made expectation suite

# set up batch request
batch_request = RuntimeBatchRequest(
   datasource_name="my_datasource",
   data_connector_name="my_runtime_data_connector",
   data_asset_name=data_asset_name,
   runtime_parameters={"batch_data": df},
   batch_identifiers={
      "id": batch_id,
   },
)

# context.run_checkpoint method looks for checkpoint file on disk.  Create one...
checkpoint_name = 'check'
checkpoint_path = os.path.abspath(f'{path_to_dir}/great_expectations/checkpoints/{checkpoint_name}.yml')
checkpoint_yml = f'''
name: {checkpoint_name}
config_version: 1
class_name: SimpleCheckpoint
expectation_suite_name: {suite_name}
runtime_configuration:
        result_format:
            result_format: COMPLETE
'''
with open(checkpoint_path, 'w') as f:
   f.write(checkpoint_yml)

# now run the checkpoint
result = context.run_checkpoint(
   checkpoint_name=checkpoint_name,
   validations=[{"batch_request": batch_request, 'expectation_suite_name': suite_name}, ],
)

# make a table to show how the data performed against this suite
json_data = result
run_results = json_data['run_results']
val_results= run_results[list(run_results.keys())[0]]
#action_results = val_results['actions_results']
val_results = val_results['validation_result']
suite_stats = val_results['statistics'] # and this becomes out suite_report when put into df
suite_dict ={'meta_name':['evaluated_expectations','successful_expectations',
                          'unsuccessful_expectations','success_percent'],
             'meta_value':[suite_stats['evaluated_expectations'],suite_stats['successful_expectations'],
                           suite_stats['unsuccessful_expectations'],suite_stats['success_percent']]}
suiteReport = pd.DataFrame(suite_dict)
SAS.df2sd(suiteReport, SAS.symget('suiteReport'))

# make tables so show which expectations were failed and which succeeded
results = json.loads(str(val_results))
meta_results = pd.json_normalize(results['results'])
good_expectations = {}
bad_expectations = {}
for i in range(len(meta_results['success'])):
   exp = meta_results['expectation_config.expectation_type'][i]
   if 'table' in exp:
      col = 'Table Expectation'
   else:
      col = meta_results['expectation_config.kwargs.column'][i]
   if meta_results['success'][i] == True:
      if exp in good_expectations:
         good_expectations[exp].append(col)
      else:
         good_expectations[exp] = []
         good_expectations[exp].append(col)
   else: # expectation failed
      if exp in bad_expectations:
         bad_expectations[exp].append(col)
      else:
         bad_expectations[exp] = []
         bad_expectations[exp].append(col)
            
good_expectations_format = {}
bad_expectations_format = {}
for entry in good_expectations: # formatting
   good_expectations_format[entry] = ', '.join(map(str, good_expectations[entry]))
for entry in bad_expectations: # formatting
   bad_expectations_format[entry] = ', '.join(map(str, bad_expectations[entry]))
good_df = pd.DataFrame(list(good_expectations_format.items()), columns=['expectation', 'columns'])
bad_df = pd.DataFrame(list(bad_expectations_format.items()), columns=['expectation', 'columns'])
print(good_df)
SAS.df2sd(good_df, SAS.symget('goodExp'))
SAS.df2sd(bad_df, SAS.symget('badExp'))

# get table for flags
out_df = df # copy original data
out_df['gx_flag'] = False

# make dataframe for exceptions
df_exception = pd.DataFrame({'execution_datetime': [], 'execution_rule': [], 'column': [], 'exception_value': [], 'exception_count': [],})

# put flag if if in index list
def create_output(data, index_list, column_name):
   if np.isnan(index_list).any() == False:
      for ind in index_list:
         data['gx_flag'][ind] = 1
   return data

# get exceptions table
def merge_tbls(df, date, expectation_type, column, value, count):
   data = pd.DataFrame({
                'execution_datetime': date,
                'execution_rule': expectation_type,
                'column': column,
                'exception_value': value,
                'exception_count': count
                }, index=[0])           
   df = pd.concat([df, data], axis=0, ignore_index=True)
   return df

# Create exception table for an output (ignores quantiles)
def create_exception_table(df, date, expectation, column, unexpected_counts):
   if type(unexpected_counts) != float:
      for i in range(len(unexpected_counts)):
         value = unexpected_counts[i]['value']
         count = unexpected_counts[i]['count']           
         df = merge_tbls(df, date, expectation, column, value, count) 
   return df

for exp in range(len(meta_results)): # loop through all expectations
   out_df = create_output(out_df, meta_results['result.unexpected_index_list'][exp], meta_results['expectation_config.kwargs.column'][exp])
   df_exception = create_exception_table(df_exception, dtime, meta_results['expectation_config.expectation_type'][exp], meta_results['expectation_config.kwargs.column'][exp], meta_results['result.partial_unexpected_counts'][exp])

good_rec = out_df[out_df['gx_flag'] == False]
good_rec = good_rec.drop('gx_flag', axis=1)
bad_rec = out_df[out_df['gx_flag'] == True]
bad_rec = bad_rec.drop('gx_flag', axis=1)
SAS.df2sd(good_rec, SAS.symget('goodRecords'))
SAS.df2sd(bad_rec, SAS.symget('badRecords'))

SAS.df2sd(df_exception, SAS.symget('exceptions'))

   endsubmit;
run;

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

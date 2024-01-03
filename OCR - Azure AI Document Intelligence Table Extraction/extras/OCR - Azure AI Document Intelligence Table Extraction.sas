/*-----------------------------------------------------------------------------------------*
   START MACRO DEFINITIONS.
*------------------------------------------------------------------------------------------*/

/* -----------------------------------------------------------------------------------------* 
   Error flag for capture during code execution.
*------------------------------------------------------------------------------------------ */

%global _eto_error_flag;
%let _eto_error_flag=0;

/* -----------------------------------------------------------------------------------------* 
   Global macro variable for the trigger to run this custom step. A value of 1 
   (the default) enables this custom step to run.  A value of 0 (provided by upstream code)
   sets this to disabled.
*------------------------------------------------------------------------------------------ */

%global _eto_run_trigger;

%if %sysevalf(%superq(_eto_run_trigger)=, boolean)  %then %do;

	%put NOTE: Trigger macro variable _eto_run_trigger does not exist. Creating it now.;
    %let _eto_run_trigger=1;

%end;

/* -----------------------------------------------------------------------------------------* 
   Create a macro variable which contains the location of the key file.
*------------------------------------------------------------------------------------------ */

data _null_;
   call symput("docIntKeyLoc", scan("&docIntKey.",2,":","MO"));
run;

/* -----------------------------------------------------------------------------------------* 
   Read the key contents into a macro variable
*------------------------------------------------------------------------------------------ */

data _null_;
length text $10000.;
infile "&docIntKeyLoc." lrecl=10000 ;
input @1 text $;
call symput("docIntKeyValue",text);
run;

/* -----------------------------------------------------------------------------------------* 
   Create a macro variable which contains the location of the JSON file.
*------------------------------------------------------------------------------------------ */

data _null_;
   call symput("jsonFilePath", scan("&jsonFileName.",2,":","MO"));
run;



/*-----------------------------------------------------------------------------------------*
   FUTURE PLACEHOLDER: EXECUTION CODE MACRO 
   NOTE: Execution code needs (proc python) submit blocks to be converted to infiles for 
         running within a macro.  Placeholder to undertake this in future.
*------------------------------------------------------------------------------------------*/
%macro main_execution_code;
%mend main_execution_code;


/*-----------------------------------------------------------------------------------------*
   END OF MACROS
*------------------------------------------------------------------------------------------*/


/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE
   Note: Python code blocks follow different indentation logic and are currently not
   indented within the SAS proc python blocks below. Comments may not be rendered as 
   elegantly as SAS code.
*------------------------------------------------------------------------------------------*/


proc python;

submit;

#############################################################################################
#
#  Imports
#
#############################################################################################

import os
from azure.ai.formrecognizer import DocumentAnalysisClient
from azure.core.credentials import AzureKeyCredential
import pandas as pd
import json

#############################################################################################
#
#  Helper functions (code adapted from Quickstart guide of MS Azure)
#  located at 
#  https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/quickstarts/get-started-sdks-rest-api?pivots=programming-language-python
# 
#############################################################################################

def format_polygon(polygon):
    if not polygon:
        return "N/A"
    return ", ".join(["[{}, {}]".format(p.x, p.y) for p in polygon])


def analyze_general_documents(docUrl):    
#############################################################################################
#
#  Create a document analysis client
#
#############################################################################################
    document_analysis_client = DocumentAnalysisClient(endpoint=endpoint, credential=AzureKeyCredential(key))
#############################################################################################
#
#  FOR USER CUSTOMIZATION CONSIDERATION: You may choose to swap out the prebuilt-document  
#  template with a custom model after going through Azure references and documentation
#
#############################################################################################
    poller = document_analysis_client.begin_analyze_document_from_url(
            "prebuilt-document", docUrl)
    result = poller.result()
#############################################################################################
#
#  Table processing activities follow  Future placeholder: additional helper functions for
#  handling other extracted elements, for example, raw text, selection marks etc 
#
#############################################################################################
    for table_idx, table in enumerate(result.tables):
        print(
            "Table # {} has {} rows and {} columns".format(
                table_idx, table.row_count, table.column_count
            )
        )
        for region in table.bounding_regions:
            print(
                "Table # {} location on page: {} is {}".format(
                    table_idx,
                    region.page_number,
                    format_polygon(region.polygon),
                )
            )  
    return result.tables

#############################################################################################
#
#  Obtain docUrl, endpoint and key from UI
#
#############################################################################################

_eto_error_flag   = SAS.symget("_eto_error_flag")
docUrl            = SAS.symget("docUrl")
endpoint          = SAS.symget("docIntEndpoint")
key               = SAS.symget("docIntKeyValue")
_eto_run_trigger  = SAS.symget("_eto_run_trigger")
output_option     = SAS.symget("outputOption")
json_file_path    = SAS.symget("jsonFilePath")
output_table_lib  = SAS.symget("outputListTable_lib")
output_table_name = SAS.symget("outputListTable_name")
output_table      = SAS.symget("outputListTable")

#############################################################################################
#
#  Error check: has an output dataset been provided in case of dataset being selected?
#
#############################################################################################

if output_option == "dataset":
   if not output_table:
      SAS.logMessage("Check if you've provided a valid output table.","ERROR")
      _eto_error_flag = 1

#############################################################################################
#
#  Error check: has a JSON file been provided in case of JSON being selected?
#
#############################################################################################

if output_option == "json":
   if not json_file_path:
      SAS.logMessage("Check if you've provided a valid path to a JSON file.","ERROR")
      _eto_error_flag = 1

#############################################################################################
#
#  Error check: has a key velue been provided?
#
#############################################################################################

if not key:
   SAS.logMessage("Key value seems empty, check contents of key file.","ERROR")
   _eto_error_flag = 1

#############################################################################################
#
#  Error check: has the endpoint been provided?
#
#############################################################################################

if not endpoint:
   SAS.logMessage("Provide an active Azure Document Intelligence resource endpoint.","ERROR")
   _eto_error_flag = 1

#############################################################################################
#
#  Run main extraction, conditional upon the run-time trigger
#
#############################################################################################

if int(_eto_run_trigger) == 1  and int(_eto_error_flag) == 0:
   table_result = analyze_general_documents(docUrl)

#############################################################################################
#
#  Process output to make it easier to transfer to downstream tasks
#
#############################################################################################
if table_result:
   all_tables = []
   for idx, atable in enumerate(table_result):
      row_count = atable.row_count
      column_count = atable.column_count
#############################################################################################
#
#  Create an empty array of the same shape as table 
#  Future placeholder: create the same in an elegant way without loops
#
#############################################################################################
      darray=[]
      for row in range(row_count):
        carray=[]
        for col in range(column_count):
           carray.append("")
        darray.append(carray)
#############################################################################################
#
#  Populate array with specific indices output from cell results
#
#############################################################################################
      for eachcell in atable.cells:
         darray[eachcell.row_index][eachcell.column_index]=eachcell.content
#############################################################################################
#
#  Convert to Pandas DataFrame and add to final result array
#
#############################################################################################
      pdf = pd.DataFrame(darray)
      all_tables.append(pdf.to_dict(orient='list'))
#############################################################################################
#
#  For cases where the user chooses to output to SAS dataset, carry out the conversion for 
#  each dataframe one by one
#
#############################################################################################
      SAS.df2sd(pdf, dataset="{}.{}_{}".format(output_table_lib,output_table_name,str(idx)))
#############################################################################################
#
#  For cases where the user chooses to output to JSON, write the entire list of dictionaries 
#  to a JSON file
#
#  Customization consideration: You may choose to write additional code harnessing SAS JSON
#  libname engine to read the JSON file as an alternative data transfer mechanism
#
#############################################################################################
   if output_option == "json":
      with open(json_file_path,"w") as jsonfile:
         json.dump(all_tables,jsonfile)

SAS.symput("_eto_error_flag", _eto_error_flag)

endsubmit;
quit;

/*-----------------------------------------------------------------------------------------*
   Create a summary table of all extracts
*------------------------------------------------------------------------------------------*/
%if &_eto_error_flag. = 0 %then %do;
   proc datasets noprint;
      contents data=_all_ out=&outputListTable.;
   quit;
%end;


/*-----------------------------------------------------------------------------------------*
   Clean up existing macro variables and macro definitions.
*------------------------------------------------------------------------------------------*/
%sysmacdelete main_execution_code;
%symdel _eto_run_trigger;
%symdel docIntKeyLoc ;
%symdel docIntKeyValue ;
%symdel jsonFilePath ;
%symdel _eto_error_flag;
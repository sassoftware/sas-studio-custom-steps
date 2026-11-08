/* SAS templated code goes here */


/* Set debug options whether to write debugging information to log */
%macro _dm_debugMacros;

   %global _dm_resetDebug _dm_defaultsource _dm_defaultsymbolgen _dm_defaultmlogic _dm_defaultmprint _dm_defaultmlogicnest _dm_defaultmprintnest;

   %let _dm_resetDebug = 0; 
   %let _dm_defaultsource = %sysfunc(getoption(source2));
   %let _dm_defaultsymbolgen = %sysfunc(getoption(symbolgen)) ;
   %let _dm_defaultmlogic= %sysfunc(getoption(mlogic));
   %let _dm_defaultmprint= %sysfunc(getoption(mprint));
   %let _dm_defaultmlogicnest= %sysfunc(getoption(mlogicnest));
   %let _dm_defaultmprintnest= %sysfunc(getoption(mprintnest));

   %if &_dm_debugMacro. eq 1 %then %do;
      options source2 symbolgen mlogic mprint mlogicnest mprintnest;
      /* Reset the flag for resetting debug options at the end of run */
      %let _dm_resetDebug = 1;
   %end;

%mend _dm_debugMacros;

%_dm_debugMacros;

/* Create variables for great expectations suite */
%macro _dm_create_input_variables;

%global options;

%if &_dm_filter_rules = column_rule %then %do;
	
	/* if the user chooses "expect_column_distinct_values_to_be_in_set" or "expect_column_values_to_be_in_set" or "expect_column_values_to_not_be_in_set"; */
	%if (&_dm_expectation_col = expect_column_distinct_values_to_be_in_set) or
			   (&_dm_expectation_col = expect_column_values_to_be_in_set) or
			    (&_dm_expectation_col = expect_column_values_to_not_be_in_set) %then %do;
	
		%let options = column = &_dm_column,
	                   value_set = &_dm_value_set,
	                   result_format = COMPLETE;
	%end;

	/* if the user chooses "expect_column_max_to_be_between" or "expect_column_min_to_be_between" or "expect_column_mean_to_be_between";*/
	%else %if (&_dm_expectation_col = expect_column_max_to_be_between) or
				(&_dm_expectation_col = expect_column_min_to_be_between) or 
				 (&_dm_expectation_col = expect_column_mean_to_be_between) or 
				   (&_dm_expectation_col = expect_column_value_lengths_to_be_between) or 
				     (&_dm_expectation_col = expect_column_median_to_be_between) or 
				       (&_dm_expectation_col = expect_column_values_to_be_between) %then %do;
	
		%let options = column = &_dm_column, 
	                   min_value = &_dm_min_value, 
	                   max_value = &_dm_max_value,  
	                   result_format = COMPLETE;		
	%end;
	
	/* if the user chooses "expect_column_values_to_match_regex";*/
	%else %if (&_dm_expectation_col = expect_column_values_to_match_regex) or
				(&_dm_expectation_col = expect_column_values_to_not_match_regex) %then %do;
		%let options = column = &_dm_column, 
					   regex = &_dm_regex,
	                   result_format = COMPLETE;		
	%end;
	
	/* if the user chooses "expect_column_values_to_not_be_null " */
	%else %do;
		%let options = column = &_dm_column, 
	                   result_format = COMPLETE;		
	%end;
%end;

%else %do; /*if _dm_filter_rules = table_rule*/

	/* if the user chooses "expect_table_columns_to_match_set"*/
	%if &_dm_expectation_tbl = expect_table_columns_to_match_set %then %do;
		%let options = column_set = &_dm_column_set, 
                        exact_match = &_dm_exact_match,
                   		result_format = COMPLETE;
	%end;
	%else %if &_dm_expectation_tbl = expect_column_to_exist %then %do;
		%let options = column = &_dm_search_column, 
                   		result_format = COMPLETE;
	%end;
%end;


%mend;
%_dm_create_input_variables;

/* %put &=options;*/


proc python;
submit;

#SAS.hideLOG(False)

import json
import numpy as np
import pandas as pd
import datetime
import great_expectations as gx
from great_expectations.dataset import PandasDataset

# Get system date and time 
dt = datetime.datetime.now()
# dtime = dt.strftime('%m-%d-%Y')
dtime = dt.strftime('%m-%d-%Y %H:%M:%S')


#================= Create dictionary of options ===============================

def parse_options(options):
    options_dict = {}
    for opt in options.split(", "):
        key, value = opt.split("=")
        value = value.strip()
        
        if value.startswith("[") and value.endswith("]"):
            # map values to correct data type based on their content
            value_list = value[1:-1].split(",")
            value = []
            for v in value_list:
                v = v.strip()
                if v.isnumeric():
                    value.append(int(v))
                else:
                    value.append(v)
                    
        elif value.startswith("{") and value.endswith("}"):
            value = set(map(str.strip, value[1:-1].split(",")))
        elif value.isnumeric():
            value = int(value)      
        else:
            try:
                value = float(value)
            except ValueError:
                options_dict[key] = value 
        options_dict[key] = value
                
    trimmed_dict = {key.strip(): value for key, value in options_dict.items()}        
    return trimmed_dict

#=================== Apply expectation to data =============================

def apply_expectation(dataset, expectation, options=None):
    # Call the expectation dynamically using getattr
    expectation_func = getattr(dataset, expectation)
    
    # Apply the expectation with the specified options(if provided)
    if options is not None:
        result = expectation_func(**options)
    else:
        result = expectation_func()

    return result

#=================== Provide output ========================================
# Output table with gx_flag if a flag exists
def create_output(data, gx_json_obj, column_name):
    # Find the failed record indices and return output as False
    result = gx_json_obj['result']
    gx_configuration = gx_json_obj['expectation_config']
    if 'unexpected_index_list' in result:
        index_list = result['unexpected_index_list']
        data['gx_flag'] = ~data.index.isin(index_list)    
    else:
        data['gx_flag'] = True
        
    # for distinct set-type expectations   
    if  'observed_value' in result and 'value_set' in gx_configuration['kwargs']:   
        value_set = gx_configuration['kwargs']['value_set']
        observed_set = result['observed_value']
        exception_set = set(observed_set) - set(value_set) 
        data['gx_flag'] = np.where(data[column_name].isin(exception_set), False, True)

    return data

#=================Build output meta table ==============================
# populate a list
def append_lists(alist_, blist_, name, value):
    alist_.append(name)
    blist_.append(value)
    
    return alist_, blist_
    
# Build a gx_meta dataframe
def build_meta_table(gx_json_obj):
    gx_configuration = gx_json_obj['expectation_config']
    result = gx_json_obj['result']
    
    data = dict()  
    data['meta_name'] = []
    data['meta_value'] = []
    
    # create a list of initial column name and values
    column_name = ['expectation_type', 'success']
    column_value = [gx_configuration['expectation_type'], gx_json_obj['success']] 
    
    # populate the lists
    kwarg_list = ['column','column_set','value_set','min_value','max_value','mostly']
    
    for item in kwarg_list:
        if item in gx_configuration['kwargs']:
            if item == 'value_set' or item == 'column_set':
                value_set = ", ".join(str(value) for value in gx_configuration['kwargs'][item])
                append_lists(column_name, column_value, item, value_set)
            else:
                append_lists(column_name, column_value, item, gx_configuration['kwargs'][item])
        
    list_of_args = ['observed_value', 'element_count', 'missing_count', 'missing_percent', 'unexpected_count']
    
    for item in list_of_args:
        if item in result: 
            if item == 'observed_value':  
                observed_value = result['observed_value']
                if hasattr(observed_value, '__iter__') and type(observed_value) is not str:
                    observed_value = ", ".join(str(value) for value in result['observed_value'])
                append_lists(column_name, column_value, item, observed_value)
            
            elif item == 'unexpected_count':
                list_ = ['unexpected_count','unexpected_percent','unexpected_percent_total','unexpected_percent_nonmissing']
                for name in list_:
                    if name in result:
                        append_lists(column_name, column_value, name, result[name])     
            else:
                append_lists(column_name, column_value, item, result[item])
                
    for name, value in zip(column_name, column_value):
        data['meta_name'].append(name)
        data['meta_value'].append(value)
    
    df = pd.DataFrame(data) #.reset_index(drop=True)
        
    return df

def create_rules_report(dataframe):
    # Structure of the rule`s report[`transaction_ID`, `meta_name`, `meta_value` ]
    df_meta = pd.DataFrame({'transaction_ID': [], 'meta_name': [], 'meta_value': []}) 
    if df_meta.empty:
        id = 1
    else:
        id = df_meta.iloc[-1]['transaction_ID'] + 1
    
    df_meta = pd.concat([df_meta, dataframe], axis=0, ignore_index=True)
    df_meta['transaction_ID'] = df_meta['transaction_ID'].fillna(id)
    
    return df_meta

#=================Build exception`s table ==============================

# Merge tables functions for exception report
def merge_tbls(df, date, expectation_type, value, count):
    data = pd.DataFrame({
                'execution_datetime': date,
                'execution_rule': expectation_type,
                'exception_value': value,
                'exception_count': count
                }, index=[0])           
    df = pd.concat([df, data], axis=0, ignore_index=True)
    return df

# Create exception table for as an output
def create_exception_table(df, date, gx_json_obj):
    gx_configuration = gx_json_obj['expectation_config']
    expectation_type = gx_configuration['expectation_type']
    result = gx_json_obj['result']
    
    if 'partial_unexpected_counts' in result:
        len_result = len(result['partial_unexpected_counts'])
    
        for i in range(len_result):
            value = result['partial_unexpected_counts'][i]['value']
            count = result['partial_unexpected_counts'][i]['count']           
            df = merge_tbls(df, date, expectation_type, value, count) 
            
    elif 'details' in result and 'value_set' in gx_configuration['kwargs']:
        value_set = gx_configuration['kwargs']['value_set']
        observed_set = result['observed_value']
        exception_set = set(observed_set) - set(value_set)
        
        for item in result['details']['value_counts']:
            if item['value'] in exception_set:
                value = item['value']
                count = item['count']
                df = merge_tbls(df, date, expectation_type, value, count)   
    else:
        value = ''
        count = ''
        df = merge_tbls(df, date, expectation_type, value, count)
        
    return df

#======================================================================================
#------------- Load data and run expectations on the data------------------------------

#===================== Load data as SAS table ========================= 

in_table = SAS.symget("_dm_input_table")
df_in = SAS.sd2df(in_table)
df = PandasDataset(df_in)

#===================== Create Expectations ==============================
# determine the type of rule (column or table rule)
rule_type = SAS.symget("_dm_filter_rules")
if rule_type == "column_rule":
    expectation_dm = SAS.symget("_dm_expectation_col")
else:
	expectation_dm = SAS.symget("_dm_expectation_tbl")
# print(expectation_dm)

options = SAS.symget("options")
options = options.replace("'", "").replace('"', '')
options_dict = parse_options(options)
if 'mostly' in options_dict:
    if options_dict['mostly'] == '':
        options_dict['mostly'] = None
print(options_dict)

expectation_outcome = apply_expectation(
                            dataset = df, 
				  			expectation = expectation_dm,
				  			options = options_dict
						)

print(expectation_outcome)

gx_obj = json.loads(str(expectation_outcome))
gx_out = pd.json_normalize(gx_obj)
print(gx_obj)

#=================== Export Tables as Output =================================

# Define the output method based on the rule-filter

if rule_type == "column_rule":
    """
       This section of code should be modified in the case of building an expectation suite.
        - get the transaction_id of the the previous expectation run and build the meta table- 
    """
    # create good and bad records
    column_name = options_dict['column']
    df_out = create_output(df, gx_obj, column_name)  # output data with returned flags
    df_good = df_out[df_out['gx_flag'] == True].drop('gx_flag', axis=1) # inplace=True
    # df_good = df_good.drop('gx_flag', axis=1) 
    df_bad = df_out[df_out['gx_flag'] == False].drop('gx_flag', axis=1)
    # df_bad = df_bad.drop('gx_flag', axis=1)

    # print(df_out.head())
    SAS.df2sd(df_good, SAS.symget('_dm_good_records'))
    SAS.df2sd(df_bad, SAS.symget('_dm_bad_records'))


# create rules-report table 
gx_meta_df = build_meta_table(gx_obj)   # gx meta data
df_meta = create_rules_report(gx_meta_df)
SAS.df2sd(df_meta, SAS.symget('_dm_rule_report'))

# create exceptions table
df_exception = pd.DataFrame({'execution_datetime': [], 'execution_rule': [], 'exception_value': [], 'exception_count': [],})
df_exception = create_exception_table(df_exception, dtime, gx_obj)
SAS.df2sd(df_exception, SAS.symget('_dm_exceptions'))


#SAS.printLOG()

config = df.get_expectation_suite()
print(config)


endsubmit;
quit;


/*   Reset debug options to not write debugging information to log at the end of run */
%macro _dm_resetDebugMacros;
   %if &_dm_resetDebug. eq 1 %then %do;
      options &_dm_defaultsource. &_dm_defaultsymbolgen. &_dm_defaultmlogic. &_dm_defaultmprint. &_dm_defaultmlogicnest. &_dm_defaultmprintnest.;
   %end;
%mend _dm_resetDebugMacros;

%_dm_resetDebugMacros;





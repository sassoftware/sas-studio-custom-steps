/* SAS templated code goes here */

/*-----------------------------------------------------------------------------------------*
   START MACRO DEFINITIONS.
*------------------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------------*
   Macro to capture indicator and UUID of any currently active CAS session.
*------------------------------------------------------------------------------------------*/

%global casSessionExists;
%global _current_uuid_;

%macro _plos_checkSession;
   %if %sysfunc(symexist(_SESSREF_)) %then %do;
      %let casSessionExists= %sysfunc(sessfound(&_SESSREF_.));
      %if &casSessionExists.=1 %then %do;
         proc cas;
            session.sessionId result = sessresults;
            call symputx("_current_uuid_", sessresults[1]);
            %put NOTE: A CAS session &_SESSREF_. is currently active with UUID &_current_uuid_. ;
         quit;
      %end;
   %end;
%mend _plos_checkSession;


/*-----------------------------------------------------------------------------------------*
   FUTURE PLACEHOLDER: EXECUTION CODE MACRO 
   NOTE: Execution code needs (proc python) submit blocks to be converted to infiles for 
         running within a macro.  Placeholder to undertake this in future.
*------------------------------------------------------------------------------------------*/
%macro main_execution_code;
%mend main_execution_code;


/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE 
   Note: Python code blocks follow different indentation logic and are currently not
   indented within the SAS proc python blocks below. Comments may not be rendered as 
   elegantly as SAS code.
*------------------------------------------------------------------------------------------*/

/* -----------------------------------------------------------------------------------------* 
   Run macro to capture any current CAS session details.
*------------------------------------------------------------------------------------------ */

%_plos_checkSession;


/* -----------------------------------------------------------------------------------------* 
   This step "hoists" all required functions. Procs split for ease of access.
*------------------------------------------------------------------------------------------ */

proc python;
   submit;

#############################################################################################
#
#  Helper functions 
#
#############################################################################################

#############################################################################################
#  Function to drop a table in global scope prior to promotion  
#############################################################################################

def drop_global_table(conn,outputtable_name,outputtable_lib):
   exists=conn.table.tableexists(name=outputtable_name,caslib=outputtable_lib)
   if exists.exists > 0:
      print(exists.exists)
      conn.table.droptable(name=outputtable_name,caslib=outputtable_lib)
      SAS.logMessage("Dropped existing table")
      drop_global_table(conn,outputtable_name,outputtable_lib)

#############################################################################################
#  Function to convert a pandas dataframe to a SAS table (either CAS or SAS) object. 
#  Note this is used for explicit Pandas dataframes selection as well as intermediate
#  transfer object when lists / dicts are selected 
#############################################################################################

def pd_to_sas(pdf):
   outputtable_engine    =  SAS.symget("OUTPUTTABLE_ENGINE")   
   SAS.logMessage("The output table engine is {}".format(outputtable_engine))
   if outputtable_engine=="V9":
      outputtable        =  SAS.symget("outputTable")
      SAS.df2sd(pdf, dataset=outputtable)
      SAS.logMessage("Transferred to SAS dataset.")
   else:
      cas_session_exists =  SAS.symget("casSessionExists")
      cas_host_path      =  SAS.symget("casHostPath")
      cas_host_port      =  SAS.symget("casHostPort")
      outputtable_name   =  SAS.symget("outputTable_name_base")
      outputtable_lib    =  SAS.symget("outputTable_lib")
      promote_table      =  SAS.symget("promoteTable")
      promote_flag       =  True if promote_table=='1' else False
      replace_flag       =  False if promote_flag else True
      import swat
      import os
#     Add certificate location to operating system list of trusted certs detailed in About tab - Documentation    
      os.environ['CAS_CLIENT_SSL_CA_LIST']=os.environ['SSLCALISTLOC']
#     Connect to CAS
      if cas_session_exists=='1':
         sessuuid        =  SAS.symget("_current_uuid_")
         SAS.logMessage("Connection exists. Session UUID is {}".format(sessuuid))   
         conn            =  swat.CAS(hostname=cas_host_path,port=cas_host_port, password=os.environ['SAS_SERVICES_TOKEN'],session=sessuuid)
      else:
         SAS.logMessage("New Connection made to CAS through swat.")
         conn            =  swat.CAS(hostname=cas_host_path,port=cas_host_port, password=os.environ['SAS_SERVICES_TOKEN'])

      if conn:
         SAS.logMessage("Connection established.")
         drop_global_table(conn,outputtable_name,outputtable_lib)
         cas_table       = conn.CASTable(name=outputtable_name, caslib=outputtable_lib, replace=replace_flag, promote=promote_flag)
         cas_table.from_dict(data=pdf, connection=conn, casout=cas_table)
         SAS.logMessage("Table loaded to CAS.")

   endsubmit;
quit;

/* -----------------------------------------------------------------------------------------* 
   Execute operations based on user choice
*------------------------------------------------------------------------------------------ */

proc python;
   submit;

import gc

# Obtain values from UI

selected_option = SAS.symget("selectedOption")
pdf_name        = SAS.symget("pdfName")
pvar_name       = SAS.symget("pythonVarName")
pylist_name     = SAS.symget("pythonListName")
pydict_name     = SAS.symget("pythonDictName")   

#############################################################################################
#  Treatment for a standard Python int/str object 
#############################################################################################

if selected_option == "vars" and pvar_name:
   sas_macro_var_name = SAS.symget("sasMacroVarName")
   if not sas_macro_var_name:
      SAS.logMessage("Provide a valid SAS macro variable!","ERROR")
   else:
      SAS.symput(sas_macro_var_name,locals()[pvar_name])
      SAS.logMessage("The macro variable {} has value {}".format(sas_macro_var_name,SAS.symget(sas_macro_var_name)))   

#############################################################################################
#  Treatment for a Python list object 
#############################################################################################

if selected_option == "list" and pylist_name:
   list_column_name   = SAS.symget("listColumnName")
   import pandas as pd
   _pdf_from_list     = pd.DataFrame({list_column_name:locals()[pylist_name]})
   pd_to_sas(_pdf_from_list)
   del _pdf_from_list
   gc.collect()
   SAS.logMessage("Intermediate Pandas dataframe freed from memory.")

#############################################################################################
#  Treatment for a Python dict object 
#############################################################################################

if selected_option == "dict" and pydict_name:
   import pandas as pd
   _pdf_from_list     = pd.DataFrame(locals()[pydict_name])
   pd_to_sas(locals()[pydict_name])
   del locals()[pydict_name]
   gc.collect()
   SAS.logMessage("Intermediate Pandas dataframe freed from memory.")

#############################################################################################
#  Treatment for a Pandas dataframe 
#############################################################################################

if selected_option == "pandas" and pdf_name:
   del_pdf            = SAS.symget("delPdf")
   pd_to_sas(locals()[pdf_name])
   if del_pdf=='1':
      del locals()[pdf_name]
      gc.collect()
      SAS.logMessage("Pandas dataframe freed from memory.")

   endsubmit;
quit;



/*-----------------------------------------------------------------------------------------*
   Remove execution-time macro variables.
*------------------------------------------------------------------------------------------*/

%if %sysfunc(symexist(_SESSREF_)) %then %do;
   %symdel casSessionExists;
%end;

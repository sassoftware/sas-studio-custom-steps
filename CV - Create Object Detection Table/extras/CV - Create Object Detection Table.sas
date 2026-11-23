/*-------------------------------*
    CREATE MACRO DEFINITIONS
*------------------------------*/

/* -------------------------------------------------------------------------------------------* 
   This code ensures that the user specifies a valid CASLIB for output table's library name
*-------------------------------------------------------------------------------------------- */
%global _codt_nameCaslib;

%if "%upcase(&codt_op_table_name_engine)" ne "CAS" %then %do;
  data _null_;
     putlog "ERROR: The selected table is not a CAS table.";
     putlog "ERROR: Please select a library that points to a caslib.";
     abort 42;
  run;
%end;
%else %do;
  proc sql noprint;
     select sysvalue into :_codt_nameCaslib trimmed from dictionary.libnames
     where libname=upcase("&codt_op_table_name_lib") and upcase(sysname)="CASLIB";
  quit;
  %put CASLIB name: &_codt_nameCaslib;
%end;

/* -----------------------------------------------------------------------------* 
   This code ensures the user uploads data only from the "SAS server" directory
*---------------------------------------------------------------------------- */

data _null_;
	location = scan("&codt_input_path.", 1, ':', 'MO');
	if location eq 'sascontent' then do;
		putlog "ERROR: Please ensure that the directory containing images and annotations is located in SAS Server not in SAS Content";
		abort 42;
	end;

	location = scan("&codt_output_table_path.", 1, ':', 'MO');
	if location eq 'sascontent' then do;
		putlog "ERROR: Please ensure that the folder location to save object detection table is located in SAS Server not in SAS Content";
		abort 42;
	end;

run;

/* -----------------------------------------------------------------------------------------* 
   This macro definition identifies if an active CAS session exists. About[doc] for details
*------------------------------------------------------------------------------------------ */

%if %sysfunc(symexist(_SESSREF_)) %then %do;
   %let casSessionExists= %sysfunc(sessfound(&_SESSREF_.));
%end;

/*-----------------------------------------------------------------------------------------*
   EXECUTION CODE 
   Note: Python code blocks follow different indentation logic and are currently not
   indented within the SAS proc python blocks below. Comments may not be rendered as 
   elegantly as SAS code.
*------------------------------------------------------------------------------------------*/

proc python restart;
submit;

#############################################################################################
#  Imports
#############################################################################################

import os
import dlpy as dlpy
import swat as swat
from dlpy.utils import *
from dlpy.model import *
from dlpy.images import ImageTable
import matplotlib.pyplot as plt
import pandas as pd
pd.set_option("display.max_columns", None)

#############################################################################################
#  Establish a connection to CAS, attempting to connect to an existing connection.
#  Ensure that an active CAS connection exists prior to running
#  Otherwise, default to a new connection  
#############################################################################################

cas_session_exists =  SAS.symget("casSessionExists")
cas_host_path      =  SAS.symget("_CASHOST_SHARED_")
cas_host_port      =  SAS.symget("_CASPORT_")

SAS.logMessage(f"Host is {cas_host_path}")
SAS.logMessage(f"Port is {cas_host_port}")

os.environ["CAS_CLIENT_SSL_CA_LIST"] = os.environ["SSLCALISTLOC"]

if cas_session_exists=="1":
    sessuuid           =  SAS.symget("_IOCASUUID_")
    SAS.logMessage(f"Connection exists. Session UUID is {sessuuid}")
    s = swat.CAS(hostname= cas_host_path.strip('"'), port=cas_host_port, password=os.environ["SAS_SERVICES_TOKEN"],session=sessuuid)
    SAS.logMessage("Connected to existing session.")

else:
    SAS.logMessage("New Connection made to CAS through swat.")
    s = swat.CAS(hostname=cas_host_path.strip('"'),port=cas_host_port, password=os.environ["SAS_SERVICES_TOKEN"])

#############################################################################################
# Get user inputs from UI 
#############################################################################################

input_path         = SAS.symget("codt_input_path")
trimmed_input_path = str.split(input_path,":")[1]
img_size           = int(SAS.symget("codt_img_size"))
output_table_name  = SAS.symget("codt_op_table_name_name_base")
output_caslib      = SAS.symget("codt_op_table_name_lib")
save_table		   = SAS.symget("codt_save_table")

#############################################################################################
#  Create an object detection table to the output table port
#############################################################################################

s.sessionProp.setSessOpt(caslib=output_caslib)

s.loadactionset("image")
s.loadactionset('deepLearn')

trainset = ImageTable.load_files(conn=s, casout=dict(name="trainset"), path=trimmed_input_path)

SAS.logMessage("Displaying some input images")

disp = trainset.show(ncol=3)
SAS.pyplot(plt)
plt.close()

object_detection_targets = create_object_detection_table(
															s, 
                                                         	image_size=img_size,
                                                         	data_path = trimmed_input_path,
                                                         	coord_type = 'yolo', 
                                                         	output = output_table_name
														)

SAS.logMessage("Displaying some examples of bounding boxes")

disp2 = display_object_detections(s, coord_type="yolo", max_objects=10, table=output_table_name, n_col=3)
SAS.pyplot(plt)
plt.close()

#############################################################################################
#  Save the object detection table locally
#############################################################################################

if save_table == "Yes":
		
	output_path 	= SAS.symget("codt_output_table_path")
	trimmed_op_path = str.split(output_path,":")[1] 
	
	s.addcaslib(name="output_data", path=trimmed_op_path, activeOnAdd=False, subdirectories=True)
	
	s.table.save(table=output_table_name, name=output_table_name+".sashdat", replace=True, caslib="output_data", permission="PUBLICWRITE")

	s.dropcaslib(name="output_data")

endsubmit;
quit;

%symdel casSessionExists _codt_nameCaslib;
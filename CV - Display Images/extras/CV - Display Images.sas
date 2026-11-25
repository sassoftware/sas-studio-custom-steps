/*-------------------------------*
    CREATE MACRO DEFINITIONS
*------------------------------*/

/* -----------------------------------------------------------------------------------------* 
   This macro definition identifies if an active CAS session exists. About[doc] for details
*------------------------------------------------------------------------------------------ */

%if %sysfunc(symexist(_SESSREF_)) %then %do;
   %let casSessionExists= %sysfunc(sessfound(&_SESSREF_.));
%end;

proc python restart;
submit;

#############################################################################################
#  Imports
#############################################################################################

import swat
import dlpy as dlpy
import os
import numpy as np
from swat import *
from matplotlib import pyplot
import matplotlib.pylab as plt
import matplotlib

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

os.environ['CAS_CLIENT_SSL_CA_LIST'] = os.environ['SSLCALISTLOC']

if cas_session_exists=='1':
    sessuuid           =  SAS.symget("_IOCASUUID_")
    SAS.logMessage("Connection exists. Session UUID is {}".format(sessuuid))
    s = swat.CAS(hostname= cas_host_path.strip('"'), port=cas_host_port, password=os.environ['SAS_SERVICES_TOKEN'],session=sessuuid)
    SAS.logMessage("Connected to existing session.")

else:
    SAS.logMessage("New Connection made to CAS through swat.")
    s = swat.CAS(hostname=cas_host_path.strip('"'),port=cas_host_port, password=os.environ['SAS_SERVICES_TOKEN'])

#############################################################################################
# Get user inputs from UI 
#############################################################################################

s.loadactionset("image")
s.loadactionset("bioMedImage")

img_count           = SAS.symget("disp_count")
input_table_name	= SAS.symget("disp_ip_tbl_name_base")
input_caslib        = SAS.symget("disp_ip_table_lib")
is_dicom            = SAS.symget("disp_dicom")

s.sessionProp.setSessOpt(caslib=input_caslib)

input_castbl = s.CASTable(input_table_name)

if int(is_dicom) == 1:
	
	s.image.processimages(
						   casout=dict(name=input_castbl, replace=True),
						   imageFunctions=[{"functionOptions":{"functionType":"CONVERT_COLOR", "type":"GRAY2COLOR"}}],
						   table = input_castbl
						 )

for i in range(int(img_count)):
	a = input_castbl.fetchimages().Images['Image'][i]  
	plt.xticks([]), plt.yticks([])
	plt.imshow(a)
	SAS.pyplot(plt)

endsubmit;
quit;

%symdel casSessionExists;
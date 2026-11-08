/*
Author: Duncan Bain
With assistance from:
Angus Looney
Hary Snart
Casey Smith
*/
proc python;
submit;
#First run will take a while especially if there are lot of dependencies- be patient

import os
import sys
import subprocess
import pkg_resources

# check for directory first and if not create it

localpip = SAS.symget("fileorfolderselector1").split(sep=':')[1]

try:
	os.makedirs(localpip, exist_ok = True)
	print("Directory created successfully")
except OSError as error:
	print("Directory can not be created")

#then append it to the python path if necessary

if not localpip in sys.path:
	sys.path.append(localpip)

endsubmit;
run;
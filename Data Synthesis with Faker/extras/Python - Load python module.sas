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
import importlib

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

#now check to see if the package is installed and if not install it.

try:
	importlib.import_module(SAS.symget('inputfield1'))
	print(SAS.symget('inputfield1') + ' already exists - not replacing')
except ImportError:
	print(SAS.symget('inputfield1') + ' does not exist. Attempting to fetch from pip.')
	python = sys.executable
	target = "--target="+localpip
	subprocess.check_call([python, '-m', 'pip', 'install',  target, SAS.symget('inputfield1'), '--no-cache-dir'])
finally:
	importlib.import_module(SAS.symget('inputfield1'))
	print(SAS.symget('inputfield1') + ' loaded successfully.')

endsubmit;
run;
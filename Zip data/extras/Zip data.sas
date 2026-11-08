* ----------------------------------------------------------------------------;
* Archive files to ZIP;
* ----------------------------------------------------------------------------;

/*
* Print macro variables passed from custom step;

* Source directory;
%put NOTE: &=dirSource;
* Source filename pattern;
%put NOTE: &=pattern;
* Target directory;
%put NOTE: &=dirTarget;
* Archive period number;
%put NOTE: &=periodCount;
* Archive period units;
%put NOTE: &=periodUnit;
* Action (move or copy);
%put NOTE: &=action;
* Dry run;
%put NOTE: &=dryRun;
*/

* Set error flag to 0;
%let errorFlag=0;

* Check the source and target directories both exist and are on the file system;
data _null_;
	* Get file system type and directory names;
	fsSource=scan("&dirSource",1,":");
	dirSource=scan("&dirSource",2,":");
	fsTarget=scan("&dirTarget",1,":");
	dirTarget=scan("&dirTarget",2,":");

	errorFlag=0;

	* Check source directory;
	if fsSource="sasserver" then do;
		if fileexist(dirSource) then put "NOTE: Source directory exists";
		else do;
			put "ERROR: The source directory does not exist";
			errorFlag=1;
		end;
	end;
	else do;
		put "ERROR: The source directory must be on the file system, not SAS Content";
    errorFlag=1;
	end;

	* Check target directory;
	if fsTarget="sasserver" then do;
		if fileexist(dirTarget) then put "NOTE: Target directory exists";
		else do;
			put "ERROR: The target directory does not exist";
			errorFlag=1;
		end;
	end;
	else do;
		put "ERROR: The target directory must be on the file system, not SAS Content";
    errorFlag=1;
	end;

	* Set return code to 1 if directories are not ok;
  call symput("errorFlag",put(errorFlag,1.));
run;

* Run the Python code if the source and target directories are ok;
%if &errorFlag=0 %then %do;

proc python;
submit;
# -----------------------------------------------------------------------------
# Archive files to ZIP
# -----------------------------------------------------------------------------

# Import modules
import datetime
from dateutil.relativedelta import relativedelta
import glob
import os
from os.path import basename
import time
import zipfile

# -----------------------------------------------------------------------------
# Get parameters from SAS macro variables

# Source directory
dirSource = SAS.symget('dirSource').split(':')[1]

# Pattern
pattern = SAS.symget('pattern')

# Target directory
dirTarget = SAS.symget('dirTarget').split(':')[1]

# Archive period
periodCount = float(SAS.symget('periodCount'))
periodUnit = SAS.symget('periodUnit')

# Move files to ZIP
action = SAS.symget('action')

# Dry run
dryRun = bool(int(SAS.symget('dryRun')))

# -----------------------------------------------------------------------------
# Get list of files to archive

# Get current date-time
now = datetime.datetime.now()

# Calculate cutoff date-time
period = {'minutes': 0, 'hours': 0, 'days': 0, 'weeks': 0, 'months': 0, 'years': 0}
period.update({periodUnit: periodCount})
cutoff = now - relativedelta(
    minutes=period.get('minutes'), 
    hours=period.get('hours'), 
    days=period.get('days'), 
    weeks=period.get('weeks'), 
    months=period.get('months'), 
    years=period.get('years'))

# Get list of files based on the pattern and modified date-time constraints
files = list(
    filter(
        lambda name: os.path.isfile(name) and 
        datetime.datetime.fromtimestamp(os.path.getmtime(name)) < cutoff, 
        glob.glob(f'{dirSource}/{pattern}')))

# Get number of files that match the constraints
nFiles = len(files)

print(f'Archiving files with the pattern: {pattern}')
print(f'Archiving files last modified before: {cutoff.isoformat(sep="T", timespec="seconds")}')
print(f'Found {nFiles} files that match the pattern and modified date-time constraints')

# -----------------------------------------------------------------------------
# Archive files

# Counter for files archived
n = 0

# Error code
rc = 0

if nFiles > 0 and dryRun:
    print('Skipping zip - dry run only...')
    for file in files:
        # Get the filename (remove the path)
        bName = basename(file)
        print(f'Skipping zip of: {bName}')
elif nFiles > 0 and not dryRun:
    print('Zipping files...')
    for file in files:
        # Get the filename (remove the path)
        bName = basename(file)
        try:
            with zipfile.ZipFile(f'{dirTarget}/{bName}.zip', 'w') as myzip:
                # Zip file
                print(f'Zipping: {bName}')
                myzip.write(file, arcname = bName)
                # If files are being moved to a ZIP file, then delete the source
                if action == 'Move':
                    try:
                        print(f'Deleting: {bName}')
                        os.remove(file)
                    except OSError as e:
                        print(f'Error deleting file: {e}')
                        rc = 1
                # Increment counter for number of files archived
                n += 1

        except:
            print('Error zipping file {bName}')
        myzip.close()
    print(f'Archived {n} files that match the pattern and modified date-time constraints')

if rc == 0:
    print('Finished')
else:
    print('Finished with error(s)')

# Pass return code as a SAS macro variable
SAS.symput('errorFlag', str(rc))

endsubmit;
run;

%end;

%if &errorFlag=0 %then %do;
	%put NOTE: Step ended successfully;
%end;
%else %do;
	%put ERROR: Step ended with errors;
%end;

* ----------------------------------------------------------------------------;
* Delete macro variables;
* ----------------------------------------------------------------------------;

%if %symexist(errorFlag) %then %do;
  %symdel errorFlag;
%end;

* ----------------------------------------------------------------------------;
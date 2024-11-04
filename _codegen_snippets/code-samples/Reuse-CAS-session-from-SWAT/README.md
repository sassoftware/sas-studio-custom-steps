# Reusing CAS session from SWAT (Python)

## Background

There are situations where you have Python logic that uses SWAT that you would want to use inside a SAS Studio Custom Step. It's strongly recommended that if the existing Compute session had already started a CAS session, that your Python code instructs SWAT to reuse that CAS session. 

Keep in mind that SAS has Python libraries, like DLPy, that have logic that runs CAS actions (through SWAT) but also has Python logic for whch there is no equivalent CAS action. 

The code below was provided by [Sundaresh Sankaran](https://github.com/SundareshSankaran).

## SAS Macro to retrieve information about existing CAS session

```SAS
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

```

## Proc Python code snippet to have SWAT connect to the existing CAS session

This Proc Python code snippet uses user-defined SAS macro variables **cas_session_exists** and **\_current_uuid_**. These are created by running user-defined SAS macro **\_plos_checkSession** that is shown earlier on this page before running proc python with the code shown below.

```Python
import os
import swat

cas_session_exists = SAS.symget('casSessionExists')
cas_host_path = SAS.symget('casHostPath')
cas_host_port = SAS.symget('casHostPort')

#  Add certificate location to operating system list of trusted certs detailed in About tab - Documentation    
os.environ['CAS_CLIENT_SSL_CA_LIST'] = os.environ['SSLCALISTLOC']
                                                                                                                  
                                                               
#  Connect to CAS
if cas_session_exists == '1':
   sessuuid = SAS.symget('_current_uuid_')
   SAS.logMessage(f"Connection exists. Session UUID is {sessuuid}")   
   conn = swat.CAS(hostname = cas_host_path, port = cas_host_port, password = os.environ['SAS_SERVICES_TOKEN'], session = sessuuid)
else:
   SAS.logMessage('New Connection made to CAS through SWAT.')
   conn = swat.CAS(hostname = cas_host_path, port = cas_host_port, password = os.environ['SAS_SERVICES_TOKEN'])

if conn:
   SAS.logMessage('Connection established.')
```
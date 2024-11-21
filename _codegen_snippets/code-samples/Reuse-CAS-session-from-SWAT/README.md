# Reusing CAS session from SWAT (Python)

## Background

There are situations where you have Python logic that uses SWAT that you would want to use inside a SAS Studio Custom Step. It's strongly recommended that if the existing Compute session had already started a CAS session, that your Python code instructs SWAT to reuse the CAS session that was created by Compute.

A typical use case is where Python code using SWAT was developed in a pure Python environment and then re-used inside a SAS Studio Custom Step to  provide
a point-and-click UI on top of that functionality and use it in SAS Studio flows. 

Keep in mind that SAS has Python libraries, like DLPy, that contain logic that runs CAS actions (through SWAT) but might contain Python logic that does not run in CAS. 

Part of this code was provided by [Sundaresh Sankaran](https://github.com/SundareshSankaran).

## SAS Macro to retrieve information about existing CAS session

```SAS
/*-----------------------------------------------------------------------------------------*
   Macro to check whether CAS session exists, and if so retrieve CAS session UUID.
*------------------------------------------------------------------------------------------*/
%global casSessionExists;
%global casSessionUUID;

%macro _casCheckSessionExists;
   %* Check whether CAS session exist, and if so retrieve CAS session UUID;
   %if %sysfunc(symexist(_SESSREF_)) %then %do;
      %let casSessionExists= %sysfunc(sessfound(&_SESSREF_));
      %if &casSessionExists=1 %then %do;
         proc cas;
            session.sessionId result = sessresults;
            call symputx("casSessionUUID", sessresults[1]);
            %put NOTE: CAS session with name &_SESSREF_ is currently active with UUID &casSessionUUID;
         quit;
      %end;
   %end;
%mend _casCheckSessionExists;
%_casCheckSessionExists;
```

## Proc Python code snippet to have SWAT connect to the existing CAS session

This Proc Python code snippet uses user-defined SAS macro variables **casSessionExists** and **casSessionUUID**. These are created by running user-defined SAS macro **casCheckSessinExists** that is shown earlier on this page before running proc python with the code shown below.

```Python
import os
import swat
cas_session_exists = SAS.symget('casSessionExists')

# Retrieve values for SAS options cashost and casport, these are needed by SWAT connection 
cas_host_name = SAS.sasfnc('getoption','cashost')
cas_host_port = SAS.sasfnc('getoption','casport')

#  Add certificate location to operating system list of trusted certs
os.environ['CAS_CLIENT_SSL_CA_LIST'] = os.environ['SSLCALISTLOC']
                                                                                                                  
                                                               
#  Connect to CAS
if cas_session_exists == '1':
   cas_session_uuid = SAS.symget('casSessionUUID')
   SAS.logMessage(f"CAS connection exists. Session UUID is {cas_session_uuid}")   
   conn = swat.CAS(hostname = cas_host_name, port = cas_host_port, password = os.environ['SAS_SERVICES_TOKEN'], session = cas_session_uuid)
   if conn:
      SAS.logMessage('SWAT connection established.')

else:
   SAS.logMessage('ERROR: No active CAS session. Connect to a CAS session in upstream step in the flow.')
```

# Alternative approaches when CAS session does not exist
Instead of creating an error when a CAS session does not exist, you could also create a CAS session on the fly and then remove it again at the end of your custom step.

## Approach 1: Create CAS session directly through SWAT, SAS Compute has no knowledge about that CAS session
```Python
SAS.logMessage('Create CAS session through SWAT.')
conn = swat.CAS(hostname = cas_host_name, port = cas_host_port, password = os.environ['SAS_SERVICES_TOKEN'])
if conn:
   SAS.logMessage('SWAT connection established.')
```

## Approach 2: Create CAS session using SAS Compute and then connect to that session from SWAT
```Python
SAS.logMessage('Create CAS session using SAS Compute and then connect to that same session through SWAT.')
SAS.submit('cas;')
conn = swat.CAS(hostname = cas_host_name, port = cas_host_port, password = os.environ['SAS_SERVICES_TOKEN'])
if conn:
    SAS.logMessage('SWAT connection established.')
```

## Cleaning up CAS session that was created on the fly
 * When having used approach 1 to create the CAS session:
     * Terminate CAS session created by SWAT using
       ```Python
       swat.CAS.terminate()
        ```
 * When having used approach 2 to create the CAS session:
     * Close SWAT connection to CAS using
       ```Python
       swat.CAS.close()
       ```
     * Terminate CAS session created by Compute using
       ```Python
       SAS.submit('cas casauto terminate;')
       ```
/* SAS templated code goes here */



proc python;

submit;

import os
from virtualenv import cli_run

venv=SAS.symget("venv")

pyt=os.environ["PROC_PYPATH"]
SAS.symput("MAIN_PYTH",str(pyt))

cli_run([venv])
activate_this_file = os.path.join(venv,"bin","activate_this.py")
exec(open(activate_this_file).read(), {'__file__': str(activate_this_file)})
SAS.symput("TEMP_PYTH",str(os.path.join(venv,"bin","python3")))



endsubmit;

quit;
proc python terminate;
quit;

options set=PROC_PYPATH="&TEMP_PYTH.";

%put &TEMP_PYTH.;
%put &MAIN_PYTH.;

proc python;
submit;
import os
pyt=SAS.symget("TEMP_PYTH")
print("Hello World")
req=SAS.symget("req")
if os.path.isfile(req):
    print("File provided")
    os.system("{pyt} -m pip install -r {req}".format(pyt=pyt,req=req))
else:
    print("List provided")
    os.system("{pyt} -m pip install {req}".format(pyt=pyt,req=req))

endsubmit;
quit;





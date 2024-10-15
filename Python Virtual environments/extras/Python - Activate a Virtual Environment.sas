/* SAS templated code goes here */


proc python;

submit;

import os
venv=SAS.symget("venv")

pyt=os.environ["PROC_PYPATH"]

mpt=SAS.symget("MAIN_PYTH")

if mpt=="":
    SAS.symput("MAIN_PYTH",str(pyt))

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
print("Environment activated: {pyt}".format(pyt=pyt))
endsubmit;
quit;
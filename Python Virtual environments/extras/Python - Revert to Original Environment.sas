/* SAS templated code goes here */

proc python;

submit;

import os

current_venv=SAS.symget("TEMP_PYTH")
pyt=SAS.symget("MAIN_PYTH")




endsubmit;

quit;

options set=PROC_PYPATH="&MAIN_PYTH.";

%put &TEMP_PYTH.;
%put &MAIN_PYTH.;

proc python terminate;
quit;

proc python;
submit;
import os
pyt=SAS.symget("MAIN_PYTH")
print("Virtual environment deactivated; Python is now at {pyt}".format(pyt=pyt))
endsubmit;
quit;
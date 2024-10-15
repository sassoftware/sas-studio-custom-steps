/* SAS templated code goes here */

proc python;

submit;

import os

req=SAS.symget("req")
pyt=SAS.symget("TEMP_PYTH")

os.system("{pyt} -m pip freeze > {req}".format(pyt=pyt,req=req))

print("Requirements file saved at {req}".format(req=req))

endsubmit;

quit;
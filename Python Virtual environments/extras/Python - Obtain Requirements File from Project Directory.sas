/* SAS templated code goes here */

proc python;

submit;


projectarea=SAS.symget("projectarea")
resultloc=SAS.symget("resultloc")

import os
os.system("{} -m pipreqs.pipreqs --save {}  --force {}".format(os.environ["PROC_PYPATH"],resultloc,projectarea))

endsubmit;


quit;
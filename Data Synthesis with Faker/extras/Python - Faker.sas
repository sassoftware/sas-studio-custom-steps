/*
Author: Duncan Bain
With assistance from:
Angus Looney
Hary Snart
Casey Smith
*/
proc python;
submit;
from faker import Faker
import pandas as pd
import gc
from random import randint

#instantiate class based on requriement for uniqueness
if SAS.symget("makeUnique") == '0' :
    fake = Faker(SAS.symget("locale"))
else:
    fake = Faker(SAS.symget("locale")).unique

#set the seed
seed = int(SAS.symget("seed"))

if seed == 0:
    seed = randint(0, 65536)

print('Using seed', seed)
Faker.seed(seed)

#special case for the convience function profile which generates its own columnnames
#then a try catch to handle providers with no optional args

provider = SAS.symget("provider")
provider_opts = SAS.symget("provider_options")
numfakes = int(SAS.symget("numfakes"))

try:
    if provider in ['profile'] :
       df_fakes = pd.DataFrame([getattr(fake,provider)(provider_opts) for _ in range(numfakes)])
    else:
        try:
            df_fakes = pd.DataFrame([getattr(fake,provider)(provider_opts) for _ in range(numfakes)],columns=[provider])
        except:
           df_fakes = pd.DataFrame([getattr(fake,provider)() for _ in range(numfakes)],columns=[provider])
except Exception as e:
    erstr = "data _null_; error 'ERROR: " + str(e).replace('\'','\'\'') + "'; abort; run;"
    SAS.submit(erstr)
    raise e

ds_fakes = SAS.df2sd(df_fakes,SAS.symget("_output1"))

#delete the dataframe and then force a garbage collection to save memory
del df_fakes
gc.collect()

endsubmit;
run;

/*
This last step adds the index numbers. It's just easier in SAS	
*/
data &_output1;
	set &_output1;
	idx = _N_ + &indexOffset;
run;
# R Runner
SAS Studio needs a quick and easy interface to R. This repository provides a custom step (a low-code component) which will enable developers to quickly submit R scripts from within SAS Studio (on SAS Viya) in a quick and no-nonsense manner.

**Analytics developers appreciate unified interaction with SAS and R, especially in certain industries such as Pharma and Healthcare, which have significant R developers.  R Runner helps such developers create solutions using R (as well as SAS and Python if required) within SAS Studio on SAS Viya.**

## A general idea (click on image below to watch video)

[![Beep Beep](/img/r_runner_snapshot.png)](https://youtu.be/qB6GlElZF_w)

R Runner enables you to submit R scripts from within SAS Studio and develop integrated analytics pipelines. You can submit either:

1. Short R snippets in the text area provided

2. R scripts (programs) through a file selector

Variables created within the R script (also known as R environment variables) can also be written to an output SAS dataset for reference and reuse in downstream code.

In this early version, you'll also be able to attach an input table (SAS dataset) to the custom step, which will be converted to an R data frame (via Python) for analysis in the R script.

### <mark> An important note for this early version </mark>
This is the first release of R Runner and facilitates the basic task of executing R scripts within SAS Studio.  We'll consider additional improvements in future.

To set correct expectations,

- R Runner should NOT be considered an R editor / IDE for SAS Studio (though it's tempting for us, the creators, to label it so :)).   

- Given the recency of this step, there are bound to be teething troubles.  We appreciate your patience (and even more so, suggestions and contributions). 

- While this may seem obvious, do not expect syntax checks, highlighting or other convenience you are used to with R interfaces.


## SAS Viya Version Support
Tested in Viya 4, Stable 2023.08


## Requirements

This custom step accesses an R interpreter through a Python package (rpy2).  Therefore, ensure:

1. A SAS Viya 4 environment (monthly release 2023.08 or later) with SAS Studio Flows.  Earlier versions of Viya 4 (where Proc Python is supported) *should* be okay, as long as you understand the configuration for R_HOME and the packages involved. Try it out and let us know.

2. SAS Viya has access to an active Python and R environment.  Proc Python makes use of this Python environment.

3. The rpy2 Python package is installed and configured. Refer documentation for details on rpy2.

4. A path to R is available through the R_HOME environment variable.

5. Preferable / recommended:  Administrators could make use of the SAS Configurator for Open Source (also commonly known as sas-pyconfig) to install and configure Python and R access from SAS Viya.  Refer SAS Viya Deployment Guide (monthly stable 2023.08 onwards) for instructions on the same. Documentation provided below.


## Parameters:

### Input parameters:

1. Input Data (input port, optional): attach an input table (SAS dataset) to this port to facilitate analysis in R.  You should refer this input dataset as r_input_table inside the R script. 

2. Input R Script (file selector, optional):  attach an R script which you wish to execute.

3. R Snippet (text area, optional): use this for short (less than 32768 characters) snippets of R code you wish to execute.

Ensure your R script is styled and  indented as per R conventions to avoid failures.

4. R dataframe to output (text field, optional): refer an R dataframe (which exists in the R session) which you desire to output to a SAS dataset for downstream analysis.

5. Output table (output port, optional): attach a SAS dataset to this port which will contain data from a R dataframe you wish to output.

6. R_HOME path (Configuration tab, verify/change defaults): rpy2  needs to know where to find R on the system.  Change this default value after consulting your administrator.  The default is based on an environment where R and Python are installed using the SAS Configurator for Open Source (also known as sas-pyconfig) and sas-open-source-config utilities.


### Output specifications:

* Reference dataset for R environment variables (output port, optional) : attach a SAS dataset to the envData output port of this custom step to refer variables created during R execution.  These are known as R environment variables and can be accessed through the globalenvs attribute of the robjects object in rpy2 (documentation below).

## Documentation:

1. Documentation on the rpy2 package: [here](https://rpy2.github.io/doc/latest/html/introduction.html)

2. Access to R from inside a SAS Viya environment is governed by some environment variables, including R_HOME and DM_RHOME, used within this custom step to configure the rpy2 package.  Refer [this link](https://go.documentation.sas.com/doc/en/sasadmincdc/default/dplyml0phy0dkr/n08u2yg8tdkb4jn18u8zsi6yfv3d.htm#n0mq2y83d72jr8n1va9uuv04vx76) (and embedded references) for instructions on configuring open source environments with SAS Viya: 

3. This [SAS Communities article on R integration](https://communities.sas.com/t5/SAS-Communities-Library/Configuring-SAS-Viya-for-R-Integration/ta-p/848186) is also useful. Note especially the way that R_HOME is defined. 

4. The SAS Viya Platform Deployment Guide (refer to SAS Configurator for Open Source within): [here](https://go.documentation.sas.com/doc/en/itopscdc/default/itopssr/p1n66p7u2cm8fjn13yeggzbxcqqg.htm?fromDefault=#p19cpvrrjw3lurn135ih46tjm7oi) 


## Installation & Usage
- Refer to the [steps listed here](https://github.com/sassoftware/sas-studio-custom-steps#getting-started---making-a-custom-step-from-this-repository-available-in-sas-studio).


## Created / contact : 

- Samiul Haque (samiul.haque@sas.com)
- Sundaresh Sankaran (sundaresh.sankaran@sas.com)


## Some known issues & behavior:

This is not a comprehensive list of all known issues with rpy2. However, it's likely you may encounter some of these (given that you are working with THREE languages !) issues and the following links may be helpful.

1. Pandas may not transfer cleanly to R dataframe due to a mismatch in types: https://stackoverflow.com/questions/60197294/error-when-using-pandas-dataframe-in-r-cell-in-rpy2-jupyter-notebook

2. A table may be created but you are not able to access / export it.  This might be due to global envs vs. local sessions: https://stackoverflow.com/questions/15227926/rpy2-object-not-found-error


## Change Log

Version 1.0 (18AUG2023) 
* Initial Step Creation


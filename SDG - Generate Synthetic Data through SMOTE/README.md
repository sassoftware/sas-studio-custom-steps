# Synthetic Minority Oversampling TEchnique (SMOTE) 

This custom step helps you generate synthetic data based on an input table, using the Synthetic Minority Oversampling TEchnique (SMOTE). SMOTE is an oversampling technique which identifies new data observations in the neighborhood of closely associated original observations. 

SMOTE is an alternative approach to Generative Adversarial Networks (GANs) for generating synthetic tabular data. Access to synthetic data helps you make better, data-informed decisions in situations where you have imbalanced, scant, poor quality, unobservable, or restricted data.

## A general idea

This video (click on below image to play) provides a basic idea: 

[![SDG - SMOTE](./img/SDG_SMOTE.png)](https://www.youtube.com/watch?v=iVFv1ewVU20)

----
## Table of Contents
1. [Requirements](#requirements)
2. [Parameters](#parameters)
   1. [Input Parameters](#input-parameters)
   2. [Configuration](#configuration)
   3. [Output Specifications](#output-specifications)
3. [Run-time Control](#run-time-control)
4. [Documentation](#documentation)
5. [SAS Program](#sas-program)
6. [Installation and Usage](#installation--usage)
7. [Created/Contact](#createdcontact)
8. [Change Log](#change-log)
----
## Requirements

1. A SAS Viya 4 environment, preferably monthly stable 2024.10 or later

2. A Visual Data Mining and Machine Learning (VDMML) license, usually provided with SAS Viya, SAS Viya Enterprise or Advanced.

3. An active SAS Cloud Analytics Services (CAS) connection during runtime.

4. The smote.smoteSample CAS action requires Python configuration, as specified in [SAS documentation](https://go.documentation.sas.com/doc/en/pgmsascdc/default/casactml/casactml_smote_details01.htm). Please work with your SAS administrator to have the same configured. Specifically, ensure the following:

   1. The correct version of Python is installed (as of version 2024.10, this was 3.11.x)  
   2. [sas-ipc-queue](https://pypi.org/project/sas-ipc-queue/) , version atleast 0.7.0 and beyond 
   3. [hnswlib](https://pypi.org/project/hnswlib/)
   4. [protobuf](https://pypi.org/project/protobuf/)

### (OPTIONAL) Prerequisites for Singling Out Risk calculation

If you want to measure singling out risk (provided as an option in this step), note the following additional prerequisites:

1. SAS compute session should be configured to access a Python runtime of version of > 3.7 and < 3.12.

2. A Python package - [anonymeter](https://pypi.org/project/anonymeter/) - should be installed in the above runtime.  Make note of details about anonymeter at https://pypi.org/project/anonymeter/

3. As a further dependency on above, anonymeter requires NumPy between version 1.2 and less than 1.7 (specifically, "numpy >=1.22, <1.27", # limited by Numba support)

Note terms of anonymeter license here: https://github.com/statice/anonymeter/blob/main/LICENSE.md

Note citation in [Privacy Risk](#privacy-risk) section below.

-----
## Parameters
----
### Input Parameters

1. Input table (input port, required): connect a CAS table to the input port.

2. Nearest neighbors (numeric stepper, default 5): select the number of nearest neighbours to be used by the SMOTE algorithm as the basis for identifying candidate synthetic points.

3. Input columns (column selector): select all inputs for the SMOTE process.  You would also need to include the class and any nominal columns.

4. Nominal variables (column selector): select any nominal variables you wish to use. Your nominal variables are required to be in the inputs column list.

5. Select a class column (column selector, optional): select a column if you wish to use SMOTE in order to balance or augment a level within the class column.  Be judicious in the choice of this column since a column with a high number of levels may slow down or even fail the process.  Your class column is required to be in the inputs column list.

6. Class to augment (drop-down list, values from class column if selected): select the level of the class variable you wish to augment.  The values that appear here depend on the data that's contained in the class column, so may take time to populate based on actual data and number of levels.
----
### Privacy Risk
Synthetic data requires assurances on data privacy.  One aspect of privacy risk is singling out risk, which evolved alongside General Data Protection Regulation (GDPR).  **This is an optional step.**  If you wish to measure singling out risk,  enter the parameters below.

1. **Measure Singling Out Risk** (check box, default not checked):  select this option if you want to measure singling out risk.  Be aware of the Python dependencies (in Prerequisites section) and the fact that this involves a longer runtime in addition to the generation operation.

2. **Evaluation mode** (drop-down list): select either univariate or multivariate to define the type of attack query to be tested.

3. **Confidence interval** (percentage, numeric stepper): select a number from 90 to 99 to define the confidence level while providing privacy risk estimates.

4.  **Number of attacks** (numeric stepper, default 100) : enter number of attacks (queries) to simulate.

5. **Singling Out Risk Results table** (output port): attach a CAS table to the so_results_tbl output port to hold results.

6. **Singling Out Risk Queries table** (output port): attach a CAS table to the so_queries_tbl output port to hold results.

#### Citation for anonymeter

As we make use of an open-source package, anonymeter, to perform these calculations, we note the following citation: 

"A Unified Framework for Quantifying Privacy Risk in Synthetic Data", M. Giomi et al, PoPETS 2023. 

This bibtex entry refers to the paper:

```
@misc{anonymeter,
  doi = {https://doi.org/10.56553/popets-2023-0055},
  url = {https://petsymposium.org/popets/2023/popets-2023-0055.php},
  journal = {Proceedings of Privacy Enhancing Technologies Symposium},
  year = {2023},
  author = {Giomi, Matteo and Boenisch, Franziska and Wehmeyer, Christoph and Tasnádi, Borbála},
  title = {A Unified Framework for Quantifying Privacy Risk in Synthetic Data},
}
```


----
### Configuration 

1. **Number of threads:** (numeric stepper, optional):  most of the time, you do not need to modify this.  Change if you need to especially control the number of threads in which the process runs.

2. **Select a seed** (numeric field, optional): specify a seed number to establish (but not completely guarantee) some level of reproducability with respect to results.
3. **Select extrapolation factor**: specify a number (double) to use as a standard deviation in order to perturb (add noise or randomness) the input data boundaries. 
4. Name for synthetic data provenance variable (optional, default provided): insert a value only if you want to give a special name to a flag that indicates this data is synthetic.  Otherwise, a default name of Synthetic_Data_Provenance will be used instead.
5. Provide sampling percentage for assessment (numeric stepper, default is 0):  Enter a value between 0 and 100 to sample a test dataset before running SMOTE.  Note that the test dataset will NOT be used to generate data.  The test dataset will be appended with an equal number of observations from the synthetic dataset (along with the provenance flag described in #4) and can be used for assessment purposes.

----
### Output Specification


1. **Number of synthetic observations** (numeric field): specify the number of synthetic observations you would like in the output table.

2. **Output table** (output port, option): attach a CAS table to the output port to hold results.  

3. Assessment table (output port, optional): Attach a CAS table to the second output port (assessmentTable) of this step in case you select a sampling percentage (refer Configuration tab, pt #5) greater than 0.  A default value of PUBLIC.SMOTE_ASSESSMENT is assigned in case you do not specify a table.

----
## Run-time Control

Note: Run-time control is optional.  You may choose whether to execute the main code of this step or not, based on upstream conditions set by earlier SAS programs.  This includes nodes run prior to this custom step earlier in a SAS Studio Flow, or a previous program in the same session.

Refer this blog (https://communities.sas.com/t5/SAS-Communities-Library/Switch-on-switch-off-run-time-control-of-SAS-Studio-Custom-Steps/ta-p/885526) for more details on the concept.

The following macro variable,
```sas
_smt_run_trigger
```

will initialize with a value of 1 by default, indicating an "enabled" status and allowing the custom step to run.

If you wish to control execution of this custom step, include code in an upstream SAS program to set this variable to 0.  This "disables" execution of the custom step.

To "disable" this step, run the following code upstream:

```sas
%global _smt_run_trigger;
%let _smt_run_trigger =0;
```

To "enable" this step again, run the following (it's assumed that this has already been set as a global variable):

```sas
%let _smt_run_trigger =1;
```


IMPORTANT: Be aware that disabling this step means that none of its main execution code will run, and any  downstream code which was dependent on this code may fail.  Change this setting only if it aligns with the objective of your SAS Studio program.

----
## Documentation

1. [SAS documentation for the smote.smoteSample CAS action.](https://go.documentation.sas.com/doc/en/pgmsascdc/default/casactml/casactml_smote_details01.htm)

2. PyPi page for [sas-ipc-queue](https://pypi.org/project/sas-ipc-queue/) 

3. PyPi page for [hnswlib](https://pypi.org/project/hnswlib/)
4. PyPi page for [protobuf](https://pypi.org/project/protobuf/)
5. PyPi page for [anonymeter](https://pypi.org/project/anonymeter/)

----
## SAS Program

Refer [here](./extras/SDG_SMOTE_Synthetic_Data.sas) for the SAS program used by the step.  You'd find this useful for situations where you wish to execute this step through non-SAS Studio Custom Step interfaces such as the [SAS Extension for Visual Studio Code](https://github.com/sassoftware/vscode-sas-extension), with minor modifications. 

----
## Installation & Usage

- Refer to the [steps listed here](https://github.com/sassoftware/sas-studio-custom-steps#getting-started---making-a-custom-step-from-this-repository-available-in-sas-studio).

----
## Created/contact:  

- Sundaresh Sankaran (sundaresh.sankaran@sas.com)
- Josiah Chua (josiah.chua@sas.com)

Acknowledgements to others for their help on details, testing or exploring the area: 
- David Olaleye (david.olaleye@sas.com)
- Suneel Grover (suneel.grover@sas.com)
- Reza Nazari (reza.nazari@sas.com)
- SAS Analytics R&D team

----
## Change Log

* Version 1.3.1 (10DEC2024)
    * Add calculation for privacy risk (singling out risk)
* Version 1.2 (11NOV2024) 
    * Add provenance flag and sampling for assessment
* Version 1.1 (02NOV2024) 
    * Version for GitHub release
* Version 1.0 (10APR2024) 
    * Initial version
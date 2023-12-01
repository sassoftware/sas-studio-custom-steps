# Find Nearest Neighbors

The Find Nearest Neighbors Custom Step searches a base table to identify nearest neighbors to observations in an input query table, based on a distance formula.

This step facilitates  applications in recommendation engines, similarity analysis, search and others.  With an increased focus on generative AI, this step can be used to match embeddings to find similar documents and augment semantic search and large language models.

This custom step makes use of the fastknn.fastknn SAS Cloud Analytics Services (CAS) action.


## A general idea

![A general idea](./img/Find%20Nearest%20Neighbors.png)


## SAS Viya Version Support
Tested in Viya 4, Stable 2023.11


## Requirements

1. A SAS Viya environment, version 2023.11 or later

2. **At runtime: an active connection to CAS:** This custom step runs on data loaded to a SAS Cloud Analytics Services (CAS) library (known as a caslib). Ensure you are connected to CAS before running this step. 

3. This custom step requires a license for SAS Viya or higher to be able to run the fastknn.fastknn action.


## User Interface

### Input Parameters

1. Base table (input port, required): attach a CAS table to this port containing data to be searched against.

2. Query table (input port, required): attach a CAS table to this port containing data for which you would like to search nearest neighbors.

3. ID column (column selector, required): select a numeric column to serve as the unique identifier for each observation.

4. Input columns (column selector, required): select one or more numeric columns which will be used to calculate the distance measure which serves as the basis for selecting nearest neighbors.

### Settings

1. Distance threshold (stepper, default 100): select a threshold which will act as the maximum limit to calculate distance.

2. Search Method (drop-down list,  default is Approximate): select whether to use the Exact or Approximate search method.  Refer documentation for details.

3. Number of binary trees (stepper, upon selection of Approximate search method, default 10):  select the number of adjacent binary trees to which the search method will confine its search to.

4. Maximum number of points (stepper, upon selection of Approximate search method, default 100):  select maximum number of points to evaluate in a leaf node.

5. Parallelization method (set to current default of Query, not modifiable in this version):  this setting specifies whether the query table or the base table will be parallelized while conducting the search.  We have set this to the default value of Query for this initial version of the step and will explore providing the Input (base table) option in a future version.

### Output Specifications

1. Number of matches (stepper, default of 4): select maximum number of neighbors (similar observations) you would like for each observation. Note that selecting a higher number leads to longer computation time, wider set of columns for the output tables, and a larger distance table.

2. Output table (output port, required): attach a CAS table to this port.  This will hold the output data containing each ID column of the query table along with additional columns containing IDs of the neighbors identified.

3. Output Distance table (output port, required): attach a CAS table to this port.  This will hold a long dataset containing the ID from the query table, the neighbor ID from the base table and the Euclidean distance measure.


## Run Time Control

This is optional.  In some scenarios, you may wish to dynamically control whether this custom step runs or simply "passes through" without doing anything, in a SAS Studio session. The following macro variable is set to initialize with a value of 1 by default, indicating an "enabled" status and allowing the custom step to run.

Refer this [blog](https://communities.sas.com/t5/SAS-Communities-Library/Switch-on-switch-off-run-time-control-of-SAS-Studio-Custom-Steps/ta-p/885526) for more details on the concept.

```sas
/* To demonstrate the default value of the trigger macro variable */;

&_fnn_run_trigger.=1;
```

If you wish to control execution of this custom step programmatically (within a session, including execution of a SAS Studio Flow), make sure that an upstream SAS program sets the macro variable to 0.  Setting the value to 0 "disables" the execution of this custom step.

For example, to "disable" this step, run the following code upstream:

```sas
%global _fnn_run_trigger;
%let _fnn_run_trigger=0;
```

To "enable" this step again, run the following (it's assumed that this has already been set as a global variable):

```sas
%let _fnn_run_trigger=1;
```

**Important:** Be aware that disabling this step means that none of its main execution code will run, and any  downstream code which was dependent on this code may fail.  Change this setting only if it aligns with the objective of your SAS Studio program.


## Documentation

1. [The fastknn.fastknn Cloud Analytics Service (CAS) action](https://go.documentation.sas.com/doc/en/pgmsascdc/default/casactml/cas-fastknn-fastknn.htm)

2. [Useful SAS Communities article on the K-Nearest Neighbors algorithm](http://communities.sas.com/t5/SAS-Communities-Library/A-Simple-Introduction-to-K-Nearest-Neighbors-Algorithm/ta-p/565402)

3. [Details on the optional run-time trigger control](https://communities.sas.com/t5/SAS-Communities-Library/Switch-on-switch-off-run-time-control-of-SAS-Studio-Custom-Steps/ta-p/885526)

## SAS Program
Refer [here](./extras/Find%20Nearest%20Neighbours.sas) for the SAS program used by the step.  You'd find this useful for situations where you wish to execute this step through non-SAS Studio Custom Step interfaces such as the [SAS Extension for Visual Studio Code](https://github.com/sassoftware/vscode-sas-extension), with minor modifications. 


## Installation & Usage
- Refer to the [steps listed here](https://github.com/sassoftware/sas-studio-custom-steps#getting-started---making-a-custom-step-from-this-repository-available-in-sas-studio).


## Created / contact : 

- Sundaresh Sankaran (sundaresh.sankaran@sas.com)


## Change Log

* Version 1.0 (29NOV2023)
  * Initial Version


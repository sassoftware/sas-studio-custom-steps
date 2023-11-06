# Natural Language Processing (NLP) - Sentence Splitter

The "Sentence Splitter" custom step, as its name implies, splits a text column into multiple observations with constituent sentences, to enable further desired operations downstream.

Sentence-level analysis can improve Natural Language Processing (NLP) quality in some cases.  It aids feature-level sentiment analysis, early reads, data cleansing, and summarization.  For large documents, sentence-level analysis can also be more efficient than analysing the document as a whole.

Consider this as part of your preprocessing pipeline prior to model development.  This custom step requires a SAS Visual Text Analytics (VTA) license.
 
 
## A general idea (below picture's an animated gif)

![Sentence Splitter](./img/NLP%20-%20Sentence%20Splitter.gif)

## SAS Viya Version Support
Tested in Viya 4, Stable 2023.08

## Requirements

1. A SAS Viya 4 environment (monthly release 2023.08 or later) with SAS Studio Flows.

2. **At runtime: an active connection to CAS:** This custom step requires SAS Cloud Analytics Services (CAS). Ensure you have an active CAS connection available prior to running the same.

3. A SAS Visual Text Analytics (VTA) license. 


## User Interface

This custom step runs on data loaded to a SAS Cloud Analytics Services (CAS) library (known as a caslib).  Ensure you are connected to CAS before running this step.

Also, this step requires that you have assigned the Public caslib to map to the PUBLIC SAS library.   This is used to create an intermediate CAS table during the process. Assign the caslib once you have established a connection to CAS.

This custom step also requires a SAS Visual Text Analytics (VTA) license in order to run a sentence extraction model.

### Parameters:
1. Input table containing a text column (input port, required): attach a CAS table to this port. 

2. Language (drop-down list, default English): choose from the 33 languages supported by VTA.

3. Document ID column (column selector, required): select a column from the input table which acts as the unique identifier for the observation.

4. Text column (column selector, required): self-explanatory


#### Output specifications:

- Output table (output port, required): specify a CAS table to capture results at a sentence level
   - In addition to each sentence, the output table also contains a new observation ID (Obs_ID) which combines the original document ID with the sentence ID
   - The sentence ID is also recalculated to be in sync with its position in the original document.


#### Run-time control

**Note that this is optional.**  In some scenarios, you may wish to dynamically control whether this custom step runs or simply "passes through" without doing anything, in a SAS Studio session. The following macro variable is set to initialize with a value of 1 by default, indicating an "enabled" status and allowing the custom step to run.

Refer this [blog](https://communities.sas.com/t5/SAS-Communities-Library/Switch-on-switch-off-run-time-control-of-SAS-Studio-Custom-Steps/ta-p/885526) for more details on the concept.

```sas
/* To demonstrate the default value of the trigger macro variable */;

&_ss_run_trigger.=1;
```

If you wish to control execution of this custom step programmatically (within a session, including execution of a SAS Studio Flow), make sure that an upstream SAS program sets the macro variable to 0.  Setting the value to 0 "disables" the execution of this custom step.

For example, to "disable" this step, run the following code upstream:

```sas
%global _ss_run_trigger;
%let _ss_run_trigger=0;
```

To "enable" this step again, run the following (it's assumed that this has already been set as a global variable):

```sas
%let _ss_run_trigger=1;
```

**Important:** Be aware that disabling this step means that none of its main execution code will run, and any  downstream code which was dependent on this code may fail.  Change this setting only if it aligns with the objective of your SAS Studio program.


## Documentation:

1. This custom step borrows from the following [example](https://go.documentation.sas.com/doc/en/pgmsascdc/default/casvtapg/n104aqxy69w3phn13njmc3dn3own.htm) in SAS documentation

2. [Blog](https://blogs.sas.com/content/sgf/2018/07/26/how-to-tokenize-documents-into-sentences/) by Emily Gao, with an example

3. SAS Documentation for the [textRuleDevelop.compileConcept and textRuleDevelop.validateConcept](https://go.documentation.sas.com/doc/en/pgmsascdc/default/casvtapg/cas-textruledevelop-compileconcept.htm) actions (located in nearby section)

4. SAS Documentation for the [textRuleScore.applyConcept](https://go.documentation.sas.com/doc/en/pgmsascdc/default/casvtapg/cas-textrulescore-applyconcept.htm) action


## Installation & Usage
- Refer to the [steps listed here](https://github.com/sassoftware/sas-studio-custom-steps#getting-started---making-a-custom-step-from-this-repository-available-in-sas-studio).

## Created / contact : 

- Sundaresh Sankaran (sundaresh.sankaran@sas.com)

## Change Log

* Version 1.1 (03NOV2023) 
   * Better error messages & documentation - identified during review

* Version 1.0 (15SEP2023) 
   * Initial Step Creation
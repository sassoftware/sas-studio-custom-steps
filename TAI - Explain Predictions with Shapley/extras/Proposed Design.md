# Proposed Design

## Purpose

This step will be used to emulate the `Proc Shapley` so that the user doesn't need to hand-code the procedure. 

The step is designed to measure importantance of the output on an existing predictive model (Such as a forest or logistical regression). It's meant for users who already have the output from the model and want further detail on what the prediction means.

## What the procedure needs

1. **Input data table** — The table that contains the observations to explain. This is the query or scoring table (most often the output of the predictive model) that contains the input variables and the predicted target column.

2. **Reference data table** — Select a table that contains representative observations from the population used to train or score the model. `PROC SHAPLEY` uses this table when estimating how much each input variable contributes to a prediction. In most cases, this is a larger table containing many rows that are similar to the data used for model training.

3. **Input variables** — The model inputs used to explain the prediction. These are split into interval inputs and nominal inputs because `PROC SHAPLEY` needs to know the measurement level of each input variable.

4. **Predicted target** — The prediction column that's being explained. This is usually a column created by a scoring or modeling step, commonly with a `P_` prefix.

At least one interval input or nominal input must be selected. The predicted target must exist in the input data table.

## Design

  ### Options
  1. **Select an input data table:** Select the query or scored table that contains the observation to explain, the model input variables, and the predicted target column. 
  2. **Select a reference data table:** Select the background table used to estimate the contribution of each input variable.
  3. **Select interval inputs:** Select one or more numeric or continuous input variables to include in the `INPUT` statement with `LEVEL=INTERVAL`.
  4. **Select nominal inputs:** Select one or more categorical input variables to include in the `INPUT` statement with `LEVEL=NOMINAL`.
  5. **Select a predicted target:** Select the prediction column that `PROC SHAPLEY` should explain.
  6. **Select an analytic store model:** Optionally select an ASTORE table for the `ASTOREMODEL` statement.

### Configuration
  - **Select a weight variable:** Optionally select a weight column for the WEIGHT statement.

  - **Select a Shapley method:** Dropdown list containing:
    - HyperSHAP
    - KernelSHAP

The selected method controls which configuration options are displayed.

#### Options displayed for all methods:
  - **Specify the seed:** Optionally specify a random seed for reproducibility.
  - **Use raw data:** Specifies whether the procedure uses the original input observations instead of a summarized background distribution when calculating Shapley values. Using the raw data can provide a more detailed representation of the data but may increase processing time.

#### Options displayed only when HyperSHAP is selected:
  - **Depth:** Controls how many data samples are used to estimate each variable's contribution to the model's prediction. More samples generally lead to more accurate results.

#### Options displayed only when KernelSHAP is selected:
  - **Specify the bin width:** Specifies the bin width used by the KernelSHAP method to group values during Shapley value estimation. Smaller bin widths create finer groupings, which can produce more detailed results but may increase processing time. The default is 0.1.
  - **Include missing values for KernelSHAP:** Choose whether missing values should be included.
  - **Sample size:** Specifies the sample size used by the KernelSHAP method to estimate Shapley values. Increasing the sample size can improve the stability and accuracy of the estimates but might increase computation time. The default is 500.

### Basic PROC SHAPLEY example

The generated SAS code should follow this general structure. The specific statements included depend on what the user selects in the UI.

```sas
proc shapley data=mycas.query referencedata=mycas.reference;
   astoremodel rstore=mycas.forest_astore;
   input age amount duration / level=interval;
   input coapp foreign job / level=nominal;
   predictedtarget P_good_badbad;
   method hypershap(depth=1 seed=12345 userawdata);
run;
```

A KernelSHAP variation would use the same required structure but change the `METHOD` statement:

```sas
proc shapley data=mycas.query referencedata=mycas.reference;
   astoremodel rstore=mycas.forest_astore;
   input age amount duration / level=interval;
   input coapp foreign job / level=nominal;
   predictedtarget P_good_badbad;
   method kernelshap(binwidth=0.1 samplesize=500 seed=12345 includemissing userawdata);
run;
```

#### About tab

The About tab will summarize what the step does, list prerequisites, link to `PROC SHAPLEY` documentation, explain each UI control, and show the version and author information.
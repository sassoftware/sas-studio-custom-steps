# Nominal Dimensionality Reduction

## Description
Performs dimensionality reduction on nominal variables using SAS's PROC NOMINALDR. The step supports Multiple Correspondence Analysis (MCA) and Logistic Principal Component Analysis (LPCA) to reduce the dimensionality of categorical features for downstream modeling and analysis.

This custom step wraps the PROC NOMINALDR call with runtime guards, helpful defaults, and small cleanup routines so it can be executed either standalone or from SAS Studio Flows.

## User Interface

Refer to the "About" tab on this step in SAS Studio for more details.

### Parameters

1. **Input table (input port):** Select the input dataset containing nominal variables (required).
2. **Select nominal variables (column selector):** One or more nominal variables to reduce (required).
3. **Select other variables to copy (column selector):** Optional variables to pass through to the output.
4. **Select method (dropdown):** Choose `MCA` (Multiple Correspondence Analysis) or `LPCA` (Logistic Principal Components Analysis) (required).
5. **Select number of dimensions (numeric stepper):** Target number of dimensions.
6. **Specify output prefix (text field):** Prefix for generated reduced variable names (optional).
7. **Specify output table (output port):** Output dataset to save reduced variables (required).
8. **Specify RStore name (output port):** Optional RStore name to save model artifacts.

## Requirements

- SAS Viya with access to PROC NOMINALDR (CASML)
- SAS Viya monthly cadence of 2025.12 or later
- An execution environment where SAS Studio Flows can invoke the step.

## Installation & Usage

This step is delivered as a SAS Studio custom step. See the main repository README for installation and registration instructions for custom steps in SAS Studio.

This folder contains:
- The `.step` file (UI wrapper) which embeds the components JSON and references the SAS program.
- The `Nominal Dimensionality Reduction components.json` file (UI definition and About tab content).
- The `Nominal Dimensionality Reduction.sas` SAS program that executes the procedure.

Use the About tab and the step parameters in SAS Studio to configure inputs and outputs before running the step in a Flow.

## References
1. [Technical Paper, Nominal Variables Dimension Reduction Using SAS®, Yonggui Yan and Zohreh Asgharzadeh, SAS Institute](https://support.sas.com/content/dam/SAS/support/en/technical-papers/nominal-variables-dimension-reduction-using-sas.pdf)

2. [Documentation, PROC NOMINALDR, SAS Institute](https://go.documentation.sas.com/doc/en/sasstudiocdc/default/pgmsascdc/casml/casml_nominaldr_syntax.htm)

## Version

1.0.1 (23DEC2025)

## Contact

Sundaresh Sankaran (sundaresh.sankaran@sas.com)

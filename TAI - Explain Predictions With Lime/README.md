# TAI - Explain Predictions with LIME

## Description
The **Trustworthy AI (TAI) - Explain Predictions with LIME** custom step executes `PROC LIME` in SAS Viya to explain machine learning model predictions. It fits a local interpretable surrogate model (such as a LASSO regression) around a specific query observation. 

By analyzing the local behavior of a complex model, this step helps you understand which variables influenced a specific prediction. This increases transparency, aids in regulatory compliance, and helps technical and non-technical stakeholders trust and verify black-box machine learning models.

---
## Requirements
- **SAS Viya Environment:** Tested on monthly stable version **2026.05** or later.
- **SAS Cloud Analytics Services (CAS):** Since `PROC LIME` runs in CAS, input tables (Reference and Query data) must be loaded into a CAS library (e.g., `public`, `casuser`).

---
## Usage
1. Add the **TAI - Explain Predictions with LIME** step to your SAS Studio flow.
2. Connect your reference (background) data to the input port or select it in the **Design** tab.
3. Configure the query observation (either specify a query table or select the option to automatically use the first row of your reference data).
4. Map the predicted target and input variables (interval/nominal).
5. (Optional) Configure advanced options like ASTORE models, score code, distance weights, and explainer settings in the **Configuration** tab.
6. Run the flow to generate local model explanations.

---
## Parameters

### Design Parameters
- **Select reference data** (Input Table, Required): The background/reference data table containing model inputs and predictions.
- **Use the first row of the reference data as the query observation** (Checkbox, Optional): If checked, the step automatically extracts the first row of your reference table to use as the query observation.
- **Select query data** (Input Table, Optional): The table containing the specific query observation you want to explain. (Visible only when the checkbox above is unchecked).
- **Select predicted target column** (Column Selector, Required): The numeric variable containing the machine learning model's predictions.
- **Select interval inputs** (Column Selector, Optional): Numeric interval variables used as inputs for the model.
- **Select nominal inputs** (Column Selector, Optional): Nominal/categorical variables used as inputs for the model.

### Configuration Parameters

#### Model Options
- **Select analytic store model table 1, 2, 3** (Input Tables, Optional): Up to three Analytic Store (ASTORE) tables representing your trained ML model.
- **Select CODE statement source** (Dropdown, Required): Specify how score code is supplied. Options:
  - *Do not use a CODE statement*
  - *Use an external code file* (requires **Enter code file path**)
  - *Use a code table* (requires **Select code table**)

#### PROC LIME Options
- **Treat missing nominal values as valid levels** (Checkbox, Optional): If checked, missing values in nominal variables are treated as a distinct category.
- **Select log level** (Dropdown, Optional): Controls the notes printed to the SAS log (Default, 0 - Warnings & Errors, 1 - Some Notes, 2 - Many Notes).
- **Enter number of threads** (Numeric, Optional): Thread count for parallel execution.
- **Enter sample size** (Numeric, Optional): Number of synthetic observations to generate around the query observation for local model fitting.
- **Enter random seed** (Numeric, Optional): Seed value for reproducible synthetic sample generation.

#### Analysis Roles
- **Select weight column** (Column Selector, Optional): Specifies a numeric variable to weight the reference observations.
- **Select frequency column** (Column Selector, Optional): Specifies a numeric variable containing frequency counts for reference observations.

#### Distance Options
- **Enter exponential kernel denominator** (Numeric, Optional): Constant used to scale distance calculations.
- **Select missing value imputation method** (Dropdown, Required): Method to handle missing values during distance calculations (*None*, *Mean*, or *Weighted mean*).
- **Enter mixed distance weight** (Numeric, Optional): Scaling factor to balance interval and nominal inputs in mixed distance calculations.

#### Explainer Options
- **Enter maximum/minimum number of effects** (Numeric, Optional): Bounds on the number of effects the LASSO regression can select for the local explanation.
- **Select estimates to standardize** (Dropdown, Required): Standardize estimates for *None* or *Interval variables*.

#### Output Options
- **Create output table** (Output Table, Optional): Output table to capture the PROC LIME ODS results (containing local parameter estimates, fit statistics, and variable importances).

---
## Explanation Methods Supported
The step primarily leverages local surrogate modeling through **LIME (Local Interpretable Model-agnostic Explanations)**. By generating perturbed samples around a query point and weighting them based on distance, it approximates the decision boundary of complex black-box models. 

This framework is also structurally compatible with and supports:
- **KernelSHAP:** Local explanation via weighted linear regression mimicking Shapley value estimation.
- **HyperSHAP:** Advanced local explanation kernels optimized for high-dimensional or complex data structures.

---
## ASTORE & Code Requirements
When explaining predictions from complex models saved as analytic stores:
- **Single ASTORE:** You can supply one ASTORE table directly to score the generated local perturbation sample.
- **Multiple ASTOREs (Ensembles/Chains):** If you provide more than one ASTORE table (up to 3), SAS requires accompanying score code to coordinate how the model runs. In this scenario, you **must** set the **CODE statement source** parameter to either *FILE* or *TABLE* and provide the corresponding path or table.

---
## Limitations & Notes
- Input datasets must be accessible by your CAS session (CAS tables).
- Explanations are local and specific to the selected query observation; they do not represent global model rules.
- Generating very large sample sizes (e.g., >100,000) for complex models may increase execution times significantly depending on the available CAS threads.

---
## Change Log
- **Version: 1.0.0 (31JUL2026)**
  - Initial release supporting PROC LIME with customizable distance and explainer parameters.

---
## Contact
- [Dawn Pancholi](mailto:Shubham.Pancholi@sas.com)
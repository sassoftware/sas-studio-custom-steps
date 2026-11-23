# Surrogate Key Generator

:::note[**ACCESS THE CUSTOM STEP FOLDER**]

[Surrogate Key Generator](https://github.com/sassoftware/sas-studio-custom-steps/tree/main/Surrogate%20Key%20Generator)

:::


## Description

The "**Surrogate Key Generator**" custom step generates a surrogate key based on a business key.

## User Interface

* ### Surrogate Key Generator Settings tab ###
   ![](/img/Surrogate%20Key%20Generator/img/SGK-tab-SGKSettings-flow-mode.GIF)

* ### About tab ###
   ![](/img/Surrogate%20Key%20Generator/img/SKG-tab-About.GIF)

## Usage

### Surrogate Key Generator Settings tab tab

- **Business Key:**
Select the columns from the input table that constitute the business key.
- **Surrogate Key:**
The name of the column in the result table containing the surrogate key.

### Input Port
- Table with new records to assign surrogate key to.

### Output Port
- Table with new surrogate keys added.

## Change Log

* Version 1.0 (29SEP2022)
    * Inital version

# Import - Extract Table from PDF (requires Python package)

This custom step enables you to extract tabular data from within a PDF document and load the same to a SAS dataset.

**A Python package, tabula-py, is a pre-requisite for running this step. In addition, use of this custom step requires that SAS Studio is configured to run Python code.**

This custom step enables use-cases requiring import of structured data from text (unstructured) sources into SAS for downstream analysis. For example, PDFs relating to scientific research often contain a mix of text and tabular information, and such tabular information needs to retain its structure in order to be useful.


## A general idea

![Data Ingestion - Extract Table from PDF](./img/extract_table_general_idea.gif)


## SAS Viya Version Support
Tested in Viya 4, Stable 2023.03


## Requirements

1. A SAS Viya 4 environment (monthly release 2023.03 or later) with SAS Studio Flows.

2. Configure SAS Studio to run Python. This is usually carried out by a SAS administrator.  [This link](https://communities.sas.com/t5/SAS-Communities-Library/Configuring-SAS-Viya-for-Python-Integration/ta-p/847459)  provides some information to get started

3. Install the tabula-py Python package.  Visit the [PyPi page](https://pypi.org/project/tabula-py/) for details.  The tabula-py package uses the [tabula-java library](https://github.com/tabulapdf/tabula-java) under the covers, which requires a Java runtime to be installed and available to the environment.  This may not be an issue as SAS compute servers have Java installed.  Tabula-py also has a dependency on pandas, which is installed (along with other dependencies) when tabula-py is installed.


**Hint** : You may like to use the [Python -  Virtual Environments](https://github.com/sassoftware/sas-studio-custom-steps/blob/main/Python%20Virtual%20environments/README.md) folder within the SAS Studio Custom Steps GitHub repository to create a virtual environment with tabula-py installed.


## User Interface

### Parameters:

Note : In this version, we recommend that users specify a desired table and page number.  In case users do not know the specific page number / table number in advance, an initial run of this custom step will extract the first identified table, and also provide a list of all possible tabular structures that were gleaned from the PDF through a second output table.  Users may refer to the second output table and make a decision on which table number to specify.  The page number is useful if the user has it, but not strictly necessary.  Future versions shall look to incorporate more automation and convenience.  

Also note that quality of output is dictated completely by the capabilties of tabula-py, the Python package used within this custom step.  Tabula-py is not guaranteed to accurately identify all table structures from PDFs (which might have been generated from different sources in different ways).

#### Input parameters:

1. Input file (file selector required): select a PDF file which is location on the SAS server filesystem. PDFs located within SAS Content folders should not be chosen as this custom step does not support the same.

2. Page number (numeric field, optional): select a page on which your desired table is located. Leaving this field blank will lead to the first possible table across all pages getting extracted.

3. Table number (numeric field, optional): provide a number (starting from 1) indicating the table you want to extract.  For example, 1 extracts the first table on the specified page, 2 extracts the second and so on. Leaving this field blank sets the table number as 1.

#### Output specifications:

1. Output table (output port, required): connect an output SAS dataset  to contain the extracted table. 

2. All identified tabular structures (output port, connecting a table is optional) : connect an output SAS dataset to this port in order to capture a list of all possible table structures that tabula-py was able to capture from the PDF.  You can use this as reference in case you were unsure about the table number, and rerun the custom step after identifying an appropriate table number.

Important:  You might notice an error stating "Got stderr: Picked up _JAVA_OPTIONS: -Djava.awt.headless=true" in the log.  You can safely ignore the same, as this is due to a Java option which is not relevant to the environment under which this custom step is run.

Important: Your mileage might vary with the tabula-py package, but we’ve successfully tested with various PDFs.


## Documentation:

1. [Configuring SAS Viya for Python Integration](https://communities.sas.com/t5/SAS-Communities-Library/Configuring-SAS-Viya-for-Python-Integration/ta-p/847459)

2. [PyPi page for tabula-py](https://pypi.org/project/tabula-py/)

3. [Tabula-py documentation](https://tabula-py.readthedocs.io/en/latest/)

4. [Tabula-py GitHub project](https://github.com/chezou/tabula-py)


## Installation & Usage
- Refer to the [steps listed here](https://github.com/sassoftware/sas-studio-custom-steps#getting-started---making-a-custom-step-from-this-repository-available-in-sas-studio).


## Created / contact : 

1. [Sundaresh Sankaran](mailto:sundaresh.sankaran@sas.com)

2. [Dragos Coles](mailto:dragos.coles@sas.com)


## Change Log

Version : 1.0.   (01MAY2023)
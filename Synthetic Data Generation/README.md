# Synthetic Data Generation

## Description
Make better data-informed decisions, even in situations where you have imbalanced, scant, poor quality, unobservable, or restricted data!  This folder contains **four** SAS Studio custom steps which help you train, score and assess Synthetic Data models.  

A general idea :

### Training a Synthetic Data Model

![Training Flow](./img/general-idea-training-flow.png)

### Generating Synthetic Data

![Scoring Flow](./img/general-idea-scoring-flow.png)

Read this [blog](https://communities.sas.com/t5/SAS-Communities-Library/SAS-for-Synthetic-Data-Generation-in-Martech/ta-p/837716) for a general overview of applying these steps (taking Marketing Intelligence as an example).


## SAS Viya Version Support
Tested in Viya 4, Stable 2022.09

## User Interface

Refer the "About" tab on each of the individual steps for more details on what they are used for.

### Train a Synthetic Data Generator
This step helps you train a synthetic data generator model, using a Generative Adversarial Network. Parameters required :
1. Variables you wish to generate a Synthetic Data Generator for
2. Number of sample observations, for assessment purposes
3. Optional - training parameters such as number of epochs etc. (Advanced)
4. Input port - attach a training dataset
5. Output ports - attach tables for the sample observations and the desired model binary (astore).

![Train a Synthetic Data Generator](./img/train-a-synthetic-data-generator.png)

### Generate Synthetic Data
This step helps you generate new data using the trained astore. Parameters required:
1. Number of observations desired
2. Input Port - attach the astore referring the Generator you have trained
3. Output Port - attach a table referring the desired output table.

![Generate Synthetic Data](./img/generate-synthetic-data.png)

### Generate Distribution Comparison
This step helps you assess the distributions of your generated data with original data. Parameters required:
1. Select columns you wish to assess
2. Input Ports - attach the training (original) and the synthetic data tables


![Generate Distribution Comparison](./img/generate-distribution-comparison.png)

### Generate Correlation Comparison
This step helps you assess the correlation among variables in your generated and original data. Parameters required:
1. Select columns you wish to assess
2. Input Ports - attach the training (original) and the synthetic data tables


![Generate Correlation Comparison](./img/generate-correlation-comparison.png)


## Requirements

1. A SAS Viya 4 environment (monthly release 2022.09 or later) with SAS Studio Flows

## Installation & Usage

Refer to the [steps listed here](https://github.com/sassoftware/sas-studio-custom-steps#getting-started---making-a-custom-step-from-this-repository-available-in-sas-studio).

If you want to use the Home Equity sample data (HMEQ) used in the screenshots above to get started with these custom steps, then you can make them available in your SAS Studio session. This sample data set is part of the SAS sample data library (sampsio) which should be available in a standard SAS Viya deployment. But the library is not visible by default in the Libraries panel in SAS Studio. Here is how to make this library available:

* Open SAS Program using New -> SAS Program from the main menu
* Run the following SAS code to get a listing of all the SAS datasets in the sampsio sample library that should be part of a default SAS deployment
```sas
proc datasets library=sampsio; run;
```
* This will display a list of tables in the Results window and will make the library sampsio available in the Libraries panel for your current SAS Studio session
* TIP: Watch this [SAS Sample Data for Forecasting](https://www.youtube.com/watch?v=wX6mdBgYmXo&t=271s) recording on Youtube for more pointers to interesting sample data available from SAS

## Change Log

Version 1.0 (06OCT2022)


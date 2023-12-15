# CAS - Submit Python and R Code

## Description

The "**CAS - Submit Python and R Code**" provides a wrapping for the CAS action *gateway.runLang*.

Use this custom step to execute open-source programs, taking advantage of parallelization, multiple threads and fast data exchange mechanisms (backed by the Apache Arrow in-memory data format).

In the connect Python/R script you can access the input tables 1-10 like this:

**Python example:**  df = gateway.read_table(gateway.args['inputtable1'])
**R example:** tbl <- read_table(gw$args[['inputtable1']])

Here is an example for the output tables 1-10:

**Python example:** gateway.write_table(df, (gateway.args['outputtable1'])
**R example:** tbl <- write_table(gw$args[['outputtable1']])

In addition there are two variables available *inputTableCounter* and *outputTableCounter* which contain how many tables are connected to the step.

## User Interface

* ### Definition tab ###

   ![Definition](img/CAS-Submit-Python-and-R-Code-Definition.png)

* ### Options tab ###

   ![Options](img/CAS-Submit-Python-and-R-Code-Options.png)

## Requirements

SAS Viya 2023.11 or later

Ensure that Python and R are configured correctly according to the [SAS documentation](https://go.documentation.sas.com/doc/en/pgmsascdc/default/caspg/p1l6rncqa8tu8jn1pd05x8r1nwop.htm#n0c4rig8h837zhn1dm5yj6dpc7k0).

## Usage

Find a demonstration of this step in this YouTube video: [CAS - Submit Python and R Code | Custom Step](https://youtu.be/DFhVVVonkB4)

## Change Log

* Version 1.0 (19NOV2023)
    * Initial version

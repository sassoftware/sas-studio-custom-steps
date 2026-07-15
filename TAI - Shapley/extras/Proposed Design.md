# Proposed Design

This step will be used to emulate the Proc Shapley procedure designed to find Shapley Values to measure importantance of an observation to understand why a machine learning model predicted a specific output for a query. The design for the step will contain two tabs, one for items that are required for the procedure to compile and another for optional items. The exact items in each are below 

* Design
  * Select an Input Data Table (Input Table)
  * Select a Reference Data Table (Input Table)
  * Specify Interval Inupt (Column Selector that allows multiple columns)
  * Specify Nominal Inupt (Column Selector that allows multiple columns)
  * Specify the Predicted Target (Column Selector, Usually has a P_ prefix from the input table)
* Configuration
  * Weight (Column Selector that only allows one column)
  * AStoreModel (Inupt Table)
  * Method (List that triggers other options depending on what methods have been checked)
    * Hypershap
      * Seed (Numeric Stepper)
      * useRawData (Check Box on if it should be used or not)
      * Depth (Numeric Stepper with default of 1)
    * Kernelshap
      * Binwidth (Numeric Stepper with default of 0.1)
      * includeMissing (Check Box on if it should be used or not)
      * SampleSize (Numeric Stepper with default of 500)
      * Seed (Numeric Stepper)
      * useRawData (Check Box on if it should be used or not)

# Glossary - Get Term Types

## Description
This custom step extracts all term types, the term type attributes and, if available, the items you can choose from, for a given term type attribute.

The custom steps outputs 3 tables:

- A table with the focus on term type and its properties.
- A table with the term type attributes
- A table with the possible values an end-user can choose from for term type attributes of type 'single-select'.

For more details, see below.

## SAS Viya version support

This custom step is created and tested in Viya 4, Stable 2025.08

## User interface

### Tab: Options

![Options](img/Step%20-%20Options.png)
- **Sort by column:**: The column you select here will be used to sort the resulting table by. By dedault, the resulting table will be sorted based on the term type **name**.
- **Limit the number of returned values to:** Here you can limit the number of returned value. Note that the minimum value is 10 and the default value is 50.

### Tab: About

![About](img/Step%20-%20About.png)

## Usage

Download the .step file, upload it into your environment and start using it. The custom step generates three output tables.

Example flow:

![Usage](img/Step%20-%20Usage.png)

### Output table 1 (_output1)

Contains information on the term type and its properties.

|#| Column | Type | Comment |
|-|--------|------|---------|
|1| termTypeId | char(36) | The primary key for the term type.|
|2| version | integer ||
|3| name | char(512)||
|4| label | char(512) ||
|5| description | char(1024) ||
|6| usageCount | integer | Contains the number of terms for this term type. |
|7| attributeCount | integer | Contains the number of term type attributes |
|8| creationTimeStamp | datetime22.3 ||
|9| modifiedTimeStamp | datetime22.3 ||
|10| createdBy | char(64) ||
|11| modifiedBy | char(64) ||

### Output table 2 (_output2)

Contains, for each term type, the term type attributes and its properties.

|#| Column | Type | Comment |
|-|--------|------|---------|
|1| termTypeId | char(36) | The foreign key for the term type.|
|2| attributeId | char(36) | The primary key for the attribute.
|3| name | char(36) ||
|4| description | char(1024) ||
|5| type | char(32) ||
|6| required | integer | Is empty (=.) in case of No, 1 for Yes.|
|7| defaultValue | char(32) | Contains the default value for the given term type attribute.|

### Output table 3 (_output3)

Contains the possible values an end-user can choose from, when creating a term for the given term type and filling in a value for this given term type attribute(s).

|#| Column | Type | Comment |
|-|--------|------|---------|
|1| attributeId | char(36) | The foreign key for the attribute.
|2| value | char(32) | Contains the/a value an end-user can choose from. |


## Custom step messages
|#|Step message | Reason | Result |
|-|-----------|--------|--------|
|1|ERROR: Please select a location on the SAS Server. SAS Content folders are not supported by this custom step | The custom step only supports physical locations on the SAS compute environment | No export has been created.|
|2|ERROR: No response file received for macro 'getTermTypes'. Please review the log for more details.| A REST API call to the 'termTypes' endpoint was unsuccessful.| There's no response file available. The custom step is not able to continue for the specified Id. The resulting table might be not complete.|
|3|ERROR: No response file received for macro 'getTermTypeById'. Please review the log for more details.| A REST API call to the 'termTypes' endpoint was unsuccessful. | There's no response file available. The custom step is not able to continue for the specified Id. The resulting table might be not complete.

## Change log
- Version 1.1 (04FEB2026)
    - Cleaning libnames and filenames

- Version 1.0 (16JAN2025)
    - Initial version.
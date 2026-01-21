# Glossary - Get Terms by Term Type(s)

## Description
This custom step extracts for one or more term types the terms.

The custom step needs 1 input table:
- A table containing the term type id for which you want to extract the terms.

You can use the custom step '[**Glossary - Get Term Types**](../Glossary%20-%20Get%20Term%20Types/README.md)' to extract all term types, including the column termTypeId, defined by the SAS Viya system.

The custom steps outputs 2 tables:

- A table with the focus on the individual term and its properties.
- A table with the term attribute values

For more details, see below.

## SAS Viya version support

This custom step is created and tested in Viya 4, Stable 2025.08

## User interface

### Tab: Options

![Options](img/Step%20-%20Options.png)
- **Select the column containing the term type id:** Here you can select the column, from the input table, containing the term type id.
- **Sort by column:** Here you can select the column the custom step uses to sort **output table 1** by. The default value is **name**
- **Limit the number of returned values to:** Here you can limit the number of returned value. Note that the minimum value is 10 and the default value is 50.
- **Allow draft versions:** This option controls the extraction of terms that are in draft mode in the following manner:

|#| Value | Result |
|-|-------|--------|
|1| all| Extract all terms, including the ones in draft mode. 
|2| user | Extract all terms, including the ones assigned to/created by the user running the custom step that are in draft mode. **This is the default value**.
|3| none | Extract all terms, **excluding** the ones in draft mode.

### Tab: About

![About](img/Step%20-%20About.png)

## Usage

Download the .step file, upload it into your environment and start using it. The custom step generates two output tables.

Example flow:

![usage](img/Step%20-%20Usage.png)

In this example:
- The source table is generated and filled by the '[**Glossary - Get Term Types**](../Glossary%20-%20Get%20Term%20Types/README.md)' custom step, containing ALL term types.
- You can exclude the term types for which you do not want extract the terms.

### Output table 1 (_output1)

Contains information on the term and its properties.

|#| Column | Type | Comment |
|-|--------|------|---------|
|1| creationTimeStamp | datetime22.3 ||
|2| modifiedTimeStamp | datetime22.3 ||
|3| termId | char(36) | The primary key for this table |
|4| termTypeId | char(36) | The foreign key for the term type.|
|5| version | integer ||
|6| name | char(512)||
|7| description | char(8192) ||
|8| parentId | char(36) | Contains the parent termId |
|9| assetCount | integer | The number of times the term is assigned/related to a column in the SAS Information Catalog|
|10| isDraft | integer | Contains 1 in case the term is in draft mode, 0 otherwise.|
|11| Status | char(16) ||
|12| createdBy | char(64) ||
|13| modifiedBy | char(64) ||

### Output table 2 (_output2)

Contains, for each term , the attribute and the value for it.

|#| Column | Type | Comment |
|-|--------|------|---------|
|1| termId | char(36) | The foreign key for the term.|
|2| attributeId | char(36) | The foreign key for the attribute.
|3| attributeValue | char(1024) | Contains the value for the given term attribute.|

## Custom step messages
|#|Step message | Reason | Result |
|-|-----------|--------|--------|
|2|ERROR: No response file received for macro 'getTermTypes'. Please review the log for more details.| A REST API call to the 'termTypes' endpoint was unsuccessful.| There's no response file available. The custom step is not able to continue for the specified Id. The resulting table might be not complete.|
|3|ERROR: No response file received for macro 'getTermTypeById'. Please review the log for more details.| A REST API call to the 'termTypes' endpoint was unsuccessful. | There's no response file available. The custom step is not able to continue for the specified Id. The resulting table might be not complete.

## Change log
Version 1.0 (16JAN2025): Initial version.
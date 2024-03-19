# UI Guidelines

All SAS Studio provided steps follow certain UI guidelines. To provide consistency across steps, including custom steps, it is highly recommended 
that custom step contributions follow these guidelines.

A good example of a custom step that follows these guidelines is the **Sample controls** custom step. You can view it in the Custom Step Designer by going to the **Steps** panel, clicking the 
**New and sample custom steps** button in that panel, and selecting  **Sample controls**.

![](img/UI-guidelines-StepsPane-Use-SampleControls.png)

This opens the Custom Step Designer
![](img/UI-guidelines-SampleControls-Label-SentenceCapitalization-and-colon.png)

| UI Element | Capitalization | Remarks|
| --- | --- | --- |
| Tab labels | Title | Keep them short, preferably one or two words |
| Section labels | Sentence | Note: These labels should not end with a colon |
| Input/Output Table labels | Sentence | These labels should end with a colon. Keep in mind that when used in Standalone mode the Step UI displays these labels! |
| Field labels - Labels for any of the UI elements (checkboxes excluded) | Sentence | Put colons after labels. For example:  ***Select a column:***     <br><br>**Exceptions**<br><ul><li>Labels of checkboxes should not end with a colon</li><li>Labels of radio button groups when they represent a question and end with a question mark (?)</li></ul>|
| Values in lists <ul><li>Drop-down List</li><li>List</li><li>Radio Button Group</li></ul> | Sentence |
---
## Explanation of capitalization rules
  * Title capitalization:
     * Each word starts with capital. Prepositions (such as of, for, with), articles (a, an, the) and conjunctions (and, or, but) should not be initial-capped
  * Sentence capitalization:
     * Only first word is capitalized

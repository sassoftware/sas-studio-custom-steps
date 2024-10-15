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
---
## Considerations for About tab
As custom steps are delivered independent of SAS Studio releases, it is strongly recommend to add an About tab with at least the following information:
  * A General description section at the top that summarizes the functionality of the step
  * A Pre-requisites section that lists any specific pre-reqs. This section should be collapsed by default (uncheck "Open by default" in the Section control)
  * A Documentation section that points to relevant SAS documentation and/or points to other information that is relevant. This section should be collapsed by default.
     * If the step supports a long list of parameters that you want to also describe in the About tab (besides describing them in the README.md) then consider taking the approach as outlined in [IDEA: About tab using nested sections when describing a long list of options or parameters](https://github.com/sassoftware/sas-studio-custom-steps/issues/165)
  * A Changelog/Version section that at least lists the latest version and what was changed since the previous version. This is the only way for a consumer of the step to know which version they are working. This section should be expanded by default.
  *  The version number and release date in the About tab should be in sync with the info that is part of the full change log in the readme.md file for the step.
  *  Use self-explanatory names for the controls in the About tab

Note: See [_template.step in this folder](https://github.com/sassoftware/sas-studio-custom-steps/tree/main/_template) for a simple example.

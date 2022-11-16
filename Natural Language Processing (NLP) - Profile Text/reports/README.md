# NLP Text Profile Visual Analytics Report

This subfolder contains an additional asset to help you visualize output tables from the NLP - Profile Text Custom Step in an insightful manner.

## Instructions

Please follow this [video](./Instructions%20-%20Import%20VA%20report.mp4) for step-by-step instructions. The animated GIF below also describes the steps.

![Instructions - Import VA Report](./img/Demo%20-%20Import%20VA%20Report.gif)

### Steps, in brief:

1. There is a SAS Viya transfer package (a JSON file) in this folder which contains a Visual Analytics Report.
2. Inside Environment Manager within SAS Viya, click on Content and navigate to SAS Folders.
3. Click on the Import button as shown in the GIF.
4. Browse through your workstation and select the [transfer package](./NLP%20-%20Text%20Profile%20Package.json).
5. Move to the Mapping tab and click on Import
6. Wait a short while and ensure that 4 objects in total (3 folders and 1 SAS report object) have been imported successfully.
7. The report (Text_Profile) is now available at SAS Content -> Public -> NLP - Text Profile -> reports.

**Note that this report won't contain any data, yet.  The data will automatically refresh upon successful first run of the custom step.**


You can use the extras subfolder to store optional/special items related to your custom step.

Please do not store .step files, .zip files or sample data in this folder. 
* Some users have setup automated sync routines that extract all .step files and make them available in their SAS Viya deployment. 
  We don't want to break those routines.
* A zip file cannot be tracked by Git and is considered a dangerous file by some organizations. 
* If there is a need to highlight a previous version, then consider using a link in your README.md that points to the commit that contributed that version. This can be done as follow:
   * Open GitHub webUI for the repo and click on "Pull requests"
   * This lists the open pull requests, and displays a link for Closed pull request at the top of the table listing the open requests
   * Select the pull request of interest (you can type words to search for in the filters field), which will show details of the pull request
   * Click on the tab "Files changed"
   * Select the .step file, which will show the contents of the file
   * The panel showing the content of the file has a "..." menu at the top right, from that menu select "View file" 
   * This opens a new panel showing the "Code" in the file. At the top right of this panel there is a "Download raw file" button. 


Examples of files that could be included in this extras subfolder: 
* A SAS Export Package for your custom step, please use a ".package.json" extension for such a file.
* A .sas file containing a slighly modified/simplified version of the SAS code generator (macro) of your step for use in other SAS applications.
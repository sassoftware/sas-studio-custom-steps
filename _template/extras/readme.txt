You can use the extras subfolder to store optional/special items related to your custom step.

Please do not store .step files, .zip files or sample data in this folder. 
* Some users have setup automated sync routines that extract all .step files and make them available in their SAS Viya deployment. 
  We don't want to break those routines.
* A zip file cannot be tracked by Git and is considered a dangerous file by some organizations. 
* If there is a need to highlight a previous version, then consider using a link in your README.md that points to the commit that contributed that version.

Examples of files that could be included in this extras subfolder: 
* A SAS Export Package for your custom step, please use a ".package.json" extension for such a file.
* A .sas file containing a slighly modified/simplified version of the SAS code generator (macro) of your step for use in other SAS applications.
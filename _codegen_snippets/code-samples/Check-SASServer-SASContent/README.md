# Check SAS Server or SAS Content location

## Background

If your SAS code only supports files/folders on the SAS Server, or only supports files/folders stored in SAS Content, then you
need to check at runtime what the user has selected. The ***File or Folder Selector*** control currently does not support an attribute
for the step author to restrict the location type.

The SAS macro variable associated with the control has a value that starts with ***sasserver:*** or with ***sascontent:*** to indicate
the location type. 

Here is some simple SAS code to check if the user has selected a file (or folder) on the SAS Compute server:
```
data _null_;
   locationType=scan("&fileorfolderselector",1,":");
   if lowcase(locationType) ne "sasserver" then do;
      putlog "ERROR: Please select location on the SAS Server";
      abort;
   end;
run;
```

And similarly to check whether a SAS Content folder has been selected:
```
data _null_;
   locationType=scan("&fileorfolderselector",1,":");
   if lowcase(locationType) ne "sascontent" then do;
      putlog "ERROR: Please select a location in a SAS Content folder";
      abort;
   end;
run;
```
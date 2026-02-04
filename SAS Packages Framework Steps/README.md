# SAS Packages Framework Steps

## Description
The [SAS Packages Framework](https://github.com/yabwon/SAS_PACKAGES), created by [Bart Jablonski](https://github.com/yabwon), allows users to develop and use SAS packages:

> A SAS package is an automatically generated, single, stand alone zip file containing organised and ordered code structures, created by the developer and extended > with additional automatically generated "driving" files (i.e. description, metadata, load, unload, and help files).
>
> The purpose of a package is to be a simple, and easy to access, code sharing medium, which will allow: on the one hand, to separate the code complex dependencies > created by the developer from the user experience with the final product and, on the other hand, reduce developer's and user's unnecessary frustration related to > a remote deployment process.

These custom steps add an interface around the SAS Packages Framework, enabling SAS Packages to be easily embedded into a SAS Studio flow.

## Features
* Initialize, install, load, and update SAS packages in one step using the latest version from GitHub (default), your own URL, or a local `SPFInit.sas` file
* Choose from the rich ecosystem of SAS packages: [SASPAC](https://github.com/SASPAC), [PharmaForest](https://github.com/PharmaForest/), GitHub, or your own  custom repository
* Install, load, and unload SAS packages as individual steps for granular flow control
* Choose advanced options to load individual packages
* Get HTML results for package help, package previews, or a list of packages
* Get an inventory of packages on your system
* Viya File Service support<sup>*</sup>
* Comprehensive help tab within each step
* Connect together multiple steps within a single flow
* Specify packages as a list or from a file in one of five intuitive formats:
###### packages.txt
```
package
package(version)
package[version]
package{version}
package==version
```

**\* Not all features are supported. A physical disk or mounted network drive is highly recommended for package storage.**

## Quick Start Guide
1. Upload _Initialize SAS Packages Framework_ to SAS Viya
2. Add _Initialize SAS Packages Framework_ to a flow
3. Select a folder to store SAS Packages (a physical disk or mounted network drive is highly recommended)
4. In the _Install / Load_ tab, check the _Install packages_ and _Load packages_ options
5. Add a list of packages you wish to install and load from a repository; for example, [sqlInDs](https://github.com/SASPAC/sqlinds) from the SAS Packages repository
6. Run the step
7. Create a new SAS program and test your package code:

```sas
data hello_cars;
    set %sql(select * from sashelp.cars);
run;
```

## Example workflows

#### Initialize, install, and load packages, run code, then unload
<img width="397" height="124" alt="image" src="https://github.com/user-attachments/assets/59d8e860-5c1a-4d53-9f13-b10983703ab0" />

#### Initialize and install packages from two different sources, run code, then unload
<img width="602" height="246" alt="image" src="https://github.com/user-attachments/assets/5f619bd3-9cda-4236-9b01-70f2e2ddb91a" />

#### Initialize and load packages, run code, then unload
<img width="507" height="145" alt="image" src="https://github.com/user-attachments/assets/acd63441-1178-44c3-ba08-9b33e8d415db" />

#### Get help about packages
<img width="143" height="120" alt="image" src="https://github.com/user-attachments/assets/0465c4a0-1932-4a69-b967-f3c27a4dfaf5" />

## User Interface
#### Initialize:
<img width="438" height="299" alt="image" src="https://github.com/user-attachments/assets/31306608-5ac3-443d-8f6f-ac7344b4f0e3" />

<img width="653" height="519" alt="image" src="https://github.com/user-attachments/assets/026568ce-22ea-4d4b-8fa9-2f823d88bb8a" />

<img width="847" height="480" alt="image" src="https://github.com/user-attachments/assets/b95743a2-55dd-49db-8606-e02c7db92832" />

#### Install:
<img width="430" height="433" alt="image" src="https://github.com/user-attachments/assets/a25abf48-eef4-4d1d-a872-1e555b4300c6" />

#### Load:
<img width="468" height="433" alt="image" src="https://github.com/user-attachments/assets/2e49fa82-929a-4e5b-bec2-2567bbd233aa" />
<br/>
<img width="430" height="287" alt="image" src="https://github.com/user-attachments/assets/2ec58e04-20d2-443f-8d82-f109cde18edf" />

#### Unload:
<img width="426" height="269" alt="image" src="https://github.com/user-attachments/assets/4326e015-334d-4481-aa43-a635bcaf2994" />

#### Get Package Info:
<img width="427" height="419" alt="image" src="https://github.com/user-attachments/assets/d789f051-8652-40be-b5a3-47800bd21012" />

## SAS Viya Version Support

Tested on Viya 4, Stable 2025.12

## Requirements

- SAS Packages Framework (SPFInit.sas) 20251231 or higher

## Documentation:
- SAS Packages Framework: https://github.com/yabwon/SAS_PACKAGES

All documentation is provided within the **Help** section of each step. A general description of all available steps is provided below.

_Note: SAS packages must be created with SAS Packages macros. Package creation and modification steps are not available at this time._

#### Initialize SAS Packages Framework
Initializes the SAS Packages Framework, and optionally installs and loads packages in a single step.

#### Install SAS Packages
An independent step to install SAS packages.

#### Load SAS Packages
An independent step to load SAS packages.

#### Unload SAS Packages
Unload SAS packages from the current session.

#### Get Package Info
- Prints developer-provided package help and optionally generates a dataset of package content
- Prints a package preview
- Prints all SAS packages in the PACKAGES fileref and optionally generates a dataset with all packages to create an inventory

Results are printed to either HTML or the log.

## Created / contact:

- Custom Steps: Stu Sztukowski (stu.sztukowski@sas.com; https://github.com/stu-code)
- SAS Packages Framework: Bart Jablonski (https://github.com/yabwon)

## Change Log
- Version 1.0 (03FEB2026)
    - Initial version

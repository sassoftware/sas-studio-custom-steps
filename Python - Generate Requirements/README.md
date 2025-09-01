
# Python - Generate Requirements

---

This custom step helps you generate a requirements.txt file for your Python project or environment. You can either freeze all packages in a given Python environment, or generate requirements based on the imports used in a folder of Python scripts.

A general idea:
![Gif](./img/Python_Generate_Requirements.gif)

---# Python - Generate Requirements

## Description
Generate a `requirements.txt` file for your Python project or environment directly from SAS Studio. This custom step allows you to either:
- Freeze all packages in a given Python environment, or
- Generate requirements based on the imports used in a folder of Python scripts.

This enables reproducible, portable analytics workflows and helps ensure your Python dependencies are clearly documented for deployment or sharing.

A general idea of how to use steps related to virtual environments:

![General idea](./img/Python_Generate_Requirements.gif)

## User Interface

Refer to the "About" tab on this step in SAS Studio for more details.

### Parameters

This step helps you generate a requirements file. Input arguments required:

1. **What do you want to generate? (radio button group)**
   - Freeze all packages in a Python environment
   - Generate requirements from a folder of Python scripts

2. **Python environment folder (folder selector)**
   - The folder containing `/bin/python3` (required if freezing environment)

3. **Project folder (folder selector)**
   - The folder containing your Python scripts (required if generating from scripts)

4. **Requirements file path (file selector)**
   - The output path for the generated `requirements.txt` file

## Requirements

- SAS Viya 4 environment (tested on monthly release 2025.07) with SAS Studio Flows
- Python environment accessible to the SAS Compute Server
- Python package 'pipreqs' to be installed if you wish to generate requirements from Python scripts. Details [here](https://pypi.org/project/pipreqs/).

## Version

* 1.1.0 (01SEP2025)

## Contact:

- Sundaresh Sankaran (sundaresh.sankaran@sas.com)
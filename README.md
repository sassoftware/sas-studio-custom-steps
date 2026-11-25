# SAS Studio Custom Steps (for SAS Data and AI Studio)

## Overview

A custom step offers a user interface for SAS programs in SAS Studio (now known as [SAS Data and AI Studio](https://www.sas.com/en_us/software/data-and-ai-studio.html)). Using [SAS Studio Custom Steps](https://communities.sas.com/t5/SAS-Communities-Library/Explaining-Custom-Steps-using-SAS-Studio-Assets/ta-p/904444), data engineers and data scientists in SAS Viya can package specific tasks and integrate them into data pipelines, reuse code and collaborate with other stakeholders.

Watch this SAS video - [Create Custom Steps with SAS Data and AI Studio on SAS Viya](https://video.sas.com/detail/videos/sas-viya-quick-start/video/6347011003112/create-custom-steps-with-sas-studio?autoStart=true) - for a quick introduction. For more details see [SAS Documentation on Custom Steps in SAS Data and AI Studio](https://documentation.sas.com/?cdcId=webeditorcdc&cdcVersion=default&docsetId=webeditorsteps&docsetTarget=titlepage.htm). 

## List of Contributions

>[List of custom steps in this repository](https://github.com/sassoftware/sas-studio-custom-steps/blob/main/CUSTOM_STEPS_LIST.md)

## Repository Structure

Each custom step contribution resides in its own folder, named after the step, with the following **structure:**

```
Custom Step Name/
├── Custom Step Name.step
├── README.md
├── img/
    ├── Illustrative screenshot.png
└── extras/
    ├── Custom Step Name.sas
    └── Custom Step Name.json
    └── CHANGELOG.md
```

At a minimum, expect to find a `.step` file and a `README.md`.

* `Custom Step Name.step`: The custom step file, containing the SAS program and UI.
* `README.md`: Documentation describing the step, its requirements, and how to use it.
* `img/`: Optional but recommended. Screenshots and other images referenced in the documentation.
* `extras/`: Optional but recommended. Other useful artifacts associated with the custom step. These include separate copies of the step’s components (SAS program and UI configuration) for review and reference, and a detailed Changelog to capture previous versions of a custom step.


## Getting Started - Making a step from this repository available in SAS Data and AI Studio 

Follow the instructions on [Using a Custom Step from this GitHub repository in SAS Data and AI Studio](https://github.com/sassoftware/sas-studio-custom-steps/blob/main/docs/IMPORT_CUSTOM_STEP.md) to download custom steps from this repository and make them available for use in your SAS Data and AI Studio environment. 

It describes how to do this manually using standard GitHub webUI functionality and also contains a pointer to a SAS Communities blog entry describing how you could automate things using a SAS script and the SAS git functions.

## Contributing

We welcome contributions! Please read [CONTRIBUTING.md](https://github.com/sassoftware/sas-studio-custom-steps/blob/main/CONTRIBUTING.md) for details on how to submit contributions to this project.

## License

This project is licensed under the [Apache 2.0 License](https://github.com/sassoftware/sas-studio-custom-steps/blob/main/LICENSE).

## Additional Resources

* [SAS Documentation on Custom Steps in SAS Data and AI Studio](https://documentation.sas.com/?cdcId=webeditorcdc&cdcVersion=default&docsetId=webeditorsteps&docsetTarget=titlepage.htm)
* [SAS Demo - Create a Custom Step in SAS Data and AI Studio on SAS Viya (YouTube)](https://www.youtube.com/watch?v=vkI0mysfAkQ)
> [!TIP] 
> - [List of SAS code snippets for common tasks in code generator of a Custom Step](https://github.com/sassoftware/sas-studio-custom-steps/blob/main/_codegen_snippets/README.md)
> - [Tools to help you build, modify and unpack Custom Steps](https://pypi.org/project/py-sas-studio-custom-steps/)



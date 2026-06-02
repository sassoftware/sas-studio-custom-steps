# Changelog

This file documents notable, user-visible changes to the Rake (Kumade)
SAS Studio custom step.

## Version 1.3 (7May2026)

- Added a **Default** option to the time zone selection and changed the default value from `UTC` to `default`.
- Fixed incorrect handling of the `to=` parameter passed from the Custom Step UI.
- Added a UI option to extract the embedded `rake.sas` code from the Custom Step.
- Updated parameter documentation in `extras/MACRO.md` to reflect the revised time zone behavior.
- Refactored the custom step to comply with the `CONTRIBUTING.md` guidelines by embedding the macro logic directly in the step.
- Updated the public README and cleaned up auxiliary files under the `extras/` directory.

## Version 1.2.1 (19Nov2025)

- Changed the default setting of the log check option to *off*.

## Version 1.2 (15Nov2025)

- Added a time zone dropdown list to the Custom Step UI.
- Added time zone support (`tz=`) as a macro argument.
- Fixed an issue with absolute date/time specification for the `to=` parameter.

## Version 1.1 (27Dec2024)

- Added OpenSearch URL support to `RakeConfig.txt`.
- Added macro functions to save user credentials and the OpenSearch URL.
- Added a macro function to reset the OpenSearch URL.
- Updated the Custom Step UI to align with the new macro functions.
- Updated SAS system options to suppress source code logging in error messages.
- Removed temporary data sets `_SGSORT` and `CHECK`.

## Version 1.0 (24Jul2024)

- Added a Custom Step wrapper.
- Added TSV output functionality.
- Added the Custom Step for SAS Studio.

## Version 0.9 (25Jun2024)

- Added the `check` function for log inspection.

## Version 0.8 (19Jun2024)

- Initial release.

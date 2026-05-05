# Changelog

This file documents notable, user-visible changes to the Rake (Kumade)
SAS Studio custom step.

## Version 1.2.2 (2026-05-03)

- Refactored the custom step to comply with the `CONTRIBUTING.md` guidelines by embedding the macro logic directly in the step.
- Updated the public README and cleaned up auxiliary files under the `extras/` directory.

## Version 1.2.1 (2025-11-19)

- Changed the default setting of the log check option to *off*.

## Version 1.2 (2025-11-15)

- Added a time zone dropdown list to the Custom Step UI.
- Added time zone support (`tz=`) as a macro argument.
- Fixed an issue with absolute date/time specification for the `to=` parameter.

## Version 1.1 (2024-12-27)

- Added OpenSearch URL support to `RakeConfig.txt`.
- Added macro functions to save user credentials and the OpenSearch URL.
- Added a macro function to reset the OpenSearch URL.
- Updated the Custom Step UI to align with the new macro functions.
- Updated SAS system options to suppress source code logging in error messages.
- Removed temporary data sets `_SGSORT` and `CHECK`.

## Version 1.0 (2024-07-24)

- Added a Custom Step wrapper.
- Added TSV output functionality.
- Added the Custom Step for SAS Studio.

## Version 0.9 (2024-06-25)

- Added the `check` function for log inspection.

## Version 0.8 (2024-06-19)

- Initial release.
# :arrows_clockwise: Veeam VB365 As Built Report Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.1] - 2024-03-30

### Added

- Added License Usage Chart
- Improved Authentication Types in Notification section

### Changed

- Increase AsBuiltReport.Core modules to v1.4.0
- Migrate NOTOCHeading3 to NOTOCHeading4 to fix section heading

### Fixed

- Fix charts palette to follow new AsBuiltReport.Core theme
- Fix Diagram labelalloc when no Infrastructure is detected in Cluster Node
- Fix Encryption Keys Used At not displaying correct information
- Removed Used At column from Cloud Credentials table

## [0.3.0] - 2024-03-22

### Added

- Add Restore Session information section
- Add Restore Point information section
- Add Server Session History Retention section
- Add Organization Backup Application section
- Add Restore Operator Roles section
- Minor code improvements
- Add CodeQL security scanning
- Add Known Issues to the ReadMe file
- Add support for creation of Infrastructure diagrams
- Add Diagrammer.Core to the module requirements

### Changed

- Increase actions/checkout to v4

### Fixed

- Fix [#8](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365/issues/8)
- Fix [#9](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365/issues/9)
- Fix [#10](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365/issues/10)
- Fix [#12](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365/issues/12)
- Fix [#13](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365/issues/13)
- Fix [#14](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365/issues/14)
- Fix [#15](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365/issues/15)

## [0.2.0] - 2023-04-22

### Added
- Improved organization section
  - Added Office365 synchronization state
  - Added Office365 SharePoint Connection Settings
  - Added Office365 Exchange Connection Settings
- Added backup job status chart

## [0.1.1] - 2023-03-29

### Added
- Initial report release. Support for;
    - Backup Copy Job
    - Backup Job
    - Backup Repository
    - Backup Proxy
    - Cloud Credentials
    - Encryption Keys
    - License usage
    - Server Configuration
    - Object Repository
    - Organizations


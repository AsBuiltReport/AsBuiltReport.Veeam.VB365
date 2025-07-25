# :arrows_clockwise: Veeam VB365 As Built Report Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

##### This project is community maintained and has no sponsorship from Veeam, its employees or any of its affiliates.

## [0.3.12] - 2025-07-25

### Changed

- Bump version to 0.3.12
- Refactor diagram export logic for improved clarity
- Bump the `Diagrammer.Core` module to version `0.2.27`.
- Update PSScriptAnalyzer settings, enhance Release workflow, and modify output messages in Invoke-AsBuiltReport script
- Test with VB365 v8.1.2.180 P20250619

## [0.3.11] - 2025-05-05

### Added

- Add the `Export-AbrVb365Diagram` function to enhance diagram export capabilities.

### Changed

- Update the module version to `0.3.11`.
- Upgrade the `Diagrammer.Core` module to version `0.2.25`.
- Move the infrastructure diagram to appear as the first section in the report.
- Refactore `Write-PScriboMessage` calls to use the `-Message` parameter for consistency across scripts.

### Removed

- Remove unused diagram generation code.

## [0.3.10] - 2025-04-11

### Changed

- Bump module version to 0.3.10
- Update dependencies in changelog
- Improve diagram AdditionalInfo sorting
- Refactor Infrastructure Diagram generation logic for clarity and efficiency

## [0.3.9] - 2025-03-04

### Added

- Improve disk space information
- Improve RESTful API section details

### Changed

- Update GitHub release workflow for Bluesky integration
- Update sample report and diagram files
- Increase dependencies to latest versions

### Fixed

- Resolve issue with diagram watermark text generation

## [0.3.8] - 2024-11-12

### Added

- Add code to properly display diskspace information

### Changed

- Improve detection of empty fields in tables
- Improve detection of true/false elements in tables
- Update GitHub release workflow to add post to Bluesky social platform
- Increase Diagrammer.Core to v0.2.12
- Update Sample report & diagram files

## [0.3.7] - 2024-10-12

### Changed
Increase Diagrammer.Core to v0.2.12
- Improve infrastructure diagram
- Increase Diagrammer.Core to v0.2.9
- Update Sample Diagram

### Fixed

- Improved Proxy section CIMInstance code

## [0.3.6] - 2024-09-16

### Added

- Add diagram theming (Black/White/Neon)

### Changed

- Improve infrastructure diagram error handling
- Update Veeam default logo

## [0.3.5] - 2024-09-09

### Added

- Add Proxy Pool support

### Changed

- Migrate infrastructure diagram to use Diagrammer.Core's New-Diagrammer module

### Fixed

- Fix export diagram option using wrong filename

## [0.3.4] - 2024-09-03

### Added

- Add ExportDiagramsFormat option that allows specifying the format of the exported diagrams
  - Supported formats are dot, pdf, png, svg
- Initial compatibility tests with v8 were performed

### Changed

- Update Diagrammer.Core to v0.2.3

### Fixed

- Suppress Get-VBOObjectStorageRepository deprecation warning message

## [0.3.3] - 2024-07-06

### Changed

- Update Diagrammer.Core to v0.2.2

### Fixed

- Fix Diagram VBO Server not displaying version object

## [0.3.2] - 2024-05-25

### Changed

- Move 'Licensed Users' section to InfoLevel 2

### Fixed

- Fix [#23](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365/issues/23)
- Fix [#24](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365/issues/24)
- Fix [#25](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365/issues/25)
- Fix [#27](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365/issues/27)
- Fix [#28](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365/issues/28)
- Fix [#29](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365/issues/29)
- Fix [#30](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365/issues/30)
- Fix [#31](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365/issues/31)

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


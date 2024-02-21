<!-- ********** DO NOT EDIT THESE LINKS ********** -->
<p align="center">
    <a href="https://www.asbuiltreport.com/" alt="AsBuiltReport"></a>
            <img src='https://raw.githubusercontent.com/AsBuiltReport/AsBuiltReport/master/AsBuiltReport.png' width="8%" height="8%" /></a>
</p>
<p align="center">
    <a href="https://www.powershellgallery.com/packages/AsBuiltReport.Veeam.VB365/" alt="PowerShell Gallery Version">
        <img src="https://img.shields.io/powershellgallery/v/AsBuiltReport.Veeam.VB365.svg" /></a>
    <a href="https://www.powershellgallery.com/packages/AsBuiltReport.Veeam.VB365/" alt="PS Gallery Downloads">
        <img src="https://img.shields.io/powershellgallery/dt/AsBuiltReport.Veeam.VB365.svg" /></a>
    <a href="https://www.powershellgallery.com/packages/AsBuiltReport.Veeam.VB365/" alt="PS Platform">
        <img src="https://img.shields.io/powershellgallery/p/AsBuiltReport.Veeam.VB365.svg" /></a>
</p>
<p align="center">
    <a href="https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365/graphs/commit-activity" alt="GitHub Last Commit">
        <img src="https://img.shields.io/github/last-commit/AsBuiltReport/AsBuiltReport.Veeam.VB365/master.svg" /></a>
    <a href="https://raw.githubusercontent.com/AsBuiltReport/AsBuiltReport.Veeam.VB365/master/LICENSE" alt="GitHub License">
        <img src="https://img.shields.io/github/license/AsBuiltReport/AsBuiltReport.Veeam.VB365.svg" /></a>
    <a href="https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365/graphs/contributors" alt="GitHub Contributors">
        <img src="https://img.shields.io/github/contributors/AsBuiltReport/AsBuiltReport.Veeam.VB365.svg"/></a>
</p>
<p align="center">
    <a href="https://twitter.com/AsBuiltReport" alt="Twitter">
            <img src="https://img.shields.io/twitter/follow/AsBuiltReport.svg?style=social"/></a>
</p>
<!-- ********** DO NOT EDIT THESE LINKS ********** -->

# Veeam VB365 As Built Report

Veeam VB365 As Built Report is a PowerShell module which works in conjunction with [AsBuiltReport.Core](https://github.com/AsBuiltReport/AsBuiltReport.Core).

[AsBuiltReport](https://github.com/AsBuiltReport/AsBuiltReport) is an open-sourced community project which utilises PowerShell to produce as-built documentation in multiple document formats for multiple vendors and technologies.

Please refer to the AsBuiltReport [website](https://www.asbuiltreport.com) for more detailed information about this project.

# :books: Sample Reports

## Sample Report - Custom Style

Sample Veeam VB365 As Built report HTML file: [Sample Veeam VB365 As Built Report.html](https://htmlpreview.github.io/?https://raw.githubusercontent.com/rebelinux/AsBuiltReport.Veeam.VB365/dev/Samples/Sample%20Veeam%20VB365%20As%20Built%20Report.html)

Sample Veeam VB365 As Built report PDF file: [Sample Veeam VB365 As Built Report.pdf](https://github.com/rebelinux/AsBuiltReport.Veeam.VB365/raw/dev/Samples/Sample%20Veeam%20VB365%20As%20Built%20Report.pdf)

# :beginner: Getting Started
Below are the instructions on how to install, configure and generate a Veeam VB365 As Built report.

## :floppy_disk: Supported Versions
<!-- ********** Update supported VB365 versions ********** -->
The Veeam VB365 As Built Report supports the following Veeam Backup for Microsoft 365 version;

- Veeam Backup for Microsoft 365 v6+

### PowerShell
This report is compatible with the following PowerShell versions;

<!-- ********** Update supported PowerShell versions ********** -->
| Windows PowerShell 5.1 | PowerShell 7 |
| :--------------------: | :----------: |
|   :white_check_mark:   |     :x:      |
## :wrench: System Requirements
<!-- ********** Update system requirements ********** -->
PowerShell 5.1, and the following PowerShell modules are required for generating a Veeam VB365 As Built Report.

- [Veeam.Archiver.PowerShell Module](https://helpcenter.veeam.com/docs/vbo365/powershell/getting_started.html?ver=70)
- [PScriboCharts Module](https://github.com/iainbrighton/PScriboCharts)
- [AsBuiltReport.Veeam.VB365 Module](https://www.powershellgallery.com/packages/AsBuiltReport.Veeam.VB365/)

### :closed_lock_with_key: Required Privileges
<!-- ********** Define required privileges ********** -->
<!-- ********** Try to follow best practices to define least privileges ********** -->
Only users with Local Administrator group permissions can generate a Veeam VB365 As Built Report.


## :package: Module Installation

### PowerShell
<!-- ********** Add installation for any additional PowerShell module(s) ********** -->
```powershell
install-module AsBuiltReport.Veeam.VB365
```

### GitHub
If you are unable to use the PowerShell Gallery, you can still install the module manually. Ensure you repeat the following steps for the [system requirements](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365#wrench-system-requirements) also.

1. Download the code package / [latest release](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365/releases/latest) zip from GitHub
2. Extract the zip file
3. Copy the folder `AsBuiltReport.Veeam.VB365` to a path that is set in `$env:PSModulePath`.
4. Open a PowerShell terminal window and unblock the downloaded files with
    ```powershell
    $path = (Get-Module -Name AsBuiltReport.Veeam.VB365 -ListAvailable).ModuleBase; Unblock-File -Path $path\*.psd1; Unblock-File -Path $path\Src\Public\*.ps1; Unblock-File -Path $path\Src\Private\*.ps1
    ```
5. Close and reopen the PowerShell terminal window.

_Note: You are not limited to installing the module to those example paths, you can add a new entry to the environment variable PSModulePath if you want to use another path._

## :pencil2: Configuration

The Veeam VB365 As Built Report utilises a JSON file to allow configuration of report information, options, detail and healthchecks.

A Veeam VB365 report configuration file can be generated by executing the following command;
```powershell
New-AsBuiltReportConfig -Report Veeam.VB365 -FolderPath <User specified folder> -Filename <Optional>
```

Executing this command will copy the default Veeam VB365 report JSON configuration to a user specified folder.

All report settings can then be configured via the JSON file.

The following provides information of how to configure each schema within the report's JSON file.

<!-- ********** DO NOT CHANGE THE REPORT SCHEMA SETTINGS ********** -->
### Report
The **Report** schema provides configuration of the Veeam VB365 report information.

| Sub-Schema          | Setting      | Default                     | Description                                                  |
| ------------------- | ------------ | --------------------------- | ------------------------------------------------------------ |
| Name                | User defined | Veeam VB365 As Built Report | The name of the As Built Report                              |
| Version             | User defined | 1.0                         | The report version                                           |
| Status              | User defined | Released                    | The report release status                                    |
| ShowCoverPageImage  | true / false | true                        | Toggle to enable/disable the display of the cover page image |
| ShowTableOfContents | true / false | true                        | Toggle to enable/disable table of contents                   |
| ShowHeaderFooter    | true / false | true                        | Toggle to enable/disable document headers & footers          |
| ShowTableCaptions   | true / false | true                        | Toggle to enable/disable table captions/numbering            |

### Options

The **Options** schema allows certain options within the report to be toggled on or off.

| Sub-Schema       | Setting  | Default | Description                                       |
| ---------------- | -------- | ------- | ------------------------------------------------- |
| BackupServerPort | TCP Port | 9191    | Used to specify the backup service's custom port. |


<!-- ********** Add/Remove the number of InfoLevels as required ********** -->
### InfoLevel
The **InfoLevel** schema allows configuration of each section of the report at a granular level. The following sections can be set.

There are 3 levels (0-2) of detail granularity for each section as follows;

| Setting | InfoLevel         | Description                                                          |
| :-----: | ----------------- | -------------------------------------------------------------------- |
|    0    | Disabled          | Does not collect or display any information                          |
|    1    | Enabled / Summary | Provides summarised information for a collection of objects          |
|    2    | Adv Summary       | Provides condensed, detailed information for a collection of objects |

The table below outlines the default and maximum **InfoLevel** settings for each Infrastructure section.

| Sub-Schema      | Default Setting | Maximum Setting |
| --------------- | :-------------: | :-------------: |
| ServerConfig    |        1        |        1        |
| License         |        1        |        1        |
| Proxy           |        1        |        2        |
| Repository      |        1        |        2        |
| Organization    |        1        |        2        |
| EncryptionKey   |        1        |        2        |
| CloudCredential |        1        |        2        |

The table below outlines the default and maximum **InfoLevel** settings for each Jobs section.

| Sub-Schema    | Default Setting | Maximum Setting |
| ------------- | :-------------: | :-------------: |
| BackupJob     |        1        |        2        |
| BackupCopyJob |        1        |        2        |

### Healthcheck
The **Healthcheck** schema is used to toggle health checks on or off.

## :computer: Examples

There are a few examples listed below on running the AsBuiltReport script against a Veeam Backup Server. Refer to the `README.md` file in the main AsBuiltReport project repository for more examples.

```powershell
# Generate a Veeam VB365 As Built Report for Backup Server 'veeam-vbr365.pharmax.local' using specified credentials. Export report to HTML & DOCX formats. Use default report style. Append timestamp to report filename. Save reports to 'C:\Users\Jon\Documents'
PS C:\> New-AsBuiltReport -Report Veeam.VB365 -Target veeam-vbr365.pharmax.local -Username 'Domain\veeam_admin' -Password 'P@ssw0rd' -Format Html,Word -OutputFolderPath 'C:\Users\Jon\Documents' -Timestamp

# Generate a Veeam VB365 As Built Report for Backup Server veeam-vbr365.pharmax.local using specified credentials and report configuration file. Export report to Text, HTML & DOCX formats. Use default report style. Save reports to 'C:\Users\Jon\Documents'. Display verbose messages to the console.
PS C:\> New-AsBuiltReport -Report Veeam.VB365 -Target veeam-vbr365.pharmax.local -Username 'Domain\veeam_admin' -Password 'P@ssw0rd' -Format Html,Word -OutputFolderPath 'C:\Users\Jon\Documents' -ReportConfigFilePath 'C:\Users\Jon\AsBuiltReport\AsBuiltReport.Veeam.VB365.json' -Verbose

# Generate a Veeam VB365 As Built Report for Backup Server veeam-vbr365.pharmax.local using stored credentials. Export report to HTML & Text formats. Use default report style. Highlight environment issues within the report. Save reports to 'C:\Users\Jon\Documents'.
PS C:\> $Creds = Get-Credential
PS C:\> New-AsBuiltReport -Report Veeam.VB365 -Target veeam-vbr365.pharmax.local -Credential $Creds -Format Html,Text -OutputFolderPath 'C:\Users\Jon\Documents' -EnableHealthCheck

# Generate a Veeam VB365 As Built Report for Backup Server veeam-vbr365.pharmax.local using stored credentials. Export report to HTML & DOCX formats. Use default report style. Reports are saved to the user profile folder by default. Attach and send reports via e-mail.
PS C:\> New-AsBuiltReport -Report Veeam.VB365 -Target veeam-vbr365.pharmax.local -Username 'Domain\veeam_admin' -Password 'P@ssw0rd' -Format Html,Word -OutputFolderPath 'C:\Users\Jon\Documents' -SendEmail

```

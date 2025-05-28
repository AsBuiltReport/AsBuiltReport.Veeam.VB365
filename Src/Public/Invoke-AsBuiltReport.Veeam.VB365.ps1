function Invoke-AsBuiltReport.Veeam.VB365 {
    <#
    .SYNOPSIS
        PowerShell script to document the configuration of Veeam VB365 in Word/HTML/Text formats
    .DESCRIPTION
        Documents the configuration of Veeam VB365 in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.11
        Author:         Jonathan Colon
        Twitter:        @jcolonzenpr
        Github:         @rebelinux
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365
    #>

    # Do not remove or add to these parameters
    param (
        [String[]] $Target,
        [PSCredential] $Credential
    )

    #Requires -Version 5.1
    #Requires -PSEdition Desktop
    #Requires -RunAsAdministrator

    if ($psISE) {
        Write-Error -Message "You cannot run this script inside the PowerShell ISE. Please execute it from the PowerShell Command Window."
        break
    }

    Write-PScriboMessage -Plugin "Module" -IsWarning -Message "Please refer to the AsBuiltReport.Veeam.VB365 github website for more detailed information about this project."
    Write-PScriboMessage -Plugin "Module" -IsWarning -Message "Do not forget to update your report configuration file after each new version release."
    Write-PScriboMessage -Plugin "Module" -IsWarning -Message "Documentation: https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365"
    Write-PScriboMessage -Plugin "Module" -IsWarning -Message "Issues or bug reporting: https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365/issues"
    Write-PScriboMessage -Plugin "Module" -IsWarning -Message "This project is community maintained and has no sponsorship from Veeam, its employees or any of its affiliates."

    # Check the version of the dependency modules
    $ModuleArray = @('AsBuiltReport.Veeam.VB365', 'Diagrammer.Core')

    foreach ($Module in $ModuleArray) {
        Try {
            $InstalledVersion = Get-Module -ListAvailable -Name $Module -ErrorAction SilentlyContinue | Sort-Object -Property Version -Descending | Select-Object -First 1 -ExpandProperty Version

            if ($InstalledVersion) {
                Write-Host "- $Module module v$($InstalledVersion.ToString()) is currently installed."
                $LatestVersion = Find-Module -Name $Module -Repository PSGallery -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Version
                if ($InstalledVersion -lt $LatestVersion) {
                    Write-Host "  - $Module module v$($LatestVersion.ToString()) is available." -ForegroundColor Red
                    Write-Host "  - Run 'Update-Module -Name $Module -Force' to install the latest version." -ForegroundColor Red
                }
            }
        } Catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    # Import Report Configuration
    $script:Report = $ReportConfig.Report
    $script:InfoLevel = $ReportConfig.InfoLevel
    $script:Options = $ReportConfig.Options

    # Set Custom styles for Veeam theme template
    if ($Options.ReportStyle -eq "Veeam") {
        & "$PSScriptRoot\..\..\AsBuiltReport.Veeam.VB365.Style.ps1"
    } else {
        # Set Custom styles for Default AsBuiltReport template
        Style -Name 'ON' -Size 8 -BackgroundColor '4c7995' -Color 4c7995
        Style -Name 'OFF' -Size 8 -BackgroundColor 'ADDBDB' -Color ADDBDB
    }

    # Used to set values to TitleCase where required
    $script:TextInfo = (Get-Culture).TextInfo

    #region foreach loop
    foreach ($System in $Target) {

        Get-AbrVB365RequiredModule -Name 'Veeam.Archiver.PowerShell' -Version '6.0'
        Get-AbrVB365ServerConnection

        $script:VeeamBackupServer = ((Get-VBOServerComponents -Name Server).ServerName).ToString().ToUpper().Split(".")[0]
        $script:VBOversion = try { (Get-VBOVersion).ProductVersion } catch { Out-Null }

        #---------------------------------------------------------------------------------------------#
        #                            Backup Infrastructure Section                                    #
        #---------------------------------------------------------------------------------------------#

        Section -Style Heading1 $($VeeamBackupServer) -Orientation Portrait {
            Paragraph "The following section provides an overview of the implemented components of Veeam Backup for Microsoft 365."
            BlankLine

            #---------------------------------------------------------------------------------------------#
            #                            Export Infrastructure Diagram Section                            #
            #---------------------------------------------------------------------------------------------#

            Export-AbrVb365Diagram

            Get-AbrVb365InstalledLicense
            Get-AbrVb365ServerConfiguration
            Get-AbrVb365CloudCredential
            Get-AbrVb365EncryptionKey
            Get-AbrVb365ServerComponent
            Get-AbrVb365Proxy
            Get-AbrVb365ObjectRepository
            Get-AbrVb365BackupRepository
            Get-AbrVb365RestoreOperator
            Get-AbrVb365Organization
            Get-AbrVb365BackupJob
            Get-AbrVb365RestoreSession
            Get-AbrVb365RestorePoint
        }
    } #endregion foreach loop
}
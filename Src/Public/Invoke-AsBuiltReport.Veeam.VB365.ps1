function Invoke-AsBuiltReport.Veeam.VB365 {
    <#
    .SYNOPSIS
        PowerShell script to document the configuration of Veeam VB365 in Word/HTML/Text formats
    .DESCRIPTION
        Documents the configuration of Veeam VB365 in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.4.0
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
    #Requires -RunAsAdministrator

    if ($psISE) {
        Write-Error -Message 'You cannot run this script inside the PowerShell ISE. Please execute it from the PowerShell Command Window.'
        break
    }

    # Import Report Configuration
    $script:Report = $ReportConfig.Report
    $script:InfoLevel = $ReportConfig.InfoLevel
    $script:Options = $ReportConfig.Options


    # Check the version of the dependency modules
    if ($Options.UpdateCheck) {
        Write-ReportModuleInfo -ModuleName 'AsBuiltReport.Veeam.VB365'
    }
    Write-Host ' - To sponsor this project, please visit: ' -NoNewline
    Write-Host 'https://ko-fi.com/F1F8DEV80' -ForegroundColor Cyan

    if ($Options.UpdateCheck) {
        Write-Host ' - Getting dependency information:'
        # Check the version of the dependency modules
        $ModuleArray = @('AsBuiltReport.Diagram', 'AsBuiltReport.Chart')

        foreach ($Module in $ModuleArray) {
            try {
                $InstalledVersion = Get-Module -ListAvailable -Name $Module -ErrorAction SilentlyContinue | Sort-Object -Property Version -Descending | Select-Object -First 1 -ExpandProperty Version

                if ($InstalledVersion) {
                    Write-Host "    - $Module module v$($InstalledVersion.ToString()) is currently installed."
                    $LatestVersion = Find-Module -Name $Module -Repository PSGallery -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Version
                    if ($InstalledVersion -lt $LatestVersion) {
                        Write-Host "      - $Module module v$($LatestVersion.ToString()) is available." -ForegroundColor Red
                        Write-Host "      - Run 'Update-Module -Name $Module -Force' to install the latest version." -ForegroundColor Red
                    }
                }
            } catch {
                Write-PScriboMessage -IsWarning $_.Exception.Message
            }
        }
    }

    # Set Custom styles for Veeam theme template
    if ($Options.ReportStyle -eq 'Veeam') {
        & "$PSScriptRoot\..\..\AsBuiltReport.Veeam.VB365.Style.ps1"
    } else {
        # Set Custom styles for Default AsBuiltReport template
        Style -Name 'ON' -Size 8 -BackgroundColor '4c7995' -Color 4c7995
        Style -Name 'OFF' -Size 8 -BackgroundColor 'ADDBDB' -Color ADDBDB
    }

    #Used to set values to TitleCase where required
    $script:TextInfo = (Get-Culture).TextInfo

    #region foreach loop
    foreach ($System in $Target) {
        if (Select-String -InputObject $System -Pattern '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
            throw "IP address format is not supported for the Target parameter. Please provide a hostname or FQDN for the Veeam Backup Server Host: $System"
        }

        Get-AbrVB365RequiredModule -Name 'Veeam.Archiver.PowerShell' -Version '6.0'
        Get-AbrVB365ServerConnection

        $script:VeeamBackupServer = ((Get-VBOServerComponents -Name Server).ServerName).ToString().ToUpper().Split('.')[0]
        $script:VBOversion = try { (Get-VBOVersion).ProductVersion } catch { Out-Null }
        if ($script:VBOversion) {
            Write-PScriboMessage -Message "Detected Veeam VB365 product version $($script:VBOversion)."
        }

        #---------------------------------------------------------------------------------------------#
        #                            Backup Infrastructure Section                                    #
        #---------------------------------------------------------------------------------------------#

        Section -Style Heading1 $($VeeamBackupServer) {
            Paragraph 'The following section provides an overview of the implemented components of Veeam Backup for Microsoft 365.'
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

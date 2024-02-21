function Invoke-AsBuiltReport.Veeam.VB365 {
    <#
    .SYNOPSIS
        PowerShell script to document the configuration of Veeam VB365 in Word/HTML/Text formats
    .DESCRIPTION
        Documents the configuration of Veeam VB365 in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.2.1
        Author:         Jonathan Colon
        Twitter:
        Github:
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365
    #>

    # Do not remove or add to these parameters
    param (
        [String[]] $Target,
        [PSCredential] $Credential
    )

    Write-PScriboMessage -IsWarning "Please refer to the AsBuiltReport.Veeam.VB365 github website for more detailed information about this project."
    Write-PScriboMessage -IsWarning "Do not forget to update your report configuration file after each new version release."
    Write-PScriboMessage -IsWarning "Documentation: https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365"
    Write-PScriboMessage -IsWarning "Issues or bug reporting: https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365/issues"

    # Check the current AsBuiltReport.Veeam.VB365 module
    Try {
        $InstalledVersion = Get-Module -ListAvailable -Name AsBuiltReport.Veeam.VB365 -ErrorAction SilentlyContinue | Sort-Object -Property Version -Descending | Select-Object -First 1 -ExpandProperty Version

        if ($InstalledVersion) {
            Write-PScriboMessage -IsWarning "AsBuiltReport.Veeam.VB365 $($InstalledVersion.ToString()) is currently installed."
            $LatestVersion = Find-Module -Name AsBuiltReport.Veeam.VB365 -Repository PSGallery -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Version
            if ($LatestVersion -gt $InstalledVersion) {
                Write-PScriboMessage -IsWarning "AsBuiltReport.Veeam.VB365 $($LatestVersion.ToString()) is available."
                Write-PScriboMessage -IsWarning "Run 'Update-Module -Name AsBuiltReport.Veeam.VB365 -Force' to install the latest version."
            }
        }
    } Catch {
        Write-PScriboMessage -IsWarning $_.Exception.Message
    }

    # Import Report Configuration
    $script:Report = $ReportConfig.Report
    $script:InfoLevel = $ReportConfig.InfoLevel
    $script:Options = $ReportConfig.Options

    # Used to set values to TitleCase where required
    $script:TextInfo = (Get-Culture).TextInfo

    #region foreach loop
    foreach ($System in $Target) {

        Get-AbrVB365RequiredModule -Name 'Veeam.Archiver.PowerShell' -Version '6.0'
        Get-AbrVB365ServerConnection

        $VeeamBackupServer = ((Get-VBOServerComponents -Name Server).ServerName).ToString().ToUpper().Split(".")[0]

        Section -Style Heading1 $($VeeamBackupServer) {
            Paragraph "The following section provides an overview of the implemented components of Veeam Backup for Microsoft 365."
            BlankLine
            #---------------------------------------------------------------------------------------------#
            #                            Backup Infrastructure Section                                    #
            #---------------------------------------------------------------------------------------------#

            Get-AbrVb365InstalledLicense
            Get-AbrVb365ServerConfiguration
            Get-AbrVb365CloudCredential
            Get-AbrVb365EncryptionKey
            Get-AbrVb365ServerComponent
            Get-AbrVb365Proxy
            Get-AbrVb365ObjectRepository
            Get-AbrVb365BackupRepository
            Get-AbrVb365Organization
            Get-AbrVb365BackupJob
        }

    }
    #endregion foreach loop
}

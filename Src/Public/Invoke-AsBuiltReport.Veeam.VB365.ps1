function Invoke-AsBuiltReport.Veeam.VB365 {
    <#
    .SYNOPSIS
        PowerShell script to document the configuration of Veeam VB365 in Word/HTML/Text formats
    .DESCRIPTION
        Documents the configuration of Veeam VB365 in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.0
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

    Write-PScriboMessage -Plugin "Module" -IsWarning "Please refer to the AsBuiltReport.Veeam.VB365 github website for more detailed information about this project."
    Write-PScriboMessage -Plugin "Module" -IsWarning "Do not forget to update your report configuration file after each new version release."
    Write-PScriboMessage -Plugin "Module" -IsWarning "Documentation: https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365"
    Write-PScriboMessage -Plugin "Module" -IsWarning "Issues or bug reporting: https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365/issues"

    # Check the current AsBuiltReport.Veeam.VB365 module
    Try {
        $InstalledVersion = Get-Module -ListAvailable -Name AsBuiltReport.Veeam.VB365 -ErrorAction SilentlyContinue | Sort-Object -Property Version -Descending | Select-Object -First 1 -ExpandProperty Version

        if ($InstalledVersion) {
            Write-PScriboMessage -Plugin "Module" -IsWarning "AsBuiltReport.Veeam.VB365 $($InstalledVersion.ToString()) is currently installed."
            $LatestVersion = Find-Module -Name AsBuiltReport.Veeam.VB365 -Repository PSGallery -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Version
            if ($LatestVersion -gt $InstalledVersion) {
                Write-PScriboMessage -Plugin "Module" -IsWarning "AsBuiltReport.Veeam.VB365 $($LatestVersion.ToString()) is available."
                Write-PScriboMessage -Plugin "Module" -IsWarning "Run 'Update-Module -Name AsBuiltReport.Veeam.VB365 -Force' to install the latest version."
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
            Get-AbrVb365RestoreOperator
            Get-AbrVb365Organization
            Get-AbrVb365BackupJob
            Get-AbrVb365RestoreSession
            Get-AbrVb365RestorePoint

            if ($Options.EnableDiagrams) {

                $DiagramParams = @{
                    Direction = 'top-to-bottom'
                    DiagramType = "Backup-to-All"
                }

                if ($Options.ExportDiagrams) {
                    $DiagramParams.Add('Format', "png")
                    $DiagramParams.Add('FileName','AsBuiltReport.Veeam.VB365.png')
                    $DiagramParams.Add('OutputFolderPath', (Get-Location).Path)
                } else {
                    $DiagramParams.Add('Format', "base64")
                }

                if ($Options.EnableDiagramDebug) {

                    $DiagramParams.Add('EnableEdgeDebug', $True)
                    $DiagramParams.Add('EnableSubGraphDebug', $True)

                }

                if ($Options.EnableDiagramSignature) {
                    $DiagramParams.Add('Signature', $True)
                    $DiagramParams.Add('AuthorName', $Options.SignatureAuthorName)
                    $DiagramParams.Add('CompanyName', $Options.SignatureCompanyName)
                }

                if ($Options.ExportDiagrams) {
                    Try {
                        $Graph = Get-AbrVb365Diagram @DiagramParams
                        if ($Graph) {
                            Write-Information "Saved 'AsBuiltReport.Veeam.VB365.png' diagram to '$((Get-Location).Path)\'." -InformationAction Continue
                        }
                    } Catch {
                        Write-PScriboMessage -IsWarning "Unable to export the Infrastructure Diagram: $($_.Exception.Message)"
                    }

                    if ($Graph) {
                        If ((Get-DiaImagePercent -ImageInput $Graph.FullName).Width -gt 1500) { $ImagePrty = 20 } else { $ImagePrty = 50 }
                        Section -Style Heading3 "Infrastructure Diagram." {
                            Image -Path $Graph.FullName -Text "Veeam Backup for Microsoft 365 Diagram" -Percent $ImagePrty -Align Center
                            Paragraph "Image preview: Opens the image in a new tab to view it at full resolution." -Tabs 2
                        }
                        BlankLine
                    }

                } else {
                    try {
                        try {
                            $Graph = Get-AbrVb365Diagram @DiagramParams
                        } catch {
                            Write-PScriboMessage -IsWarning "Unable to generate the Infrastructure Diagram: $($_.Exception.Message)"
                        }

                        if ($Graph) {
                            If ((Get-DiaImagePercent -GraphObj $Graph).Width -gt 1500) { $ImagePrty = 20 } else { $ImagePrty = 50 }
                            Section -Style Heading3 "Infrastructure Diagram." {
                                Image -Base64 $Graph -Text "Veeam Backup for Microsoft 365 Diagram" -Percent $ImagePrty -Align Center
                                Paragraph "Image preview: Opens the image in a new tab to view it at full resolution." -Tabs 2
                            }
                            BlankLine
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "Infrastructure Diagram: $($_.Exception.Message)"
                    }
                }
            }
        }
    }
    #endregion foreach loop
}
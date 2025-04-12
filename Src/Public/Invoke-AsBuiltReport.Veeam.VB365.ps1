function Invoke-AsBuiltReport.Veeam.VB365 {
    <#
    .SYNOPSIS
        PowerShell script to document the configuration of Veeam VB365 in Word/HTML/Text formats
    .DESCRIPTION
        Documents the configuration of Veeam VB365 in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.10
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

    Write-PScriboMessage -Plugin "Module" -IsWarning "Please refer to the AsBuiltReport.Veeam.VB365 github website for more detailed information about this project."
    Write-PScriboMessage -Plugin "Module" -IsWarning "Do not forget to update your report configuration file after each new version release."
    Write-PScriboMessage -Plugin "Module" -IsWarning "Documentation: https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365"
    Write-PScriboMessage -Plugin "Module" -IsWarning "Issues or bug reporting: https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365/issues"
    Write-PScriboMessage -Plugin "Module" -IsWarning "This project is community maintained and has no sponsorship from Veeam, its employees or any of its affiliates."

    # Check the current AsBuiltReport.Veeam.VB365 module
    Try {
        $InstalledVersion = Get-Module -ListAvailable -Name AsBuiltReport.Veeam.VB365 -ErrorAction SilentlyContinue | Sort-Object -Property Version -Descending | Select-Object -First 1 -ExpandProperty Version

        if ($InstalledVersion) {
            Write-PScriboMessage -Plugin "Module" -IsWarning "AsBuiltReport.Veeam.VB365 $($InstalledVersion.ToString()) is currently installed."
            $LatestVersion = Find-Module -Name AsBuiltReport.Veeam.VB365 -Repository PSGallery -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Version
            if ([version]$LatestVersion -gt [version]$InstalledVersion) {
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
                Write-PScriboMessage "Collecting Veeam Infrastructure diagram"

                # Variable translating Icon to Image Path ($IconPath)
                $script:Images = @{
                    "VB365_Server" = "VBR_server.png"
                    "VB365_Proxy_Server" = "Proxy_Server.png"
                    "VB365_Proxy" = "Veeam_Proxy.png"
                    "VBR_LOGO" = "Veeam_logo_new.png"
                    "VB365_LOGO_Footer" = "verified_recoverability.png"
                    "VB365_Repository" = "VBO_Repository.png"
                    "VB365_Windows_Repository" = "Windows_Repository.png"
                    "VB365_Object_Repository" = "Object_Storage.png"
                    "VB365_Object_Support" = "Object Storage support.png"
                    "Veeam_Repository" = "Veeam_Repository.png"
                    "VB365_On_Premises" = "SMB.png"
                    "VB365_Microsoft_365" = "Cloud.png"
                    "Microsoft_365" = "Microsoft_365.png"
                    "Datacenter" = "Datacenter.png"
                    "VB365_Restore_Portal" = "Web_console.png"
                    "VB365_User_Group" = "User_Group.png"
                    "VB365_User" = "User.png"
                    "VBR365_Amazon_S3_Compatible" = "S3-compatible.png"
                    "VBR365_Amazon_S3" = "AWS S3.png"
                    "VBR365_Azure_Blob" = "Azure Blob.png"
                }

                $RootPath = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
                [System.IO.FileInfo]$IconPath = Join-Path $RootPath 'icons'

                $DiagramParams = @{
                    'FileName' = "AsBuiltReport.Veeam.VB365"
                    'OutputFolderPath' = $OutputFolderPath
                    'Direction' = 'top-to-bottom'
                    'MainDiagramLabel' = 'Backup for Microsoft 365'
                    'MainDiagramLabelFontsize' = 28
                    'MainDiagramLabelFontcolor' = '#565656'
                    'MainDiagramLabelFontname' = 'Segoe UI Black'
                    'IconPath' = $IconPath
                    'ImagesObj' = $Images
                    'LogoName' = 'VBR_LOGO'
                    'SignatureLogoName' = 'VB365_LOGO_Footer'
                    'WaterMarkText' = $Options.DiagramWaterMark
                    'WaterMarkColor' = 'DarkGreen'
                }

                if ($Options.DiagramTheme -eq 'Black') {
                    $DiagramParams.add('MainGraphBGColor', 'Black')
                    $DiagramParams.add('Edgecolor', 'White')
                    $DiagramParams.add('Fontcolor', 'White')
                    $DiagramParams.add('NodeFontcolor', 'White')
                } elseif ($Options.DiagramTheme -eq 'Neon') {
                    $DiagramParams.add('MainGraphBGColor', 'grey14')
                    $DiagramParams.add('Edgecolor', 'gold2')
                    $DiagramParams.add('Fontcolor', 'gold2')
                    $DiagramParams.add('NodeFontcolor', 'gold2')
                }

                if ($Options.ExportDiagrams) {
                    if (-Not $Options.ExportDiagramsFormat) {
                        $DiagramFormat = 'png'
                    } else {
                        $DiagramFormat = $Options.ExportDiagramsFormat
                    }
                    $DiagramParams.Add('Format', $DiagramFormat)
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
                        Write-PScriboMessage "Generating Veeam Infrastructure diagram"
                        $Graph = Get-AbrVb365Diagram
                        if ($Graph) {
                            Write-PScriboMessage "Saving Veeam Infrastructure diagram"
                            $Diagram = New-Diagrammer @DiagramParams -InputObject $Graph
                            if ($Diagram) {
                                foreach ($OutputFormat in $DiagramFormat) {
                                    Write-Information "Saved 'AsBuiltReport.Veeam.VB365.$($OutputFormat)' diagram to '$($OutputFolderPath)'." -InformationAction Continue
                                }
                            }
                        }
                    } Catch {
                        Write-PScriboMessage -IsWarning "Unable to export the Infrastructure Diagram: $($_.Exception.Message)"
                    }
                } else {
                    try {
                        try {
                            $Graph = Get-AbrVb365Diagram
                            $Diagram = New-Diagrammer @DiagramParams -InputObject $Graph
                        } catch {
                            Write-PScriboMessage -IsWarning "Unable to generate the Infrastructure Diagram: $($_.Exception.Message)"
                        }

                        if ($Diagram) {
                            If ((Get-DiaImagePercent -GraphObj $Diagram).Width -gt 1500) { $ImagePrty = 20 } else { $ImagePrty = 50 }
                            Section -Style Heading2 "Infrastructure Diagram." {
                                Image -Base64 $Diagram -Text "Veeam Backup for Microsoft 365 Diagram" -Percent $ImagePrty -Align Center
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
    } #endregion foreach loop
}
function Export-AbrVb365Diagram {
    <#
    .SYNOPSIS
    Used by As Built Report to export Veeam VB365 infrastructure diagram
    .DESCRIPTION
        Documents the configuration of Veeam VB365 in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.11
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365
    #>
    [CmdletBinding()]
    param (
    )

    begin {
        Write-PScriboMessage -Message "EnableDiagrams set to $($Options.EnableDiagrams)."
    }

    process {
        if ($Options.EnableDiagrams) {
            Write-PScriboMessage -Message "Collecting Veeam Infrastructure diagram"

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
            }

            if ($Options.DiagramTheme -eq 'Black') {
                $DiagramParams.add('MainGraphBGColor', 'Black')
                $DiagramParams.add('Edgecolor', 'White')
                $DiagramParams.add('Fontcolor', 'White')
                $DiagramParams.add('NodeFontcolor', 'White')
                $DiagramParams.add('WaterMarkColor', 'White')
            } elseif ($Options.DiagramTheme -eq 'Neon') {
                $DiagramParams.add('MainGraphBGColor', 'grey14')
                $DiagramParams.add('Edgecolor', 'gold2')
                $DiagramParams.add('Fontcolor', 'gold2')
                $DiagramParams.add('NodeFontcolor', 'gold2')
                $DiagramParams.add('WaterMarkColor', '#FFD700')
            } else {
                $DiagramParams.add('WaterMarkColor', 'DarkGreen')
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

                $DiagramParams.Add('DraftMode', $True)

            }

            if ($Options.EnableDiagramSignature) {
                $DiagramParams.Add('Signature', $True)
                $DiagramParams.Add('AuthorName', $Options.SignatureAuthorName)
                $DiagramParams.Add('CompanyName', $Options.SignatureCompanyName)
            }

            if ($Options.ExportDiagrams) {
                Try {
                    Write-PScriboMessage -Message "Generating Veeam Infrastructure diagram"
                    $Graph = Get-AbrVb365Diagram
                    if ($Graph) {
                        Write-PScriboMessage -Message "Saving Veeam Infrastructure diagram"
                        $Diagram = New-Diagrammer @DiagramParams -InputObject $Graph
                        if ($Diagram) {
                            foreach ($OutputFormat in $DiagramFormat) {
                                Write-Information -MessageData "Saved 'AsBuiltReport.Veeam.VB365.$($OutputFormat)' diagram to '$($OutputFolderPath)'." -InformationAction Continue
                            }
                        }
                    }
                } Catch {
                    Write-PScriboMessage -IsWarning -Message "Unable to export the Infrastructure Diagram: $($_.Exception.Message)"
                }
            }
            try {
                $DiagramParams.Remove('Format')
                $DiagramParams.Add('Format', "base64")

                $Graph = Get-AbrVb365Diagram
                $Diagram = New-Diagrammer @DiagramParams -InputObject $Graph
                if ($Diagram) {
                    If ((Get-DiaImagePercent -GraphObj $Diagram).Width -gt 800) { $ImagePrty = 15 } else { $ImagePrty = 30 }
                    Section -Style Heading2 "Infrastructure Diagram." {
                        Image -Base64 $Diagram -Text "Veeam Backup for Microsoft 365 Diagram" -Percent $ImagePrty -Align Center
                        Paragraph "Image preview: Opens the image in a new tab to view it at full resolution." -Tabs 2
                    }
                }
            } catch {
                Write-PScriboMessage -IsWarning -Message "Unable to generate the Infrastructure Diagram: $($_.Exception.Message)"
            }
        }
    }

    end {}
}
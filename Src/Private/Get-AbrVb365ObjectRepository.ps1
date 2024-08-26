function Get-AbrVB365ObjectRepository {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Object Repository
    .DESCRIPTION
        Documents the configuration of Veeam VB365 in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.2
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
        Write-PScriboMessage "Repository InfoLevel set at $($InfoLevel.Infrastructure.Repository)."
    }

    process {
        try {
            $script:ObjectRepositories = Get-VBOObjectStorageRepository | Sort-Object -Property Name
            if (($InfoLevel.Infrastructure.Repository -gt 0) -and ($ObjectRepositories)) {
                Write-PScriboMessage "Collecting Veeam VB365 Object Repository."
                Section -Style Heading2 'Object Repositories' {
                    $ObjectRepositoryInfo = @()
                    foreach ($ObjectRepository in $ObjectRepositories) {
                        $inObj = [ordered] @{
                            'Name' = $ObjectRepository.Name
                            'Type' = $ObjectRepository.Type
                            'Folder' = $ObjectRepository.Folder
                            'Enable Size Limit' = ConvertTo-TextYN $ObjectRepository.EnableSizeLimit
                            'Size Limit' = "$($ObjectRepository.SizeLimit) GB"
                            'Used Space' = ConvertTo-FileSizeString $ObjectRepository.UsedSpace
                            'Free Space' = ConvertTo-FileSizeString $ObjectRepository.FreeSpace
                            'Is Long Term' = ConvertTo-TextYN $ObjectRepository.IsLongTerm
                            'Is Secondary' = ConvertTo-TextYN $ObjectRepository.IsSecondary
                            'Use Archiver Appliance' = ConvertTo-TextYN $ObjectRepository.UseArchiverAppliance
                            'Immutability Enabled' = ConvertTo-TextYN $ObjectRepository.EnableImmutability
                            'Description' = $ObjectRepository.Description

                        }
                        $ObjectRepositoryInfo += [PSCustomObject]$InObj
                    }

                    if ($InfoLevel.Infrastructure.Repository -ge 2) {
                        Paragraph "The following sections detail the configuration of the object repository within $VeeamBackupServer backup server."
                        foreach ($ObjectRepository in $ObjectRepositoryInfo) {
                            if ($HealthCheck.Infrastructure.Repository) {
                                $ObjectRepository | Where-Object { $_.'Is Outdated' -eq 'Yes' } | Set-Style -Style Warning -Property 'Is Outdated'
                                $ObjectRepository | Where-Object { $_.'Immutability Enabled' -eq 'No' } | Set-Style -Style Warning -Property 'Immutability Enabled'
                            }
                            Section -ExcludeFromTOC -Style NOTOCHeading4 "$($ObjectRepository.Name)" {
                                $TableParams = @{
                                    Name = "Object Repository - $($ObjectRepository.Name)"
                                    List = $true
                                    ColumnWidths = 40, 60
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $ObjectRepository | Table @TableParams
                                if (($HealthCheck.Infrastructure.Repository) -and ($ObjectRepository | Where-Object { $_.'Immutability Enabled' -eq 'No' })) {
                                    Paragraph "Health Check:" -Bold -Underline
                                    BlankLine
                                    Paragraph {
                                        Text "Best Practice:" -Bold
                                        Text "Veeam recommend to implement Immutability where it is supported. It,s done for increased security: immutability protects your data from loss as a result of attacks, malware activity or any other injurious actions."
                                        Text "https://bp.veeam.com/vb365/guide/design/hardening/Repo_specifics.html" -Color Blue
                                    }
                                    BlankLine
                                }
                            }
                        }
                    } else {
                        if ($HealthCheck.Infrastructure.Repository) {
                            $ObjectRepositoryInfo | Where-Object { $_.'Immutability Enabled' -eq 'No' } | Set-Style -Style Warning -Property 'Immutability Enabled'
                        }
                        Paragraph "The following table summarizes the configuration of the object repository within within the $VeeamBackupServer backup server."
                        BlankLine
                        $TableParams = @{
                            Name = "Object Repositories - $VeeamBackupServer"
                            List = $false
                            Columns = 'Name', 'Type', 'Used Space', 'Free Space', 'Immutability Enabled'
                            ColumnWidths = 28, 27, 15, 15, 15
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $ObjectRepositoryInfo | Table @TableParams
                        if (($HealthCheck.Infrastructure.Repository) -and ($ObjectRepositoryInfo | Where-Object { $_.'Immutability Enabled' -eq 'No' })) {
                            Paragraph "Health Check:" -Bold -Underline
                            BlankLine
                            Paragraph {
                                Text "Best Practice:" -Bold
                                Text "Veeam recommend to implement Immutability where it is supported. It,s done for increased security: immutability protects your data from loss as a result of attacks, malware activity or any other injurious actions."
                                Text "https://bp.veeam.com/vb365/guide/design/hardening/Repo_specifics.html" -Color Blue
                            }
                            BlankLine
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Object Repository Section: $($_.Exception.Message)"
        }
    }

    end {}
}
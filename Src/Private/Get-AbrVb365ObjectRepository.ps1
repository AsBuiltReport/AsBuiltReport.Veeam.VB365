function Get-AbrVB365ObjectRepository {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Object Repository
    .DESCRIPTION
        Documents the configuration of Veeam VB365 in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.2.1
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
                            'Enable Immutability' = ConvertTo-TextYN $ObjectRepository.EnableImmutability
                            'Description' = $ObjectRepository.Description

                        }
                        $ObjectRepositoryInfo += [PSCustomObject]$InObj
                    }

                    if ($HealthCheck.Infrastructure.Repository) {
                        $ObjectRepositoryInfo | Where-Object { $_.'Is Outdated' -eq 'Yes' } | Set-Style -Style Warning -Property 'Is Outdated'
                    }

                    if ($InfoLevel.Infrastructure.Repository -ge 2) {
                        Paragraph "The following sections detail the configuration of the object repository within $VeeamBackupServer backup server."
                        foreach ($ObjectRepository in $ObjectRepositoryInfo) {
                            Section -ExcludeFromTOC -Style NOTOCHeading3 "$($ObjectRepository.Name)" {
                                $TableParams = @{
                                    Name = "Object Repository - $($ObjectRepository.Name)"
                                    List = $true
                                    ColumnWidths = 40, 60
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $ObjectRepository | Table @TableParams
                            }
                        }
                    } else {
                        Paragraph "The following table summarizes the configuration of the object repository within within the $VeeamBackupServer backup server."
                        BlankLine
                        $TableParams = @{
                            Name = "Object Repositories - $VeeamBackupServer"
                            List = $false
                            Columns = 'Name', 'Type', 'Size Limit', 'Used Space', 'Free Space'
                            ColumnWidths = 28, 27, 15, 15, 15
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $ObjectRepositoryInfo | Table @TableParams
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Object Repository Section: $($_.Exception.Message)"
        }
    }

    end {}
}
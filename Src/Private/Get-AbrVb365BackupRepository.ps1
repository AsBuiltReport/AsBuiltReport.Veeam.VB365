function Get-AbrVB365BackupRepository {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Backup Repository
    .DESCRIPTION
        Documents the configuration of Veeam VB365 in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.13
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
        Write-PScriboMessage -Message "Repository InfoLevel set at $($InfoLevel.Infrastructure.Repository)."
    }

    process {
        try {
            if ($InfoLevel.Infrastructure.Repository -le 0) {
                return
            }

            if ($script:Repositories) {
                Write-PScriboMessage -Message "Using cached Veeam VB365 Backup Repository inventory."
                $Repositories = $script:Repositories
            } else {
                if ($InfoLevel.Infrastructure.Repository -ge 2) {
                    Write-PScriboMessage -Message "Collecting Veeam VB365 Backup Repository inventory."
                    $Repositories = Get-AbrVb365BackupRepositoryInventory
                } else {
                    Write-PScriboMessage -Message "Collecting Veeam VB365 Backup Repository summary from job references."
                    $Repositories = Get-AbrVb365BackupRepositoryInventory -SummaryOnly
                }
            }

            if (($InfoLevel.Infrastructure.Repository -gt 0) -and ($Repositories)) {
                Write-PScriboMessage -Message "Collecting Veeam VB365 Backup Repository."
                Section -Style Heading2 'Backup Repositories' {
                    $EncryptionKeyLookup = @{}
                    if (($InfoLevel.Infrastructure.Repository -ge 2 -or $HealthCheck.Infrastructure.Repository) -and ($Repositories | Where-Object { $_.EnableObjectStorageEncryption })) {
                        $KnownEncryptionKeys = if ($script:EncryptionKeys) { $script:EncryptionKeys } else { Get-VBOEncryptionKey }
                        foreach ($EncryptionKey in ($KnownEncryptionKeys | Where-Object { $_ })) {
                            if ($EncryptionKey.Id) {
                                $EncryptionKeyLookup[$EncryptionKey.Id.ToString()] = $EncryptionKey.Description
                            }
                        }
                    }

                    $RepositoryInfo = @()
                    foreach ($Repository in $Repositories) {
                        $inObj = [ordered] @{
                            'Name' = $Repository.Name
                            'Path' = $Repository.Path
                            'Capacity' = if ($null -ne $Repository.Capacity) { ConvertTo-FileSizeString $Repository.Capacity } else { '--' }
                            'Free Space' = if ($null -ne $Repository.FreeSpace) { ConvertTo-FileSizeString $Repository.FreeSpace } else { '--' }
                            'Retention Type' = switch ($Repository.RetentionType) {
                                'SnapshotBased' { 'Snapshot Based' }
                                'ItemLevel' { 'Item Level' }
                                default { $Repository.RetentionType }
                            }
                            'Retention Period' = switch ($Repository.RetentionPeriod) {
                                "Years1" { '1 Year' }
                                "Years2" { '2 Years' }
                                "Years3" { '3 Years' }
                                "Years5" { '5 Years' }
                                "Years7" { '7 Years' }
                                "Years10" { '10 Years' }
                                "Years25" { '25 Years' }
                                "KeepForever" { 'Keep Forever' }
                                default { $Repository.RetentionPeriod }
                            }
                        }

                        if ($InfoLevel.Infrastructure.Repository -ge 2 -or $HealthCheck.Infrastructure.Repository) {
                            $ObjectStorageRepository = Get-AbrVb365PropertyValue -InputObject $Repository -Name 'ObjectStorageRepository'
                            $ObjectStorageEncryptionKey = Get-AbrVb365PropertyValue -InputObject $Repository -Name 'ObjectStorageEncryptionKey'
                            $ObjectStorageEncryptionKeyId = Get-AbrVb365PropertyValue -InputObject $ObjectStorageEncryptionKey -Name 'Id'

                            $ObjectStorageRepositoryValue = switch ([string]::IsNullOrEmpty($ObjectStorageRepository)) {
                                $true { "Disabled" }
                                $false { $ObjectStorageRepository }
                                default { 'Unknown' }
                            }
                            $ObjectStorageEncryptionKeyValue = switch ($Repository.EnableObjectStorageEncryption) {
                                $true {
                                    if ($ObjectStorageEncryptionKeyId -and $EncryptionKeyLookup.ContainsKey($ObjectStorageEncryptionKeyId.ToString())) {
                                        $EncryptionKeyLookup[$ObjectStorageEncryptionKeyId.ToString()]
                                    } else {
                                        Get-AbrVb365PropertyValue -InputObject $ObjectStorageEncryptionKey -Name 'Description' -Default 'Unknown'
                                    }
                                }
                                $false { "Disabled" }
                                default { "Unknown" }
                            }

                            $inObj.Add('Object Storage Repository', $ObjectStorageRepositoryValue)
                            $inObj.Add('Object Storage Encryption Key', $ObjectStorageEncryptionKeyValue)
                        }

                        if ($InfoLevel.Infrastructure.Repository -ge 2) {
                            $inObj.Add('Is Outdated', $Repository.IsOutdated)
                            $inObj.Add('Is Out Of Sync', $Repository.IsOutOfSync)
                            $inObj.Add('Used Space', (ConvertTo-FileSizeString ($Repository.Capacity - $Repository.FreeSpace)))
                            $inObj.Add('Is Long Term', $Repository.IsLongTerm)
                            $inObj.Add('Retention Frequency Type', $Repository.RetentionFrequencyType)
                            $inObj.Add('Proxy Pool', $Repository.ProxyPool)
                            $inObj.Add('Description', $Repository.Description)
                        }

                        $RepositoryInfo += [pscustomobject](ConvertTo-HashToYN $inObj)
                    }

                    if ($InfoLevel.Infrastructure.Repository -ge 2) {
                        Paragraph "The following sections detail the configuration of the backup repository within $VeeamBackupServer backup server."
                        foreach ($Repository in $RepositoryInfo) {
                            if ($HealthCheck.Infrastructure.Repository) {
                                $Repository | Where-Object { $_.'Is Outdated' -eq 'Yes' } | Set-Style -Style Warning -Property 'Is Outdated'
                                $Repository | Where-Object { $_.'Object Storage Repository' -ne 'Disabled' -and $_.'Object Storage Encryption Key' -eq 'Disabled' } | Set-Style -Style Warning -Property 'Object Storage Encryption Key'
                            }
                            Section -ExcludeFromTOC -Style NOTOCHeading4 "$($Repository.Name)" {
                                $TableParams = @{
                                    Name = "Repository - $($Repository.Name)"
                                    List = $true
                                    ColumnWidths = 40, 60
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $Repository | Table @TableParams
                                if ($HealthCheck.Infrastructure.Repository) {
                                    if ($Repository | Where-Object { $_.'Object Storage Repository' -ne 'Disabled' -and $_.'Object Storage Encryption Key' -eq 'Disabled' }) {
                                        Paragraph "Health Check:" -Bold -Underline
                                        BlankLine
                                        Paragraph {
                                            Text "Best Practice:" -Bold
                                            Text "Backups data is a high potential source of vulnerability. To secure data stored in object repositories, use Veeam's inbuilt encryption to protect data in backups."
                                            Text "https://bp.veeam.com/vb365/guide/design/hardening/Repo_specifics.html" -Color Blue
                                        }
                                        BlankLine
                                    }
                                }
                            }
                        }
                    } else {
                        if ($HealthCheck.Infrastructure.Repository) {
                            $RepositoryInfo | Where-Object { $_.'Object Storage Repository' -ne 'Disabled' -and $_.'Object Storage Encryption Key' -eq 'Disabled' } | Set-Style -Style Warning
                        }
                        Paragraph "The following table summarizes the configuration of the backup repository within within the $VeeamBackupServer backup server."
                        BlankLine
                        $TableParams = @{
                            Name = "Repositories - $VeeamBackupServer"
                            List = $false
                            Columns = 'Name', 'Path', 'Retention Type', 'Capacity', 'Free Space'
                            ColumnWidths = 28, 27, 20, 12, 13
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $RepositoryInfo | Table @TableParams
                        if ($HealthCheck.Infrastructure.Repository) {
                            if ($RepositoryInfo | Where-Object { $_.'Object Storage Repository' -ne 'Disabled' -and $_.'Object Storage Encryption Key' -eq 'Disabled' }) {
                                Paragraph "Health Check:" -Bold -Underline
                                BlankLine
                                Paragraph {
                                    Text "Best Practice:" -Bold
                                    Text "Found a Object Storage repository without encryption enabled. Backups data is a high potential source of vulnerability. To secure data stored in object repositories, use Veeam's inbuilt encryption to protect data in backups."
                                    Text "https://bp.veeam.com/vb365/guide/design/hardening/Repo_specifics.html" -Color Blue
                                }
                                BlankLine
                            }
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning -Message "Repository Section: $($_.Exception.Message)"
        }
    }

    end {}
}

function Get-AbrVB365BackupRepository {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Backup Repository
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
        Write-PScriboMessage -Message "Repository InfoLevel set at $($InfoLevel.Infrastructure.Repository)."
    }

    process {
        try {
            $script:Repositories = Get-VBORepository | Sort-Object -Property Name
            if (($InfoLevel.Infrastructure.Repository -gt 0) -and ($Repositories)) {
                Write-PScriboMessage -Message "Collecting Veeam VB365 Backup Repository."
                Section -Style Heading2 'Backup Repositories' {
                    $RepositoryInfo = @()
                    foreach ($Repository in $Repositories) {
                        $inObj = [ordered] @{
                            'Name' = $Repository.Name
                            'Path' = $Repository.Path
                            'Object Storage Repository' = Switch ([string]::IsNullOrEmpty($Repository.ObjectStorageRepository)) {
                                $true { "Disabled" }
                                $false { $Repository.ObjectStorageRepository }
                                default { 'Unknown' }
                            }
                            'Object Storage Encryption Key' = Switch ($Repository.EnableObjectStorageEncryption) {
                                $true { (Get-VBOEncryptionKey -Id $Repository.ObjectStorageEncryptionKey.id).Description }
                                $false { "Disabled" }
                                default { "Unknown" }
                            }
                            'Is Outdated' = $Repository.IsOutdated
                            'Is Out Of Sync' = $Repository.IsOutOfSync
                            'Capacity' = ConvertTo-FileSizeString $Repository.Capacity
                            'Free Space' = ConvertTo-FileSizeString $Repository.FreeSpace
                            'Used Space' = ConvertTo-FileSizeString ($Repository.Capacity - $Repository.FreeSpace)
                            'Is Long Term' = $Repository.IsLongTerm
                            'Retention Type' = Switch ($Repository.RetentionType) {
                                'SnapshotBased' { 'Snapshot Based' }
                                'ItemLevel' { 'Item Level' }
                                default { $Repository.RetentionType }
                            }
                            'Retention Period' = Switch ($Repository.RetentionPeriod) {
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
                            'Retention Frequency Type' = $Repository.RetentionFrequencyType
                            'Proxy Pool' = $Repository.ProxyPool
                            'Description' = $Repository.Description

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
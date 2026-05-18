function Get-AbrVb365RestorePoint {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Restore Point
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
        Write-PScriboMessage -Message "RestorePoint InfoLevel set at $($InfoLevel.Restore.RestorePoint)."
    }

    process {
        try {
            if ($InfoLevel.Restore.RestorePoint -le 0) {
                return
            }

            if ($script:RestorePoints) {
                Write-PScriboMessage -Message "Using cached Veeam VB365 Restore Point inventory."
                $RestorePoints = $script:RestorePoints
            } else {
                Write-PScriboMessage -Message "Collecting Veeam VB365 Restore Point inventory."
                $script:RestorePoints = Get-VBORestorePoint | Sort-Object -Property BackupTime
                $RestorePoints = $script:RestorePoints
            }

            if ($script:BackupJobs) {
                $BackupJobs = $script:BackupJobs
            } else {
                Write-PScriboMessage -Message "Collecting Veeam VB365 Backup Jobs inventory for restore point mapping."
                $BackupJobs = Get-AbrVb365BackupJobInventory
            }

            if (($InfoLevel.Restore.RestorePoint -gt 0) -and ($RestorePoints)) {
                Write-PScriboMessage -Message "Collecting Veeam VB365 Restore Point."
                Section -Style Heading2 'Restore Point' {
                    Paragraph "The following section summarizes the configuration of the restore points within the $VeeamBackupServer backup server."
                    BlankLine
                    Section -Style Heading3 'Backup Jobs Restore Point' {
                        Paragraph "The following section summarizes the backup jobs restore points."
                        BlankLine
                        $OrganizationLookup = Get-AbrVb365OrganizationNameLookup
                        $RepositoryLookup = @{}
                        if ($InfoLevel.Restore.RestorePoint -ge 2) {
                            $RepositoryLookup = Get-AbrVb365RepositoryNameLookup
                        } else {
                            Write-PScriboMessage -Message "Skipping restore point repository name lookup at InfoLevel 1 because VB365 8.4 can trigger a blocking repository backend lookup."
                        }
                        $RestorePointsByJob = @{}
                        foreach ($RestorePoint in $RestorePoints) {
                            $JobKey = ConvertTo-AbrVb365LookupKey -Id $RestorePoint.JobId
                            if (-not $JobKey) {
                                continue
                            }
                            if (-not $RestorePointsByJob.ContainsKey($JobKey)) {
                                $RestorePointsByJob[$JobKey] = New-Object System.Collections.Generic.List[object]
                            }
                            $RestorePointsByJob[$JobKey].Add($RestorePoint)
                        }

                        foreach ($BackupJob in $BackupJobs) {
                            $BackupJobKey = ConvertTo-AbrVb365LookupKey -Id $BackupJob.Id
                            $BackupJobRepositoryProperty = $BackupJob.PSObject.Properties['AbrRepositoryName']
                            $BackupJobRepositoryName = if ($BackupJobRepositoryProperty -and $BackupJobRepositoryProperty.Value) {
                                $BackupJobRepositoryProperty.Value
                            } else {
                                '--'
                            }
                            $BackupJobRestorePoints = if ($BackupJobKey -and $RestorePointsByJob.ContainsKey($BackupJobKey)) {
                                $RestorePointsByJob[$BackupJobKey]
                            } else {
                                $null
                            }
                            if ($BackupJobRestorePoints) {
                                Section -Style Heading4  $BackupJob.Name {
                                    $RestorePointInfo = @()
                                    foreach ($RestorePoint in $BackupJobRestorePoints) {
                                        try {
                                            $OrganizationKey = ConvertTo-AbrVb365LookupKey -Id $RestorePoint.OrganizationId
                                            $RepositoryKey = ConvertTo-AbrVb365LookupKey -Id $RestorePoint.RepositoryId
                                            $OrganizationName = if ($OrganizationKey -and $OrganizationLookup.ContainsKey($OrganizationKey)) {
                                                $OrganizationLookup[$OrganizationKey]
                                            } else {
                                                '--'
                                            }
                                            $RepositoryName = if ($RepositoryKey -and $RepositoryLookup.ContainsKey($RepositoryKey)) {
                                                $RepositoryLookup[$RepositoryKey]
                                            } elseif ($BackupJobRepositoryName -and $BackupJobRepositoryName -ne '--') {
                                                $BackupJobRepositoryName
                                            } else {
                                                '--'
                                            }
                                            $inObj = [ordered] @{
                                                'Backup Time' = $RestorePoint.BackupTime
                                                'Organization Id' = $OrganizationName
                                                'Repository Id' = $RepositoryName
                                                'Type' = & {
                                                    if ($RestorePoint.IsSharePoint) {
                                                        return "SharePoint"
                                                    } elseif ($RestorePoint.IsOneDrive) {
                                                        return "OneDrive"
                                                    } elseif ($RestorePoint.IsTeams) {
                                                        return "Teams"
                                                    } elseif ($RestorePoint.IsExchange) {
                                                        return "Exchange"
                                                    } elseif ($RestorePoint.IsCopy) {
                                                        return "IsCopy"
                                                    } elseif ($RestorePoint.IsLongTermCopy) {
                                                        return "IsLongTermCopy"
                                                    } elseif ($RestorePoint.IsLongTermCopy) {
                                                        return "IsLongTermCopy"
                                                    } else {
                                                        return "Unknown"
                                                    }
                                                }
                                            }
                                            $RestorePointInfo += [pscustomobject](ConvertTo-HashToYN $inObj)
                                        } catch {
                                            Write-PScriboMessage -IsWarning -Message "Restore Point table: $($_.Exception.Message)"
                                        }
                                    }

                                    $TableParams = @{
                                        Name = "Restore Points - $($BackupJob.Name)"
                                        List = $false
                                        ColumnWidths = 25, 25, 25, 25
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $RestorePointInfo | Table @TableParams
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning -Message "Restore Point Section: $($_.Exception.Message)"
        }
    }
    end {}
}

function Get-AbrVb365RestorePoint {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Restore Point
    .DESCRIPTION
        Documents the configuration of Veeam VB365 in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.2.0
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
        Write-PScriboMessage "RestorePoint InfoLevel set at $($InfoLevel.Restore.RestorePoint)."
    }

    process {
        try {
            $RestorePoints = Get-VBORestorePoint | Sort-Object -Property BackupTime
            $BackupJobs = Get-VBOJob | Sort-Object -Property Name
            if (($InfoLevel.Restore.RestorePoint -gt 0) -and ($RestorePoints)) {
                Write-PScriboMessage "Collecting Veeam VB365 Restore Point."
                Section -Style Heading2 'Restore Point' {
                    Paragraph "The following section summarizes the configuration of the restore points within the $VeeamBackupServer backup server."
                    BlankLine
                    Section -Style Heading3 'Backup Jobs Restore Point' {
                        Paragraph "The following section summarizes the backup jobs restore points."
                        BlankLine
                        foreach ($BackupJob in $BackupJobs) {
                            $BackupJobRestorePoints = $RestorePoints | Where-Object { $_.JobId -eq $BackupJob.id }
                            if ($BackupJobRestorePoints) {
                                Section -Style Heading4  $BackupJob.Name {
                                    $RestorePointInfo = @()
                                    foreach ($RestorePoint in $BackupJobRestorePoints) {
                                        try {
                                            $inObj = [ordered] @{
                                                'Backup Time' = $RestorePoint.BackupTime
                                                'Organization Id' = Switch ([string]::IsNullOrEmpty((Get-VBOOrganization -Id $RestorePoint.OrganizationId))) {
                                                    $true {"--"}
                                                    $false {(Get-VBOOrganization -Id $RestorePoint.OrganizationId).Name}
                                                    default {'Unknown'}
                                                }
                                                'Repository Id' = Switch ([string]::IsNullOrEmpty((Get-VBORepository -Id $RestorePoint.RepositoryId))) {
                                                    $true {"--"}
                                                    $false {(Get-VBORepository -Id $RestorePoint.RepositoryId.Guid).Name}
                                                    default {'Unknown'}
                                                }
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
                                            $RestorePointInfo += [PSCustomObject]$InObj
                                        } catch {
                                            Write-PScriboMessage -IsWarning "Restore Point table: $($_.Exception.Message)"
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
            Write-PScriboMessage -IsWarning "Restore Point Section: $($_.Exception.Message)"
        }
    }
    end {}
}
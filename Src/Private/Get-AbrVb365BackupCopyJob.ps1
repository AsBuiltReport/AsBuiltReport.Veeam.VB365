function Get-AbrVb365BackupCopyJob {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Backup Copy Jobs
    .DESCRIPTION
        Documents the configuration of Veeam VB365 in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.1.1
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
        Write-PScriboMessage "BackupCopyJob InfoLevel set at $($InfoLevel.Jobs.BackupCopyJob)."
    }

    process {
        try {
            $BackupCopyJobs = Get-VBOCopyJob | Sort-Object -Property Name
            if (($InfoLevel.Jobs.BackupCopyJob -gt 0) -and ($BackupCopyJobs)) {
                Write-PscriboMessage "Collecting Veeam VB365 Backup Copy Jobs."
                Section -Style Heading3 'Backup Copy Jobs' {
                    $BackupCopyJobInfo = @()
                    foreach ($BackupCopyJob in $BackupCopyJobs) {
                        $inObj = [ordered] @{
                            'Name' = $BackupCopyJob.Name
                            'Repository' = $BackupCopyJob.Repository
                            'Schedule Policy' = $BackupCopyJob.SchedulePolicy
                            'Last Status' = $BackupCopyJob.LastStatus
                            'Last Run' = $BackupCopyJob.LastRun
                            'Next Run' = $BackupCopyJob.NextRun
                            'Last Backup' = $BackupCopyJob.LastBackup
                            'Is Enabled' = ConvertTo-TextYN $BackupCopyJob.IsEnabled
                            'Description' = ConvertTo-EmptyToFiller $BackupCopyJob.Description

                        }
                        $BackupCopyJobInfo += [PSCustomObject]$InObj
                    }

                    if ($HealthCheck.Jobs.BackupCopyJob) {
                        $BackupCopyJobInfo | Where-Object { $_.'Is Enabled' -eq 'No'} | Set-Style -Style Warning -Property 'Is Enabled'
                        $BackupCopyJobInfo | Where-Object { $_.'Last Status' -ne 'Success' } | Set-Style -Style Warning -Property 'Last Status'
                    }

                    if ($InfoLevel.Jobs.BackupCopyJob -ge 2) {
                        Paragraph "The following sections detail the configuration of the backup copy job within $VeeamBackupServer backup server."
                        foreach ($BackupCopyJob in $BackupCopyJobInfo) {
                            Section -ExcludeFromTOC -Style NOTOCHeading4 "$($BackupCopyJob.Name)" {
                                $TableParams = @{
                                    Name = "Backup Copy Job - $($BackupCopyJob.Name)"
                                    List = $true
                                    ColumnWidths = 50, 50
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $BackupCopyJob | Table @TableParams
                            }
                        }
                    } else {
                        Paragraph "The following table summarizes the configuration of the backup copy jobs within the $VeeamBackupServer backup server."
                        BlankLine
                        $TableParams = @{
                            Name = "Backup Copy Job - $VeeamBackupServer"
                            List = $false
                            Columns = 'Name', 'Repository', 'Schedule Policy', 'Is Enabled', 'Last Status'
                            ColumnWidths = 28, 27, 15, 15, 15
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $BackupCopyJobInfo | Table @TableParams
                    }
                }
            }
        } catch {
            Write-PscriboMessage -IsWarning "Backup Copy Jobs Section: $($_.Exception.Message)"
        }
    }

    end {}
}
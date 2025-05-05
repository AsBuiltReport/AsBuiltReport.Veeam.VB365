function Get-AbrVb365BackupCopyJob {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Backup Copy Jobs
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
        Write-PScriboMessage -Message "BackupCopyJob InfoLevel set at $($InfoLevel.Jobs.BackupCopyJob)."
    }

    process {
        try {
            $BackupCopyJobs = Get-VBOCopyJob | Sort-Object -Property Name
            if (($InfoLevel.Jobs.BackupCopyJob -gt 0) -and ($BackupCopyJobs)) {
                Write-PScriboMessage -Message "Collecting Veeam VB365 Backup Copy Jobs."
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
                            'Is Enabled' = $BackupCopyJob.IsEnabled
                            'Description' = $BackupCopyJob.Description

                        }
                        $BackupCopyJobInfo += [pscustomobject](ConvertTo-HashToYN $inObj)
                    }

                    if ($HealthCheck.Jobs.BackupCopyJob) {
                        $BackupCopyJobInfo | Where-Object { $_.'Is Enabled' -eq 'No' } | Set-Style -Style Warning -Property 'Is Enabled'
                        $BackupCopyJobInfo | Where-Object { $_.'Last Status' -eq 'Success' } | Set-Style -Style Ok -Property 'Last Status'
                        $BackupCopyJobInfo | Where-Object { $_.'Last Status' -eq 'Warning' } | Set-Style -Style Warning -Property 'Last Status'
                        $BackupCopyJobInfo | Where-Object { $_.'Last Status' -eq 'Failed' } | Set-Style -Style Critical -Property 'Last Status'
                    }

                    try {
                        $Alljobs = @()

                        if ((Get-VBOCopyJob -ErrorAction SilentlyContinue).LastStatus) {
                            $Alljobs += (Get-VBOCopyJob -ErrorAction SilentlyContinue).LastStatus
                        }

                        $sampleData = [ordered]@{
                            'Success' = ($Alljobs | Where-Object { $_ -eq "Success" } | Measure-Object).Count
                            'Warning' = ($Alljobs | Where-Object { $_ -eq "Warning" } | Measure-Object).Count
                            'Failed' = ($Alljobs | Where-Object { $_ -eq "Failed" } | Measure-Object).Count
                            'Stopped' = ($Alljobs | Where-Object { $_ -eq "Stopped" } | Measure-Object).Count
                        }

                        $sampleDataObj = $sampleData.GetEnumerator() | Select-Object @{ Name = 'Category'; Expression = { $_.key } }, @{ Name = 'Value'; Expression = { $_.value } }

                        $chartFileItem = Get-ColumnChart -Status -SampleData $sampleDataObj -ChartName 'RestoreSessions' -XField 'Category' -YField 'Value' -ChartAreaName 'BackupJobs' -AxisXTitle 'Status' -AxisYTitle 'Count' -ChartTitleName 'BackupJob' -ChartTitleText 'Backup Copy Jobs Latest Results'

                    } catch {
                        Write-PScriboMessage -IsWarning -Message "Backup Copy Chart Section: $($_.Exception.Message)"
                    }

                    if ($InfoLevel.Jobs.BackupCopyJob -ge 2) {
                        Paragraph "The following sections detail the configuration of the backup copy job within $VeeamBackupServer backup server."
                        if ($chartFileItem) {
                            Image -Text 'Backup Copy Job - Diagram' -Align 'Center' -Percent 100 -Base64 $chartFileItem
                        }
                        foreach ($BackupCopyJob in $BackupCopyJobInfo) {
                            Section -ExcludeFromTOC -Style NOTOCHeading4 "$($BackupCopyJob.Name)" {
                                $TableParams = @{
                                    Name = "Backup Copy Job - $($BackupCopyJob.Name)"
                                    List = $true
                                    ColumnWidths = 40, 60
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
                        if ($chartFileItem) {
                            Image -Text 'Backup Copy Job - Diagram' -Align 'Center' -Percent 100 -Base64 $chartFileItem
                        }
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
            Write-PScriboMessage -IsWarning -Message "Backup Copy Jobs Section: $($_.Exception.Message)"
        }
    }

    end {}
}
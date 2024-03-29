function Get-AbrVb365BackupJob {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Backup Jobs
    .DESCRIPTION
        Documents the configuration of Veeam VB365 in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.1
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
        Write-PScriboMessage "BackupJob InfoLevel set at $($InfoLevel.Jobs.BackupJob)."
    }

    process {
        try {
            $BackupJobs = Get-VBOJob | Sort-Object -Property Name
            if (($InfoLevel.Jobs.BackupJob -gt 0) -and ($BackupJobs)) {
                Write-PScriboMessage "Collecting Veeam VB365 Backup Jobs."
                Section -Style Heading2 'Backup Jobs' {
                    $BackupJobInfo = @()
                    foreach ($BackupJob in $BackupJobs) {
                        $inObj = [ordered] @{
                            'Name' = $BackupJob.Name
                            'Organization' = $BackupJob.Organization
                            'Job Backup Type' = $BackupJob.JobBackupType
                            'Selected Items' = Switch ([string]::IsNullOrEmpty($BackupJob.SelectedItems)) {
                                $true { '--' }
                                $false { $BackupJob.SelectedItems }
                                default { 'Unknown' }
                            }
                            'Excluded Items' = Switch ([string]::IsNullOrEmpty($BackupJob.ExcludedItems)) {
                                $true { '--' }
                                $false { $BackupJob.ExcludedItems }
                                default { 'Unknown' }
                            }
                            'Repository' = $BackupJob.Repository
                            'Last Status' = ConvertTo-EmptyToFiller $BackupJob.LastStatus
                            'Last Run' = ConvertTo-EmptyToFiller $BackupJob.LastRun
                            'Next Run' = ConvertTo-EmptyToFiller $BackupJob.NextRun
                            'Last Backup' = ConvertTo-EmptyToFiller $BackupJob.LastBackup
                            'Is Enabled' = ConvertTo-TextYN $BackupJob.IsEnabled
                            'Description' = ConvertTo-EmptyToFiller $BackupJob.Description

                        }
                        $BackupJobInfo += [PSCustomObject]$InObj
                    }

                    if ($HealthCheck.Jobs.BackupJob) {
                        $BackupJobInfo | Where-Object { $_.'Is Enabled' -eq 'No' } | Set-Style -Style Warning -Property 'Is Enabled'
                        $BackupJobInfo | Where-Object { $_.'Last Status' -ne 'Success' } | Set-Style -Style Warning -Property 'Last Status'
                    }

                    try {
                        $Alljobs = @()
                        if ($BackupJobs.LastStatus) {
                            $Alljobs += $BackupJobs.LastStatus
                        }
                        if ((Get-VBOCopyJob -ErrorAction SilentlyContinue).LastStatus) {
                            $Alljobs += (Get-VBOCopyJob -ErrorAction SilentlyContinue).LastStatus
                        }

                        $sampleData = @{
                            'Success' = ($Alljobs | Where-Object { $_ -eq "Success" } | Measure-Object).Count
                            'Warning' = ($Alljobs | Where-Object { $_ -eq "Warning" } | Measure-Object).Count
                            'Failed' = ($Alljobs | Where-Object { $_ -eq "Failed" } | Measure-Object).Count
                            'Stopped' = ($Alljobs | Where-Object { $_ -eq "Stopped" } | Measure-Object).Count
                        }

                        $sampleDataObj = $sampleData.GetEnumerator() | Select-Object @{ Name = 'Category'; Expression = { $_.key } }, @{ Name = 'Value'; Expression = { $_.value } } | Sort-Object -Property 'Category'

                        $chartFileItem = Get-ColumnChart -SampleData $sampleDataObj -ChartName 'RestoreSessions' -XField 'Category' -YField 'Value' -ChartAreaName 'BackupJobs' -AxisXTitle 'Status' -AxisYTitle 'Count' -ChartTitleName 'BackupJob' -ChartTitleText 'Jobs Latest Results'

                    } catch {
                        Write-PScriboMessage -IsWarning "Backup Copy Chart Section: $($_.Exception.Message)"
                    }

                    if ($InfoLevel.Jobs.BackupJob -ge 2) {
                        Paragraph "The following sections detail the configuration of the backup job within $VeeamBackupServer backup server."
                        if ($chartFileItem) {
                            Image -Text 'Backup Repository - Diagram' -Align 'Center' -Percent 100 -Base64 $chartFileItem
                        }
                        foreach ($BackupJob in $BackupJobInfo) {
                            Section -ExcludeFromTOC -Style NOTOCHeading4 "$($BackupJob.Name)" {
                                $TableParams = @{
                                    Name = "Backup Job - $($BackupJob.Name)"
                                    List = $true
                                    ColumnWidths = 40, 60
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $BackupJob | Table @TableParams
                            }
                        }
                    } else {
                        Paragraph "The following table summarizes the configuration of the backup jobs within the $VeeamBackupServer backup server."
                        BlankLine
                        if ($chartFileItem) {
                            Image -Text 'Backup Repository - Diagram' -Align 'Center' -Percent 100 -Base64 $chartFileItem
                        }
                        BlankLine
                        $TableParams = @{
                            Name = "Backup Job - $VeeamBackupServer"
                            List = $false
                            Columns = 'Name', 'Organization', 'Repository', 'Is Enabled', 'Last Status'
                            ColumnWidths = 20, 20, 20, 20, 20
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $BackupJobInfo | Table @TableParams
                    }

                    # Backup Copy Jobs
                    Get-AbrVb365BackupCopyJob
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Backup Copy Section: $($_.Exception.Message)"
        }
    }

    end {}
}
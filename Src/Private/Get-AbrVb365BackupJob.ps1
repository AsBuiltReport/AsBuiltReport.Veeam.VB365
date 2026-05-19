function Get-AbrVb365BackupJob {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Backup Jobs
    .DESCRIPTION
        Documents the configuration of Veeam VB365 in Word/HTML/Text formats using PScribo.
    .NOTE
        Version:        0.4.0
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
        Write-PScriboMessage -Message "BackupJob InfoLevel set at $($InfoLevel.Jobs.BackupJob)."
    }

    process {
        try {
            if ($InfoLevel.Jobs.BackupJob -le 0 -and $InfoLevel.Jobs.BackupCopyJob -le 0) {
                return
            }

            if ($script:BackupJobs) {
                Write-PScriboMessage -Message 'Using cached Veeam VB365 Backup Jobs inventory.'
                $BackupJobs = $script:BackupJobs
            } else {
                Write-PScriboMessage -Message 'Collecting Veeam VB365 Backup Jobs inventory.'
                $BackupJobs = Get-AbrVb365BackupJobInventory
            }

            if (($InfoLevel.Jobs.BackupJob -gt 0) -and ($BackupJobs)) {
                $BackupJobRepositoryLookup = @{}
                Write-PScriboMessage -Message 'Using pre-captured Veeam VB365 Backup Job repository inventory.'
                foreach ($BackupJob in $BackupJobs) {
                    $LookupJobName = Get-AbrVb365PropertyValue -InputObject $BackupJob -Name 'Name' -Default 'Unknown'
                    $LookupJobId = Get-AbrVb365PropertyValue -InputObject $BackupJob -Name 'Id'
                    $LookupKey = ConvertTo-AbrVb365LookupKey -Id $LookupJobId
                    if (-not $LookupKey) {
                        $LookupKey = $LookupJobName
                    }

                    $RepositoryNameProperty = $BackupJob.PSObject.Properties['AbrRepositoryName']
                    $BackupJobRepositoryLookup[$LookupKey] = if ($RepositoryNameProperty -and $RepositoryNameProperty.Value) { $RepositoryNameProperty.Value } else { '--' }
                }

                Write-PScriboMessage -Message 'Collecting Veeam VB365 Backup Jobs.'
                Section -Style Heading2 'Backup Jobs' {
                    $BackupJobInfo = @()
                    foreach ($BackupJob in $BackupJobs) {
                        Write-PScriboMessage -Message "Processing backup job '$($BackupJob.Name)'."
                        $JobName = Invoke-AbrVb365TimedValue -Label "backup job '$($BackupJob.Name)' Name property" -ScriptBlock { $BackupJob.Name }
                        $JobOrganization = Invoke-AbrVb365TimedValue -Label "backup job '$JobName' Organization property" -ScriptBlock { ConvertTo-AbrVb365DisplayValue -InputObject $BackupJob.Organization }
                        $JobId = Get-AbrVb365PropertyValue -InputObject $BackupJob -Name 'Id'
                        $JobLookupKey = ConvertTo-AbrVb365LookupKey -Id $JobId
                        if (-not $JobLookupKey) {
                            $JobLookupKey = $JobName
                        }
                        $JobRepository = if ($JobLookupKey -and $BackupJobRepositoryLookup.ContainsKey($JobLookupKey)) { $BackupJobRepositoryLookup[$JobLookupKey] } else { '--' }
                        $JobLastStatus = Invoke-AbrVb365TimedValue -Label "backup job '$JobName' LastStatus property" -ScriptBlock { $BackupJob.LastStatus }
                        $JobIsEnabled = Invoke-AbrVb365TimedValue -Label "backup job '$JobName' IsEnabled property" -ScriptBlock { $BackupJob.IsEnabled }

                        $inObj = [ordered] @{
                            'Name' = $JobName
                            'Organization' = $JobOrganization
                            'Repository' = $JobRepository
                            'Last Status' = $JobLastStatus
                            'Is Enabled' = $JobIsEnabled
                        }

                        if ($InfoLevel.Jobs.BackupJob -ge 2) {
                            $SelectedItems = switch ([string]::IsNullOrEmpty($BackupJob.SelectedItems)) {
                                $true { '--' }
                                $false { $BackupJob.SelectedItems }
                                default { 'Unknown' }
                            }
                            $ExcludedItems = switch ([string]::IsNullOrEmpty($BackupJob.ExcludedItems)) {
                                $true { '--' }
                                $false {
                                    if (($BackupJob.ExcludedItems | Measure-Object).Count -gt 30) {
                                        'Multiple'
                                    } else {
                                        $BackupJob.ExcludedItems
                                    }
                                }
                                default { 'Unknown' }
                            }

                            $JobBackupType = Invoke-AbrVb365TimedValue -Label "backup job '$JobName' JobBackupType property" -ScriptBlock { $BackupJob.JobBackupType }
                            $JobLastRun = Invoke-AbrVb365TimedValue -Label "backup job '$JobName' LastRun property" -ScriptBlock { $BackupJob.LastRun }
                            $JobNextRun = Invoke-AbrVb365TimedValue -Label "backup job '$JobName' NextRun property" -ScriptBlock { $BackupJob.NextRun }
                            $JobLastBackup = Invoke-AbrVb365TimedValue -Label "backup job '$JobName' LastBackup property" -ScriptBlock { $BackupJob.LastBackup }
                            $JobDescription = Invoke-AbrVb365TimedValue -Label "backup job '$JobName' Description property" -ScriptBlock { $BackupJob.Description }

                            $inObj.Add('Job Backup Type', $JobBackupType)
                            $inObj.Add('Selected Items', $SelectedItems)
                            $inObj.Add('Excluded Items', $ExcludedItems)
                            $inObj.Add('Last Run', $JobLastRun)
                            $inObj.Add('Next Run', $JobNextRun)
                            $inObj.Add('Last Backup', $JobLastBackup)
                            $inObj.Add('Description', $JobDescription)
                        }

                        $BackupJobInfo += [pscustomobject](ConvertTo-HashToYN $inObj)
                    }

                    if ($HealthCheck.Jobs.BackupJob) {
                        $BackupJobInfo | Where-Object { $_.'Is Enabled' -eq 'No' } | Set-Style -Style Warning -Property 'Is Enabled'
                        $BackupJobInfo | Where-Object { $_.'Last Status' -eq 'Success' } | Set-Style -Style Ok -Property 'Last Status'
                        $BackupJobInfo | Where-Object { $_.'Last Status' -eq 'Warning' } | Set-Style -Style Warning -Property 'Last Status'
                        $BackupJobInfo | Where-Object { $_.'Last Status' -eq 'Failed' } | Set-Style -Style Critical -Property 'Last Status'
                    }

                    try {
                        $Alljobs = @()
                        if ($BackupJobInfo.'Last Status') {
                            $Alljobs += $BackupJobInfo.'Last Status'
                        }

                        $sampleData = [ordered]@{
                            'Success' = ($Alljobs | Where-Object { $_ -eq 'Success' } | Measure-Object).Count
                            'Warning' = ($Alljobs | Where-Object { $_ -eq 'Warning' } | Measure-Object).Count
                            'Failed' = ($Alljobs | Where-Object { $_ -eq 'Failed' } | Measure-Object).Count
                            'Stopped' = ($Alljobs | Where-Object { $_ -eq 'Stopped' } | Measure-Object).Count
                        }

                        $sampleDataObj = $sampleData.GetEnumerator() | Select-Object @{ Name = 'Category'; Expression = { $_.key } }, @{ Name = 'Value'; Expression = { $_.value } }

                        $chartLabels = [string[]]$sampleDataObj.Category
                        $chartValues = [double[]]$sampleDataObj.Value

                        $statusCustomPalette = @('#DFF0D0', '#FFF3C4', '#FECDD1', '#ADACAF')

                        $chartFileItem = New-BarChart -Title 'Backup Jobs Latest Results' -Values $chartValues -Labels $chartLabels -LabelXAxis 'Status' -LabelYAxis 'Results' -EnableCustomColorPalette -CustomColorPalette $statusCustomPalette -Width 600 -Height 400 -Format base64 -EnableLegend -LegendOrientation Horizontal -LegendAlignment UpperCenter -AxesMarginsTop 0.5 -TitleFontBold -TitleFontSize 16

                    } catch {
                        Write-PScriboMessage -IsWarning -Message "Backup Copy Chart Section: $($_.Exception.Message)"
                    }

                    if ($InfoLevel.Jobs.BackupJob -ge 2) {
                        Paragraph "The following sections detail the configuration of the backup job within $VeeamBackupServer backup server."
                        if ($chartFileItem) {
                            Image -Text 'Backup Job - Diagram' -Align 'Center' -Percent 100 -Base64 $chartFileItem
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
            Write-PScriboMessage -IsWarning -Message "Backup Copy Section: $($_.Exception.Message)"
        }
    }

    end {}
}

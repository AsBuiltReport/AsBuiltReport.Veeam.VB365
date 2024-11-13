function Get-AbrVb365RestoreSession {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Restore Session
    .DESCRIPTION
        Documents the configuration of Veeam VB365 in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.8
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
        Write-PScriboMessage "RestoreSession InfoLevel set at $($InfoLevel.Restore.RestoreSession)."
    }

    process {
        try {
            $RestoreSessions = Get-VBORestoreSession | Sort-Object -Property Name
            if (($InfoLevel.Restore.RestoreSession -gt 0) -and ($RestoreSessions)) {
                Write-PScriboMessage "Collecting Veeam VB365 Restore Session."
                Section -Style Heading2 'Restore Session' {
                    $RestoreSessionInfo = @()
                    foreach ($RestoreSession in $RestoreSessions) {
                        $inObj = [ordered] @{
                            'Name' = $RestoreSession.Name
                            'Start Time' = $RestoreSession.StartTime
                            'End Time' = $RestoreSession.EndTime
                            'Status' = $RestoreSession.Status
                            'Result' = $RestoreSession.Result
                            'Type' = $RestoreSession.Type
                            'Initiated By' = $RestoreSession.InitiatedBy
                            'Processed Objects' = $RestoreSession.ProcessedObjects
                        }
                        $RestoreSessionInfo += [pscustomobject](ConvertTo-HashToYN $inObj)
                    }

                    if ($InfoLevel.Restore.RestoreSession) {
                        $RestoreSessionInfo | Where-Object { $_.'Result' -eq 'Success' } | Set-Style -Style Ok -Property 'Result'
                        $RestoreSessionInfo | Where-Object { $_.'Result' -eq 'Warning' } | Set-Style -Style Warning -Property 'Result'
                        $RestoreSessionInfo | Where-Object { $_.'Result' -eq 'Failed' } | Set-Style -Style Critical -Property 'Result'
                    }

                    try {
                        $sampleData = [ordered]@{
                            'Success' = ($RestoreSessions.Result | Where-Object { $_ -eq "Success" } | Measure-Object).Count
                            'Warning' = ($RestoreSessions.Result | Where-Object { $_ -eq "Warning" } | Measure-Object).Count
                            'Failed' = ($RestoreSessions.Result | Where-Object { $_ -eq "Failed" } | Measure-Object).Count
                        }

                        $sampleDataObj = $sampleData.GetEnumerator() | Select-Object @{ Name = 'Category'; Expression = { $_.key } }, @{ Name = 'Value'; Expression = { $_.value } }

                        $chartFileItem = Get-ColumnChart -Status -SampleData $sampleDataObj -ChartName 'RestoreSessions' -XField 'Category' -YField 'Value' -ChartAreaName 'RestoreSessions' -AxisXTitle 'Result' -AxisYTitle 'Count' -ChartTitleName 'RestoreSessions' -ChartTitleText 'Restore Session Results'

                    } catch {
                        Write-PScriboMessage -IsWarning "Restore Sessions Chart Section: $($_.Exception.Message)"
                    }

                    if ($InfoLevel.Restore.RestoreSession -ge 2) {
                        Paragraph "The following sections details the configuration of the restore sessions within $VeeamBackupServer backup server."
                        if ($chartFileItem) {
                            Image -Text 'Restore Sessions - Diagram' -Align 'Center' -Percent 100 -Base64 $chartFileItem
                        }
                        foreach ($RestoreSession in $RestoreSessionInfo) {
                            Section -ExcludeFromTOC -Style NOTOCHeading4 "$($RestoreSession.Name)" {
                                $TableParams = @{
                                    Name = "Restore Session - $($RestoreSession.Name)"
                                    List = $true
                                    ColumnWidths = 40, 60
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $RestoreSession | Table @TableParams
                            }
                        }
                    } else {
                        Paragraph "The following table summarizes the configuration of the restore sessions within the $VeeamBackupServer backup server."
                        BlankLine
                        if ($chartFileItem) {
                            Image -Text 'Restore Sessions - Diagram' -Align 'Center' -Percent 100 -Base64 $chartFileItem
                        }
                        BlankLine
                        $TableParams = @{
                            Name = "Restore Sessions - $VeeamBackupServer"
                            List = $false
                            Columns = 'Name', 'Start Time', 'End Time', 'Initiated By', 'Result'
                            ColumnWidths = 25, 20, 20, 20, 15
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $RestoreSessionInfo | Table @TableParams
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Restore Session Section: $($_.Exception.Message)"
        }
    }

    end {}
}
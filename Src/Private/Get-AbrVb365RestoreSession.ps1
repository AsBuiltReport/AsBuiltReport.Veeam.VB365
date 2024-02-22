function Get-AbrVb365RestoreSession {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Restore Session
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
                        $RestoreSessionInfo += [PSCustomObject]$InObj
                    }

                    if ($InfoLevel.Restore.RestoreSession) {
                        $RestoreSessionInfo | Where-Object { $_.'Result' -ne 'Success' } | Set-Style -Style Warning -Property 'Result'
                    }

                    try {
                        $sampleData = @{
                            'Success' = ($RestoreSessions.Result | Where-Object { $_ -eq "Success" } | Measure-Object).Count
                            'Warning' = ($RestoreSessions.Result | Where-Object { $_ -eq "Warning" } | Measure-Object).Count
                            'Failed' = ($RestoreSessions.Result | Where-Object { $_ -eq "Failed" } | Measure-Object).Count
                        }
                        $exampleChart = New-Chart -Name RestoreSession -Width 600 -Height 400

                        $addChartAreaParams = @{
                            Chart = $exampleChart
                            Name = 'RestoreSessions'
                            AxisXTitle = 'Result'
                            AxisYTitle = 'Count'
                            NoAxisXMajorGridLines = $true
                            NoAxisYMajorGridLines = $true
                        }
                        $exampleChartArea = Add-ChartArea @addChartAreaParams -PassThru

                        $addChartSeriesParams = @{
                            Chart = $exampleChart
                            ChartArea = $exampleChartArea
                            Name = 'exampleChartSeries'
                            XField = 'Category'
                            YField = 'Value'
                            Palette = 'Green'
                            ColorPerDataPoint = $true
                        }
                        $sampleData.GetEnumerator() | Select-Object @{ Name = 'Category'; Expression = { $_.key } }, @{ Name = 'Value'; Expression = { $_.value } } | Sort-Object -Property 'Category' | Add-ColumnChartSeries @addChartSeriesParams

                        $addChartTitleParams = @{
                            Chart = $exampleChart
                            ChartArea = $exampleChartArea
                            Name = 'RestoreSessions'
                            Text = 'Restore Session Results'
                            Font = New-Object -TypeName 'System.Drawing.Font' -ArgumentList @('Arial', '12', [System.Drawing.FontStyle]::Bold)
                        }
                        Add-ChartTitle @addChartTitleParams

                        $chartFileItem = Export-Chart -Chart $exampleChart -Path (Get-Location).Path -Format "PNG" -PassThru

                        if ($PassThru) {
                            Write-Output -InputObject $chartFileItem
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "Restore Sessions Chart Section: $($_.Exception.Message)"
                    }

                    if ($InfoLevel.Restore.RestoreSession -ge 2) {
                        Paragraph "The following sections detail the configuration of the restore sessions within $VeeamBackupServer backup server."
                        if ($chartFileItem) {
                            Image -Text 'Restore Sessions - Diagram' -Align 'Center' -Percent 100 -Path $chartFileItem
                        }
                        foreach ($RestoreSession in $RestoreSessionInfo) {
                            Section -ExcludeFromTOC -Style NOTOCHeading3 "$($RestoreSession.Name)" {
                                $TableParams = @{
                                    Name = "Restore Session - $($RestoreSession.Name)"
                                    List = $true
                                    ColumnWidths = 50, 50
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
                            Image -Text 'Restore Sessions - Diagram' -Align 'Center' -Percent 100 -Path $chartFileItem
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
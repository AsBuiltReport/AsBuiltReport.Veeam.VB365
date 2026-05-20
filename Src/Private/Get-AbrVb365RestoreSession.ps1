function Get-AbrVb365RestoreSession {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Restore Session
    .DESCRIPTION
        Documents the configuration of Veeam VB365 in Word/HTML/Text formats using PScribo.
    .NOTES
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
        Write-PScriboMessage -Message "RestoreSession InfoLevel set at $($InfoLevel.Restore.RestoreSession)."
    }

    process {
        try {
            if ($InfoLevel.Restore.RestoreSession -le 0) {
                return
            }

            if ($script:RestoreSessions) {
                Write-PScriboMessage -Message 'Using cached Veeam VB365 Restore Session inventory.'
                $RestoreSessions = $script:RestoreSessions
            } else {
                Write-PScriboMessage -Message 'Collecting Veeam VB365 Restore Session inventory.'
                $script:RestoreSessions = Get-VBORestoreSession | Sort-Object -Property Name
                $RestoreSessions = $script:RestoreSessions
            }

            if (($InfoLevel.Restore.RestoreSession -gt 0) -and ($RestoreSessions)) {
                Write-PScriboMessage -Message 'Collecting Veeam VB365 Restore Session.'
                Section -Style Heading2 'Restore Session' {
                    $RestoreSessionInfo = @()
                    foreach ($RestoreSession in $RestoreSessions) {
                        $inObj = [ordered] @{
                            'Name' = $RestoreSession.Name
                            'Start Time' = $RestoreSession.StartTime
                            'End Time' = $RestoreSession.EndTime
                            'Result' = $RestoreSession.Result
                            'Initiated By' = $RestoreSession.InitiatedBy
                        }

                        if ($InfoLevel.Restore.RestoreSession -ge 2) {
                            $inObj.Add('Status', $RestoreSession.Status)
                            $inObj.Add('Type', $RestoreSession.Type)
                            $inObj.Add('Processed Objects', $RestoreSession.ProcessedObjects)
                        }

                        $RestoreSessionInfo += [pscustomobject](ConvertTo-HashToYN $inObj)
                    }

                    if ($InfoLevel.Restore.RestoreSession) {
                        $RestoreSessionInfo | Where-Object { $_.'Result' -eq 'Success' } | Set-Style -Style Ok -Property 'Result'
                        $RestoreSessionInfo | Where-Object { $_.'Result' -eq 'Warning' } | Set-Style -Style Warning -Property 'Result'
                        $RestoreSessionInfo | Where-Object { $_.'Result' -eq 'Failed' } | Set-Style -Style Critical -Property 'Result'
                    }

                    $chartFileItem = $null
                    if ($Options.EnableCharts -ne $false) {
                        try {
                            $sampleData = [ordered]@{
                                'Success' = ($RestoreSessionInfo.Result | Where-Object { $_ -eq 'Success' } | Measure-Object).Count
                                'Warning' = ($RestoreSessionInfo.Result | Where-Object { $_ -eq 'Warning' } | Measure-Object).Count
                                'Failed' = ($RestoreSessionInfo.Result | Where-Object { $_ -eq 'Failed' } | Measure-Object).Count
                            }

                            $sampleDataObj = $sampleData.GetEnumerator() | Select-Object @{ Name = 'Category'; Expression = { $_.key } }, @{ Name = 'Value'; Expression = { $_.value } }

                            $chartLabels = [string[]]$sampleDataObj.Category
                            $chartValues = [double[]]$sampleDataObj.Value

                            $statusCustomPalette = @('#DFF0D0', '#FFF3C4', '#FECDD1', '#ADACAF')

                            $chartFileItem = New-BarChart -Title 'Restore Session Results' -Values $chartValues -Labels $chartLabels -LabelXAxis 'Status' -LabelYAxis 'Results' -EnableCustomColorPalette -CustomColorPalette $statusCustomPalette -Width 600 -Height 400 -Format base64 -EnableLegend -LegendOrientation Horizontal -LegendAlignment UpperCenter -AxesMarginsTop 0.5 -TitleFontBold -TitleFontSize 16

                        } catch {
                            Write-PScriboMessage -IsWarning -Message "Restore Sessions Chart Section: $($_.Exception.Message)"
                        }
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
            Write-PScriboMessage -IsWarning -Message "Restore Session Section: $($_.Exception.Message)"
        }
    }

    end {}
}

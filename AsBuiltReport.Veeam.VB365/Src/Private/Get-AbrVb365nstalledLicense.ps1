
function Get-AbrVB365InstalledLicense {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Installed Licenses
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
        Write-PScriboMessage -Message "Discovering Veeam VB365 License information from $System."
        $LicenseInfoLevel = Get-AbrVb365InfoLevelValue -Scope 'Infrastructure' -Name 'License' -Alias 'Licenses', 'Licensing', 'Licence', 'Licences', 'LicensedUser', 'LicensedUsers'
        Write-PScriboMessage -Message "License InfoLevel set at $LicenseInfoLevel."
    }

    process {
        try {
            if ($Licenses = Get-VBOLicense) {
                $OutObj = @()
                try {
                    Write-PScriboMessage -Message "Discovered $($Licenses.LicensedTo) license."
                    $inObj = [ordered] @{
                        'Licensed To' = $Licenses.LicensedTo
                        'Edition' = $Licenses.Package
                        'Type' = $Licenses.Type
                        'Status' = $Licenses.Status
                        'Expiration Date' = switch ([string]::IsNullOrEmpty($Licenses.ExpirationDate)) {
                            $true { '-'; break }
                            default { $Licenses.ExpirationDate.ToShortDateString() }
                        }
                        'Support Expiration Date' = switch ([string]::IsNullOrEmpty($Licenses.SupportExpirationDate)) {
                            $true { '--'; break }
                            default { $Licenses.SupportExpirationDate.ToShortDateString() }
                        }
                        'Contact Person' = $Licenses.ContactPerson
                        'License Usage' = switch ([string]::IsNullOrEmpty($Licenses.TotalNumber)) {
                            $true { '--' }
                            $false { "Total: $($Licenses.TotalNumber) - Used: $($Licenses.UsedNumber)" }
                            default { 'Unknown' }
                        }
                    }
                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                } catch {
                    Write-PScriboMessage -IsWarning -Message "Installed License Information $($Licenses.LicensedTo) Section: $($_.Exception.Message)"
                }

                if ($HealthCheck.Infrastructure.License) {
                    $OutObj | Where-Object { $_.'Status' -eq 'Expired' } | Set-Style -Style Critical -Property 'Status'
                    $OutObj | Where-Object { $_.'Type' -eq 'Evaluation' } | Set-Style -Style Warning -Property 'Type'
                    if ($A) {
                        $OutObj | Where-Object { $_.'Type' -eq 'Evaluation' } | Set-Style -Style Warning -Property 'License Usage'
                    }
                }

                $TableParams = @{
                    Name = "Licenses - $VeeamBackupServer"
                    List = $true
                    ColumnWidths = 40, 60
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }

                $chartFileItem = $null
                if ($Options.EnableCharts -ne $false) {
                    try {
                        $sampleData = [ordered]@{
                            'Free' = & {
                                if ($Licenses.TotalNumber -ne 0 -and $Licenses.UsedNumber -ne 0) {
                                    return $Licenses.TotalNumber - $Licenses.UsedNumber
                                } else {
                                    return 0
                                }
                            }
                            'Used' = $Licenses.UsedNumber
                        }

                        $sampleDataObj = $sampleData.GetEnumerator() | Select-Object @{ Name = 'Category'; Expression = { $_.key } }, @{ Name = 'Value'; Expression = { $_.value } } | Sort-Object -Property 'Category'

                        $chartLabels = [string[]]$sampleDataObj.Category
                        $chartValues = [double[]]$sampleDataObj.Value

                        $statusCustomPalette = @('#DFF0D0', '#FFF3C4', '#FECDD1', '#ADACAF')

                        $chartFileItem = New-PieChart -Title "License Usage (Total: $($Licenses.TotalNumber))" -Values $chartValues -Labels $chartLabels -EnableCustomColorPalette -CustomColorPalette $statusCustomPalette -Width 600 -Height 400 -Format base64 -EnableLegend -LegendOrientation Horizontal -LegendAlignment UpperCenter -TitleFontBold -TitleFontSize 16

                    } catch {
                        Write-PScriboMessage -IsWarning -Message "Instance License Usage chart section: $($_.Exception.Message)"
                    }
                }

                if ($OutObj) {
                    Section -Style Heading2 'Licenses' {
                        Paragraph "The following table summarizes the licensing information within $VeeamBackupServer backup server."
                        BlankLine
                        if ($Options.EnableCharts -ne $false -and $chartFileItem -and ($sampleData.Values | Measure-Object -Sum).Sum -ne 0) {
                            Image -Text 'License Usage - Chart' -Align 'Center' -Percent 100 -Base64 $chartFileItem
                        }
                        BlankLine
                        $OutObj | Table @TableParams
                        if ($HealthCheck.Infrastructure.License -and ($Licenses.UsedNumber -ge $Licenses.TotalNumber)) {
                            Paragraph 'Health Check:' -Bold -Underline
                            BlankLine
                            Paragraph {
                                Text 'Best Practice:' -Bold
                                Text 'Warning: Your license has exceeded its user limit.'
                            }
                            BlankLine
                        }

                        # Per user license information
                        if ($LicenseInfoLevel -ge 2) {
                            Get-AbrVB365InstalledLicenseUser
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning -Message "License Information Section: $($_.Exception.Message)"
        }
    }

    end {}

}

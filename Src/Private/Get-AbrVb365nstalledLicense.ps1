
function Get-AbrVB365InstalledLicense {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Installed Licenses
    .DESCRIPTION
        Documents the configuration of Veeam VB365 in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.2
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
        Write-PScriboMessage "Discovering Veeam VB365 License information from $System."
    }

    process {
        try {
            if ($Licenses = Get-VBOLicense) {
                $OutObj = @()
                try {
                    Write-PScriboMessage "Discovered $($Licenses.LicensedTo) license."
                    $inObj = [ordered] @{
                        'Licensed To' = ConvertTo-EmptyToFiller $Licenses.LicensedTo
                        'Edition' = ConvertTo-EmptyToFiller $Licenses.Package
                        'Type' = ConvertTo-EmptyToFiller $Licenses.Type
                        'Status' = ConvertTo-EmptyToFiller $Licenses.Status
                        'Expiration Date' = Switch ([string]::IsNullOrEmpty($Licenses.ExpirationDate)) {
                            $true { "-"; break }
                            default { $Licenses.ExpirationDate.ToShortDateString() }
                        }
                        'Support Expiration Date' = Switch ([string]::IsNullOrEmpty($Licenses.SupportExpirationDate)) {
                            $true { "--"; break }
                            default { $Licenses.SupportExpirationDate.ToShortDateString() }
                        }
                        'Contact Person' = ConvertTo-EmptyToFiller $Licenses.ContactPerson
                        'License Usage' = Switch ([string]::IsNullOrEmpty($Licenses.TotalNumber)) {
                            $true {'--'}
                            $false {"Total: $($Licenses.TotalNumber) - Used: $($Licenses.UsedNumber)"}
                            default {'Unknown'}
                        }
                    }
                    $OutObj += [pscustomobject]$inobj
                } catch {
                    Write-PScriboMessage -IsWarning "Installed License Information $($Licenses.LicensedTo) Section: $($_.Exception.Message)"
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

                    $chartFileItem = Get-PieChart -SampleData $sampleDataObj -ChartName 'LicenseUsage' -XField 'Category' -YField 'Value' -ChartLegendName 'Category' -ChartTitleText "License Usage (Total: $($Licenses.TotalNumber))"

                } catch {
                    Write-PScriboMessage -IsWarning "Instance License Usage chart section: $($_.Exception.Message)"
                }

                if ($OutObj) {
                    Section -Style Heading2 'Licenses' {
                        Paragraph "The following table summarizes the licensing information within $VeeamBackupServer backup server."
                        BlankLine
                        if ($chartFileItem -and ($sampleData.Values | Measure-Object -Sum).Sum -ne 0) {
                            Image -Text 'License Usage - Chart' -Align 'Center' -Percent 100 -Base64 $chartFileItem
                        }
                        BlankLine
                        $OutObj | Table @TableParams
                        if ($HealthCheck.Infrastructure.License -and ($Licenses.UsedNumber -ge $Licenses.TotalNumber)) {
                            Paragraph "Health Check:" -Bold -Underline
                            BlankLine
                            Paragraph {
                                Text "Best Practice:" -Bold
                                Text "Warning: Your license has exceeded its user limit."
                            }
                            BlankLine
                        }

                        # Per user license information
                        if ($InfoLevel.Infrastructure.License -ge 2) {
                            Get-AbrVB365InstalledLicenseUser
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "License Information Section: $($_.Exception.Message)"
        }
    }

    end {}

}
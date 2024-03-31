
function Get-AbrVB365InstalledLicense {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Installed Licenses
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
        Write-PScriboMessage "Discovering Veeam VB365 License information from $System."
    }

    process {
        try {
            $Licenses = Get-VBOLicense
            if ($Licenses) {
                $OutObj = @()
                try {
                    $Licenses = Get-VBOLicense
                    foreach ($License in $Licenses) {
                        Write-PScriboMessage "Discovered $($License.LicensedTo) license."
                        $inObj = [ordered] @{
                            'Licensed To' = ConvertTo-EmptyToFiller $License.LicensedTo
                            'Edition' = ConvertTo-EmptyToFiller $License.Package
                            'Type' = ConvertTo-EmptyToFiller $License.Type
                            'Status' = ConvertTo-EmptyToFiller $License.Status
                            'Expiration Date' = Switch ([string]::IsNullOrEmpty($License.ExpirationDate)) {
                                $true { "-"; break }
                                default { $License.ExpirationDate.ToShortDateString() }
                            }
                            'Support Expiration Date' = Switch ([string]::IsNullOrEmpty($License.SupportExpirationDate)) {
                                $true { "--"; break }
                                default { $License.SupportExpirationDate.ToShortDateString() }
                            }
                            'Contact Person' = ConvertTo-EmptyToFiller $License.ContactPerson
                            'License Usage' = Switch ([string]::IsNullOrEmpty($License.TotalNumber)) {
                                $true {'--'}
                                $false {"Total: $($License.TotalNumber) - Used: $($License.UsedNumber)"}
                                default {'Unknown'}
                            }
                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                } catch {
                    Write-PScriboMessage -IsWarning "Installed License Information $($License.LicensedTo) Section: $($_.Exception.Message)"
                }

                if ($HealthCheck.Infrastructure.License) {
                    $OutObj | Where-Object { $_.'Status' -eq 'Expired' } | Set-Style -Style Critical -Property 'Status'
                    $OutObj | Where-Object { $_.'Type' -eq 'Evaluation' } | Set-Style -Style Warning -Property 'Type'
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

                        # Per user license information
                        Get-AbrVB365InstalledLicenseUser
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "License Information Section: $($_.Exception.Message)"
        }
    }

    end {}

}
function Get-AbrVb365Organization {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Organizations
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
        Write-PScriboMessage "Organizations InfoLevel set at $($InfoLevel.Infrastructure.Organization)."
    }

    process {
        try {
            $Organizations = Get-VBOOrganization | Sort-Object -Property Name
            if (($InfoLevel.Infrastructure.Organization -gt 0) -and ($Organizations)) {
                Write-PscriboMessage "Collecting Veeam VB365 Backup Organization."
                Section -Style Heading2 'Organizations' {
                    $OrganizationInfo = @()
                    foreach ($Organization in $Organizations) {
                        $inObj = [ordered] @{
                            'Name' = $Organization.Name
                            'Type' = $Organization.Type
                            'Server' = $Organization.Server
                            'Use SSL' = ConvertTo-TextYN $Organization.UseSSL
                            'BackedUp' = ConvertTo-TextYN $Organization.IsBackedUp
                            'Licensing Options' = "Licensed Users:$($Organization.LicensingOptions.LicensedUsersCount)\Trial Users:$($Organization.LicensingOptions.TrialUsersCount)"
                            'Backup Parts' = $Organization.BackupParts
                            'Skip CA Verification' = ConvertTo-TextYN $Organization.SkipCAVerification
                            'Skip Common Name Verification' = ConvertTo-TextYN $Organization.SkipCommonNameVerification
                            'Skip Revocation Check' = ConvertTo-TextYN $Organization.SkipRevocationCheck
                            'Is Exchange Server' = ConvertTo-TextYN $Organization.IsExchange
                            'Is SharePoint' = ConvertTo-TextYN $Organization.IsSharePoint
                            'Description' = ConvertTo-EmptyToFiller $Organization.Description

                        }
                        $OrganizationInfo += [PSCustomObject]$InObj
                    }

                    if ($HealthCheck.Infrastructure.Organization) {
                        $OrganizationInfo | Where-Object { $_.'Use SSL' -eq 'No'} | Set-Style -Style Warning -Property 'Use SSL'
                        $OrganizationInfo | Where-Object { $_.'BackedUp' -ne 'Yes' } | Set-Style -Style Warning -Property 'BackedUp'
                    }

                    if ($InfoLevel.Infrastructure.Organization -ge 2) {
                        Paragraph "The following sections detail the configuration of the organization within $VeeamBackupServer backup server."
                        foreach ($Organization in $OrganizationInfo) {
                            Section -ExcludeFromTOC -Style NOTOCHeading3 "$($Organization.Name)" {
                                $TableParams = @{
                                    Name = "Organization - $($Organization.Name)"
                                    List = $true
                                    ColumnWidths = 50, 50
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $Organization | Table @TableParams
                            }
                        }
                    } else {
                        Paragraph "The following table summarises the configuration of the organizations within the $VeeamBackupServer backup server."
                        BlankLine
                        $TableParams = @{
                            Name = "Organizations - $VeeamBackupServer"
                            List = $false
                            Columns = 'Name', 'Type', 'BackedUp', 'Licensing Options'
                            ColumnWidths = 25, 20, 20, 35
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OrganizationInfo | Table @TableParams
                    }
                }
            }
        } catch {
            Write-PscriboMessage -IsWarning "Organization Section: $($_.Exception.Message)"
        }
    }

    end {}
}
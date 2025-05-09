function Get-AbrVb365Organization {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Organizations
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
        Write-PScriboMessage -Message "Organizations InfoLevel set at $($InfoLevel.Infrastructure.Organization)."
    }

    process {
        try {
            $script:Organizations = Get-VBOOrganization | Sort-Object -Property Name
            if (($InfoLevel.Infrastructure.Organization -gt 0) -and ($Organizations)) {
                Write-PScriboMessage -Message "Collecting Veeam VB365 Backup Organization."
                Section -Style Heading2 'Organizations' {
                    $OrganizationInfo = @()
                    foreach ($Organization in $Organizations) {
                        $inObj = [ordered] @{
                            'Name' = $Organization.Name
                            'Type' = $Organization.Type
                            'Server' = $Organization.Server
                            'Region' = $Organization.Region
                            'Username' = $Organization.Username
                            'Office Name' = $Organization.OfficeName
                            'Use SSL' = $Organization.UseSSL
                            'BackedUp' = $Organization.IsBackedUp
                            'Licensing Options' = "Licensed Users:$($Organization.LicensingOptions.LicensedUsersCount) Trial Users:$($Organization.LicensingOptions.TrialUsersCount)"
                            'Backup Parts' = $Organization.BackupParts
                            'Skip CA Verification' = $Organization.SkipCAVerification
                            'Skip Common Name Verification' = $Organization.SkipCommonNameVerification
                            'Skip Revocation Check' = $Organization.SkipRevocationCheck
                            'Is Exchange Server' = $Organization.IsExchange
                            'Is SharePoint' = $Organization.IsSharePoint
                            'Backup Teams' = $Organization.BackupTeams
                            'Backup Teams Chats' = $Organization.BackupTeamsChats
                            'Grant Access To Site Collections' = $Organization.GrantAccessToSiteCollections
                            'Description' = $Organization.Description

                        }

                        if ($inObj.Type -ne "Office365") {
                            $inObj.remove("Backup Teams")
                            $inObj.remove("Backup Teams Chats")
                            $inObj.remove("Region")
                            $inObj.remove("Office Name")
                            $inObj.remove("Grant Access To Site Collections")
                        }


                        if ($inObj.Type -eq "Office365") {
                            $inObj.remove("Skip CA Verification")
                            $inObj.remove("Skip Common Name Verification")
                            $inObj.remove("Skip Revocation Check")
                            $inObj.remove("Is Exchange Server")
                            $inObj.remove("Is SharePoint")
                            $inObj.remove("Server")
                            $inObj.remove("Use SSL")
                        }

                        $OrganizationInfo += [pscustomobject](ConvertTo-HashToYN $inObj)
                    }

                    if ($HealthCheck.Infrastructure.Organization) {
                        $OrganizationInfo | Where-Object { $_.'Use SSL' -eq 'No' } | Set-Style -Style Warning -Property 'Use SSL'
                        $OrganizationInfo | Where-Object { $_.'BackedUp' -ne 'Yes' } | Set-Style -Style Warning -Property 'BackedUp'
                    }

                    if ($InfoLevel.Infrastructure.Organization -ge 2) {
                        Paragraph "The following sections detail the configuration of the organization within $VeeamBackupServer backup server."
                        foreach ($Organization in $OrganizationInfo) {
                            Section -Style Heading3 "$($Organization.Name)" {
                                $TableParams = @{
                                    Name = "Organization - $($Organization.Name)"
                                    List = $true
                                    ColumnWidths = 40, 60
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }

                                $Organization | Table @TableParams

                                if ($Organization.Type -eq "Office365") {
                                    Get-AbrVb365OrganizationBackupApplication -Organization $Organization.Name
                                    Get-AbrVb365OrganizationRestoreOperator -Organization $Organization.Name
                                    Get-AbrVb365OrganizationSyncState -Organization $Organization.Name
                                    Get-AbrVb365OrganizationEXConnSetting -Organization $Organization.Name
                                    Get-AbrVb365OrganizationSPConnSetting -Organization $Organization.Name
                                }
                            }
                        }
                    } else {
                        Paragraph "The following table summarizes the configuration of the organizations within the $VeeamBackupServer backup server."
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
            Write-PScriboMessage -IsWarning -Message "Organization Section: $($_.Exception.Message)"
        }
    }

    end {}
}
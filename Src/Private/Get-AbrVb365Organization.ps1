function Get-AbrVb365Organization {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Organizations
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
        $OrganizationInfoLevel = Get-AbrVb365InfoLevelValue -Scope 'Infrastructure' -Name 'Organization' -Alias 'Organizations', 'Organisation', 'Organisations'
        Write-PScriboMessage -Message "Organizations InfoLevel set at $OrganizationInfoLevel."
    }

    process {
        try {
            if ($OrganizationInfoLevel -le 0) {
                return
            }

            if ($script:Organizations) {
                Write-PScriboMessage -Message 'Using cached Veeam VB365 Backup Organization inventory.'
            } else {
                Write-PScriboMessage -Message 'Collecting Veeam VB365 Backup Organization inventory.'
            }
            $Organizations = Get-AbrVb365OrganizationInventory

            if (($OrganizationInfoLevel -gt 0) -and ($Organizations)) {
                Write-PScriboMessage -Message 'Collecting Veeam VB365 Backup Organization.'
                Section -Style Heading2 'Organizations' {
                    if ($OrganizationInfoLevel -ge 2) {
                        Paragraph "The following sections detail the configuration of the organization within $VeeamBackupServer backup server."
                        foreach ($Organization in $Organizations) {
                            try {
                                $OrganizationName = ConvertTo-AbrVb365DisplayValue -InputObject (Get-AbrVb365PropertyValue -InputObject $Organization -Name 'Name')
                                $OrganizationType = [string](Get-AbrVb365PropertyValue -InputObject $Organization -Name 'Type')
                                Write-PScriboMessage -Message "Processing organization '$OrganizationName'."

                                $LicensedUsersCount = Get-AbrVb365PropertyValue -InputObject $Organization.LicensingOptions -Name 'LicensedUsersCount' -Default '--'
                                $TrialUsersCount = Get-AbrVb365PropertyValue -InputObject $Organization.LicensingOptions -Name 'TrialUsersCount' -Default '--'
                                $inObj = [ordered] @{
                                    'Name' = $OrganizationName
                                    'Type' = $OrganizationType
                                    'BackedUp' = Get-AbrVb365PropertyValue -InputObject $Organization -Name 'IsBackedUp' -Default $false
                                    'Licensing Options' = "Licensed Users:$LicensedUsersCount Trial Users:$TrialUsersCount"
                                    'Server' = Get-AbrVb365PropertyValue -InputObject $Organization -Name 'Server' -Default '--'
                                    'Region' = Get-AbrVb365PropertyValue -InputObject $Organization -Name 'Region' -Default '--'
                                    'Username' = Get-AbrVb365PropertyValue -InputObject $Organization -Name 'Username' -Default '--'
                                    'Office Name' = Get-AbrVb365PropertyValue -InputObject $Organization -Name 'OfficeName' -Default '--'
                                    'Use SSL' = Get-AbrVb365PropertyValue -InputObject $Organization -Name 'UseSSL' -Default $false
                                    'Backup Parts' = Get-AbrVb365PropertyValue -InputObject $Organization -Name 'BackupParts' -Default '--'
                                    'Skip CA Verification' = Get-AbrVb365PropertyValue -InputObject $Organization -Name 'SkipCAVerification' -Default $false
                                    'Skip Common Name Verification' = Get-AbrVb365PropertyValue -InputObject $Organization -Name 'SkipCommonNameVerification' -Default $false
                                    'Skip Revocation Check' = Get-AbrVb365PropertyValue -InputObject $Organization -Name 'SkipRevocationCheck' -Default $false
                                    'Is Exchange Server' = Get-AbrVb365PropertyValue -InputObject $Organization -Name 'IsExchange' -Default $false
                                    'Is SharePoint' = Get-AbrVb365PropertyValue -InputObject $Organization -Name 'IsSharePoint' -Default $false
                                    'Backup Teams' = Get-AbrVb365PropertyValue -InputObject $Organization -Name 'BackupTeams' -Default $false
                                    'Backup Teams Chats' = Get-AbrVb365PropertyValue -InputObject $Organization -Name 'BackupTeamsChats' -Default $false
                                    'Grant Access To Site Collections' = Get-AbrVb365PropertyValue -InputObject $Organization -Name 'GrantAccessToSiteCollections' -Default $false
                                    'Description' = Get-AbrVb365PropertyValue -InputObject $Organization -Name 'Description' -Default '--'
                                }

                                if ($OrganizationType -ne 'Office365') {
                                    $inObj.remove('Backup Teams')
                                    $inObj.remove('Backup Teams Chats')
                                    $inObj.remove('Region')
                                    $inObj.remove('Office Name')
                                    $inObj.remove('Grant Access To Site Collections')
                                }

                                if ($OrganizationType -eq 'Office365') {
                                    $inObj.remove('Skip CA Verification')
                                    $inObj.remove('Skip Common Name Verification')
                                    $inObj.remove('Skip Revocation Check')
                                    $inObj.remove('Is Exchange Server')
                                    $inObj.remove('Is SharePoint')
                                    $inObj.remove('Server')
                                    $inObj.remove('Use SSL')
                                }

                                $OrganizationInfo = [pscustomobject](ConvertTo-HashToYN $inObj)

                                if ($HealthCheck.Infrastructure.Organization) {
                                    $OrganizationInfo | Where-Object { $_.'Use SSL' -eq 'No' } | Set-Style -Style Warning -Property 'Use SSL'
                                    $OrganizationInfo | Where-Object { $_.'BackedUp' -ne 'Yes' } | Set-Style -Style Warning -Property 'BackedUp'
                                }

                                Section -Style Heading3 "$OrganizationName" {
                                    $TableParams = @{
                                        Name = "Organization - $OrganizationName"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }

                                    $OrganizationInfo | Table @TableParams

                                    if ($OrganizationType -eq 'Office365') {
                                        try { Get-AbrVb365OrganizationBackupApplication -Organization $OrganizationName } catch { Write-PScriboMessage -IsWarning -Message "Organization '$OrganizationName' Backup Applications Section: $($_.Exception.Message)" }
                                        try { Get-AbrVb365OrganizationRestoreOperator -Organization $OrganizationName } catch { Write-PScriboMessage -IsWarning -Message "Organization '$OrganizationName' Restore Operators Section: $($_.Exception.Message)" }
                                        try { Get-AbrVb365OrganizationSyncState -Organization $OrganizationName } catch { Write-PScriboMessage -IsWarning -Message "Organization '$OrganizationName' Synchronization State Section: $($_.Exception.Message)" }
                                        try { Get-AbrVb365OrganizationEXConnSetting -Organization $OrganizationName } catch { Write-PScriboMessage -IsWarning -Message "Organization '$OrganizationName' Exchange Connection Settings Section: $($_.Exception.Message)" }
                                        try { Get-AbrVb365OrganizationSPConnSetting -Organization $OrganizationName } catch { Write-PScriboMessage -IsWarning -Message "Organization '$OrganizationName' SharePoint Connection Settings Section: $($_.Exception.Message)" }
                                    }
                                }
                            } catch {
                                Write-PScriboMessage -IsWarning -Message "Organization '$($Organization.Name)' Detail Section: $($_.Exception.Message)"
                            }
                        }
                    } else {
                        $OrganizationInfo = @()
                        foreach ($Organization in $Organizations) {
                            try {
                                $LicensedUsersCount = Get-AbrVb365PropertyValue -InputObject $Organization.LicensingOptions -Name 'LicensedUsersCount' -Default '--'
                                $TrialUsersCount = Get-AbrVb365PropertyValue -InputObject $Organization.LicensingOptions -Name 'TrialUsersCount' -Default '--'
                                $inObj = [ordered] @{
                                    'Name' = Get-AbrVb365PropertyValue -InputObject $Organization -Name 'Name' -Default '--'
                                    'Type' = Get-AbrVb365PropertyValue -InputObject $Organization -Name 'Type' -Default '--'
                                    'BackedUp' = Get-AbrVb365PropertyValue -InputObject $Organization -Name 'IsBackedUp' -Default $false
                                    'Licensing Options' = "Licensed Users:$LicensedUsersCount Trial Users:$TrialUsersCount"
                                }

                                $OrganizationInfo += [pscustomobject](ConvertTo-HashToYN $inObj)
                            } catch {
                                Write-PScriboMessage -IsWarning -Message "Organization Summary Row Section: $($_.Exception.Message)"
                            }
                        }

                        if ($HealthCheck.Infrastructure.Organization) {
                            $OrganizationInfo | Where-Object { $_.'BackedUp' -ne 'Yes' } | Set-Style -Style Warning -Property 'BackedUp'
                        }

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

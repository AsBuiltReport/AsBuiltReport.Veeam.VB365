function Get-AbrVb365OrganizationRestoreOperator {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Office365 Restore Operator Settings
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
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String] $Organization
    )

    begin {
        $OrganizationInfoLevel = Get-AbrVb365InfoLevelValue -Scope 'Infrastructure' -Name 'Organization' -Alias 'Organizations', 'Organisation', 'Organisations'
        Write-PScriboMessage -Message "Organizations InfoLevel set at $OrganizationInfoLevel."
    }

    process {
        try {
            $Organizations = Get-AbrVb365OrganizationByName -Name $Organization
            if ($script:RestoreOperators) {
                $OrganizationKey = ConvertTo-AbrVb365LookupKey -Id $Organizations.Id
                $RestoreOperatorOrgs = $script:RestoreOperators | Where-Object { (ConvertTo-AbrVb365LookupKey -Id $_.OrganizationId) -eq $OrganizationKey } | Sort-Object -Property Name
            } else {
                $script:RestoreOperators = try { Get-VBORbacRole | Sort-Object -Property Name } catch { Out-Null }
                $OrganizationKey = ConvertTo-AbrVb365LookupKey -Id $Organizations.Id
                $RestoreOperatorOrgs = $script:RestoreOperators | Where-Object { (ConvertTo-AbrVb365LookupKey -Id $_.OrganizationId) -eq $OrganizationKey } | Sort-Object -Property Name
            }
            if (($OrganizationInfoLevel -gt 0) -and ($RestoreOperatorOrgs)) {
                Write-PScriboMessage -Message "Collecting Veeam VB365 Office365 Restore Operators Settings."
                Section -Style Heading4 'Restore Operators' {
                    foreach ($RestoreOperatorOrg in $RestoreOperatorOrgs) {
                        Section -ExcludeFromTOC -Style NOTOCHeading5 "$($RestoreOperatorOrg.Name)" {
                            $RestoreOperatorOrgInfo = @()

                            if ($RestoreOperatorOrg.Operators.UserName) {
                                $Operator = $RestoreOperatorOrg.Operators.UserName
                            } elseif ($RestoreOperatorOrg.Operators.DisplayName) {
                                $Operator = $RestoreOperatorOrg.Operators.DisplayName
                            } else {
                                $Operator = 'Unknown'
                            }

                            $inObj = [ordered] @{
                                'Role Type' = $RestoreOperatorOrg.RoleType
                                'Operators' = $Operator
                                'Selected Items' = $RestoreOperatorOrg.SelectedItems.Title -join ','
                                'Excluded Items' = $RestoreOperatorOrg.ExcludedItems.Title -join ','
                                'Description' = $RestoreOperatorOrg.Description
                            }

                            $RestoreOperatorOrgInfo += [pscustomobject](ConvertTo-HashToYN $inObj)

                            $TableParams = @{
                                Name = "Restore Operator - $($RestoreOperatorOrg.Name)"
                                List = $true
                                ColumnWidths = 40, 60
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }

                            $RestoreOperatorOrgInfo | Table @TableParams

                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning -Message "VB365 Office365 Restore Operators Settings Section: $($_.Exception.Message)"
        }
    }

    end {}
}

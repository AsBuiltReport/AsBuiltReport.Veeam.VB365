function Get-AbrVb365OrganizationRestoreOperator {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Office365 Restore Operator Settings
    .DESCRIPTION
        Documents the configuration of Veeam VB365 in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.6
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
        Write-PScriboMessage "Organizations InfoLevel set at $($InfoLevel.Infrastructure.Organization)."
    }

    process {
        try {
            $Organizations = Get-VBOOrganization -Name $Organization
            $RestoreOperatorOrgs = try { Get-VBORbacRole -Organization $Organizations | Sort-Object -Property Name } catch { Out-Null }
            if (($InfoLevel.Infrastructure.Organization -gt 0) -and ($RestoreOperators)) {
                Write-PScriboMessage "Collecting Veeam VB365 Office365 Restore Operators Settings."
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

                            $RestoreOperatorOrgInfo += [PSCustomObject]$InObj

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
            Write-PScriboMessage -IsWarning "VB365 Office365 Restore Operators Settings Section: $($_.Exception.Message)"
        }
    }

    end {}
}
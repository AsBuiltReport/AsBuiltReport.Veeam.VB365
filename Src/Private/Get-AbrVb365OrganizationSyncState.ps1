function Get-AbrVb365OrganizationSyncState {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Office365 Synchronization State Settings
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
        Write-PScriboMessage -Message "Organizations InfoLevel set at $($InfoLevel.Infrastructure.Organization)."
    }

    process {
        try {
            $Organizations = Get-VBOOrganization -Name $Organization
            $SyncState = try { Get-VBOOrganizationSynchronizationState -Organization $Organizations } catch { Out-Null }
            if (($InfoLevel.Infrastructure.Organization -gt 0) -and ($SyncState)) {
                Write-PScriboMessage -Message "Collecting Veeam VB365 Office365 Synchronization State Settings."
                Section -Style Heading4 'Synchronization State' {
                    $StateInfo = @()
                    foreach ($State in $SyncState) {
                        $inObj = [ordered] @{
                            'Organization' = $State.Organization
                            'Sync Status' = $State.SyncStatus
                            'Type' = $State.Type
                            'Last Sync Time' = $State.LastSyncTime
                            'Error' = $State.ConfigureApplication
                        }

                        $StateInfo += [pscustomobject](ConvertTo-HashToYN $inObj)
                    }

                    if ($HealthCheck.Infrastructure.Organization) {
                        $OrganizationInfo | Where-Object { $_.'Sync Status' -ne 'Success' } | Set-Style -Style Warning -Property 'Sync Status'
                    }

                    foreach ($State in $StateInfo) {
                        Section -ExcludeFromTOC -Style NOTOCHeading5 "$($State.Organization)" {
                            $TableParams = @{
                                Name = "Organization - $($State.Organization)"
                                List = $true
                                ColumnWidths = 40, 60
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }

                            $State | Table @TableParams
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning -Message "Office365 SharePoint Connection Settings Section: $($_.Exception.Message)"
        }
    }

    end {}
}
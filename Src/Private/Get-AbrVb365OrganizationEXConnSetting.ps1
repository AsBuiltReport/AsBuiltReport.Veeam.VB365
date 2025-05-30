function Get-AbrVb365OrganizationEXConnSetting {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Office365 Exchange Connection Settings
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
            if (($InfoLevel.Infrastructure.Organization -gt 0) -and ($Organizations.Office365ExchangeConnectionSettings)) {
                Write-PScriboMessage -Message "Collecting Veeam VB365 Office365 Exchange Connection Settings."
                Section -Style Heading4 'Exchange Connection Setting' {
                    $OrganizationInfo = @()
                    foreach ($Org in $Organizations.Office365ExchangeConnectionSettings) {
                        $inObj = [ordered] @{
                            'Application Id' = $Org.ApplicationId
                            'Authentication Type' = $Org.AuthenticationType
                            'Impersonation Account Name' = $Org.ImpersonationAccountName
                            'Office Organization Name' = $Org.OfficeOrganizationName
                            'Configure Application' = $Org.ConfigureApplication
                            'ApplicationCertificateThumbprint' = $Org.ApplicationCertificateThumbprint
                            'SharePoint Save All Web Parts' = $Org.SharePointSaveAllWebParts
                        }

                        $OrganizationInfo += [pscustomobject](ConvertTo-HashToYN $inObj)
                    }

                    if ($HealthCheck.Infrastructure.Organization) {
                        $OrganizationInfo | Where-Object { $_.'Authentication Type' -ne 'ApplicationOnly' } | Set-Style -Style Warning -Property 'Authentication Type'
                    }

                    foreach ($Org in $OrganizationInfo) {
                        Section -ExcludeFromTOC -Style NOTOCHeading5 "$($Org.'Application Id')" {
                            $TableParams = @{
                                Name = "Application Id - $($Org.'Application Id')"
                                List = $true
                                ColumnWidths = 40, 60
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }

                            $Org | Table @TableParams
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning -Message "Office365 Exchange Connection Settings Section: $($_.Exception.Message)"
        }
    }

    end {}
}
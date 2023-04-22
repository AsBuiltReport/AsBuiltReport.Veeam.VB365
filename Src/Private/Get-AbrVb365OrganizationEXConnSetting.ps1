function Get-AbrVb365OrganizationEXConnSetting {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Office365 Exchange Connection Settings
    .DESCRIPTION
        Documents the configuration of Veeam VB365 in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.2.0
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
            if (($InfoLevel.Infrastructure.Organization -gt 0) -and ($Organizations.Office365ExchangeConnectionSettings)) {
                Write-PscriboMessage "Collecting Veeam VB365 Office365 Exchange Connection Settings."
                Section -Style Heading4 'Exchange Connection Setting' {
                    $OrganizationInfo = @()
                    foreach ($Org in $Organizations.Office365ExchangeConnectionSettings) {
                        $inObj = [ordered] @{
                            'Application Id' = $Org.ApplicationId
                            'Authentication Type' = $Org.AuthenticationType
                            'Impersonation Account Name' = $Org.ImpersonationAccountName
                            'Office Organization Name' = $Org.OfficeOrganizationName
                            'Configure Application' = ConvertTo-TextYN $Org.ConfigureApplication
                            'ApplicationCertificateThumbprint' = $Org.ApplicationCertificateThumbprint
                            'SharePoint Save All Web Parts' = ConvertTo-TextYN $Org.SharePointSaveAllWebParts
                        }

                        $OrganizationInfo += [PSCustomObject]$InObj
                    }

                    foreach ($Org in $OrganizationInfo) {
                        Section -ExcludeFromTOC -Style NOTOCHeading5 "$($Org.'Application Id')" {
                            $TableParams = @{
                                Name = "Application Id - $($Org.'Application Id')"
                                List = $true
                                ColumnWidths = 50, 50
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }

                            $Org| Table @TableParams
                        }
                    }
                }
            }
        } catch {
            Write-PscriboMessage -IsWarning "Office365 Exchange Connection Settings Section: $($_.Exception.Message)"
        }
    }

    end {}
}
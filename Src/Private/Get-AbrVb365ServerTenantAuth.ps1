function Get-AbrVB365ServerTenantAuth {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 backup tenant authentication configuration
    .DESCRIPTION
        Documents the configuration of Veeam VB365 in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.2.1
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
        Write-PScriboMessage "ServerConfig InfoLevel set at $($InfoLevel.Infrastructure.ServerConfig)."
    }

    process {
        try {
            $TenantAuth = Get-VBOTenantAuthenticationSettings
            $OperatorAuth = Get-VBOOperatorAuthenticationSettings
            if (($InfoLevel.Infrastructure.ServerConfig -gt 0) -and ($TenantAuth -or $OperatorAuth)) {
                Write-PScriboMessage "Collecting Veeam VB365 Tenant Authentication."
                Section -Style Heading4 'Authentication' {
                    if ($TenantAuth) {
                        Section -ExcludeFromTOC -Style NOTOCHeading5 'Tenant Authentication' {
                            $TenantAuthInfo = @()
                            $inObj = [ordered] @{
                                'Is Tenant Authentication Enabled' = ConvertTo-TextYN $TenantAuth.AuthenticationEnabled
                                'Cert Friendly Name' = ConvertTo-EmptyToFiller $TenantAuth.CertificateFriendlyName
                                'Issued To' = ConvertTo-EmptyToFiller $TenantAuth.CertificateIssuedTo
                                'Issued By' = ConvertTo-EmptyToFiller $TenantAuth.CertificateIssuedBy
                                'Thumbprint' = $TenantAuth.CertificateThumbprint
                                'Expiration Date' = ConvertTo-EmptyToFiller $TenantAuth.CertificateExpirationDate
                            }
                            $TenantAuthInfo = [PSCustomObject]$InObj

                            $TableParams = @{
                                Name = "Tenant Authentication - $VeeamBackupServer"
                                List = $true
                                ColumnWidths = 50, 50
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $TenantAuthInfo | Table @TableParams
                        }
                    }
                    if ($OperatorAuth) {
                        Section -ExcludeFromTOC -Style NOTOCHeading5 'Restore Operator Authentication' {
                            $OperatorAuthInfo = @()
                            $inObj = [ordered] @{
                                'Is Restore Operator Authentication Enabled' = ConvertTo-TextYN $OperatorAuth.AuthenticationEnabled
                                'Cert Friendly Name' = ConvertTo-EmptyToFiller $OperatorAuth.CertificateFriendlyName
                                'Issued To' = ConvertTo-EmptyToFiller $OperatorAuth.CertificateIssuedTo
                                'Issued By' = ConvertTo-EmptyToFiller $OperatorAuth.CertificateIssuedBy
                                'Thumbprint' = $OperatorAuth.CertificateThumbprint
                                'Expiration Date' = ConvertTo-EmptyToFiller $OperatorAuth.CertificateExpirationDate
                            }
                            $OperatorAuthInfo = [PSCustomObject]$InObj

                            $TableParams = @{
                                Name = "Restore Operator Authentication - $VeeamBackupServer"
                                List = $true
                                ColumnWidths = 50, 50
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OperatorAuthInfo | Table @TableParams
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Authentication Section: $($_.Exception.Message)"
        }
    }

    end {}
}
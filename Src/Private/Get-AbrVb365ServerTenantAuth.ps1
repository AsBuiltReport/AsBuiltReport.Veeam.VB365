function Get-AbrVB365ServerTenantAuth {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 backup tenant authentication configuration
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
        Write-PScriboMessage -Message "ServerConfig InfoLevel set at $($InfoLevel.Infrastructure.ServerConfig)."
    }

    process {
        try {
            $TenantAuth = Get-VBOTenantAuthenticationSettings
            $OperatorAuth = Get-VBOOperatorAuthenticationSettings
            if (($InfoLevel.Infrastructure.ServerConfig -gt 0) -and ($TenantAuth -or $OperatorAuth)) {
                Write-PScriboMessage -Message "Collecting Veeam VB365 Tenant Authentication."
                Section -Style Heading4 'Authentication' {
                    if ($TenantAuth) {
                        Section -ExcludeFromTOC -Style NOTOCHeading5 'Tenant Authentication' {
                            $TenantAuthInfo = @()
                            $inObj = [ordered] @{
                                'Is Tenant Authentication Enabled' = $TenantAuth.AuthenticationEnabled
                                'Cert Friendly Name' = $TenantAuth.CertificateFriendlyName
                                'Issued To' = $TenantAuth.CertificateIssuedTo
                                'Issued By' = $TenantAuth.CertificateIssuedBy
                                'Thumbprint' = $TenantAuth.CertificateThumbprint
                                'Expiration Date' = $TenantAuth.CertificateExpirationDate.DateTime
                            }
                            $TenantAuthInfo = [pscustomobject](ConvertTo-HashToYN $inObj)

                            if ($HealthCheck.Infrastructure.ServerConfig) {
                                $TenantAuthInfo | Where-Object { $_.'Issued By' -eq 'CN=Veeam Software, O=Veeam Software, OU=Veeam Software' } | Set-Style -Style Warning -Property 'Issued By'
                                $TenantAuthInfo | Where-Object { ((Get-Date).AddDays(+90)).Date.DateTime -gt $_.'Expiration Date' } | Set-Style -Style Critical -Property 'Expiration Date'
                            }

                            $TableParams = @{
                                Name = "Tenant Authentication - $VeeamBackupServer"
                                List = $true
                                ColumnWidths = 40, 60
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $TenantAuthInfo | Table @TableParams
                            if ($HealthCheck.Infrastructure.ServerConfig -and ($TenantAuthInfo | Where-Object { $_.'Issued By' -eq 'CN=Veeam Software, O=Veeam Software, OU=Veeam Software' })) {
                                Paragraph "Health Check:" -Bold -Underline
                                BlankLine
                                Paragraph {
                                    Text "Best Practice:" -Bold
                                    Text "While self-signed certificates may seem harmless, they open up dangerous vulnerabilities from MITM attacks to disrupted services. Protect your organization by making the switch to trusted CA certificates."
                                    Text "https://bp.veeam.com/vb365/guide/supplemental/security.html#certificate-usage" -Color Blue
                                }
                                BlankLine
                            }
                        }
                    }
                    if ($OperatorAuth) {
                        Section -ExcludeFromTOC -Style NOTOCHeading5 'Restore Operator Authentication' {
                            $OperatorAuthInfo = @()
                            $inObj = [ordered] @{
                                'Is Restore Operator Authentication Enabled' = $OperatorAuth.AuthenticationEnabled
                                'Cert Friendly Name' = $OperatorAuth.CertificateFriendlyName
                                'Issued To' = $OperatorAuth.CertificateIssuedTo
                                'Issued By' = $OperatorAuth.CertificateIssuedBy
                                'Thumbprint' = $OperatorAuth.CertificateThumbprint
                                'Expiration Date' = $OperatorAuth.CertificateExpirationDate.DateTime
                            }
                            $OperatorAuthInfo = [pscustomobject](ConvertTo-HashToYN $inObj)

                            if ($HealthCheck.Infrastructure.ServerConfig) {
                                $OperatorAuthInfo | Where-Object { $_.'Issued By' -eq 'CN=Veeam Software, O=Veeam Software, OU=Veeam Software' } | Set-Style -Style Warning -Property 'Issued By'
                                $OperatorAuthInfo | Where-Object { ((Get-Date).AddDays(+90)).Date.DateTime -gt $_.'Expiration Date' } | Set-Style -Style Critical -Property 'Expiration Date'
                            }

                            $TableParams = @{
                                Name = "Restore Operator Authentication - $VeeamBackupServer"
                                List = $true
                                ColumnWidths = 40, 60
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OperatorAuthInfo | Table @TableParams
                            if ($HealthCheck.Infrastructure.ServerConfig -and ($OperatorAuthInfo | Where-Object { $_.'Issued By' -eq 'CN=Veeam Software, O=Veeam Software, OU=Veeam Software' })) {
                                Paragraph "Health Check:" -Bold -Underline
                                BlankLine
                                Paragraph {
                                    Text "Best Practice:" -Bold
                                    Text "While self-signed certificates may seem harmless, they open up dangerous vulnerabilities from MITM attacks to disrupted services. Protect your organization by making the switch to trusted CA certificates."
                                    Text "https://bp.veeam.com/vb365/guide/supplemental/security.html#certificate-usage" -Color Blue
                                }
                                BlankLine
                            }
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning -Message "Authentication Section: $($_.Exception.Message)"
        }
    }

    end {}
}
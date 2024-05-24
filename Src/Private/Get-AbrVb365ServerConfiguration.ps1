function Get-AbrVB365ServerConfiguration {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 backup server configuration
    .DESCRIPTION
        Documents the configuration of Veeam VB365 in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.2
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
            $ServerConfig = @()
            $ServerConfig += try { Get-VBOVersion } catch { Out-Null }
            $ServerConfig += Get-VBOSecuritySettings

            if (($InfoLevel.Infrastructure.ServerConfig -gt 0) -and ($ServerConfig)) {
                Write-PScriboMessage "Collecting Veeam VB365 Server Configuration."
                Section -Style Heading2 'Server Configuration' {
                    Paragraph "The following sections detail the server configuration of $VeeamBackupServer backup server."
                    BlankLine
                    Section -Style Heading4 'General Information' {
                        $ServerConfigInfo = @()
                        $inObj = [ordered] @{
                            'Server Product Version' = Switch ([string]::IsNullOrEmpty($ServerConfig.ProductVersion)) {
                                $true { '6 or less, please upgrade' }
                                $false { $ServerConfig.ProductVersion }
                                default { 'Unknown' }

                            }
                            'Certificate Friendly Name' = $ServerConfig.CertificateFriendlyName
                            'Issued To' = $ServerConfig.CertificateIssuedTo
                            'Issued By' = $ServerConfig.CertificateIssuedBy
                            'Expiration Date' = $ServerConfig.CertificateExpirationDate.DateTime
                            'Thumbprint' = $ServerConfig.CertificateThumbprint
                        }
                        $ServerConfigInfo = [PSCustomObject]$InObj

                        if ($HealthCheck.Infrastructure.ServerConfig) {
                            $ServerConfigInfo | Where-Object { $_.'Server Product Version' -eq '6 or less, please upgrade' } | Set-Style -Style Warning -Property 'Server Product Version'
                            $ServerConfigInfo | Where-Object { $_.'Issued By' -eq 'CN=Veeam Software, O=Veeam Software, OU=Veeam Software' } | Set-Style -Style Warning -Property 'Issued By'
                            $ServerConfigInfo | Where-Object { ((Get-Date).AddDays(+90)).Date.DateTime -lt $_.'Expiration Date' } | Set-Style -Style Critical -Property 'Expiration Date'
                        }

                        $TableParams = @{
                            Name = "Server Configuration - $VeeamBackupServer"
                            List = $true
                            ColumnWidths = 40, 60
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $ServerConfigInfo | Table @TableParams
                        if ($HealthCheck.Infrastructure.ServerConfig -and ($ServerConfigInfo | Where-Object { $_.'Issued By' -eq 'CN=Veeam Software, O=Veeam Software, OU=Veeam Software' })) {
                            Paragraph "Health Check:" -Bold -Underline
                            BlankLine
                            Paragraph {
                                Text "Best Practice:" -Bold
                                Text "While self-signed certificates may seem harmless, they open up dangerous vulnerabilities from MITM attacks to disrupted services. Protect your organization by making the switch to trusted CA certificates."
                            }
                            BlankLine
                        }
                    }

                    # Backup Server Internet Proxy Configuration
                    Get-AbrVB365ServerInternetProxy

                    # Backup Server RESTfull API Configuration
                    Get-AbrVB365ServerRestAPI

                    # Backup Server Email Settings
                    Get-AbrVB365ServerEmailSetting

                    #Backup Server Authentication
                    Get-AbrVB365ServerTenantAuth

                    #Backup Server Folder Exclusion
                    Get-AbrVB365ServerFolderExclution

                    #Backup Server Restore Portal
                    Get-AbrVb365ServerRestorePortal

                    #Backup Server History Retention Setting
                    Get-AbrVb365ServerHistorySetting
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Server Configuration Section: $($_.Exception.Message)"
        }
    }

    end {}
}
function Get-AbrVB365ServerRestAPI {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 backup restfull api configuration
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
            $script:ServerConfigRestAPI = Get-VBORestAPISettings
            if (($InfoLevel.Infrastructure.ServerConfig -gt 0) -and ($ServerConfigRestAPI)) {
                Write-PScriboMessage -Message "Collecting Veeam VB365 RESTful API."
                Section -Style Heading3 'RESTful API' {
                    $ServerConfigRestAPIInfo = @()
                    $inObj = [ordered] @{
                        'Is Service Enabled' = $ServerConfigRestAPI.IsServiceEnabled
                        'Auth Token LifeTime' = $ServerConfigRestAPI.AuthTokenLifeTime
                        'HTTPS Port' = $ServerConfigRestAPI.HTTPSPort
                        'Cert Friendly Name' = $ServerConfigRestAPI.CertificateFriendlyName
                        'Issued To' = $ServerConfigRestAPI.CertificateIssuedTo
                        'Issued By' = $ServerConfigRestAPI.CertificateIssuedBy
                        'Thumbprint' = $ServerConfigRestAPI.CertificateThumbprint
                        'Expiration Date' = $ServerConfigRestAPI.CertificateExpirationDate.DateTime
                    }
                    if ($VBOversion.split('')[0] -ge 8.1) {
                        $inObj.Add('Enable Swagger UI', $ServerConfigRestAPI.EnableSwaggerUI)
                        $inObj.Add('Enable Restore Operator Authentication Only', $ServerConfigRestAPI.EnableOperatorAuthenticationOnly)
                    }

                    $ServerConfigRestAPIInfo = [pscustomobject](ConvertTo-HashToYN $inObj)

                    if ($HealthCheck.Infrastructure.ServerConfig) {
                        $ServerConfigRestAPIInfo | Where-Object { $_.'Issued By' -eq 'CN=Veeam Software, O=Veeam Software, OU=Veeam Software' } | Set-Style -Style Warning -Property 'Issued By'
                        $ServerConfigRestAPIInfo | Where-Object { ((Get-Date).AddDays(+90)).Date.DateTime -gt $_.'Expiration Date' } | Set-Style -Style Critical -Property 'Expiration Date'
                        foreach ( $OBJ in ($ServerConfigRestAPIInfo | Where-Object { ((Get-Date).AddDays(+90)).Date.DateTime -gt $_.'Expiration Date' })) {
                            $OBJ.'Expiration Date' = $OBJ.'Expiration Date' + " (Expires <=90 days)"
                        }
                    }

                    $TableParams = @{
                        Name = "RESTful API - $VeeamBackupServer"
                        List = $true
                        ColumnWidths = 40, 60
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $ServerConfigRestAPIInfo | Table @TableParams
                    if ($HealthCheck.Infrastructure.ServerConfig -and ($ServerConfigRestAPIInfo | Where-Object { $_.'Issued By' -eq 'CN=Veeam Software, O=Veeam Software, OU=Veeam Software' })) {
                        Paragraph "Health Check:" -Bold -Underline
                        BlankLine
                        Paragraph {
                            Text "Best Practice:" -Bold
                            Text "While self-signed certificates may seem harmless, they open up dangerous vulnerabilities from MITM attacks to disrupted services. For the Restore Portal and API Server, consider using trusted certificates as these are services accessed by end users."
                            Text "https://bp.veeam.com/vb365/guide/supplemental/security.html#certificate-usage" -Color Blue
                        }
                        BlankLine
                    }
                    if ($HealthCheck.Infrastructure.ServerConfig -and ($ServerConfigRestAPIInfo | Where-Object { $_.'Issued By' -eq 'CN=Veeam Software, O=Veeam Software, OU=Veeam Software' })) {
                        Paragraph "Health Check:" -Bold -Underline
                        BlankLine
                        Paragraph {
                            Text "Best Practice:" -Bold
                            Text "While self-signed certificates may seem harmless, they open up dangerous vulnerabilities from MITM attacks to disrupted services. For the Restore Portal and API Server, consider using trusted certificates as these are services accessed by end users."
                            Text "https://bp.veeam.com/vb365/guide/supplemental/security.html#certificate-usage" -Color Blue
                        }
                        BlankLine
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning -Message "RESTful API Section: $($_.Exception.Message)"
        }
    }
    end {}
}
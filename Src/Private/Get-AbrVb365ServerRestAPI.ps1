function Get-AbrVB365ServerRestAPI {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 backup restfull api configuration
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
            $script:ServerConfigRestAPI = Get-VBORestAPISettings
            if (($InfoLevel.Infrastructure.ServerConfig -gt 0) -and ($ServerConfigRestAPI)) {
                Write-PScriboMessage "Collecting Veeam VB365 RESTful API."
                Section -Style Heading3 'RESTful API' {
                    $ServerConfigRestAPIInfo = @()
                    $inObj = [ordered] @{
                        'Is Service Enabled' = ConvertTo-TextYN $ServerConfigRestAPI.IsServiceEnabled
                        'Auth Token LifeTime' = ConvertTo-EmptyToFiller $ServerConfigRestAPI.AuthTokenLifeTime
                        'HTTPS Port' = ConvertTo-EmptyToFiller $ServerConfigRestAPI.HTTPSPort
                        'Cert Friendly Name' = ConvertTo-EmptyToFiller $ServerConfigRestAPI.CertificateFriendlyName
                        'Issued To' = ConvertTo-EmptyToFiller $ServerConfigRestAPI.CertificateIssuedTo
                        'Issued By' = ConvertTo-EmptyToFiller $ServerConfigRestAPI.CertificateIssuedBy
                        'Thumbprint' = $ServerConfigRestAPI.CertificateThumbprint
                        'Expiration Date' = $ServerConfigRestAPI.CertificateExpirationDate.DateTime
                    }
                    $ServerConfigRestAPIInfo = [PSCustomObject]$InObj

                    if ($HealthCheck.Infrastructure.ServerConfig) {
                        $ServerConfigRestAPIInfo | Where-Object { $_.'Issued By' -eq 'CN=Veeam Software, O=Veeam Software, OU=Veeam Software' } | Set-Style -Style Warning -Property 'Issued By'
                        $ServerConfigRestAPIInfo | Where-Object { ((Get-Date).AddDays(+90)).Date.DateTime -lt $_.'Expiration Date' } | Set-Style -Style Critical -Property 'Expiration Date'
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
                        }
                        BlankLine
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "RESTful API Section: $($_.Exception.Message)"
        }
    }
    end {}
}
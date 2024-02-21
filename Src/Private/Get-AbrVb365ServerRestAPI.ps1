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
            $ServerConfig = Get-VBORestAPISettings
            if (($InfoLevel.Infrastructure.ServerConfig -gt 0) -and ($ServerConfig)) {
                Write-PScriboMessage "Collecting Veeam VB365 RESTful API."
                Section -Style Heading3 'RESTful API' {
                    $ServerConfigInfo = @()
                    $inObj = [ordered] @{
                        'Is Service Enabled' = ConvertTo-TextYN $ServerConfig.IsServiceEnabled
                        'Auth Token LifeTime' = ConvertTo-EmptyToFiller $ServerConfig.AuthTokenLifeTime
                        'HTTPS Port' = ConvertTo-EmptyToFiller $ServerConfig.HTTPSPort
                        'Cert Friendly Name' = ConvertTo-EmptyToFiller $ServerConfig.CertificateFriendlyName
                        'Issued To' = ConvertTo-EmptyToFiller $ServerConfig.CertificateIssuedTo
                        'Issued By' = ConvertTo-EmptyToFiller $ServerConfig.CertificateIssuedBy
                        'Thumbprint' = $ServerConfig.CertificateThumbprint
                        'Expiration Date' = ConvertTo-EmptyToFiller $ServerConfig.CertificateExpirationDate
                    }
                    $ServerConfigInfo = [PSCustomObject]$InObj

                    $TableParams = @{
                        Name = "RESTful API - $VeeamBackupServer"
                        List = $true
                        ColumnWidths = 50, 50
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $ServerConfigInfo | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "RESTful API Section: $($_.Exception.Message)"
        }
    }

    end {}
}
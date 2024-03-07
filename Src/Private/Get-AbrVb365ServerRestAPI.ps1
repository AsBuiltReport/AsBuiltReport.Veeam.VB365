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
                        'Expiration Date' = ConvertTo-EmptyToFiller $ServerConfigRestAPI.CertificateExpirationDate
                    }
                    $ServerConfigRestAPIInfo = [PSCustomObject]$InObj

                    $TableParams = @{
                        Name = "RESTful API - $VeeamBackupServer"
                        List = $true
                        ColumnWidths = 40, 60
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $ServerConfigRestAPIInfo | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "RESTful API Section: $($_.Exception.Message)"
        }
    }

    end {}
}
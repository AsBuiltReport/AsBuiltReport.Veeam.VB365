function Get-AbrVB365ServerInternetProxy {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 backup server internet proxy configuration
    .DESCRIPTION
        Documents the configuration of Veeam VB365 in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.8
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
            $ServerConfig = Get-VBOInternetProxySettings
            if (($InfoLevel.Infrastructure.ServerConfig -gt 0) -and ($ServerConfig)) {
                Write-PScriboMessage "Collecting Veeam VB365 internet proxy."
                Section -Style Heading3 'Internet Proxy' {
                    $ServerConfigInfo = @()
                    $inObj = [ordered] @{
                        'Use Internet Proxy' = $ServerConfig.UseInternetProxy
                        'Proxy Host' = $ServerConfig.Host
                        'TCP Port' = $ServerConfig.Port
                        'Use Authentication' = $ServerConfig.UseAuthentication
                        'Proxy User' = $ServerConfig.User
                    }
                    $ServerConfigInfo = [pscustomobject](ConvertTo-HashToYN $inObj)

                    $TableParams = @{
                        Name = "Internet Proxy - $VeeamBackupServer"
                        List = $true
                        ColumnWidths = 40, 60
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $ServerConfigInfo | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Internet Proxy Section: $($_.Exception.Message)"
        }
    }

    end {}
}
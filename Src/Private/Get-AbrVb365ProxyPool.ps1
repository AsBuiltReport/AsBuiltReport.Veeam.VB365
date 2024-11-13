function Get-AbrVB365ProxyPool {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 proxy pool servers
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
        Write-PScriboMessage "Proxy InfoLevel set at $($InfoLevel.Infrastructure.Proxy)."
    }

    process {
        try {
            $script:ProxyPools = Get-VBOProxyPool -WarningAction SilentlyContinue | Sort-Object -Property Name
            if (($InfoLevel.Infrastructure.Proxy -gt 0) -and ($ProxyPools)) {
                Write-PScriboMessage "Collecting Veeam VB365 Proxy Pool information."
                Section -Style Heading3 'Backup Proxy Pools' {
                    Paragraph "The following table summarizes the configuration of the proxy pools within the $VeeamBackupServer backup server."
                    BlankLine
                    $ProxyInfo = @()
                    foreach ($Proxy in $ProxyPools) {
                        $inObj = [ordered] @{
                            'Name' = $Proxy.Name
                            'Proxies' = $Proxy.Proxies
                            'Description' = $Proxy.Description
                        }
                        $ProxyInfo += [pscustomobject](ConvertTo-HashToYN $inObj)
                    }

                    $TableParams = @{
                        Name = "Backup Proxy Pools - $VeeamBackupServer"
                        List = $false
                        ColumnWidths = 33, 33, 34
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $ProxyInfo | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Backup Proxy Pools Section: $($_.Exception.Message)"
        }
    }

    end {}
}
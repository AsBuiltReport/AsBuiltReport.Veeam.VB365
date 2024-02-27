function Get-AbrVB365Proxy {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 proxy servers
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
        Write-PScriboMessage "Proxy InfoLevel set at $($InfoLevel.Infrastructure.Proxy)."
    }

    process {
        try {
            $script:Proxies = Get-VBOProxy -WarningAction SilentlyContinue | Sort-Object -Property Hostname
            if (($InfoLevel.Infrastructure.Proxy -gt 0) -and ($Proxies)) {
                Write-PScriboMessage "Collecting Veeam VB365 Proxy information."
                Section -Style Heading2 'Backup Proxies' {
                    $ProxyInfo = @()
                    foreach ($Proxy in $Proxies) {
                        $inObj = [ordered] @{
                            'Name' = $Proxy.Hostname
                            'Port' = $Proxy.Port
                            'Type' = $Proxy.Type
                            'Threads Number' = $Proxy.ThreadsNumber
                            'Throttling Value' = $Proxy.ThrottlingValue
                            'Is Outdated' = ConvertTo-TextYN $Proxy.IsOutdated
                            'Is Teams Graph API Backup Enabled' = ConvertTo-TextYN $Proxy.IsTeamsGraphAPIBackupEnabled
                            'Description' = $Proxy.Description

                        }
                        $ProxyInfo += [PSCustomObject]$InObj
                    }

                    if ($HealthCheck.Infrastructure.Proxy) {
                        $ProxyInfo | Where-Object { $_.'Is Outdated' -eq 'Yes' } | Set-Style -Style Warning -Property 'Is Outdated'
                    }

                    if ($InfoLevel.Infrastructure.Proxy -ge 2) {
                        Paragraph "The following sections detail the configuration of the proxy servers within $VeeamBackupServer backup server."
                        foreach ($Proxy in $ProxyInfo) {
                            Section -ExcludeFromTOC -Style NOTOCHeading3 "$($Proxy.Name)" {
                                $TableParams = @{
                                    Name = "Backup Proxy - $($Proxy.Name)"
                                    List = $true
                                    ColumnWidths = 50, 50
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $Proxy | Table @TableParams
                            }
                        }
                    } else {
                        Paragraph "The following table summarizes the configuration of the proxy servers within the $VeeamBackupServer backup server."
                        BlankLine
                        $TableParams = @{
                            Name = "Backup Proxies - $VeeamBackupServer"
                            List = $false
                            Columns = 'Name', 'Port', 'Type', 'Is Outdated'
                            ColumnWidths = 40, 20, 20, 20
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $ProxyInfo | Table @TableParams
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Backup Proxy Section: $($_.Exception.Message)"
        }
    }

    end {}
}
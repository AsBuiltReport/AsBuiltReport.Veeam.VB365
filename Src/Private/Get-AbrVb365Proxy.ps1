function Get-AbrVB365Proxy {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 proxy servers
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
                        Try {
                            Write-PScriboMessage "Connecting to VB365 server '$Proxy.Hostname' through CIM session."
                            $TempCIMSession = New-CimSession $Proxy.Hostname -Credential $Credential -Authentication 'Negotiate' -ErrorAction Continue -Name "Global:TempCIMSession"
                        } Catch {
                            Write-PScriboMessage -IsWarning "Unable to connect to VB365 server '$System' through CIM session. Continuing"
                        }
                        if ($TempCIMSession) {
                            $domainJoined = (Get-CimInstance -Class Win32_ComputerSystem -CimSession $TempCIMSession).partofdomain
                        } else {
                            $domainJoined = 'Unknown'
                        }
                        $inObj = [ordered] @{
                            'Name' = $Proxy.Hostname
                            'Port' = $Proxy.Port
                            'Type' = $Proxy.Type
                            'Threads Number' = $Proxy.ThreadsNumber
                            'Throttling Value' = $Proxy.ThrottlingValue
                            'Is Outdated' = ConvertTo-TextYN $Proxy.IsOutdated
                            'Is Teams Graph API Backup Enabled' = ConvertTo-TextYN $Proxy.IsTeamsGraphAPIBackupEnabled
                            'Is Domain Joined' = ConvertTo-TextYN $domainJoined
                            'Description' = $Proxy.Description
                        }
                        $ProxyInfo += [PSCustomObject]$InObj

                        if ($TempCIMSession) {
                            # Remove used CIMSession
                            Write-PScriboMessage "Clearing CIM Session $($TempCIMSession.Id)"
                            Remove-CimSession -CimSession $TempCIMSession
                        }
                    }

                    if ($HealthCheck.Infrastructure.Proxy) {
                        $ProxyInfo | Where-Object { $_.'Is Outdated' -eq 'Yes' } | Set-Style -Style Warning -Property 'Is Outdated'
                        $ProxyInfo | Where-Object { $_.'Is Domain Joined' -eq 'Yes' } | Set-Style -Style Warning -Property 'Is Domain Joined'
                    }

                    if ($InfoLevel.Infrastructure.Proxy -ge 2) {
                        Paragraph "The following sections detail the configuration of the proxy servers within $VeeamBackupServer backup server."
                        foreach ($Proxy in $ProxyInfo) {
                            Section -ExcludeFromTOC -Style NOTOCHeading4 "$($Proxy.Name)" {
                                $TableParams = @{
                                    Name = "Backup Proxy - $($Proxy.Name)"
                                    List = $true
                                    ColumnWidths = 40, 60
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $Proxy | Table @TableParams
                                if ($HealthCheck.Infrastructure.Proxy -and ($Proxy | Where-Object { $_.'Is Domain Joined' -eq 'Yes' })) {
                                    Paragraph "Health Check:" -Bold -Underline
                                    BlankLine
                                    Paragraph {
                                        Text "Best Practice:" -Bold
                                        Text "When setting up the Veeam infrastructure keep in mind the principle that a data protection system should not rely on the environment it is meant to protect in any way! This is because when your production environment goes down along with its domain controllers, it will impact your ability to perform actual restores due to the backup server's dependency on those domain controllers for backup console authentication, DNS for name resolution, etc."
                                    }
                                    BlankLine
                                }
                            }
                        }
                    } else {
                        Paragraph "The following table summarizes the configuration of the proxy servers within the $VeeamBackupServer backup server."
                        BlankLine
                        $TableParams = @{
                            Name = "Backup Proxies - $VeeamBackupServer"
                            List = $false
                            Columns = 'Name', 'Port', 'Type', 'Is Outdated', 'Is Domain Joined'
                            ColumnWidths = 40, 15, 15, 15, 15
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
function Get-AbrVB365Proxy {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 proxy servers
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
        Write-PScriboMessage -Message "Proxy InfoLevel set at $($InfoLevel.Infrastructure.Proxy)."
    }

    process {
        try {
            $script:Proxies = Get-VBOProxy -WarningAction SilentlyContinue | Sort-Object -Property Hostname
            if (($InfoLevel.Infrastructure.Proxy -gt 0) -and ($Proxies)) {
                Write-PScriboMessage -Message "Collecting Veeam VB365 Proxy information."
                Section -Style Heading2 'Backup Proxies' {
                    $ProxyInfo = @()
                    foreach ($Proxy in $Proxies) {
                        Try {
                            # Parameters used to authenticate remote connections
                            $remoteParams = @{
                                Credential = $Credential
                                ComputerName = $Proxy.Hostname
                            }
                            # Parameters which are specific to Test-WSMan
                            $testWSMan = @{
                                Authentication = 'Negotiate'
                                ErrorAction = 'SilentlyContinue'
                            }
                            # By default, do not pass any extra parameters to New-CimSession
                            $newCimSession = @{}
                            if (-not (Test-WSMan @testWSMan @remoteParams)) {
                                # If WSMan fails, use DCOM (RPC over TCP) to connect
                                $newCimSession['SessionOption'] = New-CimSessionOption -Protocol Dcom
                            }
                            # Parameters to pass to Get-CimInstance
                            $getCimInstance = @{
                                ClassName = 'Win32_ComputerSystem'
                                CimSession = New-CimSession @newCimSession @remoteParams -Name "Global:TempCIMSession" -ErrorAction SilentlyContinue
                            }

                        } Catch {
                            Write-PScriboMessage -IsWarning -Message "Unable to connect to VB365 server $($Proxy.Hostname) through CIM session. Continuing"
                        }
                        if ($getCimInstance.CimSession) {
                            $domainJoined = (Get-CimInstance @getCimInstance).partofdomain
                        } else {
                            $domainJoined = 'Unknown'
                            Write-PScriboMessage -IsWarning -Message "Unable to connect to proxy server $($Proxy.Hostname) through CIM session. Continuing"
                        }
                        $inObj = [ordered] @{
                            'Name' = $Proxy.Hostname
                            'Port' = $Proxy.Port
                            'Type' = $Proxy.Type
                            'Threads Number' = $Proxy.ThreadsNumber
                            'Throttling Value' = $Proxy.ThrottlingValue
                            'Is Outdated' = $Proxy.IsOutdated
                            'Is Teams Graph API Backup Enabled' = $Proxy.IsTeamsGraphAPIBackupEnabled
                            'Is Domain Joined' = $domainJoined
                            'Version' = $Proxy.Version
                            'Operating System' = $Proxy.OperatingSystemKind
                            'Service Account' = $Proxy.ServiceAccount
                            'Proxy Pool' = Switch ($Proxy.PoolId.Guid) {
                                '00000000-0000-0000-0000-000000000000' { '-' }
                                $null { '-' }
                                Default { (Get-VBOProxyPool -Id $Proxy.PoolId).Name }
                            }
                            'Description' = $Proxy.Description
                        }
                        $ProxyInfo += [pscustomobject](ConvertTo-HashToYN $inObj)

                        if ($TempCIMSession) {
                            # Remove used CIMSession
                            Write-PScriboMessage -Message "Clearing CIM Session $($TempCIMSession.Id)"
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
                                        Text "https://bp.veeam.com/vb365/guide/design/hardening/Workgroup_or_Domain.html" -Color Blue

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
                        if ($HealthCheck.Infrastructure.Proxy -and ($ProxyInfo | Where-Object { $_.'Is Domain Joined' -eq 'Yes' })) {
                            Paragraph "Health Check:" -Bold -Underline
                            BlankLine
                            Paragraph {
                                Text "Best Practice:" -Bold
                                Text "When setting up the Veeam infrastructure keep in mind the principle that a data protection system should not rely on the environment it is meant to protect in any way! This is because when your production environment goes down along with its domain controllers, it will impact your ability to perform actual restores due to the backup server's dependency on those domain controllers for backup console authentication, DNS for name resolution, etc."
                                Text "https://bp.veeam.com/vb365/guide/design/hardening/Workgroup_or_Domain.html" -Color Blue
                            }
                            BlankLine
                        }
                    }
                    if (Get-VBOProxyPool -WarningAction SilentlyContinue) {
                        Get-AbrVB365ProxyPool
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning -Message "Backup Proxy Section: $($_.Exception.Message)"
        }
    }

    end {}
}
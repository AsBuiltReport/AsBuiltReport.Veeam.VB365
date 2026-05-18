function Get-AbrVb365BackupRepositoryInventory {
    <#
    .SYNOPSIS
        Returns VB365 backup repositories with scoped queries where possible.
    .DESCRIPTION
        Global Get-VBORepository can be slow in larger VB365 environments. This helper uses the
        documented Proxy and ProxyPool parameter sets first, which still return full VBORepository
        objects and therefore preserve detailed report output.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch] $SummaryOnly
    )

    process {
        if ($SummaryOnly -and $script:RepositorySummaries) {
            return $script:RepositorySummaries | Sort-Object -Property Name
        }

        if (-not $SummaryOnly -and $script:Repositories) {
            return $script:Repositories | Sort-Object -Property Name
        }

        if ($SummaryOnly) {
            $RepositoryReferences = @()

            if ($script:BackupJobs) {
                $RepositoryReferences += $script:BackupJobs | ForEach-Object {
                    $RepositorySummaryProperty = $_.PSObject.Properties['AbrRepositorySummary']
                    if ($RepositorySummaryProperty -and $RepositorySummaryProperty.Value) {
                        $RepositorySummaryProperty.Value
                    }
                }
            }

            if ($script:BackupCopyJobs) {
                $RepositoryReferences += $script:BackupCopyJobs | ForEach-Object {
                    $RepositorySummaryProperty = $_.PSObject.Properties['AbrRepositorySummary']
                    if ($RepositorySummaryProperty -and $RepositorySummaryProperty.Value) {
                        $RepositorySummaryProperty.Value
                    }
                }
            }

            if (-not $RepositoryReferences) {
                $JobRepositoryLookup = Get-AbrVb365ExternalJobRepositoryMap
                $RepositoryReferences += $JobRepositoryLookup.Values |
                    Where-Object { $_ -and $_ -ne '--' } |
                    Sort-Object -Unique |
                    ForEach-Object {
                        [pscustomobject]@{
                            Name = $_
                            Path = '--'
                            Capacity = $null
                            FreeSpace = $null
                            RetentionType = '--'
                            RetentionPeriod = '--'
                            IsSummaryOnly = $true
                        }
                    }
            }

            if (-not $RepositoryReferences) {
                Write-PScriboMessage -IsWarning -Message "Backup Repository summary skipped because no cached repository inventory or job repository references are available at InfoLevel 1."
                return @()
            }

            $SeenRepositories = @{}
            $script:RepositorySummaries = foreach ($RepositoryReference in ($RepositoryReferences | Where-Object { $_ })) {
                $RepositoryName = Get-AbrVb365PropertyValue -InputObject $RepositoryReference -Name 'Name' -Default $RepositoryReference.ToString()
                if (-not $RepositoryName -or $SeenRepositories.ContainsKey($RepositoryName)) {
                    continue
                }

                $SeenRepositories[$RepositoryName] = $true
                [pscustomobject]@{
                    Name = $RepositoryName
                    Path = Get-AbrVb365PropertyValue -InputObject $RepositoryReference -Name 'Path' -Default '--'
                    Capacity = Get-AbrVb365PropertyValue -InputObject $RepositoryReference -Name 'Capacity'
                    FreeSpace = Get-AbrVb365PropertyValue -InputObject $RepositoryReference -Name 'FreeSpace'
                    RetentionType = Get-AbrVb365PropertyValue -InputObject $RepositoryReference -Name 'RetentionType' -Default '--'
                    RetentionPeriod = Get-AbrVb365PropertyValue -InputObject $RepositoryReference -Name 'RetentionPeriod' -Default '--'
                    IsSummaryOnly = $true
                }
            }

            return $script:RepositorySummaries | Sort-Object -Property Name
        }

        $Repositories = @()

        if (-not $script:Proxies) {
            try {
                $script:Proxies = Get-VBOProxy -WarningAction SilentlyContinue | Sort-Object -Property Hostname
            } catch {
                Write-PScriboMessage -IsWarning -Message "Backup Repository Proxy Inventory: $($_.Exception.Message)"
            }
        }

        foreach ($Proxy in ($script:Proxies | Where-Object { $_ })) {
            try {
                Write-PScriboMessage -Message "Collecting Veeam VB365 Backup Repository inventory for proxy '$($Proxy.Hostname)'."
                $Repositories += Get-VBORepository -Proxy $Proxy
            } catch {
                Write-PScriboMessage -IsWarning -Message "Backup Repository Proxy Query '$($Proxy.Hostname)': $($_.Exception.Message)"
            }
        }

        if (-not $script:ProxyPools) {
            try {
                $script:ProxyPools = Get-VBOProxyPool -WarningAction SilentlyContinue | Sort-Object -Property Name
            } catch {
                Write-PScriboMessage -IsWarning -Message "Backup Repository Proxy Pool Inventory: $($_.Exception.Message)"
            }
        }

        foreach ($ProxyPool in ($script:ProxyPools | Where-Object { $_ })) {
            try {
                Write-PScriboMessage -Message "Collecting Veeam VB365 Backup Repository inventory for proxy pool '$($ProxyPool.Name)'."
                $Repositories += Get-VBORepository -ProxyPool $ProxyPool
            } catch {
                Write-PScriboMessage -IsWarning -Message "Backup Repository Proxy Pool Query '$($ProxyPool.Name)': $($_.Exception.Message)"
            }
        }

        $SeenRepositories = @{}
        $Repositories = foreach ($Repository in ($Repositories | Where-Object { $_ })) {
            $RepositoryId = Get-AbrVb365PropertyValue -InputObject $Repository -Name 'Id'
            $RepositoryKey = if ($RepositoryId) { $RepositoryId.ToString() } else { "$($Repository.Name)|$($Repository.Path)" }
            if (-not $RepositoryKey -or $SeenRepositories.ContainsKey($RepositoryKey)) {
                continue
            }

            $SeenRepositories[$RepositoryKey] = $true
            $Repository
        }

        if ($Repositories) {
            $script:Repositories = $Repositories | Sort-Object -Property Name
            return $script:Repositories
        }

        Write-PScriboMessage -Message "Collecting Veeam VB365 Backup Repository inventory with global query."
        $script:Repositories = Get-VBORepository | Sort-Object -Property Name
        return $script:Repositories
    }
}

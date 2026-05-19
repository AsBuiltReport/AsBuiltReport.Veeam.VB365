function Get-AbrVb365PropertyValue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $InputObject,

        [Parameter(Mandatory = $true)]
        [string[]] $Name,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Default = $null
    )

    foreach ($PropertyName in $Name) {
        if ($null -ne $InputObject -and $InputObject.PSObject.Properties[$PropertyName]) {
            return $InputObject.PSObject.Properties[$PropertyName].Value
        }
    }

    return $Default
}

function Get-AbrVb365ObjectStorageRepository {
    <#
    .SYNOPSIS
        Returns VB365 object storage repositories for the As Built report.
    .DESCRIPTION
        Get-VBOObjectStorageRepository is deprecated in Veeam Backup for Microsoft 365 v8, but
        it still returns the original VBOObjectStorageRepository fields consumed by this module.
        The supported replacement requires Get-VBORepository -LongTerm for archive-tier object
        storage repositories; that path can be slow in production environments, so the report
        keeps the deprecated cmdlet for full output parity and falls back to Get-VBORepository
        only if the deprecated cmdlet is unavailable.
    .DESCRIPTION
        Global Get-VBORepository can be slow in larger VB365 environments. This helper uses the
        documented Proxy and ProxyPool parameter sets first, which still return full VBORepository
        objects and therefore preserve detailed report output.
    .NOTES
        Version:        0.4.0
        Author:         Richard Bradley
        Twitter:        @acgdickie
        Github:         rebelinux
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365
    #>
    #>
    [CmdletBinding()]
    param (
    )

    process {
        try {
            $ObjectRepositories = Get-VBOObjectStorageRepository -WarningAction SilentlyContinue | Sort-Object -Property Name
            if ($ObjectRepositories) {
                return $ObjectRepositories
            }
        } catch {
            Write-PScriboMessage -IsWarning -Message "Object Repository Deprecated Query: $($_.Exception.Message)"
        }

        $Repositories = @()
        if ($script:Repositories) {
            $Repositories += $script:Repositories
        } else {
            $Repositories += Get-AbrVb365BackupRepositoryInventory
        }

        $SeenRepositories = @{}
        $ObjectRepositories = foreach ($Repository in ($Repositories | Where-Object { $_ })) {
            $ObjectRepository = Get-AbrVb365PropertyValue -InputObject $Repository -Name 'ObjectStorageRepository'
            $IsObjectStorage = Get-AbrVb365PropertyValue -InputObject $Repository -Name 'IsObjectStorage' -Default $false

            if (-not $ObjectRepository -and -not $IsObjectStorage) {
                continue
            }

            if (-not $ObjectRepository) {
                $ObjectRepository = $Repository
            }

            $RepositoryId = Get-AbrVb365PropertyValue -InputObject $ObjectRepository -Name 'Id' -Default (Get-AbrVb365PropertyValue -InputObject $Repository -Name 'Id')
            $RepositoryKey = if ($RepositoryId) { $RepositoryId.ToString() } else { $null }
            if ($RepositoryKey -and $SeenRepositories.ContainsKey($RepositoryKey)) {
                continue
            }
            if ($RepositoryKey) {
                $SeenRepositories[$RepositoryKey] = $true
            }

            [pscustomobject]@{
                Id = $RepositoryId
                Name = Get-AbrVb365PropertyValue -InputObject $ObjectRepository -Name 'Name' -Default (Get-AbrVb365PropertyValue -InputObject $Repository -Name 'Name')
                Description = Get-AbrVb365PropertyValue -InputObject $ObjectRepository -Name 'Description' -Default (Get-AbrVb365PropertyValue -InputObject $Repository -Name 'Description')
                Type = Get-AbrVb365PropertyValue -InputObject $ObjectRepository -Name 'Type'
                Folder = Get-AbrVb365PropertyValue -InputObject $ObjectRepository -Name 'Folder' -Default (Get-AbrVb365PropertyValue -InputObject $Repository -Name 'Path')
                EnableSizeLimit = Get-AbrVb365PropertyValue -InputObject $ObjectRepository -Name 'EnableSizeLimit'
                SizeLimit = Get-AbrVb365PropertyValue -InputObject $ObjectRepository -Name 'SizeLimit'
                UsedSpace = Get-AbrVb365PropertyValue -InputObject $ObjectRepository -Name 'UsedSpace'
                FreeSpace = Get-AbrVb365PropertyValue -InputObject $ObjectRepository -Name 'FreeSpace' -Default (Get-AbrVb365PropertyValue -InputObject $Repository -Name 'FreeSpace')
                IsLongTerm = Get-AbrVb365PropertyValue -InputObject $ObjectRepository -Name 'IsLongTerm' -Default (Get-AbrVb365PropertyValue -InputObject $Repository -Name 'IsLongTerm')
                IsSecondary = Get-AbrVb365PropertyValue -InputObject $ObjectRepository -Name 'IsSecondary'
                UseArchiverAppliance = Get-AbrVb365PropertyValue -InputObject $ObjectRepository -Name 'UseArchiverAppliance'
                EnableImmutability = Get-AbrVb365PropertyValue -InputObject $ObjectRepository -Name 'EnableImmutability'
            }
        }

        $ObjectRepositories | Sort-Object -Property Name
    }
}

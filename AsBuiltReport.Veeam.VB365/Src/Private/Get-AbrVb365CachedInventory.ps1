function ConvertTo-AbrVb365LookupKey {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $Id
    )

    process {
        if (-not $Id) {
            return $null
        }

        if ($Id.PSObject.Properties['Guid']) {
            return $Id.Guid.ToString()
        }

        return $Id.ToString()
    }
}

function ConvertTo-AbrVb365DisplayValue {
    [CmdletBinding()]
    [OutputType([pscustomobject], [string])]
    param (
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object] $InputObject,

        [Parameter(Mandatory = $false)]
        [string[]] $PreferredProperty = @('Name', 'DisplayName', 'Title', 'Description')
    )

    process {
        if ($null -eq $InputObject) {
            return '--'
        }

        if ($InputObject -is [string] -or $InputObject.GetType().IsPrimitive) {
            return $InputObject.ToString()
        }

        foreach ($PropertyName in $PreferredProperty) {
            $PropertyValue = Get-AbrVb365PropertyValue -InputObject $InputObject -Name $PropertyName
            if ($PropertyValue) {
                return $PropertyValue.ToString()
            }
        }

        return $InputObject.ToString()
    }
}


function Get-AbrVb365OrganizationInventory {
    [CmdletBinding()]
    param (
    )

    process {
        if ($script:Organizations) {
            return $script:Organizations | Sort-Object -Property Name
        }

        $script:Organizations = Get-VBOOrganization | Sort-Object -Property Name
        return $script:Organizations
    }
}

function Get-AbrVb365OrganizationNameLookup {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
    )

    process {
        $Lookup = @{}
        foreach ($Organization in (Get-AbrVb365OrganizationInventory | Where-Object { $_ })) {
            $OrganizationId = Get-AbrVb365PropertyValue -InputObject $Organization -Name 'Id'
            $OrganizationKey = ConvertTo-AbrVb365LookupKey -Id $OrganizationId
            if ($OrganizationKey) {
                $Lookup[$OrganizationKey] = $Organization.Name
            }
        }

        return $Lookup
    }
}

function Get-AbrVb365OrganizationByName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Name
    )

    process {
        Get-AbrVb365OrganizationInventory | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
    }
}

function Get-AbrVb365RepositoryNameLookup {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
    )

    process {
        $Lookup = @{}
        foreach ($Repository in (Get-AbrVb365BackupRepositoryInventory | Where-Object { $_ })) {
            $RepositoryId = Get-AbrVb365PropertyValue -InputObject $Repository -Name 'Id'
            $RepositoryKey = ConvertTo-AbrVb365LookupKey -Id $RepositoryId
            if ($RepositoryKey) {
                $Lookup[$RepositoryKey] = $Repository.Name
            }
        }

        return $Lookup
    }
}

function Get-AbrVb365BackupJobInventory {
    [CmdletBinding()]
    param (
    )

    process {
        if ($script:BackupJobs) {
            return $script:BackupJobs | Sort-Object -Property Name
        }

        $BackupJobs = @()
        $Organizations = @()

        try {
            $Organizations = Get-AbrVb365OrganizationInventory
        } catch {
            Write-PScriboMessage -IsWarning -Message "Backup Job Organization Inventory: $($_.Exception.Message)"
        }

        foreach ($Organization in ($Organizations | Where-Object { $_ })) {
            try {
                Write-PScriboMessage -Message "Collecting Veeam VB365 Backup Jobs inventory for organization '$($Organization.Name)'."
                $BackupJobs += Get-VBOJob -Organization $Organization
            } catch {
                Write-PScriboMessage -IsWarning -Message "Backup Job Organization Query '$($Organization.Name)': $($_.Exception.Message)"
            }
        }

        $SeenJobs = @{}
        $BackupJobs = foreach ($BackupJob in ($BackupJobs | Where-Object { $_ })) {
            $JobId = Get-AbrVb365PropertyValue -InputObject $BackupJob -Name 'Id'
            $JobKey = if ($JobId) { (ConvertTo-AbrVb365LookupKey -Id $JobId) } else { $BackupJob.Name }
            if (-not $JobKey -or $SeenJobs.ContainsKey($JobKey)) {
                continue
            }

            $SeenJobs[$JobKey] = $true
            $BackupJob
        }

        $RepositoryLookup = Get-AbrVb365ExternalJobRepositoryMap
        foreach ($BackupJob in ($BackupJobs | Where-Object { $_ })) {
            [void] (Set-AbrVb365JobRepositoryMetadata -Job $BackupJob -RepositoryLookup $RepositoryLookup)
        }

        if ($BackupJobs) {
            $script:BackupJobs = $BackupJobs | Sort-Object -Property Name
            return $script:BackupJobs
        }

        Write-PScriboMessage -Message 'Collecting Veeam VB365 Backup Jobs inventory with global query.'
        $BackupJobs = Get-VBOJob
        $RepositoryLookup = Get-AbrVb365ExternalJobRepositoryMap
        foreach ($BackupJob in ($BackupJobs | Where-Object { $_ })) {
            [void] (Set-AbrVb365JobRepositoryMetadata -Job $BackupJob -RepositoryLookup $RepositoryLookup)
        }

        $script:BackupJobs = $BackupJobs | Sort-Object -Property Name
        return $script:BackupJobs
    }
}

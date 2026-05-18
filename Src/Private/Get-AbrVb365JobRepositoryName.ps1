function Get-AbrVb365PowerShellProcessPath {
    [CmdletBinding()]
    param (
    )

    if ($env:ABR_VB365_REPOSITORY_MAP_POWERSHELL_PATH -and (Test-Path -LiteralPath $env:ABR_VB365_REPOSITORY_MAP_POWERSHELL_PATH)) {
        return $env:ABR_VB365_REPOSITORY_MAP_POWERSHELL_PATH
    }

    try {
        $CurrentProcessPath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        if ($CurrentProcessPath -and (Test-Path -LiteralPath $CurrentProcessPath)) {
            return $CurrentProcessPath
        }
    } catch {
    }

    foreach ($CommandName in @('pwsh', 'powershell.exe', 'powershell')) {
        $Command = Get-Command -Name $CommandName -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($Command -and $Command.Source) {
            return $Command.Source
        }
    }
}

function Set-AbrVb365JobRepositoryMetadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object] $Job,

        [Parameter(Mandatory = $false)]
        [hashtable] $RepositoryLookup,

        [Parameter(Mandatory = $false)]
        [switch] $AllowLiveLookup
    )

    if ($null -eq $Job) {
        return '--'
    }

    $JobName = Get-AbrVb365PropertyValue -InputObject $Job -Name 'Name' -Default 'Unknown'
    $JobId = Get-AbrVb365PropertyValue -InputObject $Job -Name 'Id'
    $JobIdKey = ConvertTo-AbrVb365LookupKey -Id $JobId
    $RepositoryName = $null

    if ($RepositoryLookup) {
        if ($JobIdKey -and $RepositoryLookup.ContainsKey("id:$JobIdKey")) {
            $RepositoryName = $RepositoryLookup["id:$JobIdKey"]
        } elseif ($JobName -and $RepositoryLookup.ContainsKey("name:$JobName")) {
            $RepositoryName = $RepositoryLookup["name:$JobName"]
        }
    }

    if (-not $RepositoryName -and $AllowLiveLookup) {
        $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        Write-PScriboMessage -Message "Starting backup job '$JobName' Repository live value."
        try {
            $Repository = $Job.Repository
            $RepositoryName = if ($Repository) { $Repository.ToString() } else { '--' }
        } catch {
            Write-PScriboMessage -IsWarning -Message "Backup Job Repository live lookup '$JobName': $($_.Exception.Message)"
        } finally {
            $Stopwatch.Stop()
            Write-PScriboMessage -Message ("Completed backup job '{0}' Repository live value in {1:n2}s." -f $JobName, $Stopwatch.Elapsed.TotalSeconds)
        }
    }

    if (-not $RepositoryName) {
        $RepositoryName = '--'
    }

    $RepositorySummary = [pscustomobject]@{
        Name = $RepositoryName
        Path = '--'
        Capacity = $null
        FreeSpace = $null
        RetentionType = '--'
        RetentionPeriod = '--'
        IsSummaryOnly = $true
    }

    $Job | Add-Member -NotePropertyName 'AbrRepositoryName' -NotePropertyValue $RepositoryName -Force
    $Job | Add-Member -NotePropertyName 'AbrRepositorySummary' -NotePropertyValue $RepositorySummary -Force

    return $RepositoryName
}

function Get-AbrVb365ExternalJobRepositoryMap {
    [CmdletBinding()]
    param (
    )

    if ($script:BackupJobRepositoryLookup) {
        return $script:BackupJobRepositoryLookup
    }

    $Lookup = @{}
    $ConfiguredMapPath = $env:ABR_VB365_JOB_REPOSITORY_MAP_PATH
    if ($ConfiguredMapPath -and (Test-Path -LiteralPath $ConfiguredMapPath)) {
        try {
            Write-PScriboMessage -Message "Loading Veeam VB365 Backup Job repository map from '$ConfiguredMapPath'."
            $Rows = Get-Content -LiteralPath $ConfiguredMapPath -Raw | ConvertFrom-Json
            foreach ($Row in ($Rows | Where-Object { $_ })) {
                if ($Row.Id) {
                    $Lookup["id:$($Row.Id)"] = $Row.Repository
                }
                if ($Row.Job) {
                    $Lookup["name:$($Row.Job)"] = $Row.Repository
                }
            }
            $script:BackupJobRepositoryLookup = $Lookup
            return $script:BackupJobRepositoryLookup
        } catch {
            Write-PScriboMessage -IsWarning -Message "Backup Job Repository map load failed: $($_.Exception.Message)"
        }
    }

    $PowerShellProcessPath = Get-AbrVb365PowerShellProcessPath
    if (-not $PowerShellProcessPath) {
        Write-PScriboMessage -IsWarning -Message "Backup Job Repository map skipped because a PowerShell executable was not found."
        $script:BackupJobRepositoryLookup = $Lookup
        return $script:BackupJobRepositoryLookup
    }

    $TimeoutSeconds = $env:ABR_VB365_REPOSITORY_MAP_TIMEOUT_SECONDS -as [int]
    if ($TimeoutSeconds -le 0) {
        $TimeoutSeconds = 180
    }

    $TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("AbrVb365RepoMap-{0}" -f ([guid]::NewGuid().ToString('N')))
    $ScriptPath = Join-Path $TempRoot 'Get-Vb365JobRepositoryMap.ps1'
    $CredentialPath = Join-Path $TempRoot 'credential.xml'
    $OutputPath = Join-Path $TempRoot 'repository-map.json'
    $StdoutPath = Join-Path $TempRoot 'repository-map.out'
    $StderrPath = Join-Path $TempRoot 'repository-map.err'

    try {
        [void] (New-Item -Path $TempRoot -ItemType Directory -Force)
        $Credential | Export-Clixml -LiteralPath $CredentialPath

        $CaptureScript = @'
param (
    [Parameter(Mandatory = $true)]
    [string] $Server,

    [Parameter(Mandatory = $true)]
    [int] $Port,

    [Parameter(Mandatory = $true)]
    [string] $CredentialPath,

    [Parameter(Mandatory = $true)]
    [string] $OutputPath
)

$ErrorActionPreference = 'Stop'
$Credential = Import-Clixml -LiteralPath $CredentialPath

try {
    $manualModulePath = 'C:\Program Files\Veeam\Backup365\Veeam.Archiver.PowerShell\Veeam.Archiver.PowerShell.psd1'
    if (Test-Path -LiteralPath $manualModulePath) {
        Import-Module $manualModulePath -ErrorAction Stop
    } else {
        Import-Module Veeam.Archiver.PowerShell -ErrorAction Stop
    }
} catch {
    Import-Module Veeam.Archiver.PowerShell -ErrorAction Stop
}

try {
    Disconnect-VBOServer -ErrorAction SilentlyContinue
} catch {
}

Connect-VBOServer -Server $Server -Credential $Credential -Port $Port

$orgs = Get-VBOOrganization
$jobs = foreach ($org in $orgs) {
    Get-VBOJob -Organization $org
}

$rows = foreach ($j in $jobs) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $repo = $j.Repository
        $sw.Stop()
        [pscustomobject]@{
            Id = if ($j.Id) { $j.Id.ToString() } else { $null }
            Job = $j.Name
            Repository = if ($repo) { $repo.ToString() } else { '--' }
            Seconds = [math]::Round($sw.Elapsed.TotalSeconds, 3)
        }
    } catch {
        $sw.Stop()
        [pscustomobject]@{
            Id = if ($j.Id) { $j.Id.ToString() } else { $null }
            Job = $j.Name
            Repository = '--'
            Seconds = [math]::Round($sw.Elapsed.TotalSeconds, 3)
            Error = $_.Exception.Message
        }
    }
}

$rows | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $OutputPath -Encoding UTF8

try {
    Disconnect-VBOServer -ErrorAction SilentlyContinue
} catch {
}
'@
        Set-Content -LiteralPath $ScriptPath -Value $CaptureScript -Encoding UTF8

        Write-PScriboMessage -Message "Collecting Veeam VB365 Backup Job repository map in a separate PowerShell process."
        $ArgumentList = @(
            '-NoLogo',
            '-NoProfile',
            '-ExecutionPolicy',
            'Bypass',
            '-File',
            $ScriptPath,
            '-Server',
            $System,
            '-Port',
            [string] $Options.BackupServerPort,
            '-CredentialPath',
            $CredentialPath,
            '-OutputPath',
            $OutputPath
        )
        $Process = Start-Process -FilePath $PowerShellProcessPath -ArgumentList $ArgumentList -RedirectStandardOutput $StdoutPath -RedirectStandardError $StderrPath -WindowStyle Hidden -PassThru
        if (-not $Process.WaitForExit($TimeoutSeconds * 1000)) {
            try {
                $Process.Kill()
            } catch {
            }
            Write-PScriboMessage -IsWarning -Message "Backup Job Repository map timed out after $TimeoutSeconds seconds."
            $script:BackupJobRepositoryLookup = $Lookup
            return $script:BackupJobRepositoryLookup
        }

        if ($Process.ExitCode -ne 0) {
            $ErrorText = if (Test-Path -LiteralPath $StderrPath) { (Get-Content -LiteralPath $StderrPath -Raw).Trim() } else { '' }
            Write-PScriboMessage -IsWarning -Message "Backup Job Repository map process exited with code $($Process.ExitCode). $ErrorText"
            $script:BackupJobRepositoryLookup = $Lookup
            return $script:BackupJobRepositoryLookup
        }

        if (Test-Path -LiteralPath $OutputPath) {
            $Rows = Get-Content -LiteralPath $OutputPath -Raw | ConvertFrom-Json
            foreach ($Row in ($Rows | Where-Object { $_ })) {
                if ($Row.Id) {
                    $Lookup["id:$($Row.Id)"] = $Row.Repository
                }
                if ($Row.Job) {
                    $Lookup["name:$($Row.Job)"] = $Row.Repository
                }
            }
            Write-PScriboMessage -Message "Collected Veeam VB365 Backup Job repository map with $($Lookup.Count) lookup keys."
        } else {
            Write-PScriboMessage -IsWarning -Message "Backup Job Repository map did not produce an output file."
        }
    } catch {
        Write-PScriboMessage -IsWarning -Message "Backup Job Repository map failed: $($_.Exception.Message)"
    } finally {
        if (-not $env:ABR_VB365_KEEP_REPOSITORY_MAP_CAPTURE -and (Test-Path -LiteralPath $TempRoot)) {
            Remove-Item -LiteralPath $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    $script:BackupJobRepositoryLookup = $Lookup
    return $script:BackupJobRepositoryLookup
}

function Get-AbrVb365ExternalBackupCopyJobRepositoryMap {
    [CmdletBinding()]
    param (
    )

    if ($script:BackupCopyJobRepositoryLookup) {
        return $script:BackupCopyJobRepositoryLookup
    }

    $Lookup = @{}
    $ConfiguredMapPath = $env:ABR_VB365_COPY_JOB_REPOSITORY_MAP_PATH
    if ($ConfiguredMapPath -and (Test-Path -LiteralPath $ConfiguredMapPath)) {
        try {
            Write-PScriboMessage -Message "Loading Veeam VB365 Backup Copy Job repository map from '$ConfiguredMapPath'."
            $Rows = Get-Content -LiteralPath $ConfiguredMapPath -Raw | ConvertFrom-Json
            foreach ($Row in ($Rows | Where-Object { $_ })) {
                if ($Row.Id) {
                    $Lookup["id:$($Row.Id)"] = $Row.Repository
                }
                if ($Row.Job) {
                    $Lookup["name:$($Row.Job)"] = $Row.Repository
                }
            }
            $script:BackupCopyJobRepositoryLookup = $Lookup
            return $script:BackupCopyJobRepositoryLookup
        } catch {
            Write-PScriboMessage -IsWarning -Message "Backup Copy Job Repository map load failed: $($_.Exception.Message)"
        }
    }

    $PowerShellProcessPath = Get-AbrVb365PowerShellProcessPath
    if (-not $PowerShellProcessPath) {
        Write-PScriboMessage -IsWarning -Message "Backup Copy Job Repository map skipped because a PowerShell executable was not found."
        $script:BackupCopyJobRepositoryLookup = $Lookup
        return $script:BackupCopyJobRepositoryLookup
    }

    $TimeoutSeconds = $env:ABR_VB365_COPY_REPOSITORY_MAP_TIMEOUT_SECONDS -as [int]
    if ($TimeoutSeconds -le 0) {
        $TimeoutSeconds = 180
    }

    $TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("AbrVb365CopyRepoMap-{0}" -f ([guid]::NewGuid().ToString('N')))
    $ScriptPath = Join-Path $TempRoot 'Get-Vb365CopyJobRepositoryMap.ps1'
    $CredentialPath = Join-Path $TempRoot 'credential.xml'
    $OutputPath = Join-Path $TempRoot 'copy-repository-map.json'
    $StdoutPath = Join-Path $TempRoot 'copy-repository-map.out'
    $StderrPath = Join-Path $TempRoot 'copy-repository-map.err'

    try {
        [void] (New-Item -Path $TempRoot -ItemType Directory -Force)
        $Credential | Export-Clixml -LiteralPath $CredentialPath

        $CaptureScript = @'
param (
    [Parameter(Mandatory = $true)]
    [string] $Server,

    [Parameter(Mandatory = $true)]
    [int] $Port,

    [Parameter(Mandatory = $true)]
    [string] $CredentialPath,

    [Parameter(Mandatory = $true)]
    [string] $OutputPath
)

$ErrorActionPreference = 'Stop'
$Credential = Import-Clixml -LiteralPath $CredentialPath

try {
    $manualModulePath = 'C:\Program Files\Veeam\Backup365\Veeam.Archiver.PowerShell\Veeam.Archiver.PowerShell.psd1'
    if (Test-Path -LiteralPath $manualModulePath) {
        Import-Module $manualModulePath -ErrorAction Stop
    } else {
        Import-Module Veeam.Archiver.PowerShell -ErrorAction Stop
    }
} catch {
    Import-Module Veeam.Archiver.PowerShell -ErrorAction Stop
}

try {
    Disconnect-VBOServer -ErrorAction SilentlyContinue
} catch {
}

Connect-VBOServer -Server $Server -Credential $Credential -Port $Port

$jobs = Get-VBOCopyJob
$rows = foreach ($j in $jobs) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $repo = $j.Repository
        $sw.Stop()
        [pscustomobject]@{
            Id = if ($j.Id) { $j.Id.ToString() } else { $null }
            Job = $j.Name
            Repository = if ($repo) { $repo.ToString() } else { '--' }
            Seconds = [math]::Round($sw.Elapsed.TotalSeconds, 3)
        }
    } catch {
        $sw.Stop()
        [pscustomobject]@{
            Id = if ($j.Id) { $j.Id.ToString() } else { $null }
            Job = $j.Name
            Repository = '--'
            Seconds = [math]::Round($sw.Elapsed.TotalSeconds, 3)
            Error = $_.Exception.Message
        }
    }
}

$rows | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $OutputPath -Encoding UTF8

try {
    Disconnect-VBOServer -ErrorAction SilentlyContinue
} catch {
}
'@
        Set-Content -LiteralPath $ScriptPath -Value $CaptureScript -Encoding UTF8

        Write-PScriboMessage -Message "Collecting Veeam VB365 Backup Copy Job repository map in a separate PowerShell process."
        $ArgumentList = @(
            '-NoLogo',
            '-NoProfile',
            '-ExecutionPolicy',
            'Bypass',
            '-File',
            $ScriptPath,
            '-Server',
            $System,
            '-Port',
            [string] $Options.BackupServerPort,
            '-CredentialPath',
            $CredentialPath,
            '-OutputPath',
            $OutputPath
        )
        $Process = Start-Process -FilePath $PowerShellProcessPath -ArgumentList $ArgumentList -RedirectStandardOutput $StdoutPath -RedirectStandardError $StderrPath -WindowStyle Hidden -PassThru
        if (-not $Process.WaitForExit($TimeoutSeconds * 1000)) {
            try {
                $Process.Kill()
            } catch {
            }
            Write-PScriboMessage -IsWarning -Message "Backup Copy Job Repository map timed out after $TimeoutSeconds seconds."
            $script:BackupCopyJobRepositoryLookup = $Lookup
            return $script:BackupCopyJobRepositoryLookup
        }

        if ($Process.ExitCode -ne 0) {
            $ErrorText = if (Test-Path -LiteralPath $StderrPath) { (Get-Content -LiteralPath $StderrPath -Raw).Trim() } else { '' }
            Write-PScriboMessage -IsWarning -Message "Backup Copy Job Repository map process exited with code $($Process.ExitCode). $ErrorText"
            $script:BackupCopyJobRepositoryLookup = $Lookup
            return $script:BackupCopyJobRepositoryLookup
        }

        if (Test-Path -LiteralPath $OutputPath) {
            $Rows = Get-Content -LiteralPath $OutputPath -Raw | ConvertFrom-Json
            foreach ($Row in ($Rows | Where-Object { $_ })) {
                if ($Row.Id) {
                    $Lookup["id:$($Row.Id)"] = $Row.Repository
                }
                if ($Row.Job) {
                    $Lookup["name:$($Row.Job)"] = $Row.Repository
                }
            }
            Write-PScriboMessage -Message "Collected Veeam VB365 Backup Copy Job repository map with $($Lookup.Count) lookup keys."
        } else {
            Write-PScriboMessage -IsWarning -Message "Backup Copy Job Repository map did not produce an output file."
        }
    } catch {
        Write-PScriboMessage -IsWarning -Message "Backup Copy Job Repository map failed: $($_.Exception.Message)"
    } finally {
        if (-not $env:ABR_VB365_KEEP_REPOSITORY_MAP_CAPTURE -and (Test-Path -LiteralPath $TempRoot)) {
            Remove-Item -LiteralPath $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    $script:BackupCopyJobRepositoryLookup = $Lookup
    return $script:BackupCopyJobRepositoryLookup
}

function Get-AbrVb365JobRepositoryName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object] $Job,

        [Parameter(Mandatory = $false)]
        [int] $TimeoutSeconds = 10
    )

    if ($null -eq $Job) {
        return '--'
    }

    $RepositoryNameProperty = $Job.PSObject.Properties['AbrRepositoryName']
    if ($RepositoryNameProperty -and $RepositoryNameProperty.Value) {
        return $RepositoryNameProperty.Value
    }

    return Set-AbrVb365JobRepositoryMetadata -Job $Job
}

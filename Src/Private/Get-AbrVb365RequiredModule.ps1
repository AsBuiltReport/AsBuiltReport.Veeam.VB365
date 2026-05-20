function Get-AbrVB365RequiredModule {
    <#
    .SYNOPSIS
    Function to check if the required version of Veeam.Archiver.PowerShell is installed
    .DESCRIPTION
        Documents the configuration of Veeam VB365 in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.4.0
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365
    #>
    [CmdletBinding()]

    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Version
    )
    process {
        $MyModulePath = 'C:\Program Files\Veeam\Backup365\Veeam.Archiver.PowerShell'
        if ((Test-Path -LiteralPath $MyModulePath) -and ($env:PSModulePath -notlike "*$MyModulePath*")) {
            $env:PSModulePath = $env:PSModulePath + "$([System.IO.Path]::PathSeparator)$MyModulePath"
        }

        if ($Modules = Get-Module -ListAvailable -Name $Name) {
            try {
                Write-PScriboMessage -Message 'Trying to import Veeam VB365 modules.'
                $Modules | Sort-Object -Property Version -Descending | Select-Object -First 1 | Import-Module -WarningAction SilentlyContinue
            } catch {
                Write-PScriboMessage -IsWarning -Message 'Failed to load Veeam VB365 Modules'
            }
        }
        if ($Module = Get-Module -ListAvailable -Name $Name | Sort-Object -Property Version -Descending | Select-Object -First 1) {
            try {
                Write-PScriboMessage -Message 'Identifying Veeam VB365 Powershell module version.'
                Write-PScriboMessage -Message "Using Veeam VB365 Powershell module version $($Module.Version)."
            } catch {
                Write-PScriboMessage -IsWarning -Message 'Failed to get Version from Module'
            }
        } else {
            try {
                Write-PScriboMessage -Message 'No Veeam Modules found, trying to import module manually.'
                $ManualModulePath = Join-Path -Path $MyModulePath -ChildPath 'Veeam.Archiver.PowerShell.psd1'
                Import-Module $ManualModulePath -ErrorAction Stop
                $Module = Get-Module -ListAvailable -Name $Name | Sort-Object -Property Version -Descending | Select-Object -First 1
                if ($Module) {
                    Write-PScriboMessage -Message "Using Veeam VB365 Powershell module version $($Module.Version)."
                }
            } catch {
                throw 'Failed to get version from manual Module import'
            }
        }
        # Check if the required version of VMware PowerCLI is installed
        $RequiredModule = Get-Module -ListAvailable -Name $Name | Sort-Object -Property Version -Descending | Select-Object -First 1
        if (-not $RequiredModule) {
            throw "$Name $Version or higher is required to run the Veeam VB365 As Built Report. Install the Veeam Backup & Replication for Microsoft 365 console that provide the required modules."
        }
        if ($RequiredModule.Version -lt [version]$Version) {
            throw "$Name $Version or higher is required to run the Veeam VB365 As Built Report. Update the Veeam Backup & Replication for Microsoft 365 console that provide the required modules."
        }
    }
    end {}
}

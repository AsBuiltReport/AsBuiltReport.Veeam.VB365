function Get-AbrVB365RequiredModule {
    <#
    .SYNOPSIS
    Function to check if the required version of Veeam.Archiver.PowerShell is installed
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

    Param
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
        $MyModulePath = "C:\Program Files\Veeam\BackupVBO\Veeam.Archiver.PowerShell\"
        $env:PSModulePath = $env:PSModulePath + "$([System.IO.Path]::PathSeparator)$MyModulePath"
        if ($Modules = Get-Module -ListAvailable -Name Veeam.Archiver.PowerShell) {
            try {
                Write-PScriboMessage "Trying to import Veeam VB365 modules."
                $Modules | Import-Module -WarningAction SilentlyContinue
            } catch {
                Write-PScriboMessage -IsWarning "Failed to load Veeam VB365 Modules"
            }
        }
        if ($Module = Get-Module -ListAvailable -Name Veeam.Archiver.PowerShell) {
            try {
                Write-PScriboMessage "Identifying Veeam VB365 Powershell module version."
                switch ($Module.Version.ToString()) {
                    { $_ -eq "6.0" } { [int]$Vb365Version = "6" }
                    Default { "Unknown" }
                }
                Write-PScriboMessage "Using Veeam VB365 Powershell module version $($Vb365Version)."
            } catch {
                Write-PScriboMessage -IsWarning "Failed to get Version from Module"
            }
        } else {
            try {
                Write-PScriboMessage "No Veeam Modules found, tryng to import module manually."
                Import-Module "C:\Program Files\Veeam\Backup365\Veeam.Archiver.PowerShell\Veeam.Archiver.PowerShell.psd1"
                [int]$Vb365Version = (Get-Module -ListAvailable -Name Veeam.Archiver.PowerShell).Version.ToString()
                if ($Vb365Version) {
                    Write-PScriboMessage "Using Veeam VB365 Powershell module version $($Vb365Version)."
                }
            } catch {
                throw "Failed to get version from manual Module import"
            }
        }
        # Check if the required version of VMware PowerCLI is installed
        $RequiredModule = Get-Module -ListAvailable -Name $Name | Sort-Object -Property Version -Descending | Select-Object -First 1
        $ModuleVersion = "$($RequiredModule.Version.Major)" + "." + "$($RequiredModule.Version.Minor)"
        if ($ModuleVersion -eq ".") {
            throw "$Name $Version or higher is required to run the Veeam VB365 As Built Report. Install the Veeam Backup & Replication for Microsoft 365 console that provide the required modules."
        }
        if ($ModuleVersion -lt $Version) {
            throw "$Name $Version or higher is required to run the Veeam VB365 As Built Report. Update the Veeam Backup & Replication for Microsoft 365 console that provide the required modules."
        }
    }
    end {}
}
#
# Module manifest for module 'AsBuiltReport.Veeam.VB365'
#
# Generated by: Jonathan Colon
#
# Generated on: 3/23/2023
#

@{

    # Script module or binary module file associated with this manifest.
    RootModule = 'AsBuiltReport.Veeam.VB365.psm1'

    # Version number of this module.
    ModuleVersion = '0.3.9'

    # Supported PSEditions
    # CompatiblePSEditions = @()

    # ID used to uniquely identify this module
    GUID = '3da0eaed-e086-4c3d-ab3b-41291378fa05'

    # Author of this module
    Author = 'Jonathan Colon'

    # Company or vendor of this module
    # CompanyName = 'Unknown'

    # Copyright statement for this module
    Copyright = '(c) 2024 Jonathan Colon. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'A PowerShell module to generate an as built report on the configuration of Veeam Backup for Microsoft 365.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # CLRVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module

    RequiredModules = @(
        @{
            ModuleName = 'AsBuiltReport.Core';
            ModuleVersion = '1.4.1'
        },
        @{
            ModuleName = 'PScriboCharts';
            ModuleVersion = '0.9.0'
        },
        @{
            ModuleName = 'Diagrammer.Core';
            ModuleVersion = '0.2.13'
        }
    )

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @('Invoke-AsBuiltReport.Veeam.VB365')

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    # CmdletsToExport = '*'

    # Variables to export from this module
    # VariablesToExport = '*'

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    # AliasesToExport = '*'

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('AsBuiltReport', 'Report', 'Veeam', 'VB365', 'Documentation', 'PScribo', 'Windows', 'PSEdition_Desktop', 'PSEdition_Core')

            # A URL to the license for this module.
            LicenseUri = 'https://raw.githubusercontent.com/AsBuiltReport/AsBuiltReport.Veeam.VB365/master/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365'

            # A URL to an icon representing this module.
            IconUri = 'https://github.com/AsBuiltReport.png'

            # ReleaseNotes of this module
            ReleaseNotes = 'https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365/blob/master/CHANGELOG.md'

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    HelpInfoURI = 'https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365?tab=readme-ov-file#veeam-vb365-as-built-report'

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}



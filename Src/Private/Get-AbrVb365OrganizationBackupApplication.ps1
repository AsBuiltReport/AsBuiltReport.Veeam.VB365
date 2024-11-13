function Get-AbrVb365OrganizationBackupApplication {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Office365 Backup Applications Settings
    .DESCRIPTION
        Documents the configuration of Veeam VB365 in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.8
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VB365
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String] $Organization
    )

    begin {
        Write-PScriboMessage "Organizations InfoLevel set at $($InfoLevel.Infrastructure.Organization)."
    }

    process {
        try {
            $Organizations = Get-VBOOrganization -Name $Organization
            $BackupApplications = try { Get-VBOBackupApplication -Organization $Organizations | Sort-Object -Property DisplayName} catch { Out-Null }
            if (($InfoLevel.Infrastructure.Organization -gt 0) -and ($BackupApplications)) {
                Write-PScriboMessage "Collecting Veeam VB365 Office365 Organization Backup Applications Settings."
                Section -Style Heading4 'Backup Applications' {
                    $BackupApplicationInfo = @()
                    foreach ($BackupApplication in $BackupApplications) {
                        $inObj = [ordered] @{
                            'Name' = $BackupApplication.DisplayName
                            'Certificate Thumbprint' = $BackupApplication.ApplicationCertificateThumbprint
                        }

                        $BackupApplicationInfo += [pscustomobject](ConvertTo-HashToYN $inObj)
                    }

                    $TableParams = @{
                        Name = "Backup Applications - $($Organizations.Name)"
                        List = $false
                        ColumnWidths = 40, 60
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }

                    $BackupApplicationInfo | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "VB365 Office365 Organization Backup Applications Section: $($_.Exception.Message)"
        }
    }

    end {}
}
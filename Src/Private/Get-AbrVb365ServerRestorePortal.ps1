function Get-AbrVb365ServerRestorePortal {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 backup restore portal configuration
    .DESCRIPTION
        Documents the configuration of Veeam VB365 in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.1.1
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
        Write-PScriboMessage "ServerConfig InfoLevel set at $($InfoLevel.Infrastructure.ServerConfig)."
    }

    process {
        try {
            $RestorePortal = Get-VBORestorePortalSettings
            if (($InfoLevel.Infrastructure.ServerConfig -gt 0) -and ($RestorePortal)) {
                Write-PscriboMessage "Collecting Veeam VB365 restore portal."
                Section -Style Heading3 'Restore Portal' {
                    $RestorePortalInfo = @()
                    $inObj = [ordered] @{
                        'Is Restore Portal Enable' = ConvertTo-TextYN $RestorePortal.IsServiceEnabled
                        'Region' = ConvertTo-EmptyToFiller $RestorePortal.Region
                        'Application Id' = ConvertTo-EmptyToFiller $RestorePortal.ApplicationId
                        'Portal URI' = ConvertTo-EmptyToFiller $RestorePortal.PortalUri
                        'Certificate Friendly Name' = ConvertTo-EmptyToFiller $RestorePortal.CertificateFriendlyName
                        'Issued To' = ConvertTo-EmptyToFiller $RestorePortal.CertificateIssuedTo
                        'Issued By' = ConvertTo-EmptyToFiller $RestorePortal.CertificateIssuedBy
                        'Thumbprint' = ConvertTo-EmptyToFiller $RestorePortal.CertificateThumbprint
                        'Expiration Date' = ConvertTo-EmptyToFiller $RestorePortal.CertificateExpirationDate
                    }
                    $RestorePortalInfo = [PSCustomObject]$InObj

                    $TableParams = @{
                        Name = "Restore Portal - $VeeamBackupServer"
                        List = $true
                        ColumnWidths = 50, 50
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $RestorePortalInfo | Table @TableParams
                }
            }
        } catch {
            Write-PscriboMessage -IsWarning "Restore Portal Section: $($_.Exception.Message)"
        }
    }

    end {}
}
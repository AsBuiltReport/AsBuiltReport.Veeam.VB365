function Get-AbrVb365ServerRestorePortal {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 backup restore portal configuration
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
    )

    begin {
        Write-PScriboMessage "ServerConfig InfoLevel set at $($InfoLevel.Infrastructure.ServerConfig)."
    }

    process {
        try {
            $script:RestorePortal = Get-VBORestorePortalSettings
            if (($InfoLevel.Infrastructure.ServerConfig -gt 0) -and ($RestorePortal)) {
                Write-PScriboMessage "Collecting Veeam VB365 restore portal."
                Section -Style Heading3 'Restore Portal' {
                    $RestorePortalInfo = @()
                    $inObj = [ordered] @{
                        'Is Restore Portal Enabled' = $RestorePortal.IsServiceEnabled
                        'Region' = $RestorePortal.Region
                        'Application Id' = $RestorePortal.ApplicationId
                        'Portal URI' = $RestorePortal.PortalUri
                        'Certificate Friendly Name' = $RestorePortal.CertificateFriendlyName
                        'Issued To' = $RestorePortal.CertificateIssuedTo
                        'Issued By' = $RestorePortal.CertificateIssuedBy
                        'Thumbprint' = $RestorePortal.CertificateThumbprint
                        'Expiration Date' = $RestorePortal.CertificateExpirationDate.DateTime
                    }
                    $RestorePortalInfo = [pscustomobject](ConvertTo-HashToYN $inObj)

                    if ($HealthCheck.Infrastructure.ServerConfig) {
                        $RestorePortalInfo | Where-Object { $_.'Issued By' -eq 'CN=Veeam Software, O=Veeam Software, OU=Veeam Software' } | Set-Style -Style Warning -Property 'Issued By'
                        $RestorePortalInfo | Where-Object { ((Get-Date).AddDays(+90)).Date.DateTime -gt $_.'Expiration Date' } | Set-Style -Style Critical -Property 'Expiration Date'
                        $RestorePortalInfo | Where-Object { $_.'Is Restore Portal Enabled' -eq 'No' } | Set-Style -Style Warning -Property 'Is Restore Portal Enabled'

                    }

                    $TableParams = @{
                        Name = "Restore Portal - $VeeamBackupServer"
                        List = $true
                        ColumnWidths = 40, 60
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $RestorePortalInfo | Table @TableParams
                    if ($HealthCheck.Infrastructure.ServerConfig -and ($RestorePortalInfo | Where-Object { $_.'Issued By' -eq 'CN=Veeam Software, O=Veeam Software, OU=Veeam Software' })) {
                        Paragraph "Health Check:" -Bold -Underline
                        BlankLine
                        Paragraph {
                            Text "Best Practice:" -Bold
                            Text "While self-signed certificates may seem harmless, they open up dangerous vulnerabilities from MITM attacks to disrupted services. For the Restore Portal and API Server, consider using trusted certificates as these are services accessed by end users."
                            Text "https://bp.veeam.com/vb365/guide/supplemental/security.html#certificate-usage" -Color Blue
                        }
                        BlankLine
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Restore Portal Section: $($_.Exception.Message)"
        }
    }

    end {}
}
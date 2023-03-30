function Get-AbrVB365ServerConfiguration {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 backup server configuration
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
            $ServerConfig = @()
            $ServerConfig += try {Get-VBOVersion} catch {}
            $ServerConfig += Get-VBOSecuritySettings

            if (($InfoLevel.Infrastructure.ServerConfig -gt 0) -and ($ServerConfig)) {
                Write-PscriboMessage "Collecting Veeam VB365 Server Configuration."
                Section -Style Heading3 'Server Configuration' {
                    Paragraph "The following sections detail the server configuration of $VeeamBackupServer backup server."
                    BlankLine
                    Section -Style Heading4 'General Information' {
                        $ServerConfigInfo = @()
                        $inObj = [ordered] @{
                            'Server Product Version' = Switch ([string]::IsNullOrEmpty($ServerConfig.ProductVersion)) {
                                $true {'6 or less, please upgrade'}
                                $false {$ServerConfig.ProductVersion}
                                default {'Unknown'}

                            }
                            'Certificate Friendly Name' = $ServerConfig.CertificateFriendlyName
                            'Issued To' = $ServerConfig.CertificateIssuedTo
                            'Issued By' = $ServerConfig.CertificateIssuedBy
                            'Expiration Date' = $ServerConfig.CertificateExpirationDate
                            'Thumbprint' = $ServerConfig.CertificateThumbprint
                        }
                        $ServerConfigInfo = [PSCustomObject]$InObj


                        $TableParams = @{
                            Name = "Server Configuration - $VeeamBackupServer"
                            List = $true
                            ColumnWidths = 50, 50
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $ServerConfigInfo | Table @TableParams
                    }

                    # Backup Server Internet Proxy Configuration
                    Get-AbrVB365ServerInternetProxy

                    # Backup Server RESTfull API Configuration
                    Get-AbrVB365ServerRestAPI

                    # Backup Server Email Settings
                    Get-AbrVB365ServerEmailSetting

                    #Backup Server Authentication
                    Get-AbrVB365ServerTenantAuth

                    #Backup Server Folder Exclusion
                    Get-AbrVB365ServerFolderExclution

                    #Backup Server Restore Portal
                    Get-AbrVb365ServerRestorePortal
                }
            }
        } catch {
            Write-PscriboMessage -IsWarning "Server Configuration Section: $($_.Exception.Message)"
        }
    }

    end {}
}
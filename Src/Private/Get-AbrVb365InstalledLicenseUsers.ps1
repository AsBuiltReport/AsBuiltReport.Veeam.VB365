
function Get-AbrVB365InstalledLicenseUser {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Installed Licenses
    .DESCRIPTION
        Documents the configuration of Veeam VB365 in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.11
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
        Write-PScriboMessage -Message "Discovering Veeam VB365 License information from $System."
    }

    process {
        try {
            $Licenses = Get-VBOLicensedUser | Sort-Object -Property OrganizationName
            if ($Licenses) {
                try {
                    Section -Style Heading3 'Licensed Users' {
                        $OutObj = @()
                        try {
                            foreach ($License in $Licenses) {
                                Write-PScriboMessage -Message "Discovered $($License.UserName) license."
                                $inObj = [ordered] @{
                                    'User Name' = $License.UserName
                                    'Organization' = $License.OrganizationName
                                    'Is Backed Up?' = $License.IsBackedUp
                                    'Last Backup Date' = $License.LastBackupDate.ToShortDateString()
                                    'License Status' = $License.LicenseStatus
                                }
                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning -Message "Licensed User Information $($License.UserName) Section: $($_.Exception.Message)"
                        }

                        if ($HealthCheck.Infrastructure.Status) {
                            $OutObj | Where-Object { $_.'License Status' -ne 'Licensed' } | Set-Style -Style Critical -Property 'License Status'
                            $OutObj | Where-Object { $_.'Is Backed Up' -eq 'No' } | Set-Style -Style Warning -Property 'Is Backed Up'
                        }

                        $TableParams = @{
                            Name = "Licensed Users - $VeeamBackupServer"
                            List = $false
                            ColumnWidths = 28, 27, 15, 15, 15
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
                    }
                } catch {
                    Write-PScriboMessage -IsWarning -Message "Licensed Users Section: $($_.Exception.Message)"
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning -Message "Licensed Users Section: $($_.Exception.Message)"
        }
    }

    end {}

}

function Get-AbrVB365InstalledLicenseUser {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Installed Licenses
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
    param (

    )

    begin {
        Write-PScriboMessage -Message "Discovering Veeam VB365 License information from $System."
    }

    process {
        try {
            if ($script:LicensedUsers) {
                $Licenses = $script:LicensedUsers
            } else {
                $script:LicensedUsers = Get-VBOLicensedUser | Sort-Object -Property OrganizationName
                $Licenses = $script:LicensedUsers
            }
            if ($Licenses) {
                try {
                    Section -Style Heading3 'Licensed Users' {
                        $OutObj = @()
                        Write-PScriboMessage -Message "Discovered $(($Licenses | Measure-Object).Count) licensed users."
                        foreach ($License in $Licenses) {
                            try {
                                $LastBackupDate = Get-AbrVb365PropertyValue -InputObject $License -Name 'LastBackupDate'
                                $LastBackupDateText = if ($LastBackupDate -is [datetime]) {
                                    $LastBackupDate.ToShortDateString()
                                } elseif ($LastBackupDate) {
                                    $LastBackupDate.ToString()
                                } else {
                                    '--'
                                }

                                $inObj = [ordered] @{
                                    'User Name' = ConvertTo-AbrVb365DisplayValue -InputObject (Get-AbrVb365PropertyValue -InputObject $License -Name 'UserName')
                                    'Organization' = ConvertTo-AbrVb365DisplayValue -InputObject (Get-AbrVb365PropertyValue -InputObject $License -Name 'OrganizationName')
                                    'Is Backed Up?' = Get-AbrVb365PropertyValue -InputObject $License -Name 'IsBackedUp' -Default $false
                                    'Last Backup Date' = $LastBackupDateText
                                    'License Status' = ConvertTo-AbrVb365DisplayValue -InputObject (Get-AbrVb365PropertyValue -InputObject $License -Name 'LicenseStatus')
                                }
                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                            } catch {
                                Write-PScriboMessage -IsWarning -Message "Licensed User Information Section: $($_.Exception.Message)"
                            }
                        }

                        if ($HealthCheck.Infrastructure.License) {
                            $OutObj | Where-Object { $_.'License Status' -ne 'Licensed' } | Set-Style -Style Critical -Property 'License Status'
                            $OutObj | Where-Object { $_.'Is Backed Up?' -eq 'No' } | Set-Style -Style Warning -Property 'Is Backed Up?'
                        }

                        $TableParams = @{
                            Name = "Licensed Users - $VeeamBackupServer"
                            List = $false
                            ColumnWidths = 28, 27, 15, 15, 15
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        if ($OutObj) {
                            $OutObj | Table @TableParams
                        } else {
                            Paragraph 'No licensed user records could be rendered from Get-VBOLicensedUser output.'
                        }
                    }
                } catch {
                    Write-PScriboMessage -IsWarning -Message "Licensed Users Section: $($_.Exception.Message)"
                }
            } else {
                Write-PScriboMessage -IsWarning -Message 'Licensed Users Section: Get-VBOLicensedUser returned no licensed user records.'
            }
        } catch {
            Write-PScriboMessage -IsWarning -Message "Licensed Users Section: $($_.Exception.Message)"
        }
    }

    end {}

}

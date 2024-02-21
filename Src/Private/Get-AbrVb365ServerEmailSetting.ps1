function Get-AbrVB365ServerEmailSetting {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 backup email settings configuration
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
    param (
    )

    begin {
        Write-PScriboMessage "ServerConfig InfoLevel set at $($InfoLevel.Infrastructure.ServerConfig)."
    }

    process {
        try {
            $ServerConfig = Get-VBOEmailSettings
            if (($InfoLevel.Infrastructure.ServerConfig -gt 0) -and ($ServerConfig)) {
                Write-PScriboMessage "Collecting Veeam VB365 email settings."
                Section -Style Heading3 'Notification' {
                    $ServerConfigInfo = @()
                    $inObj = [ordered] @{
                        'Enable Email Notification' = ConvertTo-TextYN $ServerConfig.EnableNotification
                        'SMTP Server' = ConvertTo-EmptyToFiller $ServerConfig.SMTPServer
                        'Port' = ConvertTo-EmptyToFiller $ServerConfig.Port
                        'Use Authentication' = ConvertTo-TextYN $ServerConfig.UseAuthentication
                        'From' = ConvertTo-EmptyToFiller $ServerConfig.From
                        'To' = ConvertTo-EmptyToFiller $ServerConfig.To
                        'Subject' = $ServerConfig.Subject
                        'Notify On Success' = ConvertTo-TextYN $ServerConfig.NotifyOnSuccess
                        'Notify On Warning' = ConvertTo-TextYN $ServerConfig.NotifyOnWarning
                        'Notify On Failure' = ConvertTo-TextYN $ServerConfig.NotifyOnFailure
                        'Supress Until Last Retry' = ConvertTo-TextYN $ServerConfig.SupressUntilLastRetry
                        'Include Detailed Report as an attachment' = ConvertTo-TextYN $ServerConfig.AttachDetailedReport
                    }
                    $ServerConfigInfo = [PSCustomObject]$InObj

                    $TableParams = @{
                        Name = "Notification Settings - $VeeamBackupServer"
                        List = $true
                        ColumnWidths = 50, 50
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $ServerConfigInfo | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Notification Settings Section: $($_.Exception.Message)"
        }
    }

    end {}
}
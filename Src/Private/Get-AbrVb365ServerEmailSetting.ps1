function Get-AbrVB365ServerEmailSetting {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 backup email settings configuration
    .DESCRIPTION
        Documents the configuration of Veeam VB365 in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.2
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
                        'Use Authentication' = ConvertTo-TextYN $ServerConfig.UseAuthentication
                        'From' = ConvertTo-EmptyToFiller $ServerConfig.From
                        'To' = ConvertTo-EmptyToFiller $ServerConfig.To
                        'Subject' = $ServerConfig.Subject
                        'Notify On Success' = ConvertTo-TextYN $ServerConfig.NotifyOnSuccess
                        'Notify On Warning' = ConvertTo-TextYN $ServerConfig.NotifyOnWarning
                        'Notify On Failure' = ConvertTo-TextYN $ServerConfig.NotifyOnFailure
                        'Supress Until Last Retry' = ConvertTo-TextYN $ServerConfig.SupressUntilLastRetry
                        'Include Detailed Report as an attachment' = ConvertTo-TextYN $ServerConfig.AttachDetailedReport
                        'Authentication Type' = $ServerConfig.AuthenticationType
                    }

                    if ($ServerConfig.AuthenticationType -ne 'CustomSmtp') {
                        $inObj.Add('User Id', $ServerConfig.UserId)
                        $inObj.Add('Mail Api Url', $ServerConfig.MailApiUrl)
                    }
                    if ($ServerConfig.AuthenticationType -eq 'CustomSmtp') {
                        $inObj.Add('SMTP Server', $ServerConfig.SMTPServer)
                        $inObj.Add('SMTP Port', $ServerConfig.Port)
                        $inObj.Add('SMTP Username', $ServerConfig.Username)
                        $inObj.Add('Use SMTP SSL', (ConvertTo-TextYN $ServerConfig.UseSSL))
                    }
                    $ServerConfigInfo = [PSCustomObject]$InObj

                    if ($HealthCheck) {
                        $ServerConfigInfo | Where-Object { $_.'Enable Email Notification' -eq 'No' } | Set-Style -Style Critical -Property 'Enable Email Notification'
                    }

                    $TableParams = @{
                        Name = "Notification Settings - $VeeamBackupServer"
                        List = $true
                        ColumnWidths = 40, 60
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $ServerConfigInfo | Table @TableParams
                    if ($HealthCheck -and ($ServerConfigInfo | Where-Object { $_.'Enable Email Notification' -eq 'No' })) {
                        Paragraph "Health Check:" -Bold -Underline
                        BlankLine
                        Paragraph {
                            Text "Best Practice:" -Bold
                            Text "Veeam recommends configuring email notifications to be able to receive jobs alerts also without setting up an email and server in the email notifications users will not get notified when there are issues."
                        }
                        BlankLine
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Notification Settings Section: $($_.Exception.Message)"
        }
    }

    end {}
}
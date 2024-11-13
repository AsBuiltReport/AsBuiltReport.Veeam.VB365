function Get-AbrVb365ServerHistorySetting {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 backup history settings configuration
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
            $ServerConfig = Get-VBOHistorySettings
            if (($InfoLevel.Infrastructure.ServerConfig -gt 0) -and ($ServerConfig)) {
                Write-PScriboMessage "Collecting Veeam VB365 history settings."
                Section -Style Heading3 'History' {
                    $ServerConfigInfo = @()
                    $inObj = [ordered] @{
                        'Keep all sessions' = $ServerConfig.KeepAllSessions
                    }
                    if (-Not $ServerConfig.KeepAllSessions) {
                        $inObj.Add('Keep only last', "$($ServerConfig.KeepOnlyLastXweeks) weeks")
                    }
                    $ServerConfigInfo = [pscustomobject](ConvertTo-HashToYN $inObj)

                    $TableParams = @{
                        Name = "History Settings - $VeeamBackupServer"
                        List = $true
                        ColumnWidths = 40, 60
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $ServerConfigInfo | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "History Settings Section: $($_.Exception.Message)"
        }
    }

    end {}
}
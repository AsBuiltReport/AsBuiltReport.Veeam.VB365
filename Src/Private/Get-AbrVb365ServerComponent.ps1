
function Get-AbrVB365ServerComponent {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Server Components
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
        Write-PscriboMessage "Discovering Veeam VB365 Server Components information from $System."
    }

    process {
        try {
            $ServerComponents = Get-VBOServerComponents | Sort-Object -Property Name
            if ($ServerComponents) {
                try {
                    Section -Style Heading2 'Server Components' {
                        Paragraph "The following table summarizes the configuration of the server components within $VeeamBackupServer backup server."
                        BlankLine
                        $OutObj = @()
                        try {
                            foreach ($ServerComponent in ($ServerComponents | where-Object {$_.Name -notlike "*Veeam Explorer for*" -and $_.Name -notlike "*PowerShell*"})) {
                                Write-PscriboMessage "Discovered $($ServerComponent.Name) Server Components."
                                $inObj = [ordered] @{
                                    'Name' = $ServerComponent.Name
                                    'Server Name' = $ServerComponent.ServerName
                                    'Is Online' = ConvertTo-TextYN $ServerComponent.IsOnline
                                    'Extended Logging' = ConvertTo-TextYN $ServerComponent.ExtendedLoggingEnabled
                                }
                                $OutObj += [pscustomobject]$inobj
                            }
                        }
                        catch {
                            Write-PscriboMessage -IsWarning "Server Components Information $($ServerComponent.Name) Section: $($_.Exception.Message)"
                        }

                        if ($HealthCheck.Infrastructure.ServerComponent) {
                            $OutObj | Where-Object { $_.'Is Online' -eq 'No'} | Set-Style -Style Warning -Property 'Is Online'
                        }

                        $TableParams = @{
                            Name = "Server Components - $VeeamBackupServer"
                            List = $false
                            ColumnWidths = 40, 30, 15, 15
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
                    }
                }
                catch {
                    Write-PscriboMessage -IsWarning "Server Components Section: $($_.Exception.Message)"
                }
            }
        } catch {
            Write-PscriboMessage -IsWarning "Server Component Section: $($_.Exception.Message)"
        }
    }

    end {}

}
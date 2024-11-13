function Get-AbrVb365RestoreOperator {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Office365 Restore Operator Settings
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
        Write-PScriboMessage "Organizations InfoLevel set at $($InfoLevel.Infrastructure.Organization)."
    }

    process {
        try {
            $script:RestoreOperators = try { Get-VBORbacRole | Sort-Object -Property Name} catch { Out-Null }
            if (($InfoLevel.Infrastructure.Organization -gt 0) -and ($RestoreOperators)) {
                Write-PScriboMessage "Collecting Veeam VB365 Office365 Restore Operators Settings."
                Section -Style Heading3 'Restore Operators' {
                    Paragraph "The following table summarizes the configuration of the restore operators within the $VeeamBackupServer backup server."
                    BlankLine
                    $RestoreOperatorInfo = @()
                    foreach ($RestoreOperator in $RestoreOperators) {
                        $inObj = [ordered] @{
                            'Name' = $RestoreOperator.Name
                            'Organization' = Switch ([string]::IsNullOrEmpty((Get-VBOOrganization -Id $RestoreOperator.OrganizationId))) {
                                $true {'--'}
                                $false {(Get-VBOOrganization -Id $RestoreOperator.OrganizationId).Name}
                                default {'Unknown'}
                            }
                            'Description' = $RestoreOperator.Description
                        }

                        $RestoreOperatorInfo += [pscustomobject](ConvertTo-HashToYN $inObj)
                    }

                    $TableParams = @{
                        Name = "Restore Operator - $($VeeamBackupServer)"
                        List = $false
                        ColumnWidths = 33, 33, 34
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }

                    $RestoreOperatorInfo | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "VB365 Office365 Restore Operators Settings Section: $($_.Exception.Message)"
        }
    }

    end {}
}
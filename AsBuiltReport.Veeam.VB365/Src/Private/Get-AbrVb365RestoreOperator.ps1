function Get-AbrVb365RestoreOperator {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Office365 Restore Operator Settings
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
        $OrganizationInfoLevel = Get-AbrVb365InfoLevelValue -Scope 'Infrastructure' -Name 'Organization' -Alias 'Organizations', 'Organisation', 'Organisations'
        Write-PScriboMessage -Message "Organizations InfoLevel set at $OrganizationInfoLevel."
    }

    process {
        try {
            if ($script:RestoreOperators) {
                $RestoreOperators = $script:RestoreOperators
            } else {
                $script:RestoreOperators = try { Get-VBORbacRole | Sort-Object -Property Name } catch { Out-Null }
                $RestoreOperators = $script:RestoreOperators
            }
            if (($OrganizationInfoLevel -gt 0) -and ($RestoreOperators)) {
                Write-PScriboMessage -Message 'Collecting Veeam VB365 Office365 Restore Operators Settings.'
                Section -Style Heading3 'Restore Operators' {
                    Paragraph "The following table summarizes the configuration of the restore operators within the $VeeamBackupServer backup server."
                    BlankLine
                    $RestoreOperatorInfo = @()
                    $OrganizationLookup = Get-AbrVb365OrganizationNameLookup
                    foreach ($RestoreOperator in $RestoreOperators) {
                        $OrganizationId = Get-AbrVb365PropertyValue -InputObject $RestoreOperator -Name 'OrganizationId'
                        $OrganizationKey = ConvertTo-AbrVb365LookupKey -Id $OrganizationId
                        $OrganizationName = if ($OrganizationKey -and $OrganizationLookup.ContainsKey($OrganizationKey)) {
                            $OrganizationLookup[$OrganizationKey]
                        } else {
                            '--'
                        }
                        $inObj = [ordered] @{
                            'Name' = $RestoreOperator.Name
                            'Organization' = $OrganizationName
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
            Write-PScriboMessage -IsWarning -Message "VB365 Office365 Restore Operators Settings Section: $($_.Exception.Message)"
        }
    }

    end {}
}

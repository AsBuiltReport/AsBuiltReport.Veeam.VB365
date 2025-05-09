function Get-AbrVB365EncryptionKey {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Encryption Key
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
        Write-PScriboMessage -Message "EncryptionKey InfoLevel set at $($InfoLevel.Infrastructure.EncryptionKey)."
    }

    process {
        try {
            $EncryptionKeys = Get-VBOEncryptionKey | Sort-Object -Property Description
            if (($InfoLevel.Infrastructure.EncryptionKey -gt 0) -and ($EncryptionKeys)) {
                Write-PScriboMessage -Message "Collecting Veeam VB365 Encryption Key."
                Section -Style Heading2 'Encryption Keys' {
                    $EncryptionKeyInfo = @()
                    foreach ($EncryptionKey in $EncryptionKeys) {
                        $UsedAT = Get-VBORepository | Where-Object { $_.ObjectStorageEncryptionKey.Id -eq $EncryptionKey.Id }
                        $inObj = [ordered] @{
                            'Id' = $EncryptionKey.Id
                            'Description' = $EncryptionKey.Description
                            'Last Modified' = $EncryptionKey.LastModified
                            'Used At' = $UsedAT -join ", "
                        }
                        $EncryptionKeyInfo += [pscustomobject](ConvertTo-HashToYN $inObj)
                    }

                    if ($InfoLevel.Infrastructure.EncryptionKey -ge 2) {
                        Paragraph "The following sections detail the configuration of the encryption key within $VeeamBackupServer backup server."
                        foreach ($EncryptionKey in $EncryptionKeyInfo) {
                            Section -ExcludeFromTOC -Style NOTOCHeading4 "$($EncryptionKey.Id)" {
                                $TableParams = @{
                                    Name = "Encryption Key - $($EncryptionKey.Id)"
                                    List = $true
                                    ColumnWidths = 40, 60
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $EncryptionKey | Table @TableParams
                            }
                        }
                    } else {
                        Paragraph "The following table summarizes the configuration of the encryption key within the $VeeamBackupServer backup server."
                        BlankLine
                        $TableParams = @{
                            Name = "Encryption Keys - $VeeamBackupServer"
                            List = $false
                            Columns = 'Description', 'Last Modified'
                            ColumnWidths = 60, 40
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $EncryptionKeyInfo | Table @TableParams
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning -Message "Encryption Key Section: $($_.Exception.Message)"
        }
    }

    end {}
}
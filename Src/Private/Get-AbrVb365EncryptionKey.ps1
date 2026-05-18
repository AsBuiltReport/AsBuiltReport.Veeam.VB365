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
            if ($InfoLevel.Infrastructure.EncryptionKey -le 0) {
                return
            }

            $script:EncryptionKeys = Get-VBOEncryptionKey | Sort-Object -Property Description
            $EncryptionKeys = $script:EncryptionKeys
            if ($EncryptionKeys) {
                Write-PScriboMessage -Message "Collecting Veeam VB365 Encryption Key."
                Section -Style Heading2 'Encryption Keys' {
                    $EncryptionKeyUsage = @{}
                    if ($InfoLevel.Infrastructure.EncryptionKey -ge 2) {
                        $Repositories = Get-AbrVb365BackupRepositoryInventory

                        foreach ($Repository in ($Repositories | Where-Object { $_ })) {
                            $EncryptionKey = Get-AbrVb365PropertyValue -InputObject $Repository -Name 'ObjectStorageEncryptionKey'
                            if (-not $EncryptionKey) {
                                continue
                            }

                            $EncryptionKeyId = Get-AbrVb365PropertyValue -InputObject $EncryptionKey -Name 'Id'
                            if (-not $EncryptionKeyId) {
                                continue
                            }

                            $EncryptionKeyId = $EncryptionKeyId.ToString()
                            if (-not $EncryptionKeyUsage.ContainsKey($EncryptionKeyId)) {
                                $EncryptionKeyUsage[$EncryptionKeyId] = New-Object System.Collections.Generic.List[string]
                            }

                            $RepositoryName = Get-AbrVb365PropertyValue -InputObject $Repository -Name 'Name'
                            if ($RepositoryName) {
                                $EncryptionKeyUsage[$EncryptionKeyId].Add($RepositoryName)
                            }
                        }
                    }

                    $EncryptionKeyInfo = @()
                    foreach ($EncryptionKey in $EncryptionKeys) {
                        $inObj = [ordered] @{
                            'Id' = $EncryptionKey.Id
                            'Description' = $EncryptionKey.Description
                            'Last Modified' = $EncryptionKey.LastModified
                        }
                        if ($InfoLevel.Infrastructure.EncryptionKey -ge 2) {
                            $EncryptionKeyId = $EncryptionKey.Id.ToString()
                            $UsedAt = if ($EncryptionKeyUsage.ContainsKey($EncryptionKeyId)) {
                                ($EncryptionKeyUsage[$EncryptionKeyId] | Sort-Object -Unique) -join ', '
                            } else {
                                '--'
                            }
                            $inObj.Add('Used At', $UsedAt)
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

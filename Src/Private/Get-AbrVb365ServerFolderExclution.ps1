function Get-AbrVB365ServerFolderExclution {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 backup tenant authentication configuration
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
            $FolderExclusion = Get-VBOFolderExclusions
            $RetentionExclusion = Get-VBOGlobalRetentionExclusion
            if (($InfoLevel.Infrastructure.ServerConfig -gt 0) -and ($FolderExclusion -or $RetentionExclusion)) {
                Write-PScriboMessage "Collecting Veeam VB365 folder exclusions."
                Section -Style Heading3 'Folders' {
                    if ($FolderExclusion) {
                        Section -ExcludeFromTOC -Style NOTOCHeading5 'Mailbox Folder Exclusion from Backup' {
                            $FolderExclusionInfo = @()
                            $inObj = [ordered] @{
                                'Deleted Items' = ConvertTo-TextYN $FolderExclusion.DeletedItems
                                'Draft' = ConvertTo-TextYN $FolderExclusion.Drafts
                                'Junk Email' = ConvertTo-TextYN $FolderExclusion.JunkEmail
                                'Outbox' = ConvertTo-TextYN $FolderExclusion.Outbox
                                'Sync Issues' = ConvertTo-TextYN $FolderExclusion.SyncIssues
                                'Litigation Hold' = ConvertTo-TextYN $FolderExclusion.LitigationHold
                                'In Place Hold' = ConvertTo-TextYN $FolderExclusion.InPlaceHold
                            }
                            $FolderExclusionInfo = [PSCustomObject]$InObj

                            $TableParams = @{
                                Name = "Mailbox Folder Exclusion from Backup - $VeeamBackupServer"
                                List = $true
                                ColumnWidths = 50, 50
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $FolderExclusionInfo | Table @TableParams
                        }
                    }
                    if ($RetentionExclusion) {
                        Section -ExcludeFromTOC -Style NOTOCHeading4 'Mailbox Folder Exclusion from Retention Policy' {
                            $RetentionExclusionInfo = @()
                            $inObj = [ordered] @{
                                'Skip Calendar' = ConvertTo-TextYN $RetentionExclusion.SkipCalendar
                                'Skip Contacts' = ConvertTo-TextYN $RetentionExclusion.SkipContacts
                            }
                            $RetentionExclusionInfo = [PSCustomObject]$InObj

                            $TableParams = @{
                                Name = "Restore Operator Authentication - $VeeamBackupServer"
                                List = $true
                                ColumnWidths = 50, 50
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $RetentionExclusionInfo | Table @TableParams
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Folders Section: $($_.Exception.Message)"
        }
    }

    end {}
}
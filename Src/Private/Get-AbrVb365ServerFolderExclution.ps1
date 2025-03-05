function Get-AbrVB365ServerFolderExclution {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 backup folder exclusions configuration
    .DESCRIPTION
        Documents the configuration of Veeam VB365 in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.9
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
                        Section -ExcludeFromTOC -Style NOTOCHeading4 'Mailbox Folder Exclusion from Backup' {
                            $FolderExclusionInfo = @()
                            $inObj = [ordered] @{
                                'Deleted Items' = $FolderExclusion.DeletedItems
                                'Draft' = $FolderExclusion.Drafts
                                'Junk Email' = $FolderExclusion.JunkEmail
                                'Outbox' = $FolderExclusion.Outbox
                                'Sync Issues' = $FolderExclusion.SyncIssues
                                'Litigation Hold' = $FolderExclusion.LitigationHold
                                'In Place Hold' = $FolderExclusion.InPlaceHold
                            }
                            $FolderExclusionInfo = [pscustomobject](ConvertTo-HashToYN $inObj)

                            $TableParams = @{
                                Name = "Mailbox Folder Exclusion from Backup - $VeeamBackupServer"
                                List = $true
                                ColumnWidths = 40, 60
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
                                'Skip Calendar' = $RetentionExclusion.SkipCalendar
                                'Skip Contacts' = $RetentionExclusion.SkipContacts
                            }
                            $RetentionExclusionInfo = [pscustomobject](ConvertTo-HashToYN $inObj)

                            $TableParams = @{
                                Name = "Restore Operator Authentication - $VeeamBackupServer"
                                List = $true
                                ColumnWidths = 40, 60
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
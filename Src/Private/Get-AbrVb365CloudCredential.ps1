function Get-AbrVb365CloudCredential {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VB365 Cloud Credential
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
        Write-PScriboMessage -Message "CloudCredential InfoLevel set at $($InfoLevel.Infrastructure.CloudCredential)."
    }

    process {
        try {
            $CloudCredentials = @()
            $CloudCredentials += Get-VBOAmazonS3Account
            $CloudCredentials += Get-VBOAmazonS3CompatibleAccount
            $CloudCredentials += Get-VBOAzureBlobAccount | Select-Object -Property id, Description, LastModified, @{Name = 'AccessKey'; Expression = { $_.Name } }, @{Name = 'ServiceType'; Expression = { "AzureBlobStorage" } }

            # $CloudCredentials += Get-VBOAzureServiceAccount

            if (($InfoLevel.Infrastructure.CloudCredential -gt 0) -and ($CloudCredentials)) {
                Write-PScriboMessage -Message "Collecting Veeam VB365 Cloud Credential."
                Section -Style Heading2 'Cloud Credentials' {
                    $CloudCredentialInfo = @()
                    foreach ($CloudCredential in $CloudCredentials) {
                        $inObj = [ordered] @{
                            'Access Key' = $CloudCredential.AccessKey
                            'Id' = $CloudCredential.Id
                            'Service Type' = Switch ($CloudCredential.ServiceType) {
                                "AmazonS3Compatible" { "Amazon S3 Compatible" }
                                "AmazonS3" { "Amazon S3" }
                                "AmazonS3Compatible" { "Amazon S3 Compatible" }
                                "AzureBlobStorage" { "Microsoft Azure Storage" }
                            }
                            'Last Modified' = $CloudCredential.LastModified
                            'Description' = $CloudCredential.Description
                        }
                        $CloudCredentialInfo += [pscustomobject](ConvertTo-HashToYN $inObj)
                    }

                    if ($InfoLevel.Infrastructure.CloudCredential -ge 2) {
                        Paragraph "The following sections detail the configuration of the cloud credential within $VeeamBackupServer backup server."
                        foreach ($CloudCredential in $CloudCredentialInfo) {
                            Section -ExcludeFromTOC -Style NOTOCHeading4 "$($CloudCredential.'Access Key')" {
                                $TableParams = @{
                                    Name = "Cloud Credential - $($CloudCredential.'Access Key')"
                                    List = $true
                                    ColumnWidths = 40, 60
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $CloudCredential | Table @TableParams
                            }
                        }
                    } else {
                        Paragraph "The following table summarizes the configuration of the cloud credentials within the $VeeamBackupServer backup server."
                        BlankLine
                        $TableParams = @{
                            Name = "Cloud Credentials - $VeeamBackupServer"
                            List = $false
                            Columns = 'Access Key', 'Description', 'Last Modified'
                            ColumnWidths = 38, 37, 25
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $CloudCredentialInfo | Table @TableParams
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning -Message "Cloud Credential Section: $($_.Exception.Message)"
        }
    }

    end {}
}
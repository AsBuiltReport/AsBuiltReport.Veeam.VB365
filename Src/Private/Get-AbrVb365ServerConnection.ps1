function Get-AbrVB365ServerConnection {
    <#
    .SYNOPSIS
    Used by As Built Report to establish conection to Veeam VB365365 Server.
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
        Write-PScriboMessage -Message "Establishing initial connection to Backup Server for Microsoft 365: $($System)."
    }

    process {
        try {
            Disconnect-VBOServer -ErrorAction SilentlyContinue
        } catch {
            Write-Verbose -Message "Unable to clear existing Veeam VB365 server connection: $($_.Exception.Message)"
        }

        try {
            Write-PScriboMessage -Message "Connecting to $($System) with $($Credential.USERNAME) credentials"
            Connect-VBOServer -Server $System -Credential $Credential -Port $Options.BackupServerPort -ErrorAction Stop
        } catch {
            $InitialErrorMessage = $_.Exception.Message
            Write-PScriboMessage -IsWarning -Message "Initial connection to Veeam Backup Server Host $($System):$($Options.BackupServerPort) failed: $InitialErrorMessage"
            Write-Verbose -Message "Disconnecting from any existing Veeam VB365 server session before retrying connection to $($System)."

            try {
                Disconnect-VBOServer -ErrorAction SilentlyContinue
            } catch {
                Write-Verbose -Message "Unable to clear existing Veeam VB365 server connection before retry: $($_.Exception.Message)"
            }

            try {
                Write-PScriboMessage -Message "Retrying connection to $($System) with $($Credential.USERNAME) credentials"
                Connect-VBOServer -Server $System -Credential $Credential -Port $Options.BackupServerPort -ErrorAction Stop
            } catch {
                $ErrorMessage = "Failed to connect to Veeam Backup Server Host $($System):$($Options.BackupServerPort) with username $($Credential.USERNAME) after retry. Initial error: $InitialErrorMessage Retry error: $($_.Exception.Message)"
                Write-Verbose -Message $ErrorMessage
                Write-PScriboMessage -IsWarning -Message $ErrorMessage
                throw $ErrorMessage
            }
        }

        Write-PScriboMessage -Message "Successfully connected to $($System):$($Options.BackupServerPort) Backup Server."
    }
    end {}
}

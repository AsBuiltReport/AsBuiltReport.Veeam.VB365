function Get-AbrVB365ServerConnection {
    <#
    .SYNOPSIS
    Used by As Built Report to establish conection to Veeam VB365365 Server.
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
        Write-PScriboMessage -Message "Establishing initial connection to Backup Server for Microsoft 365: $($System)."
    }

    process {
        #Monkey patch
        Disconnect-VBOServer

        try {
            Write-PScriboMessage -Message "Connecting to $($System) with $($Credential.USERNAME) credentials"
            Connect-VBOServer -Server $System -Credential $Credential -Port $Options.BackupServerPort
        } catch {
            Write-PScriboMessage -IsWarning -Message $_.Exception.Message
            Throw "Failed to connect to Veeam Backup Server Host $($System):$($Options.BackupServerPort) with username $($Credential.USERNAME)"
        }

        Write-PScriboMessage -Message "Successfully connected to $($System):$($Options.BackupServerPort) Backup Server."

    }
    end {}

}
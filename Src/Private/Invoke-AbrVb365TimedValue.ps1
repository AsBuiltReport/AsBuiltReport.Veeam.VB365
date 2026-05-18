function Invoke-AbrVb365TimedValue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Label,

        [Parameter(Mandatory = $true)]
        [scriptblock] $ScriptBlock
    )

    Write-PScriboMessage -Message "Starting $Label."
    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        & $ScriptBlock
    } finally {
        $Stopwatch.Stop()
        Write-PScriboMessage -Message ("Completed {0} in {1:n2}s." -f $Label, $Stopwatch.Elapsed.TotalSeconds)
    }
}

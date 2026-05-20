function ConvertTo-TextYN {
    <#
    .SYNOPSIS
        Used by As Built Report to convert true or false automatically to Yes or No.
    .DESCRIPTION

    .NOTES
        Version:        0.3.0
        Author:         LEE DAILEY

    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    [OutputType([String])]
    param (
        [Parameter (
            Position = 0,
            Mandatory)]
        [AllowEmptyString()]
        [string] $TEXT
    )

    switch ($TEXT) {
        '' { '--'; break }
        ' ' { '--'; break }
        $Null { '--'; break }
        'True' { 'Yes'; break }
        'False' { 'No'; break }
        default { $TEXT }
    }
} # end
function Get-UnixDate ($UnixDate) {
    <#
    .SYNOPSIS
    Used by As Built Report to convert Date to a more nice format.
    .DESCRIPTION
    .NOTES
        Version:        0.2.0
        Author:         LEE DAILEY
    .EXAMPLE
    .LINK
    #>
    [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($UnixDate))
} # end
function ConvertTo-EmptyToFiller {
    <#
    .SYNOPSIS
    Used by As Built Report to convert empty culumns to "-".
    .DESCRIPTION
    .NOTES
        Version:        0.4.0
        Author:         Jonathan Colon
    .EXAMPLE
    .LINK
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param
    (
        [Parameter (
            Position = 0,
            Mandatory)]
        [AllowEmptyString()]
        [string]$TEXT
    )

    switch ([string]::IsNullOrEmpty($TEXT)) {
        $true { '--'; break }
        default { $TEXT }
    }
} # end

function ConvertTo-FileSizeString {
    <#
    .SYNOPSIS
    Used by As Built Report to convert bytes automatically to GB or TB based on size.
    .DESCRIPTION
    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon
    .EXAMPLE
    .LINK
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param
    (
        [Parameter (
            Position = 0,
            Mandatory)]
        [int64] $Size,
        [Parameter(
            Position = 1,
            Mandatory = $false,
            HelpMessage = 'Please provide the source space unit'
        )]
        [ValidateSet('MB', 'GB', 'TB', 'PB')]
        [string] $SourceSpaceUnit,
        [Parameter(
            Position = 2,
            Mandatory = $false,
            HelpMessage = 'Please provide the space unit to output'
        )]
        [ValidateSet('MB', 'GB', 'TB', 'PB')]
        [string] $TargetSpaceUnit,
        [Parameter(
            Position = 3,
            Mandatory = $false,
            HelpMessage = 'Please provide the value to round the storage unit'
        )]
        [int] $RoundUnits = 0
    )

    if ($Options.RoundUnits) {
        $RoundUnits = $Options.RoundUnits
    }

    if ($SourceSpaceUnit) {
        return "$([math]::Round(($Size * $('1' + $SourceSpaceUnit) / $('1' + $TargetSpaceUnit)), $RoundUnits)) $TargetSpaceUnit"
    } else {
        $Unit = switch ($Size) {
            { $Size -gt 1PB } { 'PB' ; break }
            { $Size -gt 1TB } { 'TB' ; break }
            { $Size -gt 1GB } { 'GB' ; break }
            { $Size -gt 1Mb } { 'MB' ; break }
            default { 'KB' }
        }
        return "$([math]::Round(($Size / $('1' + $Unit)), $RoundUnits)) $Unit"
    }
} # end

function Convert-Size {
    [cmdletbinding()]
    param(
        [validateset('Bytes', 'KB', 'MB', 'GB', 'TB')]
        [string]$From,
        [validateset('Bytes', 'KB', 'MB', 'GB', 'TB')]
        [string]$To,
        [Parameter(Mandatory = $true)]
        [double]$Value,
        [int]$Precision = 4
    )
    switch ($From) {
        'Bytes' { $value = $Value }
        'KB' { $value = $Value * 1024 }
        'MB' { $value = $Value * 1024 * 1024 }
        'GB' { $value = $Value * 1024 * 1024 * 1024 }
        'TB' { $value = $Value * 1024 * 1024 * 1024 * 1024 }
    }

    switch ($To) {
        'Bytes' { return $value }
        'KB' { $Value = $Value / 1KB }
        'MB' { $Value = $Value / 1MB }
        'GB' { $Value = $Value / 1GB }
        'TB' { $Value = $Value / 1TB }

    }

    return [Math]::Round($value, $Precision, [MidPointRounding]::AwayFromZero)
}
function Get-AbrVb365InfoLevelValue {
    [CmdletBinding()]
    [OutputType([int])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Scope,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(Mandatory = $false)]
        [string[]] $Alias = @(),

        [Parameter(Mandatory = $false)]
        [int] $Default = 0
    )

    $Config = $script:InfoLevel
    if (-not $Config) {
        $Config = $InfoLevel
    }

    $ScopeObject = Get-AbrVb365PropertyValue -InputObject $Config -Name $Scope
    if (-not $ScopeObject) {
        return $Default
    }

    foreach ($PropertyName in @($Name) + $Alias) {
        $Property = $ScopeObject.PSObject.Properties[$PropertyName]
        if ($Property) {
            $Value = $Property.Value
            if ($null -eq $Value -or "$Value" -eq '') {
                return $Default
            }

            try {
                return [int]$Value
            } catch {
                Write-PScriboMessage -IsWarning -Message "InfoLevel value '$Scope.$PropertyName' is not numeric: $Value"
                return $Default
            }
        }
    }

    $SiblingLevels = @()
    foreach ($Property in $ScopeObject.PSObject.Properties) {
        if ($Property.Name -like '_*') {
            continue
        }

        if ($null -eq $Property.Value -or "$($Property.Value)" -eq '') {
            continue
        }

        try {
            $SiblingLevels += [int]$Property.Value
        } catch {
            continue
        }
    }

    if ($SiblingLevels) {
        $FallbackLevel = ($SiblingLevels | Measure-Object -Maximum).Maximum
        if ($FallbackLevel -gt 0) {
            Write-PScriboMessage -Message "InfoLevel value '$Scope.$Name' was not found. Using $Scope fallback level $FallbackLevel."
            return [int]$FallbackLevel
        }
    }

    return $Default
}
# Used for debugging
function Get-VB365DebugObject {

    [CmdletBinding()]
    param (
    )

    $script:RestoreOperators = @{
        Name = 'RestoreOperators1', 'RestoreOperators2', 'RestoreOperators3', 'RestoreOperators4', 'RestoreOperators5', 'RestoreOperators6', 'RestoreOperators7'
    }

    $script:Proxies = @{
        HostName = 'Proxy1', 'Proxy2', 'Proxy3', 'Proxy4', 'Proxy5', 'Proxy6', 'Proxy7'
    }

    $script:RestorePortal = @{
        IsServiceEnabled = $true
        PortalUri = 'https://publicurl.internet.com:4443'
    }

    $script:Repositories = @{
        Name = 'Repository1', 'Repository2', 'Repository3', 'Repository4', 'Repository5', 'Repository6', 'Repository7'
    }


    $script:ObjectRepositories = @{
        Name = 'ObjectRepositor1', 'ObjectRepositor2', 'ObjectRepositor3', 'ObjectRepositor4', 'ObjectRepositor5', 'ObjectRepositor6', 'ObjectRepositor7'
    }

    $script:Organizations = @()
    $inOrganizationOffice365Obj = [ordered] @{
        Name = 'ObjectRepositor1', 'ObjectRepositor2', 'ObjectRepositor3', 'ObjectRepositor7', 'ObjectRepositor8', 'ObjectRepositor9'
        Type = 'Office365'
    }

    $inOrganizationOnPremisesObj = [ordered] @{
        Name = 'ObjectRepositor4', 'ObjectRepositor5', 'ObjectRepositor6', 'ObjectRepositor10', 'ObjectRepositor11', 'ObjectRepositor12'
        Type = 'OnPremises'
    }

    $Organizations += [PSCustomObject]$inOrganizationOffice365Obj
    $Organizations += [PSCustomObject]$inOrganizationOnPremisesObj
}

function ConvertTo-HashToYN {
    <#
    .SYNOPSIS
        Used by As Built Report to convert array content true or false automatically to Yes or No.
    .DESCRIPTION

    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon

    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param (
        [Parameter (Position = 0, Mandatory)]
        [AllowEmptyString()]
        [Hashtable] $TEXT
    )

    $result = [ordered] @{}
    foreach ($i in $inObj.GetEnumerator()) {
        try {
            $result.add($i.Key, (ConvertTo-TextYN $i.Value))
        } catch {
            $result.add($i.Key, ($i.Value))
        }
    }
    if ($result) {
        return $result
    } else { return $TEXT }
} # end

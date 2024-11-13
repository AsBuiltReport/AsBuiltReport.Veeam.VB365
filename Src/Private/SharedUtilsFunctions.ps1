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
    Param (
        [Parameter (
            Position = 0,
            Mandatory)]
        [AllowEmptyString()]
        [string] $TEXT
    )

    switch ($TEXT) {
        "" { "--"; break }
        " " { "--"; break }
        $Null { "--"; break }
        "True" { "Yes"; break }
        "False" { "No"; break }
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
        Version:        0.5.0
        Author:         Jonathan Colon
    .EXAMPLE
    .LINK
    #>
    [CmdletBinding()]
    [OutputType([String])]
    Param
    (
        [Parameter (
            Position = 0,
            Mandatory)]
        [AllowEmptyString()]
        [string]$TEXT
    )

    switch ([string]::IsNullOrEmpty($TEXT)) {
        $true { "--"; break }
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
    Param
    (
        [Parameter (
            Position = 0,
            Mandatory)]
        [int64]
        $Size
    )

    $Unit = Switch ($Size) {
        { $Size -gt 1PB } { 'PB' ; Break }
        { $Size -gt 1TB } { 'TB' ; Break }
        { $Size -gt 1GB } { 'GB' ; Break }
        { $Size -gt 1Mb } { 'MB' ; Break }
        Default { 'KB' }
    }
    return "$([math]::Round(($Size / $("1" + $Unit)), 0)) $Unit"
} # end

function Convert-Size {
    [cmdletbinding()]
    param(
        [validateset("Bytes", "KB", "MB", "GB", "TB")]
        [string]$From,
        [validateset("Bytes", "KB", "MB", "GB", "TB")]
        [string]$To,
        [Parameter(Mandatory = $true)]
        [double]$Value,
        [int]$Precision = 4
    )
    switch ($From) {
        "Bytes" { $value = $Value }
        "KB" { $value = $Value * 1024 }
        "MB" { $value = $Value * 1024 * 1024 }
        "GB" { $value = $Value * 1024 * 1024 * 1024 }
        "TB" { $value = $Value * 1024 * 1024 * 1024 * 1024 }
    }

    switch ($To) {
        "Bytes" { return $value }
        "KB" { $Value = $Value / 1KB }
        "MB" { $Value = $Value / 1MB }
        "GB" { $Value = $Value / 1GB }
        "TB" { $Value = $Value / 1TB }

    }

    return [Math]::Round($value, $Precision, [MidPointRounding]::AwayFromZero)
}
function Get-PieChart {
    <#
    .SYNOPSIS
    Used by As Built Report to generate PScriboChart pie charts.
    .DESCRIPTION
    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon
    .EXAMPLE
    .LINK
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    Param
    (
        [Parameter (
            Position = 0,
            Mandatory)]
        [System.Array]
        $SampleData,
        [String]
        $ChartName,
        [String]
        $XField,
        [String]
        $YField,
        [String]
        $ChartLegendName,
        [String]
        $ChartLegendAlignment = 'Center',
        [String]
        $ChartTitleName = ' ',
        [String]
        $ChartTitleText = ' ',
        [int]
        $Width = 600,
        [int]
        $Height = 400,
        [Switch]
        $Status,
        [bool]
        $ReversePalette = $false
    )

    $StatusCustomPalette = @(
        [System.Drawing.ColorTranslator]::FromHtml('#DFF0D0')
        [System.Drawing.ColorTranslator]::FromHtml('#FFF4C7')
        [System.Drawing.ColorTranslator]::FromHtml('#FEDDD7')
        [System.Drawing.ColorTranslator]::FromHtml('#878787')
    )

    $AbrCustomPalette = @(
        [System.Drawing.ColorTranslator]::FromHtml('#d5e2ff')
        [System.Drawing.ColorTranslator]::FromHtml('#bbc9e9')
        [System.Drawing.ColorTranslator]::FromHtml('#a2b1d3')
        [System.Drawing.ColorTranslator]::FromHtml('#8999bd')
        [System.Drawing.ColorTranslator]::FromHtml('#7082a8')
        [System.Drawing.ColorTranslator]::FromHtml('#586c93')
        [System.Drawing.ColorTranslator]::FromHtml('#40567f')
        [System.Drawing.ColorTranslator]::FromHtml('#27416b')
        [System.Drawing.ColorTranslator]::FromHtml('#072e58')
    )

    $VeeamCustomPalette = @(
        [System.Drawing.ColorTranslator]::FromHtml('#ddf6ed')
        [System.Drawing.ColorTranslator]::FromHtml('#c3e2d7')
        [System.Drawing.ColorTranslator]::FromHtml('#aacec2')
        [System.Drawing.ColorTranslator]::FromHtml('#90bbad')
        [System.Drawing.ColorTranslator]::FromHtml('#77a898')
        [System.Drawing.ColorTranslator]::FromHtml('#5e9584')
        [System.Drawing.ColorTranslator]::FromHtml('#458370')
        [System.Drawing.ColorTranslator]::FromHtml('#2a715d')
        [System.Drawing.ColorTranslator]::FromHtml('#005f4b')
    )

    $exampleChart = New-Chart -Name $ChartName -Width $Width -Height $Height

    $addChartAreaParams = @{
        Chart = $exampleChart
        Name = 'exampleChartArea'
    }
    $exampleChartArea = Add-ChartArea @addChartAreaParams -PassThru

    if ($Status) {
        $CustomPalette = $StatusCustomPalette
    } elseif ($Options.ReportStyle -eq 'Veeam') {
        $CustomPalette = $VeeamCustomPalette

    } else {
        $CustomPalette = $AbrCustomPalette
    }

    $addChartSeriesParams = @{
        Chart = $exampleChart
        ChartArea = $exampleChartArea
        Name = 'exampleChartSeries'
        XField = $XField
        YField = $YField
        CustomPalette = $CustomPalette
        ColorPerDataPoint = $true
        ReversePalette = $ReversePalette
    }

    $sampleData | Add-PieChartSeries @addChartSeriesParams

    $addChartLegendParams = @{
        Chart = $exampleChart
        Name = $ChartLegendName
        TitleAlignment = $ChartLegendAlignment
    }
    Add-ChartLegend @addChartLegendParams

    $addChartTitleParams = @{
        Chart = $exampleChart
        ChartArea = $exampleChartArea
        Name = $ChartTitleName
        Text = $ChartTitleText
        Font = New-Object -TypeName 'System.Drawing.Font' -ArgumentList @('Segoe Ui', '12', [System.Drawing.FontStyle]::Bold)
    }
    Add-ChartTitle @addChartTitleParams

    $TempPath = Resolve-Path ([System.IO.Path]::GetTempPath())

    $ChartImage = Export-Chart -Chart $exampleChart -Path $TempPath.Path -Format "PNG" -PassThru

    $Base64Image = [convert]::ToBase64String((Get-Content $ChartImage -Encoding byte))

    Remove-Item -Path $ChartImage.FullName

    return $Base64Image

} # end

function Get-ColumnChart {
    <#
    .SYNOPSIS
    Used by As Built Report to generate PScriboChart column charts.
    .DESCRIPTION
    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon
    .EXAMPLE
    .LINK
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    Param
    (
        [Parameter (
            Position = 0,
            Mandatory)]
        [System.Array]
        $SampleData,
        [String]
        $ChartName,
        [String]
        $AxisXTitle,
        [String]
        $AxisYTitle,
        [String]
        $XField,
        [String]
        $YField,
        [String]
        $ChartAreaName,
        [String]
        $ChartTitleName = ' ',
        [String]
        $ChartTitleText = ' ',
        [int]
        $Width = 600,
        [int]
        $Height = 400,
        [Switch]
        $Status,
        [bool]
        $ReversePalette = $false
    )

    $StatusCustomPalette = @(
        [System.Drawing.ColorTranslator]::FromHtml('#DFF0D0')
        [System.Drawing.ColorTranslator]::FromHtml('#FFF4C7')
        [System.Drawing.ColorTranslator]::FromHtml('#FEDDD7')
        [System.Drawing.ColorTranslator]::FromHtml('#878787')
    )

    $AbrCustomPalette = @(
        [System.Drawing.ColorTranslator]::FromHtml('#d5e2ff')
        [System.Drawing.ColorTranslator]::FromHtml('#bbc9e9')
        [System.Drawing.ColorTranslator]::FromHtml('#a2b1d3')
        [System.Drawing.ColorTranslator]::FromHtml('#8999bd')
        [System.Drawing.ColorTranslator]::FromHtml('#7082a8')
        [System.Drawing.ColorTranslator]::FromHtml('#586c93')
        [System.Drawing.ColorTranslator]::FromHtml('#40567f')
        [System.Drawing.ColorTranslator]::FromHtml('#27416b')
        [System.Drawing.ColorTranslator]::FromHtml('#072e58')
    )

    $VeeamCustomPalette = @(
        [System.Drawing.ColorTranslator]::FromHtml('#ddf6ed')
        [System.Drawing.ColorTranslator]::FromHtml('#c3e2d7')
        [System.Drawing.ColorTranslator]::FromHtml('#aacec2')
        [System.Drawing.ColorTranslator]::FromHtml('#90bbad')
        [System.Drawing.ColorTranslator]::FromHtml('#77a898')
        [System.Drawing.ColorTranslator]::FromHtml('#5e9584')
        [System.Drawing.ColorTranslator]::FromHtml('#458370')
        [System.Drawing.ColorTranslator]::FromHtml('#2a715d')
        [System.Drawing.ColorTranslator]::FromHtml('#005f4b')
    )

    $exampleChart = New-Chart -Name $ChartName -Width $Width -Height $Height

    $addChartAreaParams = @{
        Chart = $exampleChart
        Name = $ChartAreaName
        AxisXTitle = $AxisXTitle
        AxisYTitle = $AxisYTitle
        NoAxisXMajorGridLines = $true
        NoAxisYMajorGridLines = $true
    }
    $exampleChartArea = Add-ChartArea @addChartAreaParams -PassThru

    if ($Status) {
        $CustomPalette = $StatusCustomPalette
    } elseif ($Options.ReportStyle -eq 'Veeam') {
        $CustomPalette = $VeeamCustomPalette

    } else {
        $CustomPalette = $AbrCustomPalette
    }

    $addChartSeriesParams = @{
        Chart = $exampleChart
        ChartArea = $exampleChartArea
        Name = 'exampleChartSeries'
        XField = $XField
        YField = $YField
        CustomPalette = $CustomPalette
        ColorPerDataPoint = $true
        ReversePalette = $ReversePalette
    }

    $sampleData | Add-ColumnChartSeries @addChartSeriesParams

    $addChartTitleParams = @{
        Chart = $exampleChart
        ChartArea = $exampleChartArea
        Name = $ChartTitleName
        Text = $ChartTitleText
        Font = New-Object -TypeName 'System.Drawing.Font' -ArgumentList @('Segoe Ui', '12', [System.Drawing.FontStyle]::Bold)
    }
    Add-ChartTitle @addChartTitleParams

    $TempPath = Resolve-Path ([System.IO.Path]::GetTempPath())

    $ChartImage = Export-Chart -Chart $exampleChart -Path $TempPath.Path -Format "PNG" -PassThru

    if ($PassThru) {
        Write-Output -InputObject $chartFileItem
    }

    $Base64Image = [convert]::ToBase64String((Get-Content $ChartImage -Encoding byte))

    Remove-Item -Path $ChartImage.FullName

    return $Base64Image

} # end

# Used for debugging
function Get-VB365DebugObject {

    [CmdletBinding()]
    param (
    )

    $script:RestoreOperators = @{
        Name = "RestoreOperators1", "RestoreOperators2", "RestoreOperators3", "RestoreOperators4", "RestoreOperators5", "RestoreOperators6", "RestoreOperators7"
    }

    $script:Proxies = @{
        HostName = "Proxy1", "Proxy2", "Proxy3", "Proxy4", "Proxy5", "Proxy6", "Proxy7"
    }

    $script:RestorePortal = @{
        IsServiceEnabled = $true
        PortalUri = "https://publicurl.internet.com:4443"
    }

    $script:Repositories = @{
        Name = "Repository1", "Repository2", "Repository3", "Repository4", "Repository5", "Repository6", "Repository7"
    }


    $script:ObjectRepositories = @{
        Name = "ObjectRepositor1", "ObjectRepositor2", "ObjectRepositor3", "ObjectRepositor4", "ObjectRepositor5", "ObjectRepositor6", "ObjectRepositor7"
    }

    $script:Organizations = @()
    $inOrganizationOffice365Obj = [ordered] @{
        Name = "ObjectRepositor1", "ObjectRepositor2", "ObjectRepositor3", "ObjectRepositor7", "ObjectRepositor8", "ObjectRepositor9"
        Type = "Office365"
    }

    $inOrganizationOnPremisesObj = [ordered] @{
        Name = "ObjectRepositor4", "ObjectRepositor5", "ObjectRepositor6", "ObjectRepositor10", "ObjectRepositor11", "ObjectRepositor12"
        Type = "OnPremises"
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
    Param (
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
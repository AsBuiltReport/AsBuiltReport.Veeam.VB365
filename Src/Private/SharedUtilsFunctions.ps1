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
    Param
    (
        [Parameter (
            Position = 0,
            Mandatory)]
        [AllowEmptyString()]
        [string]
        $TEXT
    )

    switch ($TEXT) {
        "" { "-" }
        $Null { "-" }
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
        Version:        0.4.0
        Author:         LEE DAILEY
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

    switch ($Size) {
        { $_ -gt 1TB }
        { [string]::Format("{0:0} TB", $Size / 1TB); break }
        { $_ -gt 1GB }
        { [string]::Format("{0:0} GB", $Size / 1GB); break }
        { $_ -gt 1MB }
        { [string]::Format("{0:0} MB", $Size / 1MB); break }
        { $_ -gt 1KB }
        { [string]::Format("{0:0} KB", $Size / 1KB); break }
        { $_ -gt 0 }
        { [string]::Format("{0} B", $Size); break }
        { $_ -eq 0 }
        { "0 KB"; break }
        default
        { "0 KB" }
    }
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
        $Height = 400
    )

    $exampleChart = New-Chart -Name $ChartName -Width $Width -Height $Height

    $addChartAreaParams = @{
        Chart = $exampleChart
        Name = 'exampleChartArea'
    }
    $exampleChartArea = Add-ChartArea @addChartAreaParams -PassThru

    $addChartSeriesParams = @{
        Chart = $exampleChart
        ChartArea = $exampleChartArea
        Name = 'exampleChartSeries'
        XField = $XField
        YField = $YField
        Palette = 'Grren'
        ColorPerDataPoint = $true
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
        Font = New-Object -TypeName 'System.Drawing.Font' -ArgumentList @('Arial', '12', [System.Drawing.FontStyle]::Bold)
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
        $Height = 400
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

    $addChartSeriesParams = @{
        Chart = $exampleChart
        ChartArea = $exampleChartArea
        Name = 'exampleChartSeries'
        XField = $XField
        YField = $YField
        Palette = 'Green'
        ColorPerDataPoint = $true
    }
    $sampleData | Add-ColumnChartSeries @addChartSeriesParams

    $addChartTitleParams = @{
        Chart = $exampleChart
        ChartArea = $exampleChartArea
        Name = $ChartTitleName
        Text = $ChartTitleText
        Font = New-Object -TypeName 'System.Drawing.Font' -ArgumentList @('Arial', '12', [System.Drawing.FontStyle]::Bold)
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
function Get-AbrVb365Diagram {
    <#
    .SYNOPSIS
        Diagram the configuration of Veeam Backup for Microsoft 365 infrastructure in PDF/SVG/DOT/PNG formats using PSGraph and Graphviz.
    .DESCRIPTION
        Diagram the configuration of Veeam Backup for Microsoft 365 infrastructure in PDF/SVG/DOT/PNG formats using PSGraph and Graphviz.
    .PARAMETER DiagramType
        Specifies the type of veeam vbr diagram that will be generated.
        The supported output diagrams are:
            Backup-to-All'
    .PARAMETER Target
        Specifies the IP/FQDN of the system to connect.
        Multiple targets may be specified, separated by a comma.
    .PARAMETER Port
        Specifies a optional port to connect to Veeam VBR Service.
        By default, port will be set to 9392
    .PARAMETER Credential
        Specifies the stored credential of the target system.
    .PARAMETER Username
        Specifies the username for the target system.
    .PARAMETER Password
        Specifies the password for the target system.
    .PARAMETER Format
        Specifies the output format of the diagram.
        The supported output formats are PDF, PNG, DOT & SVG.
        Multiple output formats may be specified, separated by a comma.
    .PARAMETER Direction
        Set the direction in which resource are plotted on the visualization
        The supported directions are:
            'top-to-bottom', 'left-to-right'
        By default, direction will be set to top-to-bottom.
    .PARAMETER NodeSeparation
        Controls Node separation ratio in visualization
        By default, NodeSeparation will be set to .60.
    .PARAMETER SectionSeparation
        Controls Section (Subgraph) separation ratio in visualization
        By default, NodeSeparation will be set to .75.
    .PARAMETER EdgeType
        Controls how edges lines appear in visualization
        The supported edge type are:
            'polyline', 'curved', 'ortho', 'line', 'spline'
        By default, EdgeType will be set to spline.
        References: https://graphviz.org/docs/attrs/splines/
    .PARAMETER OutputFolderPath
        Specifies the folder path to save the diagram.
    .PARAMETER Filename
        Specifies a filename for the diagram.
    .PARAMETER EnableEdgeDebug
        Control to enable edge debugging ( Dummy Edge and Node lines ).
    .PARAMETER EnableSubGraphDebug
        Control to enable subgraph debugging ( Subgraph Lines ).
    .PARAMETER EnableErrorDebug
        Control to enable error debugging.
    .PARAMETER AuthorName
        Allow to set footer signature Author Name.
    .PARAMETER CompanyName
        Allow to set footer signature Company Name.
    .PARAMETER Logo
        Allow to change the Veeam logo to a custom one.
        Image should be 400px x 100px or less in size.
    .PARAMETER SignatureLogo
        Allow to change the Vb365.Diagrammer signature logo to a custom one.
        Image should be 120px x 130px or less in size.
    .PARAMETER Signature
        Allow the creation of footer signature.
        AuthorName and CompanyName must be set to use this property.
    .NOTES
        Version:        0.5.9
        Author(s):      Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
        Credits:        Kevin Marquette (@KevinMarquette) -  PSGraph module
        Credits:        Prateek Singh (@PrateekKumarSingh) - AzViz module
    .LINK
        https://github.com/rebelinux/
        https://github.com/KevinMarquette/PSGraph
        https://github.com/PrateekKumarSingh/AzViz
    #>

    [Diagnostics.CodeAnalysis.SuppressMessage(
        'PSUseShouldProcessForStateChangingFunctions',
        ''
    )]

    [CmdletBinding(
        PositionalBinding = $false,
        DefaultParameterSetName = 'Credential'
    )]
    param (

        [Parameter(
            Position = 0,
            Mandatory = $true,
            HelpMessage = 'Please provide the IP/FQDN of the system'
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('Server', 'IP')]
        [String[]] $Target,

        [Parameter(
            Position = 1,
            Mandatory = $true,
            HelpMessage = 'Please provide credentials to connect to the system',
            ParameterSetName = 'Credential'
        )]
        [ValidateNotNullOrEmpty()]
        [PSCredential] $Credential,

        [Parameter(
            Position = 4,
            Mandatory = $false,
            HelpMessage = 'Please provide the diagram output format'
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('pdf', 'svg', 'png', 'dot', 'base64', 'jpg')]
        [Array] $Format = 'pdf',

        [Parameter(
            Position = 5,
            Mandatory = $false,
            HelpMessage = 'TCP Port of target Veeam Backup for Microsoft 365'
        )]
        [string] $Port = '9191',

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Direction in which resource are plotted on the visualization'
        )]
        [ValidateSet('left-to-right', 'top-to-bottom')]
        [string] $Direction = 'top-to-bottom',

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Please provide the path to the diagram output file'
        )]
        [ValidateScript( {
                if (Test-Path -Path $_) {
                    $true
                } else {
                    throw "Path $_ not found!"
                }
            })]
        [string] $OutputFolderPath = [System.IO.Path]::GetTempPath(),

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Please provide the path to the custom logo used for Signature'
        )]
        [ValidateScript( {
                if (Test-Path -Path $_) {
                    $true
                } else {
                    throw "File $_ not found!"
                }
            })]
        [string] $SignatureLogo,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Please provide the path to the custom logo'
        )]
        [ValidateScript( {
                if (Test-Path -Path $_) {
                    $true
                } else {
                    throw "File $_ not found!"
                }
            })]
        [string] $Logo,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Specify the Diagram filename'
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                if (($Format | Measure-Object).count -lt 2) {
                    $true
                } else {
                    throw "Format value must be unique if Filename is especified."
                }
            })]
        [String] $Filename,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Controls how edges lines appear in visualization'
        )]
        [ValidateSet('polyline', 'curved', 'ortho', 'line', 'spline')]
        [string] $EdgeType = 'spline',

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Controls Node separation ratio in visualization'
        )]
        [ValidateSet(0, 1, 2, 3)]
        [string] $NodeSeparation = .60,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Controls Section (Subgraph) separation ratio in visualization'
        )]
        [ValidateSet(0, 1, 2, 3)]
        [string] $SectionSeparation = .75,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Controls type of Veeam VB365 generated diagram'
        )]
        [ValidateSet('Backup-to-Tape', 'Backup-to-File-Proxy', 'Backup-to-HyperV-Proxy', 'Backup-to-vSphere-Proxy', 'Backup-to-Repository', 'Backup-to-Sobr', 'Backup-to-WanAccelerator', 'Backup-to-ProtectedGroup', 'Backup-to-All')]
        [string] $DiagramType,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Allow to enable edge debugging ( Dummy Edge and Node lines)'
        )]
        [Switch] $EnableEdgeDebug = $false,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Allow to enable subgraph debugging ( Subgraph Lines )'
        )]
        [Switch] $EnableSubGraphDebug = $false,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Allow to enable error debugging'
        )]
        [Switch] $EnableErrorDebug = $false,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Allow to set footer signature Author Name'
        )]
        [string] $AuthorName,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Allow to set footer signature Company Name'
        )]
        [string] $CompanyName,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Allow the creation of footer signature'
        )]
        [Switch] $Signature = $false
    )


    begin {

        $script:Images = @{
            "VBR_Server" = "VBR_server.png"
            "VBR_Repository" = "VBR_Repository.png"
            "VBR_Deduplicating_Storage" = "Deduplicating_Storage.png"
            "VBR_Linux_Repository" = "Linux_Repository.png"
            "VBR_Windows_Repository" = "Windows_Repository.png"
            "VBR_Cloud_Repository" = "Cloud_Repository.png"
            "VBR_Server_DB" = "Microsoft_SQL_DB.png"
            "VBR_Proxy_Server" = "Proxy_Server.png"
            "VBR_Wan_Accel" = "WAN_accelerator.png"
            "VBR_SOBR" = "Scale-out_Backup_Repository.png"
            "VBR_LOGO" = "Veeam_logo.png"
            "VBR_No_Icon" = "no_icon.png"
            'VBR_Storage_NetApp' = "Storage_NetApp.png"
            'VBR_vCenter_Server' = 'vCenter_server.png'
            'VBR_ESXi_Server' = 'ESXi_host.png'
            'VBR_HyperV_Server' = 'Hyper-V_host.png'
            'VBR_Server_EM' = 'Veeam_Backup_Enterprise_Manager.png'
            'VBR_Tape_Server' = 'Tape_Server.png'
            'VBR_Tape_Library' = 'Tape_Library.png'
            'VBR_Tape_Drive' = 'Tape_Drive.png'
            "VBR_Server_DB_PG" = "PostGre_SQL_DB.png"
            "VB365_LOGO_Footer" = "verified_recoverability.png"
            "VBR_AGENT_Container" = "Folder.png"
            "VBR_AGENT_AD" = "Server.png"
            "VBR_AGENT_MC" = "Task list.png"
            "VBR_AGENT_IC" = "Workstation.png"
            "VBR_AGENT_CSV" = "CSV_Computers.png"
            "VBR_AGENT_AD_Logo" = "Microsoft Active Directory.png"
            "VBR_AGENT_CSV_Logo" = "File.png"
            "VBR_AGENT_Server" = "Server_with_Veeam_Agent.png"
        }

        if (($Format -ne "base64") -and !(Test-Path $OutputFolderPath)) {
            Write-Error "OutputFolderPath '$OutputFolderPath' is not a valid folder path."
            break
        }

        if ($Signature -and (([string]::IsNullOrEmpty($AuthorName)) -or ([string]::IsNullOrEmpty($CompanyName)))) {
            throw "Get-AbrVb365Diagram: AuthorName and CompanyName must be defined if the Signature option is specified"
        }

        $MainGraphLabel = Switch ($DiagramType) {
            'Backup-to-All' { 'Backup for Microsoft 365 Infrastructure' }
        }

        $URLIcon = $false

        if ($EnableEdgeDebug) {
            $script:EdgeDebug = @{style = 'filled'; color = 'red' }
            $URLIcon = $true
        } else { $script:EdgeDebug = @{style = 'invis'; color = 'red' } }

        if ($EnableSubGraphDebug) {
            $script:SubGraphDebug = @{style = 'dashed'; color = 'red' }
            $URLIcon = $true
        } else { $script:SubGraphDebug = @{style = 'invis'; color = 'gray' } }

        $RootPath = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
        $IconPath = Join-Path $RootPath 'icons'
        $Dir = switch ($Direction) {
            'top-to-bottom' { 'TB' }
            'left-to-right' { 'LR' }
        }

        # Validate Custom logo
        if ($Logo) {
            $CustomLogo = Test-Logo -LogoPath (Get-ChildItem -Path $Logo).FullName -IconPath $IconPath -ImagesObj $Images
        } else {
            $CustomLogo = "VBR_LOGO"
        }
        # Validate Custom Signature Logo
        if ($SignatureLogo) {
            $CustomSignatureLogo = Test-Logo -LogoPath (Get-ChildItem -Path $SignatureLogo).FullName -IconPath $IconPath -ImagesObj $Images
        }

        $MainGraphAttributes = @{
            pad = 1.0
            rankdir = $Dir
            overlap = 'false'
            splines = $EdgeType
            penwidth = 1.5
            fontname = "Segoe Ui Black"
            fontcolor = '#005f4b'
            fontsize = 32
            style = "dashed"
            labelloc = 't'
            imagepath = $IconPath
            nodesep = $NodeSeparation
            ranksep = $SectionSeparation
        }
    }

    process {

        $script:Graph = Graph -Name VeeamVB365 -Attributes $MainGraphAttributes {
            # Node default theme
            Node @{
                label = ''
                shape = 'none'
                labelloc = 't'
                style = 'filled'
                fillColor = 'white'
                fontsize = 14;
                imagescale = $true
            }
            # Edge default theme
            Edge @{
                style = 'dashed'
                dir = 'both'
                arrowtail = 'dot'
                color = '#71797E'
                penwidth = 1.5
                arrowsize = 1
            }

            if ($Signature) {
                if ($CustomSignatureLogo) {
                    $Signature = (Get-HtmlTable -Rows "Author: $($AuthorName)", "Company: $($CompanyName)" -TableBorder 2 -CellBorder 0 -align 'left' -Logo $CustomSignatureLogo)
                } else {
                    $Signature = (Get-HtmlTable -Rows "Author: $($AuthorName)", "Company: $($CompanyName)" -TableBorder 2 -CellBorder 0 -align 'left' -Logo "VB365_LOGO_Footer")
                }
            } else {
                $Signature = " "
            }

            SubGraph OUTERDRAWBOARD1 -Attributes @{Label = $Signature; fontsize = 24; penwidth = 1.5; labelloc = 'b'; labeljust = "r"; style = $SubGraphDebug.style; color = $SubGraphDebug.color } {
                SubGraph MainGraph -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label $MainGraphLabel -IconType $CustomLogo -URLIcon $URLIcon -IconWidth 250 -IconHeight 80); fontsize = 24; penwidth = 0; labelloc = 't'; labeljust = "c" } {

                    if ($DiagramType -eq 'Backup-to-All') {

                        $ServerVersion = @{
                            'Version' = (Get-VBOVersion).ProductVersion
                        }

                        Node VB365Server @{Label = Get-DiaNodeIcon -Rows $ServerVersion -ImagesObj $Images -Name $VeeamBackupServer -IconType "VBR_Server" -Align "Center" -URLIcon $URLIcon; shape = 'plain'; fillColor = 'transparent'; fontsize = 14 }

                        Node VB365ServerPoint @{shape = "point"; size = 20 }

                        Edge -From VB365Server -To VB365ServerPoint @{minlen = 3; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }

                        # $VB365BackupInfra = Get-DiagVB365BackupInfra | Select-String -Pattern '"([A-Z])\w+"\s\[label="";style="invis";shape="point";]' -NotMatch
                        # if ($VB365BackupInfra) {
                        #     $VB365BackupInfra
                        # } else {
                        #     Write-Warning "No Backup Infrastructure available to diagram"
                        # }
                    }
                }
            }
        }
    }
    end {
        #Export Diagram
        Out-Diagram -GraphObj ($Graph | Select-String -Pattern '"([A-Z])\w+"\s\[label="";style="invis";shape="point";]' -NotMatch) -ErrorDebug $EnableErrorDebug -Rotate $Rotate -Format $Format -Filename $Filename -OutputFolderPath $OutputFolderPath
    }
}
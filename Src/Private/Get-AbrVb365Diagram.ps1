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
        Version:        0.3.0
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
            Position = 4,
            Mandatory = $false,
            HelpMessage = 'Please provide the diagram output format'
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('pdf', 'svg', 'png', 'dot', 'base64', 'jpg')]
        [Array] $Format = 'pdf',

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
        [string] $EdgeType = 'line',

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
            "VB365_Server" = "VBR_server.png"
            "VB365_Proxy_Server" = "Proxy_Server.png"
            "VB365_Proxy" = "Veeam_Proxy.png"
            "VBR_LOGO" = "Veeam_logo.png"
            "VB365_LOGO_Footer" = "verified_recoverability.png"
            "VB365_Repository" = "VBO_Repository.png"
            "VB365_Windows_Repository" = "Windows_Repository.png"
            "VB365_Object_Repository" = "Object_Storage.png"
            "VB365_Object_Support" = "Object Storage support.png"
            "Veeam_Repository" = "Veeam_Repository.png"
            "VB365_On_Premises" = "SMB.png"
            "VB365_Microsoft_365" = "Cloud.png"
        }

        if (($Format -ne "base64") -and !(Test-Path $OutputFolderPath)) {
            Write-Error "OutputFolderPath '$OutputFolderPath' is not a valid folder path."
            break
        }

        if ($Signature -and (([string]::IsNullOrEmpty($AuthorName)) -or ([string]::IsNullOrEmpty($CompanyName)))) {
            throw "Get-AbrVb365Diagram: AuthorName and CompanyName must be defined if the Signature option is specified"
        }

        $MainGraphLabel = Switch ($DiagramType) {
            'Backup-to-All' { 'Backup for Microsoft 365' }
        }

        $URLIcon = $false

        if ($EnableEdgeDebug) {
            $EdgeDebug = @{style = 'filled'; color = 'red' }
            $URLIcon = $true
        } else { $EdgeDebug = @{style = 'invis'; color = 'red' } }

        if ($EnableSubGraphDebug) {
            $SubGraphDebug = @{style = 'dashed'; color = 'red' }
            $NodeDebug = @{color = 'black'; style = 'red'; shape = 'plain' }
            $NodeDebugEdge = @{color = 'black'; style = 'red'; shape = 'plain' }
            $URLIcon = $true
        } else {
            $SubGraphDebug = @{style = 'invis'; color = 'gray' }
            $NodeDebug = @{color = 'transparent'; style = 'transparent'; shape = 'point' }
            $NodeDebugEdge = @{color = 'transparent'; style = 'transparent'; shape = 'none' }
        }

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
            pad = 1
            rankdir = $Dir
            overlap = 'false'
            splines = $EdgeType
            penwidth = 1.5
            fontname = "Tahoma Black"
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
                fillColor = '#71797E'
                fontsize = 14;
                imagescale = $true
            }
            # Edge default theme
            Edge @{
                style = 'dashed'
                dir = 'both'
                arrowtail = 'dot'
                color = '#71797E'
                penwidth = 2
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
                            'Version' = try { (Get-VBOVersion).ProductVersion } catch { 'Unknown' }
                        }

                        # VB365 Server Object
                        Node VB365Server @{Label = Get-DiaNodeIcon -Rows $ServerVersion -ImagesObj $Images -Name $VeeamBackupServer -IconType "VB365_Server" -Align "Center" -URLIcon $URLIcon; shape = 'plain'; fillColor = 'transparent'; fontsize = 14 }

                        # Proxy Graphviz Cluster
                        if ($Proxie) {
                            SubGraph ProxyServer -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Backup Proxies" -IconType "VB365_Proxy" -SubgraphLabel -URLIcon $URLIcon); fontsize = 18; penwidth = 1.5; labelloc = 'b'; style = 'dashed,rounded' } {

                                Node Proxies @{Label = (Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject ($Proxies.HostName | ForEach-Object { $_.split('.')[0] }) -Align "Center" -iconType "VB365_Proxy_Server" -columnSize 3 -URLIcon $URLIcon -MultiIcon); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Tahoma" }
                            }
                        } else {
                            SubGraph ProxyServer -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Backup Proxies" -IconType "VB365_Proxy" -SubgraphLabel -URLIcon $URLIcon); fontsize = 18; penwidth = 1.5; labelloc = 't'; style = 'dashed,rounded' } {

                                Node -Name Proxies -Attributes @{Label = 'No Backup Proxies'; shape = "rectangle"; labelloc = 'c'; fixedsize = $true; width = "3"; height = "2"; fillColor = 'transparent'; penwidth = 0 }
                            }
                        }

                        # Repositories Graphviz Cluster
                        if ($Repositories) {
                            SubGraph Repos -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Backup Repositories" -IconType "VB365_Repository" -SubgraphLabel -URLIcon $URLIcon); fontsize = 18; penwidth = 1.5; labelloc = 'b'; style = 'dashed,rounded' } {

                                Node Repositories @{Label = (Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject $Repositories.Name -Align "Center" -iconType "VB365_Windows_Repository" -columnSize 3 -URLIcon $URLIcon -MultiIcon); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Tahoma" }
                            }
                        } else {
                            SubGraph Repos -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Backup Repositories" -IconType "VB365_Repository" -SubgraphLabel -URLIcon $URLIcon); fontsize = 18; penwidth = 1.5; labelloc = 't'; style = 'dashed,rounded' } {

                                Node -Name Repositories -Attributes @{Label = 'No Backup Repositories'; shape = "rectangle"; labelloc = 'c'; fixedsize = $true; width = "3"; height = "2"; fillColor = 'transparent'; penwidth = 0 }
                            }
                        }

                        # Object Repositories Graphviz Cluster
                        if ($ObjectRepositories) {
                            SubGraph ObjectRepos -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Object Repositories" -IconType "VB365_Object_Support" -SubgraphLabel -URLIcon $URLIcon); fontsize = 18; penwidth = 1.5; labelloc = 't'; style = 'dashed,rounded' } {

                                Node ObjectRepositories @{Label = (Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject $ObjectRepositories.Name -Align "Center" -iconType "VB365_Object_Repository" -columnSize 3 -URLIcon $URLIcon -MultiIcon); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Tahoma" }
                            }
                        } else {
                            SubGraph ObjectRepos -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Object Repositories" -IconType "VB365_Object_Support" -SubgraphLabel -URLIcon $URLIcon); fontsize = 18; penwidth = 1.5; labelloc = 't'; style = 'dashed,rounded' } {

                                Node -Name ObjectRepositories -Attributes @{Label = 'No Object Repositories'; shape = "rectangle"; labelloc = 'c'; fixedsize = $true; width = "3"; height = "2"; fillColor = 'transparent'; penwidth = 0 }
                            }
                        }

                        # Organization Graphviz Cluster
                        SubGraph Organizations -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Organizations" -IconType "VB365_On_Premises" -SubgraphLabel -URLIcon $URLIcon); fontsize = 18; penwidth = 1.5; labelloc = 't'; style = 'dashed,rounded' } {

                            # On-Premises Organization Graphviz Cluster
                            if (($Organizations | Where-Object { $_.Type -eq 'OnPremises' })) {
                                SubGraph OnPremise -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "On-premises" -IconType "VB365_On_Premises" -SubgraphLabel -URLIcon $URLIcon); fontsize = 18; penwidth = 1.5; labelloc = 't'; style = 'dashed,rounded' } {

                                    Node OnpremisesOrg @{Label = (Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject ($Organizations | Where-Object { $_.Type -eq 'OnPremises' }).Name -Align "Center" -iconType "VB365_Object_Repository" -columnSize 3 -URLIcon $URLIcon -MultiIcon); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Tahoma" }
                                }
                            }

                            # Microsoft 365 Organization Graphviz Cluster
                            if ($Organizations | Where-Object { $_.Type -eq 'Office365' }) {
                                SubGraph Microsoft365 -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Microsoft 365" -IconType "VB365_Microsoft_365" -SubgraphLabel -URLIcon $URLIcon); fontsize = 18; penwidth = 1.5; labelloc = 't'; style = 'dashed,rounded' } {

                                    Node Microsoft365Org @{Label = (Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject ($Organizations | Where-Object { $_.Type -eq 'Office365' }).Name -Align "Center" -iconType "VB365_Object_Repository" -columnSize 3 -URLIcon $URLIcon -MultiIcon); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Tahoma" }
                                }
                            }
                        }

                        # Veeam VB365 elements point of connection (Dummy Nodes!)
                        $Node = @('VB365ServerPointSpace', 'VB365ProxyPoint', 'VB365ProxyPointSpace', 'VB365RepoPoint')
                        Node $Node -NodeScript { $_ } @{Label = { $_ } ; fontcolor = $NodeDebug.color; fillColor = $NodeDebug.style; shape = $NodeDebug.shape }

                        $NodeStartEnd = @('VB365StartPoint', 'VB365EndPointSpace')
                        Node $NodeStartEnd -NodeScript { $_ } @{Label = { $_ } ; fontcolor = $NodeDebugEdge.color; fillColor = $NodeDebugEdge.style; shape = $NodeDebugEdge.shape }

                        # Put the dummy node in the same rank to be able to create a horizontal line
                        Rank VB365ServerPointSpace, VB365ProxyPoint, VB365ProxyPointSpace, VB365RepoPoint, VB365StartPoint, VB365EndPointSpace

                        # Connect the Dummy Node in a straight line
                        # VB365StartPoint --- VB365ServerPointSpace --- VB365ProxyPoint --- VB365ProxyPointSpace --- VB365RepoPoint --- VB365EndPointSpace
                        Edge -From VB365StartPoint -To VB365ServerPointSpace @{minlen = 2; arrowtail = 'none'; arrowhead = 'none'; style = $EdgeDebug.style; color = $EdgeDebug.color }
                        Edge -From VB365ServerPointSpace -To VB365ProxyPoint @{minlen = 4; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
                        Edge -From VB365ProxyPoint -To VB365ProxyPointSpace @{minlen = 8; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
                        Edge -From VB365ProxyPointSpace -To VB365RepoPoint @{minlen = 8; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
                        Edge -From VB365RepoPoint -To VB365EndPointSpace @{minlen = 8; arrowtail = 'none'; arrowhead = 'none'; style = $EdgeDebug.style; color = $EdgeDebug.color }

                        # Connect Veeam Backup server to the Dummy line
                        Edge -From VB365Server -To VB365ServerPointSpace @{minlen = 2; arrowtail = 'dot'; arrowhead = 'none'; style = 'filled' }

                        # Connect Veeam Backup Server to Organization Graphviz Cluster
                        if ($Organizations | Where-Object { $_.Type -eq 'OnPremises' }) {
                            Edge -To VB365Server -From OnpremisesOrg @{minlen = 2; arrowtail = 'dot'; arrowhead = 'normal'; style = 'dashed'; color = '#DF8c42' }
                        } elseif ($Organizations | Where-Object { $_.Type -eq 'Office365' }) {
                            Edge -To VB365Server -From Microsoft365Org @{minlen = 2; arrowtail = 'dot'; arrowhead = 'normal'; style = 'dashed'; color = '#DF8c42' }
                        } else {
                            SubGraph Organizations -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Organizations" -IconType "VB365_On_Premises" -SubgraphLabel -URLIcon $URLIcon); fontsize = 18; penwidth = 1.5; labelloc = 't'; style = 'dashed,rounded' } {
                                Node -Name DummyNoOrganization -Attributes @{Label = 'No Organization'; shape = "rectangle"; labelloc = 'c'; fixedsize = $true; width = "3"; height = "2"; fillColor = 'transparent'; penwidth = 0 }
                            }
                            Edge -To VB365Server -From DummyNoOrganization @{minlen = 2; arrowtail = 'dot'; arrowhead = 'normal'; style = 'dashed'; color = '#DF8c42' }
                        }

                        # Connect Veeam Proxies Server to the Dummy line
                        Edge -From VB365ProxyPoint -To Proxies @{minlen = 2; arrowtail = 'none'; arrowhead = 'dot'; style = 'dashed' }

                        # Connect Veeam Repository to the Dummy line
                        Edge -From VB365RepoPoint -To Repositories @{minlen = 2; arrowtail = 'none'; arrowhead = 'dot'; style = 'dashed' }

                        # Connect Veeam Object Repository to the Dummy line
                        Edge -To VB365RepoPoint -From ObjectRepositories @{minlen = 2; arrowtail = 'dot'; arrowhead = 'none'; style = 'dashed' }

                        # End results
                        #
                        #
                        #
                        #
                        #                               |---------------------------------------------------|
                        #                               |  |---------------------------------------------|  |
                        #                               |  |      Subgraph Logo |      Organization      |  |
                        #                               |  |---------------------------------------------|  |
                        #        ----------------------o|  |   Onpremise Table  |  Microsoft 365 Table   |  |
                        #        |                      |  |---------------------------------------------|  |
                        #        |                      |---------------------------------------------------|
                        #        |                                 Organization Graphviz Cluster
                        #        |
                        #       \-/
                        #        |
                        # |--------------|
                        # |     ICON     |
                        # |--------------|
                        # | VB365 Server |
                        # |--------------|
                        # |   Version:   |
                        # |--------------|
                        #       O
                        #       |
                        #       |
                        # VB365StartPoint --- VB365ServerPointSpace --- VB365ProxyPoint --- VB365ProxyPointSpace --- VB365RepoPoint --- VB365EndPointSpace
                        #                                                      |
                        #                                                      |
                        #                                                      O
                        #                                   |------------------------------------|
                        #                                   |  |------------------------------|  |
                        #                                   |  |      ICON    |     ICON      |  |
                        #                                   |  |------------------------------|  |
                        #                                   |  | Proxy Server | Proxy Server  |  |
                        #                                   |  |------------------------------|  |
                        #                                   |  | Subgraph Logo | Backup Proxy |  |
                        #                                   |  |------------------------------|  |
                        #                                   |------------------------------------|
                        #                                           Proxy Graphviz Cluster
                        #
                        #
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
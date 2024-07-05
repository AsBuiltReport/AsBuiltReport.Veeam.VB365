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
        Version:        0.3.3
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
        [ValidateSet('pdf', 'svg', 'png', 'dot', 'base64')]
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
        [ValidateSet('Backup-to-All')]
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

        # Variable translating Icon to Image Path ($IconPath)
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
            "Microsoft_365" = "Microsoft_365.png"
            "Datacenter" = "Datacenter.png"
            "VB365_Restore_Portal" = "Web_console.png"
            "VB365_User_Group" = "User_Group.png"
            "VB365_User" = "User.png"
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

        $IconDebug = $false

        if ($EnableEdgeDebug) {
            $EdgeDebug = @{style = 'filled'; color = 'red' }
            $IconDebug = $true
        } else { $EdgeDebug = @{style = 'invis'; color = 'red' } }

        if ($EnableSubGraphDebug) {
            $SubGraphDebug = @{style = 'dashed'; color = 'red' }
            $NodeDebug = @{color = 'black'; style = 'red'; shape = 'plain' }
            $IconDebug = $true
        } else {
            $SubGraphDebug = @{style = 'invis'; color = 'gray' }
            $NodeDebug = @{color = 'transparent'; style = 'transparent'; shape = 'point' }
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

        # Graph default atrributes
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
                penwidth = 3
                arrowsize = 1
            }

            # Signature Section
            if ($Signature) {
                Write-PScriboMessage "Generating diagram signature"
                if ($CustomSignatureLogo) {
                    $Signature = (Get-DiaHTMLTable -ImagesObj $Images -Rows "Author: $($AuthorName)", "Company: $($CompanyName)" -TableBorder 2 -CellBorder 0 -Align 'left' -Logo $CustomSignatureLogo -IconDebug $IconDebug)
                } else {
                    $Signature = (Get-DiaHTMLTable -ImagesObj $Images -Rows "Author: $($AuthorName)", "Company: $($CompanyName)" -TableBorder 2 -CellBorder 0 -Align 'left' -Logo "VB365_LOGO_Footer" -IconDebug $IconDebug)
                }
            } else {
                Write-PScriboMessage "No diagram signature specified"
                $Signature = " "
            }

            #---------------------------------------------------------------------------------------------#
            #                             Graphviz Clusters (SubGraph) Section                            #
            #               SubGraph can be use to bungle the Nodes together like a single entity         #
            #                     SubGraph allow you to have a graph within a graph                       #
            #                PSgraph: https://psgraph.readthedocs.io/en/latest/Command-SubGraph/          #
            #                      Graphviz: https://graphviz.org/docs/attrs/cluster/                     #
            #---------------------------------------------------------------------------------------------#

            # Subgraph OUTERDRAWBOARD1 used to draw the footer signature (bottom-right corner)
            SubGraph OUTERDRAWBOARD1 -Attributes @{Label = $Signature; fontsize = 24; penwidth = 1.5; labelloc = 'b'; labeljust = "r"; style = $SubGraphDebug.style; color = $SubGraphDebug.color } {
                # Subgraph MainGraph used to draw the main drawboard.
                SubGraph MainGraph -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label $MainGraphLabel -IconType $CustomLogo -IconDebug $IconDebug -IconWidth 250 -IconHeight 80); fontsize = 24; penwidth = 0; labelloc = 't'; labeljust = "c" } {

                    if ($DiagramType -eq 'Backup-to-All') {

                        # Used for debugging
                        # Get-VB365DebugObject

                        #-----------------------------------------------------------------------------------------------#
                        #                                Graphviz Node Section                                          #
                        #                 Nodes are Graphviz elements used to define a object entity                    #
                        #                Nodes can have attribues like Shape, HTML Labels, Styles etc..                 #
                        #               PSgraph: https://psgraph.readthedocs.io/en/latest/Command-Node/                 #
                        #                     Graphviz: https://graphviz.org/doc/info/shapes.html                       #
                        #-----------------------------------------------------------------------------------------------#

                        $ServerInfo = @{
                            'Version' = Switch ([string]::IsNullOrEmpty((Get-VBOVersion).ProductVersion)) {
                                $true {'Unknown'}
                                $false {(Get-VBOVersion).ProductVersion}
                                default {'Unknown'}
                            }

                        }

                        if ($ServerConfigRestAPI.IsServiceEnabled) {
                            $ServerInfo.Add('RestAPI Port', $ServerConfigRestAPI.HTTPSPort)
                        }

                        # VB365 Server Object
                        Node VB365Server @{Label = Get-DiaNodeIcon -Rows $ServerInfo -ImagesObj $Images -Name $VeeamBackupServer -IconType "VB365_Server" -Align "Center" -IconDebug $IconDebug; shape = 'plain'; fillColor = 'transparent'; fontsize = 14 }

                        if ($RestorePortal.IsServiceEnabled) {
                            $RestorePortalURL = @{
                                'Portal URI' = $RestorePortal.PortalUri
                            }
                            Node VB365RestorePortal @{Label = Get-DiaNodeIcon -Rows $RestorePortalURL -ImagesObj $Images -Name 'Self-Service Portal' -IconType "VB365_Restore_Portal" -Align "Center" -IconDebug $IconDebug; shape = 'plain'; fillColor = 'transparent'; fontsize = 14 }
                        }

                        # Proxy Graphviz Cluster
                        if ($Proxies) {
                            $ProxiesInfo = @()

                            $Proxies | ForEach-Object {
                                $inobj = @{
                                    'Type' = $_.Type
                                    'Port' = "TCP/$($_.Port)"
                                }
                                $ProxiesInfo += $inobj
                            }

                            SubGraph ProxyServer -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Backup Proxies" -IconType "VB365_Proxy" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 'b'; style = 'dashed,rounded' } {

                                Node Proxies @{Label = (Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject ($Proxies.HostName | ForEach-Object { $_.split('.')[0] }) -Align "Center" -iconType "VB365_Proxy_Server" -columnSize 3 -IconDebug $IconDebug -MultiIcon -AditionalInfo $ProxiesInfo); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Tahoma" }
                            }
                        } else {
                            SubGraph ProxyServer -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Backup Proxies" -IconType "VB365_Proxy" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 'b'; style = 'dashed,rounded' } {

                                Node -Name Proxies -Attributes @{Label = 'No Backup Proxies'; shape = "rectangle"; labelloc = 'c'; fixedsize = $true; width = "3"; height = "2"; fillColor = 'transparent'; penwidth = 0 }
                            }
                        }

                        # Restore Operator Graphviz Cluster
                        if ($RestoreOperators) {
                            $RestoreOperatorsInfo = @()

                            $RestoreOperators | ForEach-Object {
                                $OrgId = $_.OrganizationId
                                $inobj = @{
                                    'Organization' = Switch ([string]::IsNullOrEmpty(($Organizations | Where-Object { $_.Id -eq $OrgId }))) {
                                        $true { 'Unknown' }
                                        $false { ($Organizations | Where-Object { $_.Id -eq $OrgId }).Name }
                                        default { 'Unknown' }
                                    }
                                }
                                $RestoreOperatorsInfo += $inobj
                            }

                            SubGraph RestoreOp -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Restore Operators" -IconType "VB365_User_Group" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 'b'; style = 'dashed,rounded' } {

                                Node RestoreOperators @{Label = (Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject $RestoreOperators.Name -Align "Center" -iconType "VB365_User" -columnSize 3 -IconDebug $IconDebug -MultiIcon -AditionalInfo $RestoreOperatorsInfo); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Tahoma" }
                            }
                        } else {
                            SubGraph RestoreOp -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Restore Operators" -IconType "VB365_User_Group" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 'b'; style = 'dashed,rounded' } {

                                Node -Name RestoreOperators -Attributes @{Label = 'No Restore Operators'; shape = "rectangle"; labelloc = 'c'; fixedsize = $true; width = "3"; height = "2"; fillColor = 'transparent'; penwidth = 0 }
                            }
                        }

                        # Repositories Graphviz Cluster
                        if ($Repositories) {
                            $RepositoriesInfo = @()

                            foreach ($Repository in $Repositories) {
                                if ($Repository.ObjectStorageRepository.Name) {
                                    $ObjStorage = $Repository.ObjectStorageRepository.Name
                                } else {
                                    $ObjStorage = 'None'
                                }
                                $inobj = [ordered] @{
                                    # 'Path' = $Repository.Path
                                    'Capacity' = ConvertTo-FileSizeString $Repository.Capacity
                                    'Free Space' = ConvertTo-FileSizeString $Repository.FreeSpace
                                    'ObjectStorage' = $ObjStorage
                                }
                                $RepositoriesInfo += $inobj
                            }

                            SubGraph Repos -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Backup Repositories" -IconType "VB365_Repository" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 'b'; style = 'dashed,rounded' } {

                                Node Repositories @{Label = (Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject $Repositories.Name -Align "Center" -iconType "VB365_Windows_Repository" -columnSize 3 -IconDebug $IconDebug -MultiIcon -AditionalInfo $RepositoriesInfo); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Tahoma" }
                            }
                        } else {
                            SubGraph Repos -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Backup Repositories" -IconType "VB365_Repository" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 'b'; style = 'dashed,rounded' } {

                                Node -Name Repositories -Attributes @{Label = 'No Backup Repositories'; shape = "rectangle"; labelloc = 'c'; fixedsize = $true; width = "3"; height = "2"; fillColor = 'transparent'; penwidth = 0 }
                            }
                        }
                        # Object Repositories Graphviz Cluster
                        if ($ObjectRepositories) {

                            $ObjectRepositoriesInfo = @()

                            $ObjectRepositories | ForEach-Object {
                                $inobj = @{
                                    'Type' = $_.Type
                                    'Folder' = $_.Folder
                                    'Immutability' = ConvertTo-TextYN $_.EnableImmutability
                                }
                                $ObjectRepositoriesInfo += $inobj
                            }

                            SubGraph ObjectRepos -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Object Repositories" -IconType "VB365_Object_Support" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 't'; style = 'dashed,rounded' } {

                                Node ObjectRepositories @{Label = (Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject $ObjectRepositories.Name -Align "Center" -iconType "VB365_Object_Repository" -columnSize 3 -IconDebug $IconDebug -MultiIcon -AditionalInfo $ObjectRepositoriesInfo); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Tahoma" }
                            }
                        } else {
                            SubGraph ObjectRepos -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Object Repositories" -IconType "VB365_Object_Support" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 't'; style = 'dashed,rounded' } {

                                Node -Name ObjectRepositories -Attributes @{Label = 'No Object Repositories'; shape = "rectangle"; labelloc = 'c'; fixedsize = $true; width = "3"; height = "2"; fillColor = 'transparent'; penwidth = 0 }
                            }
                        }

                        # Organization Graphviz Cluster
                        SubGraph Organizations -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Organizations" -IconType "VB365_On_Premises" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 't'; style = 'dashed,rounded' } {

                            # On-Premises Organization Graphviz Cluster
                            if (($Organizations | Where-Object { $_.Type -eq 'OnPremises' })) {
                                $OrganizationsInfo = @()

                                ($Organizations | Where-Object { $_.Type -eq 'OnPremises' }) | ForEach-Object {
                                    $inobj = @{
                                        'Users' = "Licensed: $($_.LicensingOptions.LicensedUsersCount) - Trial: $($_.LicensingOptions.TrialUsersCount)"
                                        'BackedUp' = ConvertTo-TextYN $_.IsBackedUp
                                    }
                                    $OrganizationsInfo += $inobj
                                }

                                SubGraph OnPremise -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "On-premises" -IconType "VB365_On_Premises" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 't'; style = 'dashed,rounded' } {

                                    Node OnpremisesOrg @{Label = (Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject ($Organizations | Where-Object { $_.Type -eq 'OnPremises' }).Name -Align "Center" -iconType "Datacenter" -columnSize 3 -IconDebug $IconDebug -MultiIcon -AditionalInfo $OrganizationsInfo); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Tahoma" }
                                }
                            }

                            # Microsoft 365 Organization Graphviz Cluster
                            if ($Organizations | Where-Object { $_.Type -eq 'Office365' }) {
                                $OrganizationsInfo = @()

                                ($Organizations | Where-Object { $_.Type -eq 'Office365' }) | ForEach-Object {
                                    $inobj = @{
                                        'Users' = "Licensed: $($_.LicensingOptions.LicensedUsersCount) - Trial: $($_.LicensingOptions.TrialUsersCount)"
                                        'BackedUp' = ConvertTo-TextYN $_.IsBackedUp
                                    }
                                    $OrganizationsInfo += $inobj
                                }
                                SubGraph Microsoft365 -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Microsoft 365" -IconType "VB365_Microsoft_365" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 't'; style = 'dashed,rounded' } {

                                    Node Microsoft365Org @{Label = (Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject ($Organizations | Where-Object { $_.Type -eq 'Office365' }).Name -Align "Center" -iconType "Microsoft_365" -columnSize 3 -IconDebug $IconDebug -MultiIcon -AditionalInfo $OrganizationsInfo); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Tahoma" }
                                }
                            }
                        }

                        # Veeam VB365 elements point of connection (Dummy Nodes!)
                        $Node = @('VB365ServerPointSpace', 'VB365ProxyPoint', 'VB365ProxyPointSpace', 'VB365RepoPoint')
                        Node $Node -NodeScript { $_ } @{Label = { $_ } ; fontcolor = $NodeDebug.color; fillColor = $NodeDebug.style; shape = $NodeDebug.shape }

                        $NodeStartEnd = @('VB365StartPoint', 'VB365EndPointSpace')
                        Node $NodeStartEnd -NodeScript { $_ } @{Label = { $_ } ; fontcolor = $NodeDebug.color; shape = 'point'; fixedsize = 'true'; width = .2 ; height = .2 }

                        #---------------------------------------------------------------------------------------------#
                        #                             Graphviz Rank Section                                           #
                        #                     Rank allow to put Nodes on the same group level                         #
                        #         PSgraph: https://psgraph.readthedocs.io/en/stable/Command-Rank-Advanced/            #
                        #                     Graphviz: https://graphviz.org/docs/attrs/rank/                         #
                        #---------------------------------------------------------------------------------------------#

                        # Put the dummy node in the same rank to be able to create a horizontal line
                        Rank VB365ServerPointSpace, VB365ProxyPoint, VB365ProxyPointSpace, VB365RepoPoint, VB365StartPoint, VB365EndPointSpace

                        if ($RestorePortal.IsServiceEnabled) {
                            # Put the VB365Server and the VB365RestorePortal in the same level to align it horizontally
                            Rank VB365RestorePortal, VB365Server
                        }

                        #---------------------------------------------------------------------------------------------#
                        #                             Graphviz Edge Section                                           #
                        #                   Edges are Graphviz elements use to interconnect Nodes                     #
                        #                 Edges can have attribues like Shape, Size, Styles etc..                     #
                        #              PSgraph: https://psgraph.readthedocs.io/en/latest/Command-Edge/                #
                        #                      Graphviz: https://graphviz.org/docs/edges/                             #
                        #---------------------------------------------------------------------------------------------#

                        # Connect the Dummy Node in a straight line
                        # VB365StartPoint --- VB365ServerPointSpace --- VB365ProxyPoint --- VB365ProxyPointSpace --- VB365RepoPoint --- VB365EndPointSpace
                        Edge -From VB365StartPoint -To VB365ServerPointSpace @{minlen = 10; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
                        Edge -From VB365ServerPointSpace -To VB365ProxyPoint @{minlen = 10; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
                        Edge -From VB365ProxyPoint -To VB365ProxyPointSpace @{minlen = 10; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
                        Edge -From VB365ProxyPointSpace -To VB365RepoPoint @{minlen = 10; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
                        Edge -From VB365RepoPoint -To VB365EndPointSpace @{minlen = 10; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }

                        # Connect Veeam Backup server to the Dummy line
                        Edge -From VB365Server -To VB365ServerPointSpace @{minlen = 2; arrowtail = 'dot'; arrowhead = 'none'; style = 'dashed' }

                        # Connect Veeam Backup server to RetorePortal
                        if ($RestorePortal.IsServiceEnabled) {
                            Edge -From VB365RestorePortal -To VB365Server @{minlen = 2; arrowtail = 'dot'; arrowhead = 'normal'; style = 'dashed'; color = '#DF8c42' }
                        }
                        # Connect Veeam Backup Server to Organization Graphviz Cluster
                        if ($Organizations | Where-Object { $_.Type -eq 'OnPremises' }) {
                            Edge -To VB365Server -From OnpremisesOrg @{minlen = 2; arrowtail = 'dot'; arrowhead = 'normal'; style = 'dashed'; color = '#DF8c42' }
                        } elseif ($Organizations | Where-Object { $_.Type -eq 'Office365' }) {
                            Edge -To VB365Server -From Microsoft365Org @{minlen = 2; arrowtail = 'dot'; arrowhead = 'normal'; style = 'dashed'; color = '#DF8c42' }
                        } else {
                            SubGraph Organizations -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Organizations" -IconType "VB365_On_Premises" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 't'; style = 'dashed,rounded' } {
                                Node -Name DummyNoOrganization -Attributes @{Label = 'No Organization'; shape = "rectangle"; labelloc = 'c'; fixedsize = $true; width = "3"; height = "2"; fillColor = 'transparent'; penwidth = 0 }
                            }
                            Edge -To VB365Server -From DummyNoOrganization @{minlen = 2; arrowtail = 'dot'; arrowhead = 'normal'; style = 'dashed'; color = '#DF8c42' }
                        }

                        # Connect Veeam RestorePortal to the Restore Operators
                        Edge -From VB365ServerPointSpace -To RestoreOperators @{minlen = 2; arrowtail = 'none'; arrowhead = 'dot'; style = 'dashed' }

                        # Connect Veeam Proxies Server to the Dummy line
                        Edge -From VB365ProxyPoint -To Proxies @{minlen = 2; arrowtail = 'none'; arrowhead = 'dot'; style = 'dashed' }

                        # Connect Veeam Repository to the Dummy line
                        Edge -From VB365RepoPoint -To Repositories @{minlen = 2; arrowtail = 'none'; arrowhead = 'dot'; style = 'dashed' }

                        # Connect Veeam Object Repository to the Dummy line
                        Edge -To VB365RepoPoint -From ObjectRepositories @{minlen = 2; arrowtail = 'dot'; arrowhead = 'none'; style = 'dashed' }

                        # End results example
                        #
                        #------------------------------------------------------------------------------------------------------------------------------------
                        #
                        #------------------------------------------------------------------------------------------------------------------------------------
                        #                               |---------------------------------------------------|                        ^
                        #                               |  |---------------------------------------------|  |                        |
                        #                               |  |      Subgraph Logo |      Organization      |  |                        |
                        #                               |  |---------------------------------------------|  |               MainGraph Cluster Board
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
                        # | VB365 Server | <--- Graphviz Node Example
                        # |--------------|
                        # |   Version:   |
                        # |--------------|
                        #       O                                                                                                          Dummy Nodes
                        #       |                                                                                                               |
                        #       |                                                                                                               |
                        #       |                                                                                                              \|/
                        # VB365StartPoint --- VB365ServerPointSpace --- VB365ProxyPoint --- VB365ProxyPointSpace --- VB365RepoPoint --- VB365EndPointSpace
                        #                                                      |
                        #                                                      | <--- Graphviz Edge Example
                        #                                                      |
                        #                                                      O
                        #                                   |------------------------------------|
                        #                                   |  |------------------------------|  |
                        #                                   |  |      ICON    |     ICON      |  |
                        #                                   |  |------------------------------|  |
                        #                                   |  | Proxy Server | Proxy Server  |  | <--- Graphviz Cluster Example
                        #                                   |  |------------------------------|  |
                        #                                   |  | Subgraph Logo | Backup Proxy |  |
                        #                                   |  |------------------------------|  |
                        #                                   |------------------------------------|
                        #                                           Proxy Graphviz Cluster
                        #
                        #--------------------------------------------------------------------------------------------------------------------------------------
                        #                                                                                                       |---------------------------|
                        #                                                                                                       |---------                  |
                        #                                                                                                       |        |    Author Name   |
                        #                                                                                      Signature -----> |  Logo  |                  |
                        #                                                                                                       |        |    Company Name  |
                        #                                                                                                       |---------                  |
                        #                                                                                                       |---------------------------|
                        #--------------------------------------------------------------------------------------------------------------------------------------
                        #                                                                                                                    ^
                        #                                                                                                                    |
                        #                                                                                                                    |
                        #                                                                                                      OUTERDRAWBOARD1 Cluster Board
                    }
                }
            }
        }
    }
    end {
        #Export  the Diagram
        if ($Graph) {
            Export-Diagrammer -GraphObj ($Graph | Select-String -Pattern '"([A-Z])\w+"\s\[label="";style="invis";shape="point";]' -NotMatch) -ErrorDebug $EnableErrorDebug -Format $Format -Filename $Filename -OutputFolderPath $OutputFolderPath -WaterMarkText $Options.DiagramWaterMark -WaterMarkColor "Green"
        } else {
            Write-PScriboMessage -IsWarning "No Graph object found. Disabling diagram section"
        }
    }
}
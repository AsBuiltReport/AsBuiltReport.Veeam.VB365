function Get-AbrVb365Diagram {
    <#
    .SYNOPSIS
        Diagram the configuration of Veeam Backup for Microsoft 365 infrastructure in PDF/SVG/DOT/PNG formats using PSGraph and Graphviz.
    .DESCRIPTION
        Diagram the configuration of Veeam Backup for Microsoft 365 infrastructure in PDF/SVG/DOT/PNG formats using PSGraph and Graphviz.
    .NOTES
        Version:        0.3.11
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

    begin {
        # Used for DiagramDebug
        if ($Options.EnableDiagramDebug) {
            $EdgeDebug = @{style = 'filled'; color = 'red' }
            $SubGraphDebug = @{style = 'dashed'; color = 'red' }
            $NodeDebug = @{color = 'black'; style = 'red'; shape = 'plain' }
            $NodeDebugEdge = @{color = 'black'; style = 'red'; shape = 'plain' }
            $IconDebug = $true
        } else {
            $EdgeDebug = @{style = 'invis'; color = 'red' }
            $SubGraphDebug = @{style = 'invis'; color = 'gray' }
            $NodeDebug = @{color = 'transparent'; style = 'transparent'; shape = 'point' }
            $NodeDebugEdge = @{color = 'transparent'; style = 'transparent'; shape = 'none' }
            $IconDebug = $false
        }

        if ($Options.DiagramTheme -eq 'Black') {
            $Edgecolor = 'White'
            $Fontcolor = 'White'
        } elseif ($Options.DiagramTheme -eq 'Neon') {
            $Edgecolor = 'gold2'
            $Fontcolor = 'gold2'
        } else {
            $Edgecolor = '#71797E'
            $Fontcolor = '#565656'
        }

    }

    process {

        #-----------------------------------------------------------------------------------------------#
        #                                Graphviz Node Section                                          #
        #                 Nodes are Graphviz elements used to define a object entity                    #
        #                Nodes can have attribues like Shape, HTML Labels, Styles etc..                 #
        #               PSgraph: https://psgraph.readthedocs.io/en/latest/Command-Node/                 #
        #                     Graphviz: https://graphviz.org/doc/info/shapes.html                       #
        #-----------------------------------------------------------------------------------------------#

        $ServerInfo = @{
            'Version' = Switch ([string]::IsNullOrEmpty((Get-VBOVersion).ProductVersion)) {
                $true { 'Unknown' }
                $false { (Get-VBOVersion).ProductVersion }
                default { 'Unknown' }
            }
        }

        $ServerConfigRestAPI = Get-VBORestAPISettings


        if (($ServerConfigRestAPI = Get-VBORestAPISettings).IsServiceEnabled) {
            $ServerInfo.Add('RestAPI Port', $ServerConfigRestAPI.HTTPSPort)
        }

        # VB365 Server Object
        Node VB365Server @{Label = Get-DiaNodeIcon -Rows $ServerInfo -ImagesObj $Images -Name $VeeamBackupServer -IconType "VB365_Server" -Align "Center" -IconDebug $IconDebug -FontSize 18; shape = 'plain'; fillColor = 'transparent'; fontsize = 14 }

        if (($RestorePortal = Get-VBORestorePortalSettings).IsServiceEnabled) {
            $RestorePortalURL = @{
                'Portal URI' = $RestorePortal.PortalUri
            }
            Node VB365RestorePortal @{Label = Get-DiaNodeIcon -Rows $RestorePortalURL -ImagesObj $Images -Name 'Self-Service Portal' -IconType "VB365_Restore_Portal" -Align "Center" -IconDebug $IconDebug -FontSize 18; shape = 'plain'; fillColor = 'transparent'; fontsize = 14; url = $RestorePortal.PortalUri }
        }

        # Proxy Graphviz Cluster
        try {
            $ProxiesInfo = @()

            $Proxies = Get-VBOProxy -WarningAction SilentlyContinue | Sort-Object -Property Hostname

            $Proxies | ForEach-Object {
                $inobj = [PSCustomObject] [ordered] @{
                    'Type' = $_.Type
                    'Port' = "TCP/$($_.Port)"
                    'OS' = $_.OperatingSystemKind
                }
                $ProxiesInfo += $inobj
            }

            $ProxyNodes = Node Proxies @{Label = (Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject ($Proxies.HostName | ForEach-Object { $_.split('.')[0] }) -Align "Center" -iconType "VB365_Proxy_Server" -columnSize 3 -IconDebug $IconDebug -MultiIcon -AditionalInfo $ProxiesInfo -Subgraph -SubgraphIconType "VB365_Proxy" -SubgraphLabel "Backup Proxies" -SubgraphLabelPos "top" -SubgraphTableStyle "dashed,rounded" -fontColor $Fontcolor -TableBorderColor $Edgecolor -TableBorder "1" -SubgraphLabelFontsize 22 -fontSize 18); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Segoe Ui" }

        } catch {
            Write-PScriboMessage -Message "Error: Unable to create Proxies Objects. Disabling the section"
            Write-PScriboMessage -Message "Error Message: $($_.Exception.Message)"
        }
        if ($Proxies -and $ProxyNodes) {
            $ProxyNodes
        } else {
            SubGraph ProxyServer -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Backup Proxies" -IconType "VB365_Proxy" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 'b'; style = 'dashed,rounded' } {

                Node -Name Proxies -Attributes @{Label = 'No Backup Proxies'; shape = "rectangle"; labelloc = 'c'; fixedsize = $true; width = "3"; height = "2"; fillColor = 'transparent'; penwidth = 0 }
            }
        }

        # Proxy Pools Graphviz Cluster
        try {
            $ProxyPools = Get-VBOProxyPool -WarningAction SilentlyContinue | Sort-Object -Property Name

            $ProxyPoolNodes = foreach ($ProxyPool in $ProxyPools) {
                Get-DiaHTMLTable -ImagesObj $Images -Rows ($ProxyPool.Proxies.Hostname | ForEach-Object { $_.Split('.')[0] }) -Align 'Center' -ColumnSize 2 -IconDebug $IconDebug -Subgraph -SubgraphIconType "VB365_Proxy_Server" -SubgraphLabel $ProxyPool.Name -SubgraphLabelPos "top" -fontColor $Fontcolor -TableStyle "dashed,rounded" -TableBorderColor $Edgecolor -TableBorder "1" -NoFontBold -SubgraphLabelFontsize 22 -FontSize 18
            }
        } catch {
            Write-PScriboMessage -Message "Error: Unable to create Proxies Pool Objects. Disabling the section"
            Write-PScriboMessage -Message "Error Message: $($_.Exception.Message)"
        }
        if ($ProxyPools -and $ProxyPoolNodes) {

            $ProxyPoolSubgraphNode = Node -Name "ProxyPools" -Attributes @{Label = (Get-DiaHTMLSubGraph -ImagesObj $Images -TableArray $ProxyPoolNodes -Align 'Center' -IconDebug $IconDebug -IconType 'VB365_Proxy' -Label 'Backup Proxy Pools' -LabelPos "top" -fontColor $Fontcolor -TableStyle "dashed,rounded" -TableBorderColor $Edgecolor -TableBorder "1" -columnSize 2 -fontSize 22); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Segoe Ui" }

            if ($ProxyPoolSubgraphNode) {
                $ProxyPoolSubgraphNode
            }

        }

        # Restore Operator Graphviz Cluster
        try {
            $RestoreOperators = try { Get-VBORbacRole | Sort-Object -Property Name } catch { Out-Null }

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

            $RestoreOperatorsNodes = Node RestoreOperators @{Label = (Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject $RestoreOperators.Name -Align "Center" -iconType "VB365_User" -columnSize 2 -IconDebug $IconDebug -MultiIcon -AditionalInfo $RestoreOperatorsInfo -Subgraph -SubgraphIconType "VB365_User" -SubgraphLabel "Restore Operators" -SubgraphLabelPos "top" -SubgraphTableStyle "dashed,rounded" -fontColor $Fontcolor -TableBorderColor $Edgecolor -TableBorder "1" -SubgraphLabelFontsize 22 -fontSize 18); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Segoe Ui" }

        } catch {
            Write-PScriboMessage -Message "Error: Unable to create RestoreOperators Objects. Disabling the section"
            Write-PScriboMessage -Message "Error Message: $($_.Exception.Message)"
        }
        if ($RestoreOperators -and $RestoreOperatorsNodes) {

            $RestoreOperatorsNodes

        } else {
            SubGraph RestoreOp -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Restore Operators" -IconType "VB365_User_Group" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 'b'; style = 'dashed,rounded' } {

                Node -Name RestoreOperators -Attributes @{Label = 'No Restore Operators'; shape = "rectangle"; labelloc = 'c'; fixedsize = $true; width = "3"; height = "2"; fillColor = 'transparent'; penwidth = 0 }
            }
        }

        # Repositories Graphviz Cluster
        try {

            $Repositories = Get-VBORepository | Sort-Object -Property Name

            $RepositoriesInfo = @()

            foreach ($Repository in $Repositories) {
                if ($Repository.ObjectStorageRepository.Name) {
                    $ObjStorage = $Repository.ObjectStorageRepository.Name
                } else {
                    $ObjStorage = 'None'
                }
                $inobj = [PSCustomObject] [ordered] @{
                    # 'Path' = $Repository.Path
                    'Capacity' = ConvertTo-FileSizeString $Repository.Capacity
                    'Free Space' = ConvertTo-FileSizeString $Repository.FreeSpace
                    'ObjectStorage' = $ObjStorage
                }
                $RepositoriesInfo += $inobj
            }

            $RepositoriesNodes = Node Repositories @{Label = (Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject $Repositories.Name -Align "Center" -iconType "VB365_Repository" -columnSize 3 -IconDebug $IconDebug -MultiIcon -AditionalInfo $RepositoriesInfo -Subgraph -SubgraphIconType "Veeam_Repository" -SubgraphLabel "Backup Repositories" -SubgraphLabelPos "top" -SubgraphTableStyle "dashed,rounded" -fontColor $Fontcolor -TableBorderColor $Edgecolor -TableBorder "1" -SubgraphLabelFontsize 22 -fontSize 18); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Segoe Ui" }

        } catch {
            Write-PScriboMessage -Message "Error: Unable to create Repositories Objects. Disabling the section"
            Write-PScriboMessage -Message "Error Message: $($_.Exception.Message)"
        }
        if ($Repositories -and $RepositoriesNodes) {

            $RepositoriesNodes

        } else {
            SubGraph Repos -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Backup Repositories" -IconType "Veeam_Repository" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 'b'; style = 'dashed,rounded' } {

                Node -Name Repositories -Attributes @{Label = 'No Backup Repositories'; shape = "rectangle"; labelloc = 'c'; fixedsize = $true; width = "3"; height = "2"; fillColor = 'transparent'; penwidth = 0 }
            }
        }
        # Object Repositories Graphviz Cluster
        try {

            $ObjectRepositories = Get-VBOObjectStorageRepository -WarningAction SilentlyContinue | Sort-Object -Property Name

            $ObjectRepositoriesInfo = @()
            $ORIconType = @()

            $ObjectRepositories | ForEach-Object {
                $inobj = [PSCustomObject] [ordered] @{
                    'Type' = $_.Type
                    'Folder' = $_.Folder
                    'Immutability' = $_.EnableImmutability
                }
                $ObjectRepositoriesInfo += $inobj
                $ORIconType += Switch ($_.Type) {
                    'AmazonS3' { 'VBR365_Amazon_S3' }
                    'AmazonS3Compatible' { 'VBR365_Amazon_S3_Compatible' }
                    'AzureBlob' { 'VBR365_Azure_Blob' }
                    default { $_.Type }
                }
            }

            $ObjectRepositoriesNodes = Node ObjectRepositories @{Label = (Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject $ObjectRepositories.Name -Align "Center" -iconType $ORIconType -columnSize 3 -IconDebug $IconDebug -MultiIcon -AditionalInfo $ObjectRepositoriesInfo -Subgraph -SubgraphIconType "VB365_Object_Support" -SubgraphLabel "Object Repositories" -SubgraphLabelPos "top" -SubgraphTableStyle "dashed,rounded" -fontColor $Fontcolor -TableBorderColor $Edgecolor -TableBorder "1" -SubgraphLabelFontsize 22 -fontSize 18); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Segoe Ui" }

        } catch {
            Write-PScriboMessage -Message "Error: Unable to create ObjectRepositories Objects. Disabling the section"
            Write-PScriboMessage -Message "Error Message: $($_.Exception.Message)"
        }
        if ($ObjectRepositories -and $ObjectRepositoriesNodes) {

            $ObjectRepositoriesNodes

        } else {
            SubGraph ObjectRepos -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Object Repositories" -IconType "VB365_Object_Support" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 't'; style = 'dashed,rounded' } {

                Node -Name ObjectRepositories -Attributes @{Label = 'No Object Repositories'; shape = "rectangle"; labelloc = 'c'; fixedsize = $true; width = "3"; height = "2"; fillColor = 'transparent'; penwidth = 0 }
            }
        }

        # Organization Graphviz Cluster
        try {

            $Organizations = Get-VBOOrganization | Sort-Object -Property Name

            $OrganizationsInfo = @()

            ($Organizations | Where-Object { $_.Type -eq 'OnPremises' }) | ForEach-Object {
                $inobj = [PSCustomObject] [ordered] @{
                    'Users' = "Licensed: $($_.LicensingOptions.LicensedUsersCount) - Trial: $($_.LicensingOptions.TrialUsersCount)"
                    'BackedUp' = ConvertTo-TextYN $_.IsBackedUp
                }
                $OrganizationsInfo += $inobj
            }

            if ($OrganizationsInfo) {
                $OnPremisesNode = Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject ($Organizations | Where-Object { $_.Type -eq 'OnPremises' }).Name -Align "Center" -iconType "Datacenter" -columnSize 3 -IconDebug $IconDebug -MultiIcon -AditionalInfo $OrganizationsInfo -Subgraph -SubgraphIconType "VB365_On_Premises" -SubgraphLabel "On-premises" -SubgraphLabelPos "top" -SubgraphTableStyle "dashed,rounded" -fontColor $Fontcolor -TableBorderColor $Edgecolor -TableBorder "1" -SubgraphLabelFontsize 22 -fontSize 18
            }
        } catch {
            Write-PScriboMessage -Message "Error: Unable to create OnPremises Organization Objects. Disabling the section"
            Write-PScriboMessage -Message "Error Message: $($_.Exception.Message)"
        }

        try {
            $OrganizationsInfo = @()

            ($Organizations | Where-Object { $_.Type -eq 'Office365' }) | ForEach-Object {
                $inobj = [PSCustomObject] [ordered] @{
                    'Users' = "Licensed: $($_.LicensingOptions.LicensedUsersCount) - Trial: $($_.LicensingOptions.TrialUsersCount)"
                    'BackedUp' = ConvertTo-TextYN $_.IsBackedUp
                }
                $OrganizationsInfo += $inobj
            }

            if ($OrganizationsInfo) {
                $Microsoft365Node = Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject ($Organizations | Where-Object { $_.Type -eq 'Office365' }).Name -Align "Center" -iconType "Microsoft_365" -columnSize 3 -IconDebug $IconDebug -MultiIcon -AditionalInfo $OrganizationsInfo -Subgraph -SubgraphIconType "VB365_Microsoft_365" -SubgraphLabel "Microsoft 365" -SubgraphLabelPos "top" -SubgraphTableStyle "dashed,rounded" -fontColor $Fontcolor -TableBorderColor $Edgecolor -TableBorder "1" -SubgraphLabelFontsize 22 -fontSize 18
            }
        } catch {
            Write-PScriboMessage -Message "Error: Unable to create Microsoft365 Organization Objects. Disabling the section"
            Write-PScriboMessage -Message "Error Message: $($_.Exception.Message)"
        }

        $OrganizationsInfo = @()

        # On-Premises Organization Graphviz Cluster
        if (($Organizations | Where-Object { $_.Type -eq 'OnPremises' }) -and $OnPremisesNode) {
            $OrganizationsInfo += $OnPremisesNode

        }

        # Microsoft 365 Organization Graphviz Cluster
        if (($Organizations | Where-Object { $_.Type -eq 'Office365' }) -and $Microsoft365Node) {
            $OrganizationsInfo += $Microsoft365Node
        }

        if ($OrganizationsInfo) {
            $OrganizationNode = Node -Name "Organizations" -Attributes @{Label = (Get-DiaHTMLSubGraph -ImagesObj $Images -TableArray $OrganizationsInfo -Align 'Center' -IconDebug $IconDebug -IconType 'VB365_On_Premises' -Label 'Organizations' -LabelPos "top" -fontColor $Fontcolor -TableStyle "dashed,rounded" -TableBorderColor $Edgecolor -TableBorder "1" -columnSize 3 -fontSize 22); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Segoe Ui" }

            if ($OrganizationNode) {
                $OrganizationNode
            }
        }

        if ($Options.DiagramTheme -eq 'Black') {
            $NodeFillColor = 'White'
        } elseif ($Options.DiagramTheme -eq 'Neon') {
            $NodeFillColor = 'Gold2'
        } else {
            $NodeFillColor = '#71797E'
        }

        # Veeam VB365 elements point of connection (Dummy Nodes!)
        $Node = @('VB365ServerPointSpace', 'VB365ProxyPoint', 'VB365ProxyPointSpace', 'VB365RepoPoint')
        Node $Node -NodeScript { $_ } @{Label = { $_ } ; fontcolor = $NodeDebug.color; fillColor = $NodeDebug.style; shape = $NodeDebug.shape }

        $NodeStartEnd = @('VB365StartPoint', 'VB365EndPointSpace')
        Node $NodeStartEnd -NodeScript { $_ } @{Label = { $_ } ; fillColor = $NodeFillColor; fontcolor = $NodeDebug.color; shape = 'point'; fixedsize = 'true'; width = .2 ; height = .2 }

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
        Edge -From VB365StartPoint -To VB365ServerPointSpace @{minlen = 12; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
        Edge -From VB365ServerPointSpace -To VB365ProxyPoint @{minlen = 14; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
        Edge -From VB365ProxyPoint -To VB365ProxyPointSpace @{minlen = 12; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
        Edge -From VB365ProxyPointSpace -To VB365RepoPoint @{minlen = 12; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
        Edge -From VB365RepoPoint -To VB365EndPointSpace @{minlen = 12; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }

        # Connect Veeam Backup server to the Dummy line
        Edge -From VB365Server -To VB365ServerPointSpace @{minlen = 4; arrowtail = 'dot'; arrowhead = 'none'; style = 'dashed' }

        # Connect Veeam Backup server to RetorePortal
        if ($RestorePortal.IsServiceEnabled -and $RestoreOperatorsNodes) {
            Edge -From VB365Server -To VB365RestorePortal @{minlen = 4; arrowtail = 'dot'; arrowhead = 'normal'; style = 'dashed'; color = '#DF8c42' }
        }
        # Connect Veeam Backup Server to Organization Graphviz Cluster
        if ($OrganizationNode) {
            Edge -To VB365Server -From Organizations @{minlen = 4; arrowtail = 'dot'; arrowhead = 'normal'; style = 'dashed'; color = '#DF8c42' }
        }

        # Connect Veeam RestorePortal to the Restore Operators
        Edge -From VB365ServerPointSpace -To RestoreOperators @{minlen = 4; arrowtail = 'none'; arrowhead = 'dot'; style = 'dashed' }

        # Connect Veeam Proxies Server to the Dummy line
        Edge -From VB365ProxyPoint -To Proxies @{minlen = 4; arrowtail = 'none'; arrowhead = 'dot'; style = 'dashed' }

        if ($ProxyPools -and $ProxyPoolNodes) {
            Edge -From Proxies -To ProxyPools @{minlen = 2; arrowtail = 'none'; arrowhead = 'dot'; style = 'dashed' }
        }

        # Connect Veeam Repository to the Dummy line
        Edge -From VB365RepoPoint -To Repositories @{minlen = 4; arrowtail = 'none'; arrowhead = 'dot'; style = 'dashed' }

        # Connect Veeam Object Repository to the Dummy line
        Edge -To VB365RepoPoint -From ObjectRepositories @{minlen = 4; arrowtail = 'dot'; arrowhead = 'none'; style = 'dashed' }

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
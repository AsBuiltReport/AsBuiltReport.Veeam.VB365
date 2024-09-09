function Get-AbrVb365Diagram {
    <#
    .SYNOPSIS
        Diagram the configuration of Veeam Backup for Microsoft 365 infrastructure in PDF/SVG/DOT/PNG formats using PSGraph and Graphviz.
    .DESCRIPTION
        Diagram the configuration of Veeam Backup for Microsoft 365 infrastructure in PDF/SVG/DOT/PNG formats using PSGraph and Graphviz.
    .NOTES
        Version:        0.3.5
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
                    'OS' = $_.OperatingSystemKind
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

        # Proxy Pools Graphviz Cluster
        if ($ProxyPools) {

            SubGraph ProxyPools -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Backup Proxy Pools" -IconType "VB365_Proxy" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 'b'; style = 'dashed,rounded' } {

                $PoolNumber = 0

                foreach ($ProxyPool in $ProxyPools) {
                    $SubGraphName = Remove-SpecialChar -String $ProxyPool.Name -SpecialChars '\-. '

                    SubGraph $SubGraphName -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label $ProxyPool.Name -IconType "VB365_Proxy_Server" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 'b'; style = 'dashed,rounded' } {

                        Node "ProxyPool$($PoolNumber)" @{Label = (Get-DiaHTMLTable -ImagesObj $Images -Rows $ProxyPool.Proxies.Hostname.Split('.')[0] -MultiColunms -ColumnSize 2 -Align 'Center' -IconDebug $IconDebug); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Tahoma" }

                    }
                    $PoolNumber++
                }
            }
        } else {
            SubGraph ProxyPools -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Backup Proxy Pools" -IconType "VB365_Proxy" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 'b'; style = 'dashed,rounded' } {

                Node -Name Proxies -Attributes @{Label = 'No Backup Proxy Pools'; shape = "rectangle"; labelloc = 'c'; fixedsize = $true; width = "3"; height = "2"; fillColor = 'transparent'; penwidth = 0 }
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

            SubGraph Repos -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Backup Repositories" -IconType "Veeam_Repository" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 'b'; style = 'dashed,rounded' } {

                Node Repositories @{Label = (Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject $Repositories.Name -Align "Center" -iconType "VB365_Repository" -columnSize 3 -IconDebug $IconDebug -MultiIcon -AditionalInfo $RepositoriesInfo); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Tahoma" }
            }
        } else {
            SubGraph Repos -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Backup Repositories" -IconType "Veeam_Repository" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 'b'; style = 'dashed,rounded' } {

                Node -Name Repositories -Attributes @{Label = 'No Backup Repositories'; shape = "rectangle"; labelloc = 'c'; fixedsize = $true; width = "3"; height = "2"; fillColor = 'transparent'; penwidth = 0 }
            }
        }
        # Object Repositories Graphviz Cluster
        if ($ObjectRepositories) {

            $ObjectRepositoriesInfo = @()
            $ORIconType = @()

            $ObjectRepositories | ForEach-Object {
                $inobj = @{
                    'Type' = $_.Type
                    'Folder' = $_.Folder
                    'Immutability' = ConvertTo-TextYN $_.EnableImmutability
                }
                $ObjectRepositoriesInfo += $inobj
                $ORIconType += Switch ($_.Type) {
                    'AmazonS3' { 'VBR365_Amazon_S3' }
                    'AmazonS3Compatible' { 'VBR365_Amazon_S3_Compatible' }
                    'AzureBlob' { 'VBR365_Azure_Blob' }
                }
            }

            SubGraph ObjectRepos -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Object Repositories" -IconType "VB365_Object_Support" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 't'; style = 'dashed,rounded' } {

                Node ObjectRepositories @{Label = (Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject $ObjectRepositories.Name -Align "Center" -iconType $ORIconType -columnSize 3 -IconDebug $IconDebug -MultiIcon -AditionalInfo $ObjectRepositoriesInfo); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Tahoma" }
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

        if ($ProxyPools) {
            Edge -From Proxies -To ProxyPool0 @{minlen = 1; arrowtail = 'none'; arrowhead = 'dot'; style = 'dashed' }
        }

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
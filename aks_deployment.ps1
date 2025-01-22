param (
    [string]$AksName,
    [string]$SubscriptionId,
    [string]$ResourceGroupName,
    [string]$VNetResourceId,
    [string]$NodePool1Name,
    [int]$NodePool1Nodes,
    [string]$NodePool1NetworkType,
    [int]$NodePool1Pods,
    [string]$NodePool2Name,
    [int]$NodePool2Nodes,
    [string]$NodePool2NetworkType,
    [int]$NodePool2Pods,
    [string]$ClusterType,
    [string]$RBACType,
    [string]$AdminUsers,
    [string]$UserGroups
)

# Validate inputs
if (-not $AksName) { Write-Host "AKS Name is required."; exit }
if (-not $SubscriptionId) { Write-Host "Subscription ID is required."; exit }
if (-not $ResourceGroupName) { Write-Host "Resource Group Name is required."; exit }
if (-not $VNetResourceId) { Write-Host "VNet Resource ID is required."; exit }

$validNetworkTypes = @('kubenet', 'azureCNI', 'Overlay')
if ($validNetworkTypes -notcontains $NodePool1NetworkType) { Write-Host "Invalid Network Type for NodePool 1."; exit }
if ($validNetworkTypes -notcontains $NodePool2NetworkType) { Write-Host "Invalid Network Type for NodePool 2."; exit }

if ($NodePool1Nodes -lt 3) { Write-Host "NodePool 1 must have at least 3 nodes."; exit }
if ($NodePool2Nodes -lt 3) { Write-Host "NodePool 2 must have at least 3 nodes."; exit }
if ($NodePool1Pods -lt 10) { Write-Host "NodePool 1 must have at least 10 pods per node."; exit }
if ($NodePool2Pods -lt 10) { Write-Host "NodePool 2 must have at least 10 pods per node."; exit }

if ($ClusterType -eq "Shared" -and -not $AdminUsers) { Write-Host "Admin users are required for shared cluster type."; exit }
if ($RBACType -eq "kuberbac" -and -not $UserGroups) { Write-Host "User Groups are required for kuberbac RBAC type."; exit }

# Authenticate to Azure
Connect-AzAccount
Set-AzContext -SubscriptionId $SubscriptionId

# Get VNet details
$vnet = Get-AzVirtualNetwork -ResourceId $VNetResourceId
if (-not $vnet) { Write-Host "VNet not found."; exit }

$addressPrefix = $vnet.AddressSpace.AddressPrefixes
$subnets = $vnet.Subnets

Write-Host "VNet Address Prefix: $addressPrefix"
Write-Host "Subnets: $($subnets | ForEach-Object { $_.Name })"

# Calculate IP requirements
$nodePool1Ips = $NodePool1Nodes * $NodePool1Pods
$nodePool2Ips = $NodePool2Nodes * $NodePool2Pods
$totalIpsRequired = $nodePool1Ips + $nodePool2Ips

# Check if VNet has enough space for the required IPs
$availableIps = 0
foreach ($subnet in $subnets) {
    $subnetPrefix = $subnet.AddressPrefix
    $subnetIps = [System.Net.IPNetwork]::Parse($subnetPrefix).GetAllAddresses().Count
    $availableIps += $subnetIps
}

if ($availableIps -lt $totalIpsRequired) {
    Write-Host "Not enough IPs available in the VNet. Required: $totalIpsRequired, Available: $availableIps"
    exit
} else {
    Write-Host "Sufficient IPs available in the VNet."
}

# Create AKS Cluster
$aksConfig = @{
    Name                = $AksName
    ResourceGroupName   = $ResourceGroupName
    Location            = $vnet.Location
    KubernetesVersion   = "1.24.6"  # Specify desired Kubernetes version
    NetworkProfile      = @{ NetworkPlugin = $NodePool1NetworkType }
    EnableRBAC          = $true
    ManagedCluster      = $true
    AADProfile          = @{ AdminGroupObjectIDs = $UserGroups.Split(',') }
}

$nodePool1Config = @{
    Name         = $NodePool1Name
    Count        = $NodePool1Nodes
    VmSize       = "Standard_DS2_v2"  # Adjust as necessary
    NodeLabels   = @{ "role" = "worker" }
    OsType       = "Linux"
    NetworkType  = $NodePool1NetworkType
}

$nodePool2Config = @{
    Name         = $NodePool2Name
    Count        = $NodePool2Nodes
    VmSize       = "Standard_DS2_v2"
    NodeLabels   = @{ "role" = "worker" }
    OsType       = "Linux"
    NetworkType  = $NodePool2NetworkType
}

# Deploy AKS Cluster
New-AzAksCluster -ResourceGroupName $ResourceGroupName -Name $AksName -Location $vnet.Location -KubernetesVersion "1.24.6" -NetworkProfile $aksConfig.NetworkProfile -NodePools $nodePool1Config,$nodePool2Config

Write-Host "AKS Cluster deployment initiated."

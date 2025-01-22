trigger:
- main

pool:
  vmImage: 'ubuntu-latest'

variables:
  aksName: $(AKS_NAME)
  subscriptionId: $(SUBSCRIPTION_ID)
  resourceGroupName: $(RESOURCE_GROUP_NAME)
  vnetResourceId: $(VNET_RESOURCE_ID)
  nodePool1Name: $(NODEPOOL1_NAME)
  nodePool1Nodes: $(NODEPOOL1_NODES)
  nodePool1NetworkType: $(NODEPOOL1_NETWORK_TYPE)
  nodePool1Pods: $(NODEPOOL1_PODS)
  nodePool2Name: $(NODEPOOL2_NAME)
  nodePool2Nodes: $(NODEPOOL2_NODES)
  nodePool2NetworkType: $(NODEPOOL2_NETWORK_TYPE)
  nodePool2Pods: $(NODEPOOL2_PODS)
  clusterType: $(CLUSTER_TYPE)
  rbacType: $(RBAC_TYPE)
  adminUsers: $(ADMIN_USERS)
  userGroups: $(USER_GROUPS)

jobs:
- job: DeployAKS
  displayName: 'Deploy AKS Cluster'
  steps:
  - task: AzureCLI@2
    inputs:
      azureSubscription: $(azureServiceConnection)
      scriptType: ps
      scriptLocation: inlineScript
      inlineScript: |
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
        
        # Call your PowerShell script here with the parameters
        .\aks_deployment.ps1 -AksName $AksName -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -VNetResourceId $VNetResourceId -NodePool1Name $NodePool1Name -NodePool1Nodes $NodePool1Nodes -NodePool1NetworkType $NodePool1NetworkType -NodePool1Pods $NodePool1Pods -NodePool2Name $NodePool2Name -NodePool2Nodes $NodePool2Nodes -NodePool2NetworkType $NodePool2NetworkType -NodePool2Pods $NodePool2Pods -ClusterType $ClusterType -RBACType $RBACType -AdminUsers $AdminUsers -UserGroups $UserGroups
      displayName: 'Deploy AKS Cluster'

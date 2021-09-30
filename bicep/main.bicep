targetScope = 'subscription'
var tags = {
  createdWith: 'bicep'
  project: 'gitops-demo'
}
var logRetentionDays = 30

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'gitops-demo-mgmt'
  location: deployment().location
  tags: tags
}

module lawDeploy 'modules/log_analytics.bicep' = {
  name: 'lawDeploy'
  scope: rg
  params: {
    name: 'mgmtWorkspace'
    tags: tags
    retentionDays: logRetentionDays
    enableContainerInsights: true
  }
}

module mgmtVnet 'modules/virtual_network.bicep' = {
  name: 'mgmtVnet'
  scope: rg
  params: { 
    name: 'mgmtVnet'
    tags: tags
    addressPrefixes: [
      '192.168.25.0/24'
    ]
    subnets: [
      {
        name: 'serverSubnet'
        addressPrefixes: [
          '192.168.25.0/26'
        ]
        privateLinkServiceNetworkPolicies: 'Disabled'
      }
    ]
  }
}
// Requires contributor permission at tenant scope
// https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-to-tenant?tabs=azure-cli#required-access
module spokeToHubPeering 'modules/virtual_network_peering.bicep' = {
  name: 'spokeToHubPeering'
  scope: tenant()
  params: {
    vnet1Name: 'hubnet-vnet'
    vnet1ResourceGroup: 'hubnet'
    vnet1Subscription: 'b464152a-a78e-48f5-85af-268bd1a50744'
    vnet2Name: mgmtVnet.name
    vnet2ResourceGroup: rg.name
  }
}

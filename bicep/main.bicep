// Example CLI usage
// az deployment sub create --location southcentralus --param subscriptionId='00000000-0000-0000-0000-000000000000' -f main.bicep 
param subscriptionId string
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
        properties: {
          addressPrefix: '192.168.25.0/26'
          privateLinkServiceNetworkPolicies: 'Disabled'
          routeTable: {
            id: routeTable.outputs.id
          }
        }
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
    vnet1Subscription: subscriptionId
    vnet2Name: mgmtVnet.name
    vnet2ResourceGroup: rg.name
  }
}

module routeTable 'modules/route_table.bicep' = {
  name: 'routeTable'
  scope: rg
  params: {
    name: 'hub-nva-routes'
    tags: tags
    routes: [
      {
        name: 'vpn-remote-office'
        properties: {
          addressPrefix: '192.168.16.0/21'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '192.168.24.132'
        }
      }
    ]
  }
}

module vm 'modules/virtual_machine.bicep' = {
  name: 'demoVm'
  scope: rg
  params: {
    name: 'demoVm'
    subnetName: 'serverSubnet'
    vnetId: mgmtVnet.outputs.id
/*  enableAcceleratedNetworking: false
    enableIPForwarding:false
    imageOffer: 'UbuntuServer'
    imagePublisher: 'Canonical'
    imageSku: '18.04-LTS'
    imageVersion: 'latest'
    location: resourceGroup().location
    vmSize: 'Standard_B2ms'
    storageType: 'Standard_LRS'
    vmUser: azadmin  */
    tags: tags
  }
}

module acr 'modules/container_registry.bicep' = {
  name: 'demoAcr'
  scope: rg
  params: {
    adminUserEnabled: true
    name: 'demoAcr'
    tags: tags
  }
}

module acrPrivateDns 'modules/private_dns_zone.bicep' = {
  name: 'acrPrivatelink'
  scope: rg
  params: {
    name: 'privatelink.azurecr.io'
    linkedVnets: [
      {
        name: mgmtVnet.name
        registrationEnabled: false
        id: mgmtVnet.outputs.id
      }
    ]
  }
}

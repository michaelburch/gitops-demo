param location string = resourceGroup().location
param name string
param tags object = {}
param sku string = 'Premium'
param publicNetworkAccess string = 'Disabled'
param adminUserEnabled bool = false

var uniqueSuffix = substring(subscription().subscriptionId,(length(subscription().subscriptionId) -5),5)
var uniqueName = '${name}${uniqueSuffix}'
resource acr 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: uniqueName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${acrIdentity.id}': {}
    }
  }
  sku: {
    name: sku
  }
  properties: {
    publicNetworkAccess: publicNetworkAccess
    adminUserEnabled: adminUserEnabled
  }
}

resource acrIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: uniqueName
  location: location
  tags: tags
  
}

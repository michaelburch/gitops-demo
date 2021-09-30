
param tags object = {}
param location string = resourceGroup().location
param name string
param addressPrefixes array = []
param subnets array = []

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = [for subnet in subnets: {
  name: subnet.name
  parent: vnet
  properties: {
    addressPrefix: subnet.addressPrefixes[0]
    privateLinkServiceNetworkPolicies: subnet.privateLinkServiceNetworkPolicies ?? 'Enabled'
  }
}]

output id string = vnet.id

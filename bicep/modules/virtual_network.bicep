param location string = resourceGroup().location
param name string
param tags object = {}
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
    subnets: subnets
  }
}


output id string = vnet.id

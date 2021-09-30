param location string = 'Global'
param name string
param tags object = {}
param linkedVnets array = []

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: name
  tags: tags
  location: location
}

resource vnetLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for vnet in linkedVnets :{
  name: '${vnet.name}link'
  parent: privateDnsZone
  location: location
  tags: tags
  properties: {
    registrationEnabled: vnet.registrationEnabled
    virtualNetwork: {
      id: vnet.id
    }
  }
}]

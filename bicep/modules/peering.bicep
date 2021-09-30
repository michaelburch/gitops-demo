
param parentVnetName string
param remoteVnetId string
param peeringName string = 'hubToSpoke'
param vnetAllowForward bool = true


resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: parentVnetName
}

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: peeringName
  parent: vnet
  properties: {
    remoteVirtualNetwork: {
      id: remoteVnetId
    }
    allowForwardedTraffic: vnetAllowForward
  }
}

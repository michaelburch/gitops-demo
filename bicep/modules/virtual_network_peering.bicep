
param vnet1AllowForward bool = true
param vnet2AllowForward bool = true
param vnet1Subscription string
param vnet2Subscription string = vnet1Subscription
param vnet1ResourceGroup string
param vnet2ResourceGroup string
param vnet1Name string
param vnet2Name string

targetScope = 'tenant'
resource vnet2 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  scope: resourceGroup(vnet2Subscription, vnet2ResourceGroup)
  name: vnet2Name
}
resource vnet1 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  scope: resourceGroup(vnet1Subscription, vnet1ResourceGroup)
  name: vnet1Name
}

module peering1 'peering.bicep' = {
  name: '${vnet1Name}-${vnet2Name}-peering'
  scope: resourceGroup(vnet1Subscription, vnet1ResourceGroup)
  params: {
    peeringName: vnet2Name
    parentVnetName: vnet1Name
    remoteVnetId: vnet2.id
    vnetAllowForward: vnet1AllowForward
  }
}

module peering2 'peering.bicep' = {
  name: '${vnet2Name}-${vnet1Name}-peering'
  scope: resourceGroup(vnet2Subscription, vnet2ResourceGroup)
  params: {
    peeringName: vnet1Name
    parentVnetName: vnet2Name
    remoteVnetId: vnet1.id
    vnetAllowForward: vnet2AllowForward
  }
}


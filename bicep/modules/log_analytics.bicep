param location string = resourceGroup().location
param name string
param tags object = {}
param sku string = 'PerGB2018'
param retentionDays int = 90
param enableContainerInsights bool = false

resource law 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      name: sku
    }
    retentionInDays:  retentionDays
  }
}

resource solutionContainerInsights 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = if (enableContainerInsights) {
  name: 'ContainerInsights(${law.name})'
  location: location
  tags: tags
  properties: {
    workspaceResourceId: law.id
  }
  plan: {
    name: 'ContainerInsights(${law.name})'
    publisher: 'Microsoft'
    product: 'OMSGallery/ContainerInsights'
    promotionCode: ''
  }
}

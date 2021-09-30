param location string = resourceGroup().location
param name string = 'routeTable'
param tags object = {}
param routes array = []

resource routeTable 'Microsoft.Network/routeTables@2021-02-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    routes: routes
  }
}

output id string = routeTable.id

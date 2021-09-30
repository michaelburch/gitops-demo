param tags object = {}
param location string = resourceGroup().location
param name string
param subnetName string
param vnetId string
param enableAcceleratedNetworking bool = false
param enableIPForwarding bool = false
param storageType string = 'Standard_LRS'
param vmSize string = 'Standard_B2ms'
param imagePublisher string = 'Canonical'
param imageOffer string = 'UbuntuServer'
param imageSku string = '18.04-LTS'
param imageVersion string = 'latest'
param vmUser string = 'azadmin'

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: '${name}-nic'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: '${name}-nic-ipconfig'
        properties: {
          privateIPAllocationMethod:'Dynamic'
          primary: true
          privateIPAddressVersion: 'IPv4'
          subnet: {
            id: '${vnetId}/subnets/${subnetName}'
          }
        }
      }
    ]
    enableAcceleratedNetworking: enableAcceleratedNetworking
    enableIPForwarding: enableIPForwarding
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-04-01' = {
  name: name
  tags: tags
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: storageType
        }
      }
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSku
        version: imageVersion
      }  
    }
    osProfile: {
      computerName: name
      adminUsername: vmUser
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              keyData: loadTextContent('../id_rsa.pub')
              path: '/home/${vmUser}/.ssh/authorized_keys'
            }
          ]
        }
      }
    }
  }
}

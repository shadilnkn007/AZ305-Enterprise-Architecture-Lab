targetScope = 'resourceGroup'

param location string
param serverSubnetId string

param domainControllerName string
param entraConnectName string

param domainControllerPrivateIp string

param adminUsername string

@secure()
param adminPassword string

var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var imageSku = '2022-datacenter-azure-edition'

resource dcNic 'Microsoft.Network/networkInterfaces@2025-01-01' = {
  name: '${domainControllerName}-nic'
  location: location

  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'

        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: domainControllerPrivateIp

          subnet: {
            id: serverSubnetId
          }
        }
      }
    ]
  }

  tags: {
    Environment: 'Hybrid'
    Role: 'DomainController'
    Project: 'AZ305'
    Owner: 'Student'
  }
}

resource syncNic 'Microsoft.Network/networkInterfaces@2025-01-01' = {
  name: '${entraConnectName}-nic'
  location: location

  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'

        properties: {
          privateIPAllocationMethod: 'Dynamic'

          subnet: {
            id: serverSubnetId
          }
        }
      }
    ]
  }

  tags: {
    Environment: 'Hybrid'
    Role: 'EntraConnect'
    Project: 'AZ305'
    Owner: 'Student'
  }
}

resource domainController 'Microsoft.Compute/virtualMachines@2025-04-01' = {
  name: domainControllerName
  location: location

  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2ms'
    }

    osProfile: {
      computerName: domainControllerName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }

    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSku
        version: 'latest'
      }

      osDisk: {
        createOption: 'FromImage'

        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }

    networkProfile: {
      networkInterfaces: [
        {
          id: dcNic.id
        }
      ]
    }
  }
}

resource entraConnectServer 'Microsoft.Compute/virtualMachines@2025-04-01' = {
  name: entraConnectName
  location: location

  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2ms'
    }

    osProfile: {
      computerName: entraConnectName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }

    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSku
        version: 'latest'
      }

      osDisk: {
        createOption: 'FromImage'

        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }

    networkProfile: {
      networkInterfaces: [
        {
          id: syncNic.id
        }
      ]
    }
  }
}

output domainControllerPrivateIp string = domainControllerPrivateIp
output domainControllerName string = domainController.name
output entraConnectName string = entraConnectServer.name

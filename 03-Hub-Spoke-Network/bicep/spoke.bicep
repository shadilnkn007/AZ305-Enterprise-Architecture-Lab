targetScope = 'subscription'

param resourceGroupName string
param location string
param vnetName string
param vnetAddressPrefix string

param appGatewaySubnetPrefix string
param applicationSubnetPrefix string
param privateEndpointSubnetPrefix string

resource rg 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: resourceGroupName
  location: location

  tags: {
    Environment: 'Workload'
    Project: 'AZ305'
    Owner: 'Student'
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2025-01-01' = {
  name: vnetName
  location: location

  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }

    subnets: [
      {
        name: 'snet-appgateway'
        properties: {
          addressPrefix: appGatewaySubnetPrefix
        }
      }

      {
        name: 'snet-application'
        properties: {
          addressPrefix: applicationSubnetPrefix
        }
      }

      {
        name: 'snet-private-endpoints'
        properties: {
          addressPrefix: privateEndpointSubnetPrefix
        }
      }
    ]
  }

  tags: {
    Environment: 'Workload'
    Project: 'AZ305'
    Owner: 'Student'
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output resourceGroupName string = rg.name

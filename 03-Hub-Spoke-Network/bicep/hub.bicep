targetScope = 'subscription'

param resourceGroupName string
param location string
param vnetName string
param vnetAddressPrefix string
param includeGatewaySubnet bool = false

resource rg 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: resourceGroupName
  location: location

  tags: {
    Environment: 'Network'
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

    subnets: concat(
      [
        {
          name: 'AzureFirewallSubnet'
          properties: {
            addressPrefix: replace(vnetAddressPrefix, '/16', '.1.0/26')
          }
        }

        {
          name: 'AzureBastionSubnet'
          properties: {
            addressPrefix: replace(vnetAddressPrefix, '/16', '.3.0/26')
          }
        }
      ]

      includeGatewaySubnet
        ? [
            {
              name: 'GatewaySubnet'
              properties: {
                addressPrefix: replace(vnetAddressPrefix, '/16', '.2.0/27')
              }
            }
          ]
        : []
    )
  }

  tags: {
    Environment: 'Network'
    Project: 'AZ305'
    Owner: 'Student'
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output resourceGroupName string = rg.name

targetScope = 'resourceGroup'

param location string
param vnetAddressPrefix string
param serverSubnetPrefix string
param gatewaySubnetPrefix string
param domainControllerPrivateIp string

resource vnet 'Microsoft.Network/virtualNetworks@2025-01-01' = {
  name: 'vnet-az305-onprem-ci'
  location: location

  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }

    dhcpOptions: {
      dnsServers: [
        domainControllerPrivateIp
      ]
    }

    subnets: [
      {
        name: 'snet-onprem-servers'

        properties: {
          addressPrefix: serverSubnetPrefix
        }
      }

      {
        name: 'GatewaySubnet'

        properties: {
          addressPrefix: gatewaySubnetPrefix
        }
      }
    ]
  }

  tags: {
    Environment: 'Hybrid'
    Project: 'AZ305'
    Owner: 'Student'
  }
}

output vnetName string = vnet.name

output serverSubnetId string = resourceId(
  'Microsoft.Network/virtualNetworks/subnets',
  vnet.name,
  'snet-onprem-servers'
)

output gatewaySubnetId string = resourceId(
  'Microsoft.Network/virtualNetworks/subnets',
  vnet.name,
  'GatewaySubnet'
)

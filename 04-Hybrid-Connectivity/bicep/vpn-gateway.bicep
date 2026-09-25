targetScope = 'resourceGroup'

param location string
param gatewayName string
param vnetName string
param publicIpName string
param gatewaySku string = 'VpnGw1AZ'

resource vnet 'Microsoft.Network/virtualNetworks@2025-01-01' existing = {
  name: vnetName
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2025-01-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }

  tags: {
    Project: 'AZ305'
    Owner: 'Student'
  }
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2025-01-01' = {
  name: gatewayName
  location: location

  properties: {
    enableBgp: false
    activeActive: false
    enableDnsForwarding: false

    gatewayType: 'Vpn'

    vpnType: 'RouteBased'

    sku: {
      name: gatewaySku
      tier: gatewaySku
    }

    ipConfigurations: [
      {
        name: 'gatewayIpConfig'

        properties: {
          privateIPAllocationMethod: 'Dynamic'

          subnet: {
            id: resourceId(
              'Microsoft.Network/virtualNetworks/subnets',
              vnet.name,
              'GatewaySubnet'
            )
          }

          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }

  tags: {
    Project: 'AZ305'
    Owner: 'Student'
  }
}

output gatewayName string = vpnGateway.name
output publicIpAddress string = publicIp.properties.ipAddress

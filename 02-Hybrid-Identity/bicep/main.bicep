targetScope = 'subscription'

@description('Resource group for the simulated on-premises environment.')
param resourceGroupName string = 'rg-az305-onprem-ci'

@description('Azure region.')
param location string = 'centralindia'

@description('Simulated on-premises VNet address space.')
param vnetAddressPrefix string = '10.100.0.0/16'

@description('Subnet for the simulated on-premises servers.')
param serverSubnetPrefix string = '10.100.1.0/24'

@description('Reserved subnet for the future VPN Gateway.')
param gatewaySubnetPrefix string = '10.100.255.0/27'

@description('Static private IP address of the Domain Controller.')
param domainControllerPrivateIp string = '10.100.1.10'

@description('Domain Controller VM name.')
param domainControllerName string = 'ONPREM-DC01'

@description('Entra Connect VM name.')
param entraConnectName string = 'ONPREM-ADSYNC01'

@description('Windows administrator username.')
param adminUsername string

@secure()
@description('Windows administrator password.')
param adminPassword string


resource rg 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: resourceGroupName
  location: location

  tags: {
    Environment: 'Hybrid'
    Project: 'AZ305'
    Owner: 'Student'
  }
}


module network './network.bicep' = {
  name: 'onprem-network'
  scope: rg

  params: {
    location: location
    vnetAddressPrefix: vnetAddressPrefix
    serverSubnetPrefix: serverSubnetPrefix
    gatewaySubnetPrefix: gatewaySubnetPrefix
    domainControllerPrivateIp: domainControllerPrivateIp
  }
}


module virtualMachines './vm.bicep' = {
  name: 'onprem-servers'
  scope: rg

  params: {
    location: location
    serverSubnetId: network.outputs.serverSubnetId

    domainControllerName: domainControllerName
    entraConnectName: entraConnectName

    domainControllerPrivateIp: domainControllerPrivateIp

    adminUsername: adminUsername
    adminPassword: adminPassword
  }
}


output resourceGroupName string = rg.name
output vnetName string = network.outputs.vnetName
output domainControllerPrivateIp string = domainControllerPrivateIp
output domainControllerName string = domainControllerName
output entraConnectName string = entraConnectName

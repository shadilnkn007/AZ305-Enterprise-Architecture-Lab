$productionSubscription = "<AZ305-PRODUCTION-SUBSCRIPTION-ID>"
$nonProductionSubscription = "<AZ305-NONPRODUCTION-SUBSCRIPTION-ID>"

Write-Host "Deploying Production spokes..."

az account set --subscription $productionSubscription

az deployment sub create `
    --name az305-prod-ci `
    --location centralindia `
    --template-file ../bicep/spoke.bicep `
    --parameters `
        resourceGroupName=rg-az305-prod-ci `
        location=centralindia `
        vnetName=vnet-az305-prod-ci `
        vnetAddressPrefix=10.11.0.0/16 `
        appGatewaySubnetPrefix=10.11.1.0/24 `
        applicationSubnetPrefix=10.11.2.0/24 `
        privateEndpointSubnetPrefix=10.11.3.0/24

az deployment sub create `
    --name az305-prod-si `
    --location southindia `
    --template-file ../bicep/spoke.bicep `
    --parameters `
        resourceGroupName=rg-az305-prod-si `
        location=southindia `
        vnetName=vnet-az305-prod-si `
        vnetAddressPrefix=10.21.0.0/16 `
        appGatewaySubnetPrefix=10.21.1.0/24 `
        applicationSubnetPrefix=10.21.2.0/24 `
        privateEndpointSubnetPrefix=10.21.3.0/24

Write-Host "Deploying NonProduction spoke..."

az account set --subscription $nonProductionSubscription

az deployment sub create `
    --name az305-nonprod-ci `
    --location centralindia `
    --template-file ../bicep/spoke.bicep `
    --parameters `
        resourceGroupName=rg-az305-nonprod-ci `
        location=centralindia `
        vnetName=vnet-az305-nonprod-ci `
        vnetAddressPrefix=10.12.0.0/16 `
        appGatewaySubnetPrefix=10.12.1.0/24 `
        applicationSubnetPrefix=10.12.2.0/24 `
        privateEndpointSubnetPrefix=10.12.3.0/24

Write-Host "Spoke deployment completed."

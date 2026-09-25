$connectivitySubscription = "<AZ305-CONNECTIVITY-SUBSCRIPTION-ID>"

az account set --subscription $connectivitySubscription

Write-Host "Deploying Central India Hub..."

az deployment sub create `
    --name az305-hub-ci `
    --location centralindia `
    --template-file ../bicep/hub.bicep `
    --parameters ../parameters/connectivity.parameters.json

Write-Host "Deploying South India Hub..."

az deployment sub create `
    --name az305-hub-si `
    --location southindia `
    --template-file ../bicep/hub.bicep `
    --parameters `
        resourceGroupName=rg-az305-hub-si `
        location=southindia `
        vnetName=vnet-az305-hub-si `
        vnetAddressPrefix=10.20.0.0/16 `
        includeGatewaySubnet=false

Write-Host "Hub deployment completed."

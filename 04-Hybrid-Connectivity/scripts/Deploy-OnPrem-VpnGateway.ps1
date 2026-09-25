# ============================================================
# AZ-305 Enterprise Architecture Lab
# Module 04 - Deploy Simulated On-Premises VPN Gateway
# ============================================================

$configPath = Join-Path $PSScriptRoot "..\config\lab-config.ps1"

if (-not (Test-Path $configPath)) {
    Write-Error @"
lab-config.ps1 was not found.

Create it by copying:

config\lab-config.example.ps1

to:

config\lab-config.ps1

Then configure your Connectivity subscription ID.
"@
    exit 1
}

. $configPath

if ([string]::IsNullOrWhiteSpace($ConnectivitySubscriptionId)) {
    Write-Error "ConnectivitySubscriptionId is not configured."
    exit 1
}

Write-Host "Selecting Connectivity subscription..."

az account set `
    --subscription $ConnectivitySubscriptionId

Write-Host "Deploying simulated on-premises VPN Gateway..."

az deployment group create `
    --resource-group rg-az305-onprem-ci `
    --template-file "$PSScriptRoot\..\bicep\vpn-gateway.bicep" `
    --parameters "@$PSScriptRoot\..\parameters\onprem-gateway.parameters.json"

if ($LASTEXITCODE -ne 0) {
    Write-Error "VPN Gateway deployment failed."
    exit 1
}

Write-Host ""
Write-Host "Simulated on-premises VPN Gateway deployment submitted successfully."
Write-Host ""
Write-Host "Gateway:"
Write-Host "  vpngw-az305-onprem-ci"
Write-Host ""
Write-Host "Resource Group:"
Write-Host "  rg-az305-onprem-ci"

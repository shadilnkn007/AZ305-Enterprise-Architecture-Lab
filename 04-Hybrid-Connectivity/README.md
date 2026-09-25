# Module 04 — Hybrid Connectivity

## Overview

In this module, you will connect the simulated on-premises environment created in Module 02 to the Central India Azure hub created in Module 03.

The connection will use an **IPsec/IKEv2 site-to-site VPN**.

Because our simulated on-premises environment is itself hosted in Azure, an Azure VPN Gateway is used to represent the VPN device at the simulated on-premises site.

The resulting architecture is therefore:

```text
Simulated On-Premises
10.100.0.0/16
       |
       |
 VPN Gateway
       |
       | IPsec / IKEv2
       |
 VPN Gateway
       |
Central India Hub
10.10.0.0/16
```

In a real enterprise environment, the simulated on-premises VPN Gateway would instead represent a physical or virtual customer VPN device.

Microsoft's S2S VPN architecture requires a VPN gateway on the Azure side and a VPN device/endpoint representing the on-premises side. A Local Network Gateway represents the remote VPN site and contains its public endpoint and address prefixes.

---

# 1. Learning Objectives

By completing this module, you should understand:

* What a site-to-site VPN is
* How Azure VPN Gateway works
* What a Local Network Gateway represents
* How IPsec/IKEv2 is used for VPN connectivity
* Why a shared key is required
* Why VPN gateways belong in the hub
* How gateway transit allows spokes to use a hub VPN Gateway
* How private IP ranges are routed across the VPN
* How to validate VPN connectivity
* How hybrid connectivity fits into a hub-spoke architecture

---

# 2. Current Architecture

The architecture before this module is:

```text
                 Azure
                   |
        +----------+----------+
        |                     |
 Connectivity             Workloads
        |                     |
   +----+----+          +-----+------+
   |         |          |            |
On-Prem    Hub-CI    Prod-CI     NonProd-CI
   |         |
   |         |
   +---------+
      VPN
```

After this module:

```text
                   Azure
                     |
          +----------+----------+
          |                     |
   Connectivity              Workloads
          |                     |
    +-----+-----+        +------+------+
    |           |        |             |
 On-Prem      Hub-CI   Prod-CI     NonProd-CI
    |           |
    |           |
 VPN Gateway  VPN Gateway
    |           |
    +----IPsec-+
```

---

# 3. Network Address Plan

| Environment           | VNet                    | Address Space   |
| --------------------- | ----------------------- | --------------- |
| Simulated On-Premises | `vnet-az305-onprem-ci`  | `10.100.0.0/16` |
| Central India Hub     | `vnet-az305-hub-ci`     | `10.10.0.0/16`  |
| Production CI         | `vnet-az305-prod-ci`    | `10.11.0.0/16`  |
| NonProduction CI      | `vnet-az305-nonprod-ci` | `10.12.0.0/16`  |
| South India Hub       | `vnet-az305-hub-si`     | `10.20.0.0/16`  |
| Production SI         | `vnet-az305-prod-si`    | `10.21.0.0/16`  |

The VPN will initially connect:

```text
10.100.0.0/16
        ↕
     VPN
        ↕
10.10.0.0/16
```

---

# 4. Why Is the VPN Gateway in the Hub?

The Central India hub is the connectivity boundary for the enterprise architecture.

The intended design is:

```text
                  On-Premises
                      |
                    VPN
                      |
                      v
                  Hub-CI
                 /      \
                /        \
           Prod-CI     NonProd-CI
```

We do not deploy separate VPN Gateways in every workload spoke.

This centralizes:

* Hybrid connectivity
* VPN management
* Routing
* Network security
* Future connectivity services

---

# 5. Why Do We Have Two VPN Gateways?

This is an important distinction.

In a real enterprise environment:

```text
Azure
  |
VPN Gateway
  |
IPsec VPN
  |
Customer VPN Device
  |
On-Premises
```

In our lab, both environments happen to be hosted in Azure.

Therefore:

```text
Azure VNet
    |
VPN Gateway
    |
IPsec VPN
    |
VPN Gateway
    |
Azure VNet
```

The second VPN Gateway is simply our **simulated customer VPN device**.

This allows us to build and test a real VPN connection without requiring physical on-premises infrastructure.

---

# 6. Resources We Will Create

## Central India Hub

```text
Resource Group:
rg-az305-hub-ci
```

Resources:

```text
vpngw-az305-hub-ci
pip-vpngw-az305-hub-ci
```

---

## Simulated On-Premises

```text
Resource Group:
rg-az305-onprem-ci
```

Resources:

```text
vpngw-az305-onprem-ci
pip-vpngw-az305-onprem-ci
```

---

# 7. VPN Gateway Configuration

Both gateways will use:

| Setting              | Value        |
| -------------------- | ------------ |
| Gateway type         | VPN          |
| VPN type             | Route-based  |
| Generation           | Generation 2 |
| SKU                  | `VpnGw1AZ`   |
| BGP                  | Disabled     |
| Active-active        | Disabled     |
| Public IP            | Standard     |
| Public IP allocation | Static       |
| IKE                  | IKEv2        |

Microsoft currently lists `VpnGw1AZ` as a supported zone-redundant VPN Gateway SKU and recommends AZ-supported SKUs for new deployments where available.

> If `VpnGw1AZ` is not available in the student's selected Azure environment, use the smallest currently available **AZ-supported Generation 2 VPN Gateway SKU**.

Do not use the Basic SKU for this lab.

---

# 8. Cost Warning

VPN Gateways are relatively expensive resources compared with ordinary VNets and subnets.

Gateway creation can also take a significant amount of time. Microsoft notes that gateway deployment can take 45 minutes or more depending on the SKU.

Therefore:

> Deploy the VPN Gateways only when you are ready to complete this module.

Remove them during cleanup when the lab is finished.

---

# 9. Prerequisites

Before starting this module, confirm that Modules 02 and 03 are complete.

You should already have:

* `vnet-az305-onprem-ci`
* `GatewaySubnet` in the simulated on-premises VNet
* `vnet-az305-hub-ci`
* `GatewaySubnet` in the Central India hub
* Hub-to-spoke peering
* Three Azure subscriptions
* Azure CLI
* Appropriate permissions

Verify:

```powershell
az account list --output table
```

---

# 10. Repository Configuration

The module uses a local configuration file.

Copy:

```text
config/lab-config.example.ps1
```

to:

```text
config/lab-config.ps1
```

Do not commit `lab-config.ps1` to GitHub.

---

# 11. Configure `lab-config.ps1`

The file should contain:

```powershell
$ConnectivitySubscriptionId = "<YOUR-CONNECTIVITY-SUBSCRIPTION-ID>"

$ProductionSubscriptionId = "<YOUR-PRODUCTION-SUBSCRIPTION-ID>"

$NonProductionSubscriptionId = "<YOUR-NONPRODUCTION-SUBSCRIPTION-ID>"
```

Only the Connectivity subscription is required by this module.

---

# 12. Validate Bicep

Move to:

```text
04-Hybrid-Connectivity
```

Run:

```powershell
az bicep build --file bicep/vpn-gateway.bicep
```

The command should complete without errors.

---

# 13. Deploy the Central India VPN Gateway

Run:

```powershell
.\scripts\Deploy-Hub-VpnGateway.ps1
```

The script will deploy:

```text
rg-az305-hub-ci
    |
    +-- pip-vpngw-az305-hub-ci
    |
    +-- vpngw-az305-hub-ci
```

The gateway will use:

```text
vnet-az305-hub-ci
    |
    +-- GatewaySubnet
        10.10.2.0/27
```

---

# 14. Deploy the Simulated On-Premises VPN Gateway

Run:

```powershell
.\scripts\Deploy-OnPrem-VpnGateway.ps1
```

The script will deploy:

```text
rg-az305-onprem-ci
    |
    +-- pip-vpngw-az305-onprem-ci
    |
    +-- vpngw-az305-onprem-ci
```

The gateway will use:

```text
vnet-az305-onprem-ci
    |
    +-- GatewaySubnet
        10.100.255.0/27
```

---

# 15. Wait for Gateway Deployment

VPN Gateway deployment is slow compared with normal Azure resources.

Check the gateway:

```powershell
az network vnet-gateway show `
    --resource-group rg-az305-hub-ci `
    --name vpngw-az305-hub-ci `
    --query "{Name:name, State:provisioningState}" `
    --output table
```

Expected:

```text
Name                    State
----------------------  ---------
vpngw-az305-hub-ci      Succeeded
```

Repeat for the simulated on-premises gateway:

```powershell
az network vnet-gateway show `
    --resource-group rg-az305-onprem-ci `
    --name vpngw-az305-onprem-ci `
    --query "{Name:name, State:provisioningState}" `
    --output table
```

Do not proceed until both gateways show:

```text
Succeeded
```

---

# 16. Obtain the Public IP Addresses

Central India:

```powershell
az network public-ip show `
    --resource-group rg-az305-hub-ci `
    --name pip-vpngw-az305-hub-ci `
    --query ipAddress `
    --output tsv
```

Save the value as:

```text
<HUB-VPN-PUBLIC-IP>
```

Simulated On-Premises:

```powershell
az network public-ip show `
    --resource-group rg-az305-onprem-ci `
    --name pip-vpngw-az305-onprem-ci `
    --query ipAddress `
    --output tsv
```

Save the value as:

```text
<ONPREM-VPN-PUBLIC-IP>
```

You will need both values for the next steps.

---

# 17. Create Local Network Gateway — Hub Side

We now create an Azure **Local Network Gateway** representing the simulated on-premises VPN endpoint.

Open:

```text
Azure Portal
    >
Local network gateways
    >
Create
```

Configure:

| Setting        | Value                    |
| -------------- | ------------------------ |
| Subscription   | `AZ305-Connectivity`     |
| Resource Group | `rg-az305-hub-ci`        |
| Region         | `Central India`          |
| Name           | `lng-az305-onprem-ci`    |
| Endpoint       | IP address               |
| IP address     | `<ONPREM-VPN-PUBLIC-IP>` |

Address space:

```text
10.100.0.0/16
```

BGP:

```text
Disabled
```

Create the resource.

A Local Network Gateway represents the remote VPN site and contains the remote VPN device's public IP and the address prefixes behind that device.

---

# 18. Create Local Network Gateway — On-Premises Side

Now create another Local Network Gateway.

This one represents the Central India hub from the simulated on-premises side.

Configure:

| Setting        | Value                 |
| -------------- | --------------------- |
| Subscription   | `AZ305-Connectivity`  |
| Resource Group | `rg-az305-onprem-ci`  |
| Region         | `Central India`       |
| Name           | `lng-az305-hub-ci`    |
| Endpoint       | IP address            |
| IP address     | `<HUB-VPN-PUBLIC-IP>` |

Address space:

```text
10.10.0.0/16
```

BGP:

```text
Disabled
```

Create the resource.

---

# 19. Create the VPN Connection — Hub Side

Navigate to:

```text
Virtual network gateways
    >
vpngw-az305-hub-ci
    >
Connections
    >
+ Add
```

Configure:

### Basics

| Setting         | Value                      |
| --------------- | -------------------------- |
| Connection type | Site-to-site (IPSec)       |
| Name            | `conn-az305-hub-to-onprem` |
| Region          | Central India              |

### Settings

| Setting                        | Value                 |
| ------------------------------ | --------------------- |
| Virtual network gateway        | `vpngw-az305-hub-ci`  |
| Local network gateway          | `lng-az305-onprem-ci` |
| Shared key                     | Your lab PSK          |
| IKE protocol                   | IKEv2                 |
| BGP                            | Disabled              |
| Use Azure private IP           | Disabled              |
| FastPath                       | Disabled              |
| IPsec/IKE policy               | Default               |
| Policy-based traffic selectors | Disabled              |
| DPD timeout                    | 45 seconds            |
| Connection mode                | Default               |

Leave NAT rule associations at their default values.

Microsoft's current portal guidance uses Site-to-site (IPSec), IKEv2, default IPsec/IKE policy, BGP disabled, and a matching shared key for this type of configuration.

---

# 20. Create the VPN Connection — Simulated On-Premises Side

Navigate to:

```text
Virtual network gateways
    >
vpngw-az305-onprem-ci
    >
Connections
    >
+ Add
```

Configure:

| Setting                        | Value                      |
| ------------------------------ | -------------------------- |
| Connection type                | Site-to-site (IPSec)       |
| Name                           | `conn-az305-onprem-to-hub` |
| Virtual network gateway        | `vpngw-az305-onprem-ci`    |
| Local network gateway          | `lng-az305-hub-ci`         |
| Shared key                     | **Same PSK used above**    |
| IKE protocol                   | IKEv2                      |
| BGP                            | Disabled                   |
| IPsec/IKE policy               | Default                    |
| Policy-based traffic selectors | Disabled                   |

The shared key must match on both ends.

---

# 21. Important Security Rule

Do not put the shared key into:

```text
parameters.json
```

Do not put it into:

```text
README.md
```

Do not put it into:

```text
GitHub
```

Use a temporary lab PSK and store it only where necessary.

---

# 22. Validate the VPN Connection

Open:

```text
vpngw-az305-hub-ci
    >
Connections
```

Find:

```text
conn-az305-hub-to-onprem
```

The connection should eventually show:

```text
Connected
```

Also verify the reverse connection:

```text
vpngw-az305-onprem-ci
    >
Connections
```

Expected:

```text
conn-az305-onprem-to-hub
```

Status:

```text
Connected
```

Microsoft documents that VPN connection status transitions through provisioning/connection states and can be verified from the gateway's Connections blade.

---

# 23. Validate Using Azure CLI

From the Connectivity subscription:

```powershell
az network vpn-connection list `
    --resource-group rg-az305-hub-ci `
    --output table
```

You should see:

```text
conn-az305-hub-to-onprem
```

To inspect the connection:

```powershell
az network vpn-connection show `
    --name conn-az305-hub-to-onprem `
    --resource-group rg-az305-hub-ci `
    --query "{ProvisioningState:provisioningState,ConnectionStatus:connectionStatus}" `
    --output json
```

Expected:

```json
{
  "ProvisioningState": "Succeeded",
  "ConnectionStatus": "Connected"
}
```

---

# 24. Gateway Transit

The Central India hub was configured in Module 03 to provide gateway transit to:

```text
Prod-CI
NonProd-CI
```

The conceptual traffic path is:

```text
Simulated On-Premises
        |
        | VPN
        v
     Hub-CI
        |
   +----+----+
   |         |
Prod-CI   NonProd-CI
```

The spokes do not require their own VPN Gateway.

Gateway transit allows a peered VNet to use the VPN gateway in another VNet. ([learn.microsoft.com](https://learn.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-peering-gateway-transit?utm_source=chatgpt.com))

---

# 25. Verify Gateway Transit Settings

Open:

```text
vnet-az305-hub-ci
    >
Peerings
```

For:

```text
peer-hub-ci-to-prod-ci
peer-hub-ci-to-nonprod-ci
```

verify that the hub side is configured to:

```text
Allow gateway or route server to forward traffic
```

Then open:

```text
vnet-az305-prod-ci
    >
Peerings
```

and:

```text
vnet-az305-nonprod-ci
    >
Peerings
```

Verify that the spoke side is configured to:

```text
Use the remote virtual network's gateway or route server
```

---

# 26. Why Don't We Connect South India to the VPN?

The current design intentionally centralizes hybrid connectivity through Central India.

```text
                   On-Prem
                      |
                    VPN
                      |
                   Hub-CI
                      |
          +-----------+-----------+
          |                       |
       Prod-CI                NonProd-CI


                   Hub-SI
                      |
                   Prod-SI
```

There is no VPN Gateway in:

```text
Hub-SI
```

This keeps the lab architecture manageable.

---

# 27. Enterprise Discussion

In a real enterprise architecture, the following requirements might justify additional connectivity:

* Independent regional connectivity
* Regulatory requirements
* Regional disaster recovery
* High availability
* Low latency
* Multiple on-premises locations
* ExpressRoute
* Azure Virtual WAN
* Dual ISP connectivity

Those are architectural choices rather than mandatory components of every Azure deployment.

---

# 28. Troubleshooting

## VPN status is Not Connected

Check:

1. Both VPN gateways show `Succeeded`.
2. Both public IP addresses are correct.
3. Local Network Gateway IP addresses are correct.
4. Address spaces are correct.
5. Shared keys match.
6. Both connections use IKEv2.
7. Both connections use compatible IPsec/IKE policies.
8. No NSG has been associated with `GatewaySubnet`.
9. No custom UDR has been incorrectly applied to `GatewaySubnet`.

---

## Address spaces

Verify:

### On-Premises

```text
10.100.0.0/16
```

### Central Hub

```text
10.10.0.0/16
```

They must not overlap.

---

# 29. Architecture Questions

## Question 1

Why is the VPN Gateway deployed in the hub?

---

## Question 2

Why do we need a Local Network Gateway?

---

## Question 3

What does the Local Network Gateway actually represent?

---

## Question 4

Why must the shared key match on both sides?

---

## Question 5

Why are we using IKEv2?

---

## Question 6

Why don't we deploy VPN Gateways in every spoke?

---

## Question 7

What would change if the organization had two physical on-premises locations?

---

## Question 8

When might ExpressRoute be preferable to a site-to-site VPN?

---

# 30. Final Architecture

After completing this module:

```text
                         Azure
                           |
          +----------------+----------------+
          |                                 |
  AZ305-Connectivity                  Workload
          |                                 |
     +----+-----+                    +------+------+
     |          |                    |             |
 On-Prem      Hub-CI              Prod-CI      NonProd-CI
     |          |
     |          |
 VPN GW       VPN GW
     |          |
     +--IPsec---+
```

Network ranges:

```text
On-Premises       10.100.0.0/16

Hub-CI            10.10.0.0/16
Prod-CI           10.11.0.0/16
NonProd-CI        10.12.0.0/16

Hub-SI            10.20.0.0/16
Prod-SI           10.21.0.0/16
```

---

# 31. Cleanup

When you are finished with the module, remove the VPN resources.

Delete:

```text
vpngw-az305-hub-ci
vpngw-az305-onprem-ci
pip-vpngw-az305-hub-ci
pip-vpngw-az305-onprem-ci
```

Also remove:

```text
conn-az305-hub-to-onprem
conn-az305-onprem-to-hub
```

and:

```text
lng-az305-onprem-ci
lng-az305-hub-ci
```

> Do not delete the VNet or GatewaySubnet because later modules depend on them.

---

# Module 04 Complete

At the end of this module, you have established:

* Hybrid connectivity
* Site-to-site VPN
* VPN Gateway
* Local Network Gateway
* IPsec/IKEv2
* Gateway transit
* Centralized hybrid connectivity

The next module is:

# Module 05 — Network Security

We will introduce:

* Azure Firewall
* Firewall Policy
* Network Security Groups
* User Defined Routes
* Hub-to-spoke traffic inspection
* Internet egress control
* Network segmentation
* Security architecture decisions

The architecture will evolve from:

```text
Network
   |
   v
Connectivity
   |
   v
Security
```

# Module 03 — Hub-Spoke Network

## Overview

In this module, you will build the **enterprise network foundation** for the AZ-305 architecture lab.

The design uses a **regional hub-and-spoke topology** with:

* A Central India hub
* A South India hub
* Production spokes
* A Non-Production spoke
* Dedicated networking subnets
* VNet peering
* Separate Azure subscriptions for connectivity and workloads

This network foundation will be reused by the later modules for:

* Azure Firewall
* VPN Gateway
* Application Gateway
* VM Scale Sets
* Private Endpoints
* Azure SQL
* Storage
* Key Vault
* Monitoring
* High availability and disaster recovery

Microsoft's Azure Architecture Center identifies hub-spoke as a common Azure network topology where the hub hosts shared networking services and workload VNets are placed in spokes. A hub is a regional resource, so multi-region deployments can use a hub in each region.

---

# 1. Learning Objectives

By the end of this module, you should understand:

* Why enterprises use a hub-spoke architecture
* Why shared networking services belong in the hub
* Why workloads belong in spoke VNets
* How to design non-overlapping IP address spaces
* How to separate production and non-production environments
* How to use separate Azure subscriptions for workload isolation
* How VNet peering connects hubs and spokes
* Why VNet peering is non-transitive
* Why a regional hub is useful in a multi-region architecture
* How the network foundation supports later security and connectivity requirements

---

# 2. Target Architecture

The completed network will look like this:

```text
                         Azure Tenant
                              |
             +----------------+----------------+
             |                                 |
      AZ305-Connectivity                Workload Subscriptions
             |                                 |
       +-----+------+                  +-------+-------+
       |            |                  |               |
 Central India   South India      Production     NonProduction
     Hub-CI        Hub-SI
       |              |                  |               |
       |              |             +----+----+          |
       |              |             |         |          |
       |              |          Prod-CI    Prod-SI   NonProd-CI
       |              |             |         |          |
       +--------------+-------------+---------+----------+
```

The logical regional design is:

```text
                    CENTRAL INDIA
                         |
                  +------+------+
                  |             |
               Hub-CI       Prod-CI
                  |
              NonProd-CI


                     SOUTH INDIA
                         |
                      Hub-SI
                         |
                      Prod-SI
```

---

# 3. Subscription Design

The lab uses three subscriptions.

| Subscription          | Purpose                                                 |
| --------------------- | ------------------------------------------------------- |
| `AZ305-Connectivity`  | Shared networking and simulated on-premises environment |
| `AZ305-Production`    | Production workloads                                    |
| `AZ305-NonProduction` | Development/test workloads                              |

This separation demonstrates how subscriptions can provide:

* RBAC boundaries
* Billing boundaries
* Resource management boundaries
* Environment isolation

---

# 4. Network Address Plan

All VNets use unique address spaces.

| Network               | Subscription  | Region        | Address Space   |
| --------------------- | ------------- | ------------- | --------------- |
| Simulated On-Premises | Connectivity  | Central India | `10.100.0.0/16` |
| Hub-CI                | Connectivity  | Central India | `10.10.0.0/16`  |
| Hub-SI                | Connectivity  | South India   | `10.20.0.0/16`  |
| Prod-CI               | Production    | Central India | `10.11.0.0/16`  |
| Prod-SI               | Production    | South India   | `10.21.0.0/16`  |
| NonProd-CI            | NonProduction | Central India | `10.12.0.0/16`  |

## Important

Do not change these address spaces without understanding the impact on later modules.

The address spaces have been intentionally planned so they do not overlap.

---

# 5. Central India Hub

```text
vnet-az305-hub-ci
10.10.0.0/16
│
├── AzureFirewallSubnet
│   10.10.1.0/26
│
├── GatewaySubnet
│   10.10.2.0/27
│
└── AzureBastionSubnet
    10.10.3.0/26
```

### Purpose

The Central India hub will eventually contain:

* Azure Firewall
* VPN Gateway
* Azure Bastion

The actual services are deployed in later modules.

The subnets are being reserved now so that the network architecture does not need to be redesigned later.

Azure Firewall requires a dedicated subnet named `AzureFirewallSubnet`; Microsoft currently recommends `/26` or larger. VPN Gateway uses a subnet named `GatewaySubnet`; Microsoft recommends `/27` or larger.

---

# 6. South India Hub

```text
vnet-az305-hub-si
10.20.0.0/16
│
├── AzureFirewallSubnet
│   10.20.1.0/26
│
└── AzureBastionSubnet
    10.20.3.0/26
```

The South India hub does **not** contain a GatewaySubnet in this lab.

The hybrid connectivity entry point is intentionally centralized through the Central India hub.

---

# 7. Production — Central India

```text
vnet-az305-prod-ci
10.11.0.0/16
│
├── snet-appgateway
│   10.11.1.0/24
│
├── snet-application
│   10.11.2.0/24
│
└── snet-private-endpoints
    10.11.3.0/24
```

Later modules will use these subnets for:

```text
snet-appgateway
    |
    +-- Application Gateway WAF

snet-application
    |
    +-- VM Scale Set
    +-- Internal Load Balancer

snet-private-endpoints
    |
    +-- Azure SQL
    +-- Storage
    +-- Key Vault
```

---

# 8. Production — South India

```text
vnet-az305-prod-si
10.21.0.0/16
│
├── snet-appgateway
│   10.21.1.0/24
│
├── snet-application
│   10.21.2.0/24
│
└── snet-private-endpoints
    10.21.3.0/24
```

The South India production network intentionally mirrors the Central India production design.

This simplifies the later high-availability and disaster-recovery implementation.

---

# 9. Non-Production — Central India

```text
vnet-az305-nonprod-ci
10.12.0.0/16
│
├── snet-appgateway
│   10.12.1.0/24
│
├── snet-application
│   10.12.2.0/24
│
└── snet-private-endpoints
    10.12.3.0/24
```

This provides network isolation between:

```text
Production
    |
    X
    |
Non-Production
```

The environments are separated at both the subscription and VNet levels.

---

# 10. Peering Design

The initial peering design is:

```text
Central Hub
    |
    +---- Prod-CI
    |
    +---- NonProd-CI


South Hub
    |
    +---- Prod-SI
```

We will **not** create direct spoke-to-spoke peerings at this stage.

VNet peering is non-transitive. For example:

```text
Prod-CI
   |
   | Peering
   |
Hub-CI
   |
   | Peering
   |
NonProd-CI
```

does not automatically mean:

```text
Prod-CI <----> NonProd-CI
```

If spoke-to-spoke communication is required, it must be deliberately designed using direct peering, Azure Firewall/NVA routing, or another supported connectivity mechanism.

---

# 11. Why Hub-Spoke?

The hub provides a centralized location for shared services.

For this lab:

```text
                    HUB
                     |
       +-------------+-------------+
       |             |             |
    Firewall       VPN          Bastion
       |          Gateway          |
       |             |             |
       +-------------+-------------+
                     |
                  SPOKES
```

This avoids duplicating common infrastructure inside every workload VNet.

Microsoft's current guidance also recommends keeping application workloads out of the hub and placing shared networking services in the hub.

---

# 12. Configuration

The deployment scripts require subscription IDs.

Do not hard-code your personal subscription IDs into the GitHub scripts.

Instead, create a local configuration file.

Copy:

```text
config/lab-config.example.ps1
```

to:

```text
config/lab-config.ps1
```

The local file will be ignored by Git.

---

# 13. Configure Your Lab

Open:

```text
config/lab-config.ps1
```

Set:

```powershell
$ConnectivitySubscriptionId = "<YOUR-CONNECTIVITY-SUBSCRIPTION-ID>"

$ProductionSubscriptionId = "<YOUR-PRODUCTION-SUBSCRIPTION-ID>"

$NonProductionSubscriptionId = "<YOUR-NONPRODUCTION-SUBSCRIPTION-ID>"
```

Do not commit this file to GitHub.

---

# 14. Verify Azure Login

Login:

```powershell
az login
```

Verify the subscriptions:

```powershell
az account list --output table
```

You should have access to:

```text
AZ305-Connectivity
AZ305-Production
AZ305-NonProduction
```

---

# 15. Validate Bicep

From:

```text
03-Hub-Spoke-Network
```

run:

```powershell
az bicep build --file bicep/hub.bicep
```

Then:

```powershell
az bicep build --file bicep/spoke.bicep
```

Both commands should complete without errors.

---

# 16. What-If — Central India Hub

Select the Connectivity subscription:

```powershell
az account set --subscription $ConnectivitySubscriptionId
```

Run:

```powershell
az deployment sub what-if `
    --location centralindia `
    --template-file bicep/hub.bicep `
    --parameters @parameters/connectivity.parameters.json
```

Review the resources before deployment.

Expected:

```text
rg-az305-hub-ci
    |
    +-- vnet-az305-hub-ci
          |
          +-- AzureFirewallSubnet
          +-- GatewaySubnet
          +-- AzureBastionSubnet
```

---

# 17. Deploy the Hubs

Run:

```powershell
.\scripts\Deploy-Hubs.ps1
```

The script creates:

### Central India

```text
rg-az305-hub-ci
vnet-az305-hub-ci
```

### South India

```text
rg-az305-hub-si
vnet-az305-hub-si
```

---

# 18. Validate the Hubs

List resources:

```powershell
az resource list `
    --resource-group rg-az305-hub-ci `
    --output table
```

Check the VNet:

```powershell
az network vnet show `
    --resource-group rg-az305-hub-ci `
    --name vnet-az305-hub-ci `
    --output table
```

List subnets:

```powershell
az network vnet subnet list `
    --resource-group rg-az305-hub-ci `
    --vnet-name vnet-az305-hub-ci `
    --output table
```

Expected:

```text
AzureFirewallSubnet
GatewaySubnet
AzureBastionSubnet
```

---

# 19. Deploy the Spokes

Run:

```powershell
.\scripts\Deploy-Spokes.ps1
```

The script creates:

```text
AZ305-Production
│
├── rg-az305-prod-ci
│   └── vnet-az305-prod-ci
│
└── rg-az305-prod-si
    └── vnet-az305-prod-si


AZ305-NonProduction
│
└── rg-az305-nonprod-ci
    └── vnet-az305-nonprod-ci
```

---

# 20. Validate Spoke VNets

For example:

```powershell
az network vnet show `
    --resource-group rg-az305-prod-ci `
    --name vnet-az305-prod-ci `
    --output table
```

List the subnets:

```powershell
az network vnet subnet list `
    --resource-group rg-az305-prod-ci `
    --vnet-name vnet-az305-prod-ci `
    --output table
```

Expected:

```text
snet-appgateway
snet-application
snet-private-endpoints
```

Repeat validation for:

```text
vnet-az305-prod-si
vnet-az305-nonprod-ci
```

---

# 21. Create VNet Peerings Using Azure Portal

In this lab, VNet peering will be configured manually through the **Azure Portal**.

This is intentional.

The purpose is to allow you to understand the individual peering settings and the relationship between the hub and spoke networks.

Azure VNet peering is configured as a relationship between two VNets. For cross-subscription peering, you must have the appropriate permissions in both subscriptions.

---

## 21.1 Peering Relationships

Create the following peering relationships:

```text
Central India Hub
    |
    +---- Prod-CI
    |
    +---- NonProd-CI


South India Hub
    |
    +---- Prod-SI
```

Do **not** create direct peering between:

```text
Prod-CI <----> Prod-SI
```

or:

```text
Prod-CI <----> NonProd-CI
```

The hub is intended to be the central networking boundary.

---

# 21.2 Central India Hub → Production CI

Open the Azure Portal.

Navigate to:

```text
Virtual networks
    >
vnet-az305-hub-ci
    >
Peerings
    >
+ Add
```

Configure the peering as follows.

### This virtual network

| Setting                                                                          | Value                    |
| -------------------------------------------------------------------------------- | ------------------------ |
| Peering link name                                                                | `peer-hub-ci-to-prod-ci` |
| Allow `vnet-az305-hub-ci` to access the peered VNet                              | Enabled                  |
| Allow forwarded traffic from the peered VNet                                     | Enabled                  |
| Allow gateway or route server in this VNet to forward traffic to the peered VNet | **Enabled**              |
| Enable this VNet to use the remote VNet's gateway or route server                | **Disabled**             |

### Remote virtual network

Select:

```text
vnet-az305-prod-ci
```

from:

```text
AZ305-Production
```

Configure:

| Setting                                                                          | Value                    |
| -------------------------------------------------------------------------------- | ------------------------ |
| Peering link name                                                                | `peer-prod-ci-to-hub-ci` |
| Allow the peered VNet to access `vnet-az305-hub-ci`                              | Enabled                  |
| Allow forwarded traffic from the peered VNet                                     | Enabled                  |
| Allow gateway or route server in the peered VNet to forward traffic to this VNet | **Disabled**             |
| Enable the peered VNet to use `vnet-az305-hub-ci`'s gateway or route server      | **Enabled**              |

> **Important:** Gateway transit settings are being configured because the Central India hub will later contain the hybrid VPN Gateway. The spoke will eventually use the hub gateway rather than having its own VPN Gateway.

Click:

**Add**

---

# 21.3 Central India Hub → Non-Production CI

Navigate to:

```text
Virtual networks
    >
vnet-az305-hub-ci
    >
Peerings
    >
+ Add
```

Configure:

### This virtual network

| Setting                                       | Value                       |
| --------------------------------------------- | --------------------------- |
| Peering link name                             | `peer-hub-ci-to-nonprod-ci` |
| Allow access                                  | Enabled                     |
| Allow forwarded traffic                       | Enabled                     |
| Allow gateway/route server to forward traffic | **Enabled**                 |
| Use remote gateway/route server               | **Disabled**                |

### Remote virtual network

Select:

```text
vnet-az305-nonprod-ci
```

from:

```text
AZ305-NonProduction
```

Configure:

| Setting                                       | Value                       |
| --------------------------------------------- | --------------------------- |
| Peering link name                             | `peer-nonprod-ci-to-hub-ci` |
| Allow access                                  | Enabled                     |
| Allow forwarded traffic                       | Enabled                     |
| Allow gateway/route server to forward traffic | **Disabled**                |
| Use remote gateway/route server               | **Enabled**                 |

Click:

**Add**

---

# 21.4 South India Hub → Production SI

Navigate to:

```text
Virtual networks
    >
vnet-az305-hub-si
    >
Peerings
    >
+ Add
```

Configure:

### This virtual network

| Setting                                       | Value                    |
| --------------------------------------------- | ------------------------ |
| Peering link name                             | `peer-hub-si-to-prod-si` |
| Allow access                                  | Enabled                  |
| Allow forwarded traffic                       | Enabled                  |
| Allow gateway/route server to forward traffic | **Enabled**              |
| Use remote gateway/route server               | **Disabled**             |

### Remote virtual network

Select:

```text
vnet-az305-prod-si
```

from:

```text
AZ305-Production
```

Configure:

| Setting                                       | Value                    |
| --------------------------------------------- | ------------------------ |
| Peering link name                             | `peer-prod-si-to-hub-si` |
| Allow access                                  | Enabled                  |
| Allow forwarded traffic                       | Enabled                  |
| Allow gateway/route server to forward traffic | **Disabled**             |
| Use remote gateway/route server               | **Enabled**              |

Click:

**Add**

---

# 21.5 Why Are Gateway Options Different?

The important concept is that the **hub owns the gateway**.

The architecture is:

```text
                    Central Hub
                         |
                    VPN Gateway
                         |
          +--------------+--------------+
          |                             |
       Prod-CI                       NonProd-CI
```

The spokes should therefore be configured to use the hub's gateway.

This is called **gateway transit**.

The relevant relationship is:

```text
Hub
 |
 | allow gateway transit
 v
Spoke
 |
 | use remote gateway
 v
Hub VPN Gateway
```

Microsoft documents gateway transit as the mechanism that allows a peered VNet to use the VPN gateway in another VNet. ([learn.microsoft.com](https://learn.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-peering-gateway-transit?utm_source=chatgpt.com))

---

# 21.6 Important: Gateway Transit Will Not Work Yet

At this stage, there is **no VPN Gateway deployed**.

Therefore, students may see gateway-related configuration options but there is no actual gateway to use yet.

That is expected.

The VPN Gateway will be introduced in:

**Module 04 — Hybrid Connectivity**

The sequence is intentionally:

```text
Module 03
Create VNets
     |
     v
Create Peering
     |
     v
Module 04
Deploy VPN Gateway
     |
     v
Configure Gateway Transit
     |
     v
Connect Simulated On-Premises
```

---

# 22. Validate the Peerings

After creating the peerings, open:

```text
Virtual networks
    >
vnet-az305-hub-ci
    >
Peerings
```

You should see:

```text
peer-hub-ci-to-prod-ci
peer-hub-ci-to-nonprod-ci
```

Both should eventually show:

```text
Peering status: Connected
```

---

## Validate Production CI

Open:

```text
vnet-az305-prod-ci
    >
Peerings
```

Expected:

```text
peer-prod-ci-to-hub-ci
```

Status:

```text
Connected
```

---

## Validate Non-Production CI

Open:

```text
vnet-az305-nonprod-ci
    >
Peerings
```

Expected:

```text
peer-nonprod-ci-to-hub-ci
```

Status:

```text
Connected
```

---

## Validate South India

Open:

```text
vnet-az305-hub-si
    >
Peerings
```

Expected:

```text
peer-hub-si-to-prod-si
```

Then verify:

```text
vnet-az305-prod-si
    >
Peerings
```

Expected:

```text
peer-prod-si-to-hub-si
```

---

# 23. Peering Validation Checklist

Before continuing, confirm:

| Peering              | Expected Status |
| -------------------- | --------------- |
| Hub-CI ↔ Prod-CI     | Connected       |
| Hub-CI ↔ NonProd-CI  | Connected       |
| Hub-SI ↔ Prod-SI     | Connected       |
| Prod-CI ↔ Prod-SI    | Not configured  |
| Prod-CI ↔ NonProd-CI | Not configured  |

---

# 24. Architecture Exercise

Now consider the following.

### Scenario

The production application in Central India needs to communicate with a service in the Central India hub.

Which path should the traffic take?

```text
Prod-CI
   |
   v
Hub-CI
   |
   v
Shared Network Service
```

---

### Scenario

The production application in South India needs to communicate with the South India hub.

Expected:

```text
Prod-SI
   |
   v
Hub-SI
```

---

### Scenario

A workload in `Prod-CI` needs to communicate directly with `NonProd-CI`.

There is currently no direct peering.

Ask:

> Should we create direct peering, or should the traffic be routed through a centralized network security service?

This decision will be addressed later when we introduce:

* Azure Firewall
* UDRs
* Network security controls

Do not create additional peerings just to make the connectivity work.

---

# 25. Important Design Principle

Do not assume that:

```text
Hub ↔ Spoke
```

automatically means:

```text
Spoke ↔ Spoke
```

Azure VNet peering is **non-transitive**.

The architecture must explicitly define how traffic should flow between networks.

This is one of the important decisions you should be able to explain as an Azure Solution Architect.

---

# Module 03 Peering Complete

The network now has:

```text
                    Hub-CI
                   /      \
                  /        \
             Prod-CI      NonProd-CI


                    Hub-SI
                       |
                    Prod-SI
```

The next module will introduce the connectivity layer:

**Module 04 — Hybrid Connectivity**

There we will connect:

```text
Simulated On-Premises
        |
        | S2S VPN
        v
Central India Hub
```

and introduce the VPN Gateway and gateway transit configuration.

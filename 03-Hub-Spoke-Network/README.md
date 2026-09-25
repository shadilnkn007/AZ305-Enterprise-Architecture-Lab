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

# 21. Create VNet Peerings

After all VNets exist, create the hub-to-spoke peerings.

The final relationships should be:

```text
Hub-CI
  |
  +---- Prod-CI
  |
  +---- NonProd-CI

Hub-SI
  |
  +---- Prod-SI
```

Each peering requires a relationship in **both directions**.

For example:

```text
Hub-CI
   |
   +---- Peering ----> Prod-CI
   |
   <---- Peering ----+
                    Prod-CI
```

This will be automated in the next version of the deployment script.

---

# 22. Validate the Architecture

After peering is created, verify the relationships:

```powershell
az network vnet peering list `
    --resource-group rg-az305-hub-ci `
    --vnet-name vnet-az305-hub-ci `
    --output table
```

You should eventually see:

```text
Prod-CI
NonProd-CI
```

Similarly:

```powershell
az network vnet peering list `
    --resource-group rg-az305-hub-si `
    --vnet-name vnet-az305-hub-si `
    --output table
```

Expected:

```text
Prod-SI
```

---

# 23. Architecture Decision Exercise

Before moving to the next module, answer these questions.

### Question 1

Why isn't the production application deployed directly into the hub?

---

### Question 2

Why do Production and Non-Production use separate subscriptions?

---

### Question 3

Why do we use a separate hub for South India?

---

### Question 4

Why do all VNets have non-overlapping address spaces?

---

### Question 5

Why isn't `Prod-CI` directly peered with `NonProd-CI`?

---

### Question 6

Where should Azure Firewall eventually be deployed?

---

### Question 7

Where should the VPN Gateway eventually be deployed?

---

### Question 8

Why don't we deploy a VPN Gateway in every spoke?

Microsoft's hub-spoke guidance describes using the centralized hub gateway for spoke connectivity rather than deploying a gateway in every spoke. Gateway transit can allow spokes to use the hub's VPN gateway.

---

# 24. Expected Final State

At the end of this module:

```text
                    Azure
                      |
          +-----------+-----------+
          |                       |
  AZ305-Connectivity       Workload Subscriptions
          |                       |
    +-----+-----+          +------+------+
    |           |          |             |
 Hub-CI       Hub-SI    Production   NonProduction
    |           |          |             |
 +--+--+        |       +--+--+          |
 |     |        |       |     |          |
Prod  NonProd  Prod   Prod-CI Prod-SI  NonProd-CI
 CI      CI     SI
```

Network ranges:

```text
On-Premises     10.100.0.0/16

Hub-CI          10.10.0.0/16
Prod-CI         10.11.0.0/16
NonProd-CI      10.12.0.0/16

Hub-SI          10.20.0.0/16
Prod-SI         10.21.0.0/16
```

---

# 25. What Comes Next?

This module establishes the network foundation.

The next modules will progressively add:

```text
Module 03
Hub-Spoke Network
       |
       v
Module 04
Hybrid Connectivity
       |
       v
Module 05
Network Security
       |
       v
Module 06
Application Platform
```

The important architectural progression is:

```text
Networks
   |
   v
Connectivity
   |
   v
Security
   |
   v
Application
```

Do not deploy Azure Firewall, VPN Gateway, Application Gateway or workloads in this module unless specifically instructed.

---

# Module Complete

You have established the enterprise hub-spoke network foundation.

The next module will connect the simulated on-premises environment created in Module 02 to the Central India hub using **site-to-site VPN connectivity**.

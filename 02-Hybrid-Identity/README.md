# Module 02 — Hybrid Identity

## Overview

In this module, you will build a **simulated on-premises Active Directory environment in Azure**.

The environment will be used later in the lab to demonstrate:

* Hybrid connectivity
* Active Directory integration
* Microsoft Entra Connect Sync
* Hybrid identity
* Authentication and authorization
* Secure communication between on-premises and Azure

The simulated on-premises environment is intentionally hosted in Azure to keep the lab completely cloud-based and easy for students to reproduce.

---

## Architecture

The environment will be deployed in the **Central India** region in the `AZ305-Connectivity` subscription.

```text
                         Azure Tenant
                              |
                    AZ305-Connectivity
                              |
                       Central India
                              |
                 Simulated On-Premises VNet
                       10.100.0.0/16
                              |
             +----------------+----------------+
             |                                 |
     Server Subnet                       GatewaySubnet
      10.100.1.0/24                     10.100.255.0/27
             |                                 |
       +-----+------+                    Future VPN
       |            |                     Gateway
       |            |
 ONPREM-DC01   ONPREM-ADSYNC01
 10.100.1.10       Dynamic IP
       |            |
       |            |
   AD DS + DNS   Entra Connect
       |
       |
   contoso.local
```

---

# 1. What You Will Build

You will create:

| Component              | Purpose                              |
| ---------------------- | ------------------------------------ |
| `vnet-az305-onprem-ci` | Simulated on-premises network        |
| `snet-onprem-servers`  | Server subnet                        |
| `GatewaySubnet`        | Reserved for future VPN Gateway      |
| `ONPREM-DC01`          | Domain Controller                    |
| `ONPREM-ADSYNC01`      | Microsoft Entra Connect server       |
| `contoso.local`        | On-premises AD domain                |
| AD DNS                 | Internal name resolution             |
| Test users             | Demonstrate identity synchronization |

---

# 2. Azure Environment

| Setting              | Value                  |
| -------------------- | ---------------------- |
| Subscription         | `AZ305-Connectivity`   |
| Region               | `Central India`        |
| Resource Group       | `rg-az305-onprem-ci`   |
| VNet                 | `vnet-az305-onprem-ci` |
| VNet Address Space   | `10.100.0.0/16`        |
| Server Subnet        | `10.100.1.0/24`        |
| GatewaySubnet        | `10.100.255.0/27`      |
| Domain               | `contoso.local`        |
| NetBIOS Name         | `CONTOSO`              |
| Domain Controller    | `ONPREM-DC01`          |
| Domain Controller IP | `10.100.1.10`          |
| Entra Connect Server | `ONPREM-ADSYNC01`      |

---

# 3. Important Architecture Decisions

## 3.1 Why simulate on-premises in Azure?

This lab is designed to be reproducible without requiring:

* A physical server
* A home lab
* VMware
* Hyper-V
* A physical firewall
* A physical VPN appliance

Azure VMs provide a controlled environment that behaves similarly to an on-premises Active Directory environment for the purposes of this lab.

---

## 3.2 Why use a dedicated Domain Controller?

`ONPREM-DC01` provides:

* Active Directory Domain Services
* DNS
* Domain authentication
* User accounts
* Directory services

The Domain Controller is deliberately kept separate from the Entra Connect server.

This reflects a common enterprise architecture where identity infrastructure has dedicated roles.

---

## 3.3 Why use a static private IP for the Domain Controller?

The Domain Controller uses:

```text
10.100.1.10
```

as its private IP.

This provides a predictable DNS endpoint.

The VNet uses the Domain Controller as its custom DNS server.

```text
VNet
 |
 +-- Custom DNS
       |
       +-- 10.100.1.10
              |
              +-- ONPREM-DC01
                    |
                    +-- AD DS
                    +-- DNS
```

---

## 3.4 Why reserve GatewaySubnet?

The VNet will eventually participate in the hybrid connectivity design.

Therefore, we reserve:

```text
GatewaySubnet
10.100.255.0/27
```

for the future VPN Gateway.

The VPN Gateway itself is **not deployed in this module**.

It will be introduced in:

**Module 04 — Hybrid Connectivity**

Do not deploy other workloads into `GatewaySubnet`.

---

# 4. Security Decisions

The simulated on-premises servers will **not have public IP addresses**.

```text
Internet
   X
   |
   X
ONPREM-DC01
ONPREM-ADSYNC01
```

Students should not expose:

* RDP
* SMB
* LDAP
* Kerberos
* DNS

directly to the Internet.

Administrative access should be performed through Azure management capabilities such as:

* Azure Run Command
* Azure Bastion, where introduced later

This demonstrates an important enterprise principle:

> Infrastructure servers should not be directly exposed to the public Internet simply to make administration easier.

---

# 5. Prerequisites

Before starting this module, make sure you have:

* An Azure subscription
* Access to the `AZ305-Connectivity` subscription
* Azure CLI installed
* Bicep support in Azure CLI
* Permission to create resource groups and resources
* Permission to deploy Windows VMs

Verify Azure CLI:

```powershell
az version
```

Login:

```powershell
az login
```

List subscriptions:

```powershell
az account list --output table
```

Select the Connectivity subscription:

```powershell
az account set --subscription "<AZ305-Connectivity-SUBSCRIPTION-ID>"
```

Verify:

```powershell
az account show --output table
```

---

# 6. Repository Structure

Your module should contain:

```text
02-Hybrid-Identity/
│
├── README.md
├── parameters.json
│
├── bicep/
│   ├── main.bicep
│   ├── network.bicep
│   └── vm.bicep
│
└── scripts/
    ├── Install-ADDS.ps1
    └── Create-TestUsers.ps1
```

> Never store passwords or other secrets in GitHub.

---

# 7. Validate the Bicep Files

Move into the module directory:

```powershell
cd 02-Hybrid-Identity
```

Build the Bicep template:

```powershell
az bicep build --file bicep/main.bicep
```

The command should complete without errors.

If the command reports an error, fix the Bicep issue before continuing.

---

# 8. Run What-If

Before creating resources, inspect the deployment.

```powershell
az deployment sub what-if `
  --location centralindia `
  --template-file bicep/main.bicep `
  --parameters @parameters.json
```

Review the expected resources.

You should see resources corresponding to:

* Resource Group
* Virtual Network
* Server subnet
* GatewaySubnet
* Domain Controller NIC
* Entra Connect NIC
* Domain Controller VM
* Entra Connect VM

Do not continue if the deployment shows unexpected resources.

---

# 9. Deploy the Environment

The deployment requires a Windows administrator password.

Do not place the password inside `parameters.json`.

Deploy using:

```powershell
az deployment sub create `
  --name az305-hybrid-identity `
  --location centralindia `
  --template-file bicep/main.bicep `
  --parameters @parameters.json `
  --parameters adminPassword="<YOUR-PASSWORD>"
```

Replace:

```text
<YOUR-PASSWORD>
```

with a strong temporary lab password.

---

# 10. Verify the Deployment

List the resource group:

```powershell
az resource list `
  --resource-group rg-az305-onprem-ci `
  --output table
```

You should see the VNet, NICs and VMs.

Check the VNet:

```powershell
az network vnet show `
  --resource-group rg-az305-onprem-ci `
  --name vnet-az305-onprem-ci `
  --output table
```

Check the Domain Controller NIC:

```powershell
az network nic show `
  --resource-group rg-az305-onprem-ci `
  --name ONPREM-DC01-nic `
  --query "ipConfigurations[].privateIPAddress" `
  --output tsv
```

Expected:

```text
10.100.1.10
```

---

# 11. Verify DNS Configuration

The VNet is configured to use:

```text
10.100.1.10
```

as its custom DNS server.

Check the VNet:

```powershell
az network vnet show `
  --resource-group rg-az305-onprem-ci `
  --name vnet-az305-onprem-ci `
  --query "dhcpOptions.dnsServers" `
  --output json
```

Expected:

```json
[
  "10.100.1.10"
]
```

At this stage the DNS server does not yet exist as a functioning DNS service.

It will become available after AD DS is installed.

---

# 12. Configure the Domain Controller

The first server to configure is:

```text
ONPREM-DC01
```

The server will become:

```text
Active Directory Domain Controller
+
DNS Server
```

---

# 13. Install AD DS

Azure Run Command can be used to execute PowerShell commands on the VM without exposing RDP to the Internet.

Run:

```powershell
az vm run-command invoke `
  --resource-group rg-az305-onprem-ci `
  --name ONPREM-DC01 `
  --command-id RunPowerShellScript `
  --scripts @scripts/Install-ADDS.ps1
```

The script installs:

```text
Active Directory Domain Services
DNS
```

and creates:

```text
contoso.local
```

---

# 14. Verify the Domain Controller

After the installation completes, the VM will restart.

Wait a few minutes.

Check the VM:

```powershell
az vm get-instance-view `
  --resource-group rg-az305-onprem-ci `
  --name ONPREM-DC01 `
  --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" `
  --output tsv
```

Expected:

```text
VM running
```

---

# 15. Validate Active Directory

Use Run Command:

```powershell
az vm run-command invoke `
  --resource-group rg-az305-onprem-ci `
  --name ONPREM-DC01 `
  --command-id RunPowerShellScript `
  --scripts "Get-ADDomain"
```

You should see information about:

```text
DNSRoot       : contoso.local
NetBIOSName   : CONTOSO
DomainMode    : ...
```

---

# 16. Validate DNS

Run:

```powershell
az vm run-command invoke `
  --resource-group rg-az305-onprem-ci `
  --name ONPREM-DC01 `
  --command-id RunPowerShellScript `
  --scripts "Get-Service DNS"
```

The DNS service should show:

```text
Running
```

You can also test:

```powershell
az vm run-command invoke `
  --resource-group rg-az305-onprem-ci `
  --name ONPREM-DC01 `
  --command-id RunPowerShellScript `
  --scripts "nslookup contoso.local"
```

---

# 17. Create Test Users

The lab uses two sample users:

```text
alice
bob
```

Run:

```powershell
az vm run-command invoke `
  --resource-group rg-az305-onprem-ci `
  --name ONPREM-DC01 `
  --command-id RunPowerShellScript `
  --scripts @scripts/Create-TestUsers.ps1
```

The script will prompt for the password.

Use a temporary lab password.

Do not commit the password to GitHub.

---

# 18. Verify the Users

Run:

```powershell
az vm run-command invoke `
  --resource-group rg-az305-onprem-ci `
  --name ONPREM-DC01 `
  --command-id RunPowerShellScript `
  --scripts "Get-ADUser -Filter * | Select-Object Name,SamAccountName"
```

You should see:

```text
Alice
Bob
```

---

# 19. Prepare ONPREM-ADSYNC01

The second server is:

```text
ONPREM-ADSYNC01
```

Its role is:

```text
Microsoft Entra Connect Sync
```

It should **not** be promoted to a Domain Controller.

---

# 20. Verify DNS from ONPREM-ADSYNC01

Because the VNet uses:

```text
10.100.1.10
```

as its custom DNS server, the server should use the Domain Controller for DNS.

Run:

```powershell
az vm run-command invoke `
  --resource-group rg-az305-onprem-ci `
  --name ONPREM-ADSYNC01 `
  --command-id RunPowerShellScript `
  --scripts "nslookup contoso.local"
```

The DNS server should be:

```text
10.100.1.10
```

---

# 21. Join ONPREM-ADSYNC01 to the Domain

Use Run Command to join the server to:

```text
contoso.local
```

The command requires credentials for a domain account with permission to join computers to the domain.

Example:

```powershell
$credential = Get-Credential

Add-Computer `
    -DomainName "contoso.local" `
    -Credential $credential `
    -Restart
```

Because interactive credential entry through Run Command can be inconvenient, you may instead perform this step using Azure Bastion when Bastion is introduced into the lab.

The important architecture decision is:

```text
ONPREM-ADSYNC01
       |
       +-- Domain Joined
       |
       +-- NOT a Domain Controller
```

---

# 22. Verify Domain Membership

After the server restarts, run:

```powershell
az vm run-command invoke `
  --resource-group rg-az305-onprem-ci `
  --name ONPREM-ADSYNC01 `
  --command-id RunPowerShellScript `
  --scripts "(Get-CimInstance Win32_ComputerSystem).Domain"
```

Expected:

```text
contoso.local
```

---

# 23. Install Microsoft Entra Connect

Microsoft Entra Connect Sync is used to synchronize identities from on-premises Active Directory to Microsoft Entra ID.

The architecture becomes:

```text
Active Directory
      |
      | LDAP / AD
      v
ONPREM-ADSYNC01
      |
      | Microsoft Entra Connect Sync
      v
Microsoft Entra ID
```

Use the current Microsoft Entra Connect Sync installer from Microsoft's official download location.

Do not use an old installer copied from an earlier lab.

Before installation, verify the current supported Windows Server and Entra Connect requirements.

---

# 24. Microsoft Entra Connect Configuration

During setup, select the appropriate synchronization configuration for the lab.

For this lab, the important concepts are:

### Directory

Connect:

```text
contoso.local
```

### Synchronization

Select the organizational units and objects required for the lab.

At minimum, synchronize the test users:

```text
Alice
Bob
```

### Sign-in

Use the appropriate authentication/sign-in method available in the current Entra Connect installer.

For training purposes, the key concept is:

```text
On-premises identity
        |
        v
Entra Connect
        |
        v
Microsoft Entra ID
```

---

# 25. UPN Consideration

Our Active Directory domain is:

```text
contoso.local
```

This is an internal/private namespace.

A cloud sign-in identity normally uses a verified domain in Microsoft Entra ID, for example:

```text
alice@yourverifieddomain.com
```

The on-premises AD DNS namespace does **not** have to be identical to the cloud sign-in namespace.

For example:

```text
On-Premises AD

alice@contoso.local
       |
       | Entra Connect
       v
Microsoft Entra ID

alice@yourverifieddomain.com
```

For your actual lab tenant, use a domain that is verified in that tenant.

---

# 26. Verify Synchronization

After completing Entra Connect configuration, wait for the initial synchronization.

Open:

```text
Microsoft Entra admin center
```

Navigate to:

```text
Identity
   >
Users
   >
All users
```

Verify that the synchronized users appear.

For example:

```text
Alice
Bob
```

The users should indicate that they are synchronized from on-premises Active Directory.

---

# 27. Force a Synchronization

On `ONPREM-ADSYNC01`, the synchronization scheduler can be triggered manually.

Open PowerShell:

```powershell
Start-ADSyncSyncCycle -PolicyType Delta
```

To check the scheduler:

```powershell
Get-ADSyncScheduler
```

The exact available commands and configuration options can vary with the installed Entra Connect version.

---

# 28. Validate the Complete Identity Flow

At this point, the complete identity path is:

```text
                 Simulated On-Premises
                         |
                         v
                  Active Directory
                   contoso.local
                         |
              +----------+----------+
              |                     |
           Alice                   Bob
              |                     |
              +----------+----------+
                         |
                         v
                 Entra Connect
                         |
                         v
                 Microsoft Entra ID
```

This is the foundation for the later hybrid architecture.

---

# 29. Architecture Decision Questions

Before moving to the next module, consider the following.

### Question 1

Why do we have two servers instead of installing Entra Connect on the Domain Controller?

Think about:

* Security
* Role separation
* Administration
* Enterprise architecture

---

### Question 2

Why does the Domain Controller have a static private IP?

Think about:

* DNS
* Predictability
* Infrastructure dependencies

---

### Question 3

Why don't we give the Domain Controller a public IP?

Think about:

* Attack surface
* Internet exposure
* Administrative access
* Security boundaries

---

### Question 4

Why is `GatewaySubnet` created now even though we aren't deploying a VPN Gateway?

Think about:

* Future hybrid connectivity
* Network planning
* Avoiding subnet redesign later

---

### Question 5

Why is DNS so important to Active Directory?

Think about:

* Domain discovery
* Kerberos
* LDAP
* Domain controllers
* Service location records

---

# 30. Troubleshooting

## DNS resolution fails

Check the VNet DNS configuration:

```powershell
az network vnet show `
  --resource-group rg-az305-onprem-ci `
  --name vnet-az305-onprem-ci `
  --query "dhcpOptions.dnsServers"
```

Expected:

```text
10.100.1.10
```

Then test:

```powershell
nslookup contoso.local
```

---

## Domain Controller does not respond

Check the VM:

```powershell
az vm get-instance-view `
  --resource-group rg-az305-onprem-ci `
  --name ONPREM-DC01 `
  --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus"
```

---

## AD DS installation failed

Check:

```powershell
Get-WindowsFeature AD-Domain-Services
```

and:

```powershell
Get-Service NTDS
```

If necessary, rerun the AD DS installation script.

---

## Entra Connect cannot communicate with Active Directory

Check:

1. `ONPREM-ADSYNC01` is domain joined.
2. DNS points to `10.100.1.10`.
3. `ONPREM-DC01` is running.
4. `contoso.local` resolves correctly.
5. Required Windows firewall/network communication is available.

---

# 31. Cleanup

When the module is complete and you are ready to remove the environment:

```powershell
az group delete `
  --name rg-az305-onprem-ci `
  --yes `
  --no-wait
```

This removes the simulated on-premises environment.

> Do not perform cleanup if you are continuing directly into Module 03 and Module 04. The environment will be reused by later modules.

---

# 32. Expected Final State

At the end of this module:

```text
AZ305-Connectivity
        |
        +-- rg-az305-onprem-ci
              |
              +-- vnet-az305-onprem-ci
              |      |
              |      +-- snet-onprem-servers
              |      |
              |      +-- GatewaySubnet
              |
              +-- ONPREM-DC01
              |      |
              |      +-- AD DS
              |      +-- DNS
              |      +-- contoso.local
              |
              +-- ONPREM-ADSYNC01
                     |
                     +-- Domain Joined
                     +-- Microsoft Entra Connect
```

The identity flow is:

```text
Active Directory
      |
      v
Entra Connect
      |
      v
Microsoft Entra ID
```

The network will later be extended through:

```text
Simulated On-Premises
        |
        | S2S VPN
        v
Central India Hub
        |
        +-- Production Spokes
        |
        +-- Non-Production Spokes
```

That connectivity is implemented in **Module 04 — Hybrid Connectivity**.

---

# Module Complete

You have now established the identity foundation for the enterprise architecture lab.

Next:

**Module 03 — Hub-Spoke Network**

In the next module you will build:

* Central India Hub
* South India Hub
* Production spokes
* Non-Production connectivity
* Hub-to-spoke peering
* Network segmentation
* Address-space planning
* Subnet structure
* Foundation for Azure Firewall
* Foundation for VPN connectivity
* Foundation for Application Gateway and private endpoints

# Module 02 — Hybrid Identity

**AZ-305 Enterprise Architecture Lab — Version 2**

---

## 1. Scenario

Contoso currently has an on-premises Active Directory environment.

The company wants to extend its identity platform to Microsoft Azure and Microsoft Entra ID.

For this training lab, the on-premises environment will be **simulated inside Azure**.

### Target architecture

```text
SIMULATED ON-PREMISES
        |
        +-- Active Directory Domain Services
        |
        +-- DNS
        |
        +-- Microsoft Entra Connect Sync
        |
        +-- VPN Gateway
```

The VPN connection will be configured in a later module.

---

## 2. What You Will Build

In this module you will create:

* An on-premises VNet
* A Domain Controller
* Active Directory Domain Services
* DNS
* A second Windows Server for Microsoft Entra Connect
* Test Active Directory users
* Microsoft Entra Connect Sync
* Hybrid identity synchronization

### Target identity architecture

```text
                         MICROSOFT ENTRA ID
                                ^
                                |
                         Entra Connect Sync
                                |
                        ONPREM-ADSYNC01
                                |
                         Domain Joined
                                |
                         contoso.local
                                |
                        ONPREM-DC01
                         /          \
                       AD DS        DNS
```

---

## 3. Azure Region

The simulated on-premises environment will be deployed in:

**Central India**

Azure region name:

```text
centralindia
```

---

## 4. Azure Subscription

Deploy this module into:

**AZ305-Connectivity**

This is intentional.

The simulated on-premises environment represents the hybrid connectivity side of the enterprise architecture rather than the production application workload.

---

## 5. Network

The simulated on-premises VNet will use:

| Component     | Address         |
| ------------- | --------------- |
| VNet          | `10.100.0.0/16` |
| Server subnet | `10.100.1.0/24` |

The server subnet will contain:

```text
ONPREM-DC01
ONPREM-ADSYNC01
```

A VPN Gateway will be added to this environment in a later module.

---

## 6. Servers

Two Windows Server 2022 virtual machines will be created.

| Server            | Purpose                      |
| ----------------- | ---------------------------- |
| `ONPREM-DC01`     | AD DS + DNS                  |
| `ONPREM-ADSYNC01` | Microsoft Entra Connect Sync |

Microsoft currently recommends Windows Server 2025 or Windows Server 2022 for Microsoft Entra Connect Sync.

The Connect Sync server must be domain joined and use the full GUI installation.

---

## 7. Security Decision

The Windows servers will **not have public IP addresses**.

Do not create public RDP access to:

```text
ONPREM-DC01
ONPREM-ADSYNC01
```

Initial configuration will use **Azure Run Command**.

Azure Run Command allows PowerShell commands to be executed inside an Azure VM through the VM agent without requiring normal RDP connectivity.

Later in the lab, we may introduce **Azure Bastion** as the secure administrative access mechanism.

---

# Part A — Deploy the Infrastructure

## 8. Prerequisites

Before starting this module:

* Module 01 must be completed.
* You must have access to the Connectivity subscription.
* Azure CLI must be installed.
* Bicep must be available.
* You must have permission to deploy resources.
* You must know your Connectivity subscription ID.

### Verify Azure CLI

```powershell
az version
```

### Verify Bicep

```powershell
az bicep version
```

### Login to Azure

```powershell
az login
```

### List subscriptions

```powershell
az account list -o table
```

### Select the Connectivity subscription

```powershell
az account set --subscription "<CONNECTIVITY-SUBSCRIPTION-ID>"
```

### Verify the selected subscription

```powershell
az account show -o table
```

---

## 9. Review the Bicep Files

The module contains:

```text
bicep/
├── main.bicep
├── network.bicep
└── vm.bicep
```

### `main.bicep`

Deployment entry point.

### `network.bicep`

Creates the simulated on-premises VNet and subnet.

### `vm.bicep`

Creates the two Windows Server VMs.

---

## 10. Validate the Bicep Template

Move into the module:

```powershell
cd 02-Hybrid-Identity
```

Run:

```powershell
az bicep build --file bicep/main.bicep
```

The command should complete without compilation errors.

---

## 11. Preview the Deployment

Before deploying, use `what-if`.

```powershell
az deployment sub what-if `
  --location centralindia `
  --template-file bicep/main.bicep `
  --parameters @parameters.json
```

Review the proposed changes.

You should see resources similar to:

```text
Resource Group
Virtual Network
Subnet
ONPREM-DC01 NIC
ONPREM-ADSYNC01 NIC
ONPREM-DC01 VM
ONPREM-ADSYNC01 VM
```

---

## 12. Deploy the Infrastructure

You will need to supply a secure administrator password.

**Do not store the password in GitHub.**

For example:

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

with your actual password.

> **Security note:** Avoid committing passwords, secrets, keys or tokens to the GitHub repository.

---

## 13. Validate the Deployment

Check the resource group:

```powershell
az group show `
  --name rg-az305-onprem-ci `
  -o table
```

List the virtual machines:

```powershell
az vm list `
  --resource-group rg-az305-onprem-ci `
  --show-details `
  -o table
```

Expected:

```text
Name
-------------------
ONPREM-DC01
ONPREM-ADSYNC01
```

---

## 14. Find the Domain Controller Private IP

Run:

```powershell
az vm list-ip-addresses `
  --resource-group rg-az305-onprem-ci `
  --name ONPREM-DC01 `
  -o table
```

Record the **private IP address**.

You will need it when configuring DNS on `ONPREM-ADSYNC01`.

---

# Part B — Configure Active Directory

## 15. Configure the Domain Controller

The first server will become the Domain Controller:

```text
ONPREM-DC01
```

The domain will be:

```text
contoso.local
```

NetBIOS name:

```text
CONTOSO
```

The Domain Controller will also provide DNS.

---

## 16. Install AD DS

The repository contains:

```text
scripts/Install-ADDS.ps1
```

The script installs:

* Active Directory Domain Services
* DNS
* A new AD forest

### Using Azure Portal

Go to:

**Azure Portal → Virtual Machines → ONPREM-DC01**

Select:

**Operations → Run Command**

Select:

**RunPowerShellScript**

Paste the contents of:

```text
scripts/Install-ADDS.ps1
```

Then select:

**Run**

---

## 17. Alternative — Use Azure CLI

You can also execute the script using:

```powershell
az vm run-command invoke `
  --resource-group rg-az305-onprem-ci `
  --name ONPREM-DC01 `
  --command-id RunPowerShellScript `
  --scripts @scripts/Install-ADDS.ps1
```

The server will restart during the domain controller installation.

---

## 18. Wait for the Restart

Check the VM state:

```powershell
az vm get-instance-view `
  --resource-group rg-az305-onprem-ci `
  --name ONPREM-DC01 `
  --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" `
  -o tsv
```

Expected:

```text
VM running
```

---

## 19. Validate Active Directory

Run the following through Run Command:

```powershell
Get-ADDomain
```

You should see information including:

```text
DNSRoot:
contoso.local

NetBIOSName:
CONTOSO
```

Then:

```powershell
Get-ADForest
```

Expected:

```text
Name:
contoso.local
```

---

## 20. Validate DNS

Run:

```powershell
Get-Service DNS
```

Expected:

```text
Status
------
Running
```

Then:

```powershell
Get-DnsServerZone
```

You should see:

```text
contoso.local
```

---

# Part C — Create Test Users

## 21. Create Test Users

The repository contains:

```text
scripts/Create-TestUsers.ps1
```

Run the script on:

```text
ONPREM-DC01
```

using Azure Run Command.

The script creates:

```text
alice
bob
```

---

## 22. Validate the Users

Run:

```powershell
Get-ADUser -Filter * |
    Select-Object Name, UserPrincipalName
```

You should see the test users.

---

# Part D — Configure Microsoft Entra Connect

## 23. Configure `ONPREM-ADSYNC01`

The second server will become:

```text
ONPREM-ADSYNC01
```

It will run:

**Microsoft Entra Connect Sync**

The server must first be joined to:

```text
contoso.local
```

---

## 24. Configure DNS

The simulated on-premises VNet is configured to use:

10.100.1.10

as its custom DNS server.

This is the private IP address of:

ONPREM-DC01

Because the DNS configuration is defined at the VNet level, both Windows servers inherit the DNS configuration.

Restart the Entra Connect server after deployment if necessary.

Validate from ONPREM-ADSYNC01:

```powershell
nslookup contoso.local

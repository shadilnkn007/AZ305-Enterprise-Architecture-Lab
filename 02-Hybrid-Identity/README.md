Module 02 — Hybrid Identity
AZ-305 Enterprise Architecture Lab — Version 2
1. Scenario

Contoso currently has an on-premises Active Directory environment.

The company wants to extend its identity platform to Microsoft Azure and Microsoft Entra ID.

For this training lab, the on-premises environment will be simulated inside Azure.

You will build:

SIMULATED ON-PREMISES
        |
        +-- Active Directory Domain Services
        |
        +-- DNS
        |
        +-- Microsoft Entra Connect Sync
        |
        +-- VPN Gateway

The VPN connection will be configured in a later module.

2. What You Will Build

In this module you will create:

An on-premises VNet
A Domain Controller
Active Directory Domain Services
DNS
A second Windows Server for Microsoft Entra Connect
A test Active Directory user set
A hybrid identity synchronization configuration

The target architecture is:

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
3. Azure Location

The simulated on-premises environment is deployed in:

Central India

Azure region name:

centralindia
4. Subscription

Deploy this module into:

AZ305-Connectivity

This is intentional.

The simulated on-premises environment is part of the connectivity/hybrid architecture rather than the Production workload.

5. Network

The simulated on-premises VNet will use:

VNet:
10.100.0.0/16

Server subnet:

10.100.1.0/24

The subnet will contain:

ONPREM-DC01
ONPREM-ADSYNC01

Later, a VPN Gateway will be connected to this VNet.

6. Servers

Two Windows Server 2022 virtual machines will be created.

Server	Purpose
ONPREM-DC01	AD DS + DNS
ONPREM-ADSYNC01	Microsoft Entra Connect Sync

Microsoft currently recommends Windows Server 2025 or Windows Server 2022 for Microsoft Entra Connect Sync. The Connect server must be domain joined and use the full GUI installation; Server Core isn't supported for Connect Sync.

7. Important Security Decision

The Windows servers will not have public IP addresses.

Do not create public RDP access to:

ONPREM-DC01
ONPREM-ADSYNC01

The initial Windows configuration can be performed using Azure Run Command.

Azure Run Command uses the Azure VM agent to execute PowerShell inside a Windows VM and can be used even when normal RDP access isn't available.

Later, if required, Azure Bastion can be introduced as the secure administrative access mechanism. Bastion allows RDP to a VM through the Azure portal without requiring a public IP on the VM.

8. Prerequisites

Before starting this module:

Module 01 must be completed.
You must have access to the Connectivity subscription.
Azure CLI must be installed.
Bicep must be available.
You must have permission to deploy resources.
You must know your Connectivity subscription ID.

Verify your Azure login:

az login

List subscriptions:

az account list -o table

Set the Connectivity subscription:

az account set --subscription "<CONNECTIVITY-SUBSCRIPTION-ID>"

Verify:

az account show -o table
9. Review the Bicep Files

The module contains:

bicep/
├── main.bicep
├── network.bicep
└── vm.bicep

main.bicep is the deployment entry point.

network.bicep creates the simulated on-premises VNet.

vm.bicep creates the two Windows Server VMs.

10. Validate the Bicep Template

Move into the module:

cd 02-Hybrid-Identity

Build the Bicep file:

az bicep build --file bicep/main.bicep

There should be no compilation errors.

11. Preview the Deployment

Before deployment, run:

az deployment sub what-if `
  --location centralindia `
  --template-file bicep/main.bicep `
  --parameters @parameters.json

Review the proposed resources.

You should see:

Resource Group
Virtual Network
Subnet
ONPREM-DC01 NIC
ONPREM-ADSYNC01 NIC
ONPREM-DC01 VM
ONPREM-ADSYNC01 VM
12. Deploy the Infrastructure

You will need to supply a secure administrator password.

Do not commit the password to GitHub.

For this lab, use a password that meets Azure's Windows VM password requirements.

Deploy:

az deployment sub create `
  --name az305-hybrid-identity `
  --location centralindia `
  --template-file bicep/main.bicep `
  --parameters @parameters.json `
  --parameters adminPassword="<YOUR-PASSWORD>"

Replace:

<YOUR-PASSWORD>

with your actual password.

Do not put this password into:

parameters.json

and do not commit it to GitHub.

13. Validate the Deployment

Check the resource group:

az group show `
  --name rg-az305-onprem-ci `
  -o table

List the VMs:

az vm list `
  --resource-group rg-az305-onprem-ci `
  --show-details `
  -o table

Expected:

Name
-------------------
ONPREM-DC01
ONPREM-ADSYNC01
14. Check the Private IP Addresses

Run:

az vm list-ip-addresses `
  --resource-group rg-az305-onprem-ci `
  -o table

Record the private IP address of:

ONPREM-DC01

You will need this address when configuring DNS on the Entra Connect server.

15. Configure the Domain Controller

We will now configure:

ONPREM-DC01

as the Domain Controller.

The server will become:

Domain:
contoso.local

NetBIOS:
CONTOSO
16. Run the AD DS Installation Script

The repository contains:

scripts/Install-ADDS.ps1

The script contains:

Install-WindowsFeature `
    -Name AD-Domain-Services `
    -IncludeManagementTools

Import-Module ADDSDeployment

Install-ADDSForest `
    -DomainName "contoso.local" `
    -DomainNetbiosName "CONTOSO" `
    -InstallDns `
    -Force
17. Execute the Script

You can use Azure Portal:

Virtual Machine → ONPREM-DC01 → Run command

Select:

RunPowerShellScript

Paste the contents of:

scripts/Install-ADDS.ps1

and select:

Run

Azure Run Command executes the PowerShell script through the VM agent and returns the output.

Alternatively, from Azure CLI:

az vm run-command invoke `
  --resource-group rg-az305-onprem-ci `
  --name ONPREM-DC01 `
  --command-id RunPowerShellScript `
  --scripts @scripts/Install-ADDS.ps1
18. Wait for the Restart

The server will restart during forest creation.

Wait until the VM reports:

PowerState/running

Check:

az vm get-instance-view `
  --resource-group rg-az305-onprem-ci `
  --name ONPREM-DC01 `
  --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" `
  -o tsv

Expected:

VM running
19. Validate Active Directory

Use Run Command again.

Run:

Get-ADDomain

Expected information should include:

DNSRoot:
contoso.local

NetBIOSName:
CONTOSO

Then:

Get-ADForest

Expected:

Name:
contoso.local
20. Validate DNS

Run:

Get-Service DNS

Expected:

Status:
Running

Then:

Get-DnsServerZone

You should see the:

contoso.local

DNS zone.

21. Create Test Users

The repository contains:

scripts/Create-TestUsers.ps1

Run it on:

ONPREM-DC01

using Azure Run Command.

The script creates:

alice
bob

inside the Active Directory domain.

Validate:

Get-ADUser -Filter * |
    Select-Object Name, UserPrincipalName

You should see the test users.

22. Configure ONPREM-ADSYNC01

The next step is to configure:

ONPREM-ADSYNC01

as the Microsoft Entra Connect Sync server.

The server must be joined to:

contoso.local

before installing Microsoft Entra Connect Sync.

23. Configure DNS on ONPREM-ADSYNC01

The server must use the Domain Controller as its DNS server.

First obtain the private IP of:

ONPREM-DC01

using:

az vm list-ip-addresses `
  --resource-group rg-az305-onprem-ci `
  --name ONPREM-DC01 `
  -o table

Record the private IP.

Then configure the network interface of:

ONPREM-ADSYNC01

to use the Domain Controller as its DNS server.

In the Azure Portal:

Virtual Machine → Networking → Network Interface

Then:

DNS servers → Custom

Enter:

<PRIVATE-IP-OF-ONPREM-DC01>

Save the change.

Restart:

az vm restart `
  --resource-group rg-az305-onprem-ci `
  --name ONPREM-ADSYNC01
24. Verify DNS from ONPREM-ADSYNC01

Run:

nslookup contoso.local

The DNS server shown should be:

ONPREM-DC01

Then:

nslookup ONPREM-DC01

The name should resolve to the Domain Controller's private IP.

If DNS does not work, stop here and fix DNS before proceeding.

25. Join ONPREM-ADSYNC01 to the Domain

Using Run Command, execute:

Add-Computer `
  -DomainName "contoso.local" `
  -Credential (Get-Credential) `
  -Restart

When prompted, provide the appropriate domain administrator credentials.

After the restart, verify that the server is domain joined.

Run:

(Get-CimInstance Win32_ComputerSystem).Domain

Expected:

contoso.local
26. Install Microsoft Entra Connect Sync

Do not download an old installer from a random website.

The current Microsoft Entra Connect Sync installation package is provided through the Microsoft Entra admin center. Microsoft currently requires synchronization environments to be on version 2.5.79.0 or later by September 30, 2026.

On:

ONPREM-ADSYNC01

open a browser and sign in to the Microsoft Entra admin center.

Download the current:

Microsoft Entra Connect Sync

installer.

27. Microsoft Entra Connect Configuration

Run the installer.

For this training lab, use the simplest appropriate configuration.

Choose:

Customize

when prompted.

This allows you to explicitly see the identity configuration rather than accepting every default.

Configure:

Directory:
contoso.local

Select the users/OU that contains:

Alice
Bob

For sign-in configuration, use the method appropriate to the lab tenant and licensing available.

The objective of this exercise is to demonstrate:

AD DS
  ↓
Entra Connect Sync
  ↓
Microsoft Entra ID

not to turn this lab into an Entra Connect deployment course.

28. UPN Consideration

You may notice:

alice@contoso.local

is not normally an appropriate cloud sign-in name.

In a real enterprise, the on-premises AD domain and cloud sign-in domain are commonly configured using a verified routable domain.

For example:

On-premises:
contoso.local

Cloud UPN:
alice@contoso.com

For this training environment, configure an appropriate verified domain/UPN suffix available in your lab tenant.

This is an important architecture discussion:

The on-premises AD DNS namespace and the Microsoft Entra sign-in namespace do not have to be identical.

29. Validate Synchronization

After configuring Entra Connect, wait for the initial synchronization.

Then open:

Microsoft Entra admin center → Users

Search for:

Alice
Bob

The users should appear as synchronized from on-premises Active Directory.

You can also check the Entra Connect synchronization status on:

ONPREM-ADSYNC01
30. Test the Identity Flow

Your final identity flow should now be:

Active Directory
      |
      | User created
      v
ONPREM-DC01
      |
      | Synchronization
      v
ONPREM-ADSYNC01
      |
      | Entra Connect Sync
      v
Microsoft Entra ID
31. Architecture Validation

You should now have:

                    AZURE TENANT
                         |
                 Microsoft Entra ID
                         ^
                         |
                 Entra Connect Sync
                         |
                 ONPREM-ADSYNC01
                         |
                    Domain Join
                         |
                  contoso.local
                         |
                  ONPREM-DC01
                   /          \
                 AD DS        DNS

The infrastructure is located in:

Connectivity Subscription
        |
    Central India
        |
   On-Prem VNet
32. Architecture Decision

Answer the following before continuing.

Question 1

Why did we put the simulated on-premises environment in the Connectivity subscription instead of Production?

Think about:

Workload isolation
Network ownership
Shared connectivity
Security boundaries
Question 2

Why are AD DS and Entra Connect on separate servers?

Question 3

Why does the Entra Connect server need DNS access to the Domain Controller?

Question 4

Why shouldn't the Domain Controller have a public IP address?

33. Expected Answers
Question 1

The simulated on-premises environment represents shared hybrid connectivity infrastructure rather than a production application workload.

Question 2

Separating the roles provides better security, operational separation and reflects a more realistic enterprise architecture.

Question 3

Active Directory depends heavily on DNS for locating domain controllers and services. Domain joining and directory operations therefore depend on correct DNS configuration.

Question 4

A Domain Controller is a highly privileged identity infrastructure component. Exposing it directly to the Internet unnecessarily increases the attack surface.

34. Troubleshooting
DNS does not resolve

Check:

nslookup contoso.local

Verify that ONPREM-ADSYNC01 uses the private IP of ONPREM-DC01 as DNS.

Domain join fails

Check:

nslookup contoso.local

and:

Test-NetConnection <DC-IP> -Port 53

Also verify:

Test-NetConnection <DC-IP> -Port 389
Entra Connect installation fails

Check:

Server is domain joined.
Server is Windows Server 2022 or newer supported version.
Full Desktop Experience is installed.
Current Entra Connect installer is being used.
Required outbound connectivity is available.
Appropriate Microsoft Entra permissions are available.

Microsoft's current prerequisites should be checked before installation because requirements and supported versions can change.

35. Cleanup

Do not delete the resource group yet.

The simulated on-premises network will be required by:

Module 04 — Hybrid Connectivity

and later validation.

Module Complete

You should now have:

ONPREM-DC01
    |
    +-- AD DS
    +-- DNS
    +-- contoso.local

ONPREM-ADSYNC01
    |
    +-- Domain Joined
    +-- Entra Connect Sync

Microsoft Entra ID
    |
    +-- Synchronized test users

Proceed to:

Module 03 — Hub-Spoke Network

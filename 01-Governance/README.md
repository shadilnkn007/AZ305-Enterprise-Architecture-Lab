# Module 01 — Azure Governance

## AZ-305 Enterprise Architecture Lab — Version 2

### Objective

In this module, you will establish the governance foundation for the enterprise Azure environment.

You will:

* Create or verify the Azure Management Group
* Organize the three lab subscriptions
* Configure an allowed-region policy
* Configure required resource tags
* Deploy the governance policies using Bicep
* Validate policy compliance

---

# 1. Target Architecture

The target governance structure is:

```text
Azure Tenant
    |
    +-- Contoso AZ305 Enterprise
           |
           +-- AZ305-Connectivity
           |
           +-- AZ305-Production
           |
           +-- AZ305-NonProduction
```

The Management Group provides a governance boundary above the individual subscriptions.

---

# 2. Azure Regions

This lab uses two Azure regions:

| Role    | Region        | Azure region name |
| ------- | ------------- | ----------------- |
| Primary | Central India | `centralindia`    |
| DR      | South India   | `southindia`      |

Do not use other Azure regions for the workload resources in this lab.

---

# 3. Subscriptions

You should have three Azure subscriptions available:

| Subscription        | Purpose                            |
| ------------------- | ---------------------------------- |
| AZ305-Connectivity  | Hub networking and shared security |
| AZ305-Production    | Production workload                |
| AZ305-NonProduction | Development/test workload          |

The actual subscription display names may be different in your environment.

---

# 4. Prerequisites

You need:

* Azure access
* Permission to create/manage Management Groups
* Permission to assign Azure Policy at the Management Group scope
* Azure CLI
* Bicep
* Git

Check Azure CLI:

```bash
az version
```

Check Bicep:

```bash
az bicep version
```

Login:

```bash
az login
```

List subscriptions:

```bash
az account list -o table
```

---

# 5. Create the Management Group

Open the Azure Portal.

Go to:

**Management Groups**

Select:

**Create**

Use:

```text
Management Group ID:
contoso-az305

Display Name:
Contoso AZ305 Enterprise
```

If the Management Group already exists, do not create another one.

---

# 6. Add the Three Subscriptions

Place the three lab subscriptions under:

```text
Contoso AZ305 Enterprise
```

The final structure should be:

```text
Contoso AZ305 Enterprise
│
├── AZ305-Connectivity
├── AZ305-Production
└── AZ305-NonProduction
```

Verify this in the Azure Portal.

---

# 7. Verify the Management Group

Run:

```bash
az account management-group show \
  --name contoso-az305
```

You should receive information about the Management Group.

If your Management Group ID is different, replace `contoso-az305` in the command.

---

# 8. Review the Bicep File

Open:

```text
bicep/governance.bicep
```

The template creates two governance policies:

1. Allowed Azure Locations
2. Required Resource Tags

The allowed locations are:

```text
centralindia
southindia
```

The required tags are:

```text
Environment
Project
Owner
```

The initial policy effect is:

```text
Audit
```

---

# 9. Validate the Bicep Template

From the `01-Governance` directory, run:

```bash
az bicep build --file bicep/governance.bicep
```

The command should complete without a Bicep compilation error.

---

# 10. Preview the Deployment

Before making any changes, use `what-if`.

Run:

```bash
az deployment mg what-if \
  --management-group-id contoso-az305 \
  --location centralindia \
  --template-file bicep/governance.bicep \
  --parameters @parameters.json
```

Review the proposed changes.

You should see the policy definitions and policy assignments that will be created.

---

# 11. Deploy the Governance Policies

Run:

```bash
az deployment mg create \
  --name az305-governance \
  --management-group-id contoso-az305 \
  --location centralindia \
  --template-file bicep/governance.bicep \
  --parameters @parameters.json
```

Wait for the deployment to complete.

Expected result:

```text
provisioningState: Succeeded
```

---

# 12. Validate the Policies

Open:

**Azure Portal → Policy → Assignments**

Set the scope to:

```text
Contoso AZ305 Enterprise
```

You should see:

```text
AZ305 - Allowed Azure Locations
AZ305 - Required Resource Tags
```

The effect should currently be:

```text
Audit
```

---

# 13. Validate the Allowed Locations Policy

The lab allows:

```text
Central India
South India
```

The purpose is to prevent accidental deployment of workload resources into unrelated regions.

For example:

```text
centralindia     → allowed
southindia       → allowed
eastus           → should be reported as non-compliant
```

Because the current effect is `Audit`, resources are reported rather than blocked.

---

# 14. Validate the Required Tags Policy

The required tags are:

```text
Environment
Project
Owner
```

Example:

```text
Environment = Production
Project     = AZ305
Owner       = StudentName
```

Resources missing these tags should appear as non-compliant.

---

# 15. Architecture Decision

Consider the following question:

> Why are we applying governance at the Management Group level instead of separately creating the same policies in each subscription?

Think about:

* Consistency
* Centralized governance
* Multiple subscriptions
* Future subscription growth
* Policy duplication

### Expected architectural reasoning

A Management Group provides a governance boundary above subscriptions. Policies assigned at that level can apply consistently to the subscriptions underneath it.

---

# 16. Why are we using Audit first?

We are deliberately using:

```text
Audit
```

rather than:

```text
Deny
```

during the initial build.

This allows students to identify governance violations without accidentally blocking subsequent lab deployments.

Later in the lab, we may demonstrate changing a policy from:

```text
Audit
```

to:

```text
Deny
```

This demonstrates the difference between:

* Detecting non-compliance
* Preventing non-compliance

---

# 17. Expected Result

At the end of this module:

```text
Management Group
        |
        +-------------------+
        |        |          |
        v        v          v
 Connectivity Production NonProduction
        |
        v
 Governance Policies
        |
        +-- Allowed Locations
        |
        +-- Required Tags
```

You are now ready to build the network architecture.

---

# 18. Troubleshooting

### Error: AuthorizationFailed

You probably do not have sufficient permission at the Management Group scope.

Check with:

```bash
az account show
```

and verify that your account has appropriate Management Group/Policy permissions.

---

### Error: Management Group not found

Check the ID:

```bash
az account management-group list -o table
```

Make sure the ID in `parameters.json` matches the actual Management Group ID.

---

### Error: Bicep compilation failure

Run:

```bash
az bicep build --file bicep/governance.bicep
```

Read the line number reported by Bicep and correct the syntax before attempting deployment.

---

### Error: Policy deployment fails

Verify that your account can create policy definitions and policy assignments at the Management Group scope.

---

# 19. Cleanup

Do not delete the Management Group or policies yet.

They are required by later modules.

The complete environment will be cleaned up in:

```text
99-Cleanup
```

---

## Module Complete

Proceed to:

**Module 02 — Hybrid Identity**

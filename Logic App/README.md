# Azure Logic App — Learning Project with Terraform

Welcome! This project is a hands-on learning setup for **Azure Logic Apps** and **Terraform**. It provisions a complete, secure Azure environment using infrastructure as code — all deployable directly from VS Code without any CI/CD pipeline.

---

## What This Project Does

This project creates a set of connected Azure resources that work together as a real-world learning environment. Here is a simple picture of what gets built:

```
Your Machine (Terraform)
        │
        ▼
┌─────────────────────────────────────────────┐
│           Resource Group (rg-logicapp-learn) │
│                                             │
│  Identity ──────────────────────────────┐  │
│  (Managed Identity)                     │  │
│                                         ▼  │
│  Logic App HTTP    ──► Storage Account     │
│  (HTTP → Blob)         └── workflow-runs/  │
│                            └── file share  │
│  Logic App Scheduled ──► File Share        │
│  (Every 1 hour)                            │
│                                            │
│  Web App (F1 Free)                         │
│  Key Vault                                 │
│  VNet + Subnet + NSG                       │
│  Log Analytics (Monitoring)                │
└────────────────────────────────────────────┘
```

---

## Resources Created

| Resource | Purpose | Cost |
|---|---|---|
| Logic App HTTP | Receives HTTP requests and saves payload to blob | Free (Consumption) |
| Logic App Scheduled | Runs every hour and writes heartbeat to file share | Free (Consumption) |
| Storage Account | Stores workflow blobs and file share | ~$0.02/GB |
| Web App | Sample frontend app connected to storage | Free (F1) |
| Key Vault | Stores secrets securely, no plain text anywhere | ~$0.04/10k ops |
| Managed Identity | All services authenticate without passwords | Free |
| VNet + NSG | Private networking with security rules | Free |
| Log Analytics | Monitors all resources, audit logs | Free under 5GB/day |
| Private Endpoint | Secures blob storage with private networking | ~$7.30/month |

**Estimated monthly cost: under $10** for a learning setup with light usage.

---

## Project Structure

```
Logic App/
├── main.tf               ← Wires all modules together
├── variables.tf          ← Input variable definitions
├── outputs.tf            ← Useful values shown after apply
├── terraform.tfvars      ← Your actual values (edit this)
├── providers.tf          ← Azure provider configuration
└── modules/
    ├── identity/         ← Managed Identity
    ├── networking/       ← VNet, Subnet, NSG, Private DNS
    ├── storage/          ← Storage Account, Blob Container, File Share
    ├── keyvault/         ← Key Vault with RBAC
    ├── web_app/          ← Linux Web App (F1 free tier)
    ├── logic_app/        ← Logic App workflows + API connections
    │   ├── main.tf       ← Two workflow instances + API connections
    │   ├── http_to_blob.tf    ← Workflow 1: HTTP → save to blob
    │   └── scheduled.tf       ← Workflow 2: timer → save to file share
    └── monitoring/       ← Log Analytics + Diagnostic Settings
```

---

## Getting Started

### Prerequisites
- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.6.6
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed and logged in
- An Azure subscription (Azure for Students works fine)

### 1. Login to Azure

```bash
az login
```

### 2. Update your values

Open `terraform.tfvars` and update:

```hcl
resource_group_name = "rg-logicapp-learn"
location            = "germanywestcentral"   # must be one of the 5 allowed regions
prefix              = "learn"
terraform_client_ip = "your.public.ip"       # run: curl https://api.ipify.org
```

> If your IP changes (home, office, VPN), just update `terraform_client_ip` and run `terraform apply` again.

### 3. Deploy

```bash
cd "Logic App"
terraform init
terraform plan
terraform apply -auto-approve
```

### 4. Destroy when done

```bash
terraform destroy
```

> Always destroy when you finish learning for the day — the private endpoint charges hourly (~$0.01/hour).

---

## How to Test the Logic App

After `terraform apply` completes:

**Step 1** — Find the trigger URL:
```
Azure Portal → rg-logicapp-learn → learn-logicapp-http
→ Logic app designer → click "When HTTP request received"
→ Copy the HTTP POST URL
```

**Step 2** — Send a test request:
```bash
curl -X POST "<your trigger URL>" \
  -H "Content-Type: application/json" \
  -d '{"message": "hello world", "requestId": "test-001"}'
```

**Step 3** — Check the result:
```
Portal → learn-logicapp-http → Overview → Runs history
Portal → learnstlogicapp (Storage) → Containers → workflow-runs → test-001.json
```

---

## How to Add a New Workflow

1. Create a new `.tf` file inside `modules/logic_app/`
2. Add a trigger resource pointing to either `azurerm_logic_app_workflow.http` or `azurerm_logic_app_workflow.scheduled`
3. Add your action resources
4. Run `terraform apply`

> Important: If your workflow has a **Response action**, use `azurerm_logic_app_workflow.http`. If it runs on a **schedule**, use `azurerm_logic_app_workflow.scheduled`. Azure does not allow both in the same workflow.

---

## Allowed Azure Regions

This subscription has a policy that restricts deployment to these regions only:

| Region | Notes |
|---|---|
| `germanywestcentral` | Default — best capacity |
| `francecentral` | Works but B1 capacity can be limited |
| `switzerlandnorth` | Available |
| `spaincentral` | Available |
| `norwayeast` | Available |

---

## Key Things Learned

- Terraform module structure with `main.tf / variables.tf / outputs.tf`
- Private endpoints and Private DNS Zones for secure networking
- Managed Identity + RBAC instead of storing passwords anywhere
- Logic App Consumption vs Standard tier differences
- Azure Storage — blob containers, file shares, network firewall rules
- Why Logic App Standard shows folders in storage (SMB file share mount on port 445)
- Diagnostic settings and Log Analytics for monitoring
- FinOps practices — using free tiers and minimal resources for learning

---

## Notes for Production

When moving to a real banking or production environment, consider these upgrades:

- Switch Logic App to **Standard tier (WS1)** for VNet integration and private endpoints
- Enable the **resource group lock** (commented out in `main.tf`)
- Set **purge protection** back to `true` on Key Vault
- Increase Log Analytics **retention to 90+ days** for compliance
- Add more private endpoints for Key Vault and File Share
- Use **Azure DevOps or GitHub Actions** for CI/CD instead of manual apply

---

*Built with Terraform on Azure — happy learning!*

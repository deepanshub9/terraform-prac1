data "azurerm_client_config" "current" {}

resource "azurerm_storage_account" "this" {
  name                     = "${var.prefix}stlogicapp"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"

  public_network_access_enabled   = true
  allow_nested_items_to_be_public = false

  # Firewall: deny all except Azure services + your local machine (for Terraform apply)
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = [var.terraform_client_ip]
  }

  blob_properties {
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  tags = var.tags
}

# ── 1 Private Endpoint: Blob only ─────────────────────────────────────────────
# This single PE is enough to learn the concept of private networking
# File/Queue/Table PEs removed — saves ~$22/month
resource "azurerm_private_endpoint" "blob" {
  name                = "${var.prefix}-pe-blob"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-blob"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-blob"
    private_dns_zone_ids = [var.dns_zone_blob_id]
  }
}

# ── RBAC ──────────────────────────────────────────────────────────────────────
resource "azurerm_role_assignment" "blob_contributor" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.identity_principal_id
}

# Allows Terraform caller to create containers during apply
resource "azurerm_role_assignment" "terraform_blob_contributor" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# ── Blob container ─────────────────────────────────────────────────────────────
resource "azurerm_storage_container" "workflow_runs" {
  name                  = "workflow-runs"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
  depends_on            = [azurerm_role_assignment.terraform_blob_contributor]
}

# ── File Share ─────────────────────────────────────────────────────────────────
# quota = 1 is minimum (1GB) — cheapest option
resource "azurerm_storage_share" "logicapp" {
  name                 = "logicapp-files"
  storage_account_name = azurerm_storage_account.this.name
  quota                = 1
  depends_on           = [azurerm_storage_account.this]
}

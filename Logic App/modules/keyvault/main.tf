data "azurerm_client_config" "current" {}

resource "random_id" "kv_suffix" {
  byte_length = 2
}

resource "azurerm_key_vault" "this" {
  name                = "${var.prefix}-kv-${random_id.kv_suffix.hex}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Public access ON + firewall — no private endpoint needed for learning
  # Saves ~$7.30/month vs using a private endpoint
  public_network_access_enabled = true

  # purge_protection disabled — makes terraform destroy work cleanly during learning
  # Re-enable in production: purge_protection_enabled = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = true  # once enabled cannot be disabled — managed by lifecycle below

  lifecycle {
    ignore_changes = [purge_protection_enabled]
  }

  enable_rbac_authorization = true

  # Only allow your local IP + Azure services to reach Key Vault
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = [var.terraform_client_ip]
  }

  tags = var.tags
}

# Managed identity can read secrets
resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.identity_principal_id
}

# Your own Entra ID user can manage secrets
resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

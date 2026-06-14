# F1 = Free tier — no quota required, works on Azure for Students
# For banking prod: upgrade to P1v3 after quota approval
resource "azurerm_service_plan" "this" {
  name                   = "${var.prefix}-asp-webapp"
  resource_group_name    = var.resource_group_name
  location               = var.location
  os_type                = "Linux"
  sku_name               = "F1"
  zone_balancing_enabled = false
  tags                   = var.tags
}

# Web app names are globally unique across all Azure — random suffix avoids collision
resource "random_id" "webapp_suffix" {
  byte_length = 2
}

resource "azurerm_linux_web_app" "this" {
  name                = "${var.prefix}-webapp-${random_id.webapp_suffix.hex}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.this.id
  https_only          = true
  tags                = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  site_config {
    always_on = false

    application_stack {
      node_version = "20-lts"
    }
  }

  app_settings = {
    WEBSITE_RUN_FROM_PACKAGE = "1"
    AZURE_CLIENT_ID          = var.identity_client_id
    STORAGE_ACCOUNT_NAME     = var.storage_account_name
    KEY_VAULT_URI            = var.key_vault_uri
  }
}

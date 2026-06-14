# ── Shared API Connections ─────────────────────────────────────────────────────

resource "azurerm_api_connection" "blob" {
  name                = "${var.prefix}-conn-blob"
  resource_group_name = var.resource_group_name
  managed_api_id      = "/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/${var.location}/managedApis/azureblob"
  display_name        = "Blob Storage Connection"
  tags                = var.tags

  parameter_values = {
    accountName = var.storage_account_name
    accessKey   = var.storage_primary_access_key
  }

  lifecycle {
    ignore_changes = [parameter_values]
  }
}

resource "azurerm_api_connection" "file" {
  name                = "${var.prefix}-conn-file"
  resource_group_name = var.resource_group_name
  managed_api_id      = "/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/${var.location}/managedApis/azurefile"
  display_name        = "File Storage Connection"
  tags                = var.tags

  parameter_values = {
    accountName = var.storage_account_name
    accessKey   = var.storage_primary_access_key
  }

  lifecycle {
    ignore_changes = [parameter_values]
  }
}

# ── Logic App 1: HTTP Workflow ─────────────────────────────────────────────────
# Used by http_to_blob.tf
# Rule: any workflow with a Response action MUST use an HTTP trigger only
# Azure does not allow Response action + Recurrence trigger in same workflow
resource "azurerm_logic_app_workflow" "http" {
  name                = "${var.prefix}-logicapp-http"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  workflow_parameters = {
    "$connections" = jsonencode({
      defaultValue = {}
      type         = "Object"
    })
  }

  parameters = {
    "$connections" = jsonencode({
      azureblob = {
        connectionId   = azurerm_api_connection.blob.id
        connectionName = "azureblob"
        id             = "/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/${var.location}/managedApis/azureblob"
      }
    })
  }

  depends_on = [azurerm_api_connection.blob]
}

# ── Logic App 2: Scheduled Workflow ───────────────────────────────────────────
# Used by scheduled.tf
# Rule: Recurrence trigger workflows must NOT have Response actions
resource "azurerm_logic_app_workflow" "scheduled" {
  name                = "${var.prefix}-logicapp-scheduled"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  workflow_parameters = {
    "$connections" = jsonencode({
      defaultValue = {}
      type         = "Object"
    })
  }

  parameters = {
    "$connections" = jsonencode({
      azurefile = {
        connectionId   = azurerm_api_connection.file.id
        connectionName = "azurefile"
        id             = "/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/${var.location}/managedApis/azurefile"
      }
    })
  }

  depends_on = [azurerm_api_connection.file]
}

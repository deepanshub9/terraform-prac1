# ── Logic App Workflow instance ────────────────────────────────────────────────
# One Logic App Consumption instance — all workflows share this + both connections
resource "azurerm_logic_app_workflow" "this" {
  name                = "${var.prefix}-logicapp"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  # Declare $connections schema
  workflow_parameters = {
    "$connections" = jsonencode({
      defaultValue = {}
      type         = "Object"
    })
  }

  # Wire both blob and file share connections into the workflow
  parameters = {
    "$connections" = jsonencode({
      azureblob = {
        connectionId   = azurerm_api_connection.blob.id
        connectionName = "azureblob"
        id             = "/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/${var.location}/managedApis/azureblob"
      }
      azurefile = {
        connectionId   = azurerm_api_connection.file.id
        connectionName = "azurefile"
        id             = "/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/${var.location}/managedApis/azurefile"
      }
    })
  }

  depends_on = [
    azurerm_api_connection.blob,
    azurerm_api_connection.file,
  ]
}

# ── API Connection: Azure Blob Storage ────────────────────────────────────────
# Used by workflows to read/write blobs in the workflow-runs container
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

# ── API Connection: Azure File Storage ────────────────────────────────────────
# Used by workflows to read/write files in the logicapp-files file share
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

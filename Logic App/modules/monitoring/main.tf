# Log Analytics — PerGB2018, retention set to minimum 30 days to reduce cost
# Free allowance: 5GB/day ingested + 31 days retention free
# Cost only kicks in above 5GB/day which learning traffic never reaches
resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.prefix}-law"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# ── Diagnostic Settings: Logic App ────────────────────────────────────────────
# Only WorkflowRuntime logs — skipping verbose metrics to reduce ingestion cost
resource "azurerm_monitor_diagnostic_setting" "logic_app" {
  name                       = "diag-logicapp"
  target_resource_id         = var.logic_app_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log { category = "WorkflowRuntime" }
  # metrics excluded — not needed for learning, saves ingestion cost
}

# ── Diagnostic Settings: Web App ──────────────────────────────────────────────
# Only HTTP logs — skipping AppServiceAppLogs to reduce ingestion volume
resource "azurerm_monitor_diagnostic_setting" "web_app" {
  name                       = "diag-webapp"
  target_resource_id         = var.webapp_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log { category = "AppServiceHTTPLogs" }
  # AppServiceAppLogs excluded — verbose, not needed during learning
}

# ── Diagnostic Settings: Key Vault ────────────────────────────────────────────
# AuditEvent only — every secret access logged, mandatory for banking compliance
resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "diag-kv"
  target_resource_id         = var.key_vault_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log { category = "AuditEvent" }
  # metrics excluded to save cost
}

# ── Diagnostic Settings: Storage Blob ─────────────────────────────────────────
# Write + Delete only — skipping StorageRead which fires on every blob read
# and generates the most log volume by far
resource "azurerm_monitor_diagnostic_setting" "storage_blob" {
  name                       = "diag-storage-blob"
  target_resource_id         = "${var.storage_account_id}/blobServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  # StorageRead excluded — fires on every read, very noisy and costly
  enabled_log { category = "StorageWrite" }
  enabled_log { category = "StorageDelete" }
}

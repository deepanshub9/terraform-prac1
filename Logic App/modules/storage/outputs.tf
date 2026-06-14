output "storage_account_id" {
  value = azurerm_storage_account.this.id
}

output "storage_account_name" {
  value = azurerm_storage_account.this.name
}

output "primary_access_key" {
  value     = azurerm_storage_account.this.primary_access_key
  sensitive = true
}

output "primary_connection_string" {
  value     = azurerm_storage_account.this.primary_connection_string
  sensitive = true
}

output "workflow_runs_container_name" {
  value = azurerm_storage_container.workflow_runs.name
}

output "file_share_name" {
  value = azurerm_storage_share.logicapp.name
}

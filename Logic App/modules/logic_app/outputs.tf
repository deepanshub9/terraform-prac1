output "logic_app_id" {
  value = azurerm_logic_app_workflow.this.id
}

output "logic_app_default_hostname" {
  value = azurerm_logic_app_workflow.this.access_endpoint
}

output "blob_connection_id" {
  value = azurerm_api_connection.blob.id
}

output "file_connection_id" {
  value = azurerm_api_connection.file.id
}

output "logic_app_portal_url" {
  value       = "https://portal.azure.com/#resource${azurerm_logic_app_workflow.this.id}/logicApp"
  description = "Direct link to Logic App in Azure Portal — click to see designer and run history"
}

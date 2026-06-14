output "logic_app_id" {
  value = azurerm_logic_app_workflow.http.id
}

output "logic_app_default_hostname" {
  value = azurerm_logic_app_workflow.http.access_endpoint
}

output "logic_app_http_portal_url" {
  value = "https://portal.azure.com/#resource${azurerm_logic_app_workflow.http.id}/logicApp"
}

output "logic_app_scheduled_portal_url" {
  value = "https://portal.azure.com/#resource${azurerm_logic_app_workflow.scheduled.id}/logicApp"
}

output "blob_connection_id" {
  value = azurerm_api_connection.blob.id
}

output "file_connection_id" {
  value = azurerm_api_connection.file.id
}

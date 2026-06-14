output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "logic_app_access_endpoint" {
  value = module.logic_app.logic_app_default_hostname
}

output "logic_app_portal_url" {
  value = module.logic_app.logic_app_portal_url
}

output "workflow_storage_container" {
  value = module.storage.workflow_runs_container_name
}

output "webapp_hostname" {
  value = module.web_app.webapp_default_hostname
}

output "identity_client_id" {
  value = module.identity.client_id
}

output "key_vault_uri" {
  value = module.keyvault.key_vault_uri
}

output "log_analytics_workspace_id" {
  value = module.monitoring.log_analytics_workspace_id
}

output "webapp_id" {
  value = azurerm_linux_web_app.this.id
}

output "webapp_default_hostname" {
  value = azurerm_linux_web_app.this.default_hostname
}

output "webapp_name" {
  value = azurerm_linux_web_app.this.name
}

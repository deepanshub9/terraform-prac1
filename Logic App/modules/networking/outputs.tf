output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "pe_subnet_id" {
  value = azurerm_subnet.private_endpoints.id
}

# Ready for Logic App Standard upgrade — pass this to logic_app module
# as virtual_network_subnet_id when switching from Consumption to Standard
output "logicapp_standard_subnet_id" {
  value = azurerm_subnet.logic_app_standard.id
}

output "dns_zone_blob_id" {
  value = azurerm_private_dns_zone.zones["privatelink.blob.core.windows.net"].id
}

resource "azurerm_virtual_network" "this" {
  name                = "${var.prefix}-vnet"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = [var.vnet_address_space]
  tags                = var.tags
}

# Single subnet — hosts all private endpoints
# Extra subnets for Logic App/Web App VNet integration removed:
# Consumption Logic App + F1 Web App don't support VNet integration
resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-private-endpoints"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.1.0/24"]

  private_endpoint_network_policies = "Disabled"
}

# Single NSG — one is enough to learn the concept
resource "azurerm_network_security_group" "pe" {
  name                = "${var.prefix}-nsg-pe"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  security_rule {
    name                       = "DenyInternetInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "pe" {
  subnet_id                 = azurerm_subnet.private_endpoints.id
  network_security_group_id = azurerm_network_security_group.pe.id
  depends_on                = [azurerm_virtual_network.this]
}

# Single DNS zone for blob — teaches the private DNS concept without 4x the cost
# Add more zones only when you add more private endpoints
locals {
  dns_zones = [
    "privatelink.blob.core.windows.net",
  ]
}

resource "azurerm_private_dns_zone" "zones" {
  for_each            = toset(local.dns_zones)
  name                = each.value
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "links" {
  for_each              = toset(local.dns_zones)
  name                  = "link-${replace(each.value, ".", "-")}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.zones[each.value].name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false
  tags                  = var.tags
  depends_on            = [azurerm_private_dns_zone.zones]
}

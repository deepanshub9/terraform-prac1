resource "azurerm_virtual_network" "this" {
  name                = "${var.prefix}-vnet"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = [var.vnet_address_space]
  tags                = var.tags
}

# ── Subnet: Private Endpoints ──────────────────────────────────────────────────
# Hosts the blob private endpoint
# Logic App/Web App VNet integration subnets not needed for Consumption + F1 tiers
resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-private-endpoints"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.1.0/24"]

  private_endpoint_network_policies = "Disabled"
}

# ── Subnet: Logic App Standard (for future upgrade) ───────────────────────────
# Currently unused — Consumption Logic App does not need VNet integration
# When you upgrade to Logic App Standard (WS1), uncomment the module call
# in main.tf and point virtual_network_subnet_id here
resource "azurerm_subnet" "logic_app_standard" {
  name                 = "snet-logicapp-standard"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.2.0/24"]

  # Delegation required for Logic App Standard App Service Plan
  delegation {
    name = "logicapp-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# ── NSG: Private Endpoint Subnet ──────────────────────────────────────────────
resource "azurerm_network_security_group" "pe" {
  name                = "${var.prefix}-nsg-pe"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  # Allow HTTPS inbound from VNet — needed for private endpoint traffic
  security_rule {
    name                       = "AllowHttpsInboundFromVNet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Deny all internet inbound — nothing from public internet reaches private endpoints
  security_rule {
    name                       = "DenyInternetInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

# ── NSG: Logic App Standard Subnet ────────────────────────────────────────────
# IMPORTANT: Port 445 (SMB) must be open OUTBOUND so Logic App Standard can
# mount the Azure File Share over SMB to load workflow definitions from
# site/wwwroot/. Without this, Logic App Standard designer shows blank.
#
# This is why on your work laptop the folders (site/, wwwroot/, workflow/) 
# appear in storage — Logic App Standard mounts that file share on startup.
# Logic App Consumption does NOT do this (Microsoft manages its own storage).
resource "azurerm_network_security_group" "logicapp_standard" {
  name                = "${var.prefix}-nsg-logicapp-std"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  # Allow SMB outbound to storage — Logic App Standard REQUIRES port 445
  # to mount file share and read workflow definitions
  security_rule {
    name                       = "AllowSMBOutboundToStorage"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "445"
    source_address_prefix      = "*"
    destination_address_prefix = "Storage"
  }

  # Allow HTTPS outbound — Logic App needs to call Azure APIs and connectors
  security_rule {
    name                       = "AllowHttpsOutbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Deny internet inbound to Logic App subnet
  security_rule {
    name                       = "DenyInternetInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

# ── NSG Associations ──────────────────────────────────────────────────────────
resource "azurerm_subnet_network_security_group_association" "pe" {
  subnet_id                 = azurerm_subnet.private_endpoints.id
  network_security_group_id = azurerm_network_security_group.pe.id
  depends_on                = [azurerm_virtual_network.this]
}

resource "azurerm_subnet_network_security_group_association" "logicapp_standard" {
  subnet_id                 = azurerm_subnet.logic_app_standard.id
  network_security_group_id = azurerm_network_security_group.logicapp_standard.id
  depends_on                = [azurerm_virtual_network.this]
}

# ── Private DNS Zone: Blob ─────────────────────────────────────────────────────
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

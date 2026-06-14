data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

module "identity" {
  source              = "./modules/identity"
  prefix              = var.prefix
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = var.tags
}

module "networking" {
  source              = "./modules/networking"
  prefix              = var.prefix
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  vnet_address_space  = var.vnet_address_space
  tags                = var.tags
}

module "storage" {
  source                = "./modules/storage"
  prefix                = var.prefix
  resource_group_name   = azurerm_resource_group.this.name
  location              = azurerm_resource_group.this.location
  pe_subnet_id          = module.networking.pe_subnet_id
  dns_zone_blob_id      = module.networking.dns_zone_blob_id
  identity_principal_id = module.identity.principal_id
  terraform_client_ip   = var.terraform_client_ip
  tags                  = var.tags
}

module "keyvault" {
  source                = "./modules/keyvault"
  prefix                = var.prefix
  resource_group_name   = azurerm_resource_group.this.name
  location              = azurerm_resource_group.this.location
  identity_principal_id = module.identity.principal_id
  terraform_client_ip   = var.terraform_client_ip
  tags                  = var.tags
}

module "web_app" {
  source               = "./modules/web_app"
  prefix               = var.prefix
  resource_group_name  = azurerm_resource_group.this.name
  location             = azurerm_resource_group.this.location
  identity_id          = module.identity.identity_id
  identity_client_id   = module.identity.client_id
  storage_account_name = module.storage.storage_account_name
  key_vault_uri        = module.keyvault.key_vault_uri
  tags                 = var.tags
}

module "logic_app" {
  source                       = "./modules/logic_app"
  prefix                       = var.prefix
  resource_group_name          = azurerm_resource_group.this.name
  location                     = azurerm_resource_group.this.location
  subscription_id              = data.azurerm_client_config.current.subscription_id
  identity_id                  = module.identity.identity_id
  identity_client_id           = module.identity.client_id
  storage_account_name         = module.storage.storage_account_name
  storage_primary_access_key   = module.storage.primary_access_key
  workflow_runs_container_name = module.storage.workflow_runs_container_name
  file_share_name              = module.storage.file_share_name
  key_vault_uri                = module.keyvault.key_vault_uri
  tags                         = var.tags
}

module "monitoring" {
  source              = "./modules/monitoring"
  prefix              = var.prefix
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  logic_app_id        = module.logic_app.logic_app_id
  webapp_id           = module.web_app.webapp_id
  key_vault_id        = module.keyvault.key_vault_id
  storage_account_id  = module.storage.storage_account_id
  tags                = var.tags
}

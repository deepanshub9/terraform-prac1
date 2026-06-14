resource_group_name = "rg-logicapp-learn"
location            = "germanywestcentral"
prefix              = "learn"

# Your local machine public IP — run: curl https://api.ipify.org to refresh if it changes
terraform_client_ip = "64.43.152.245"

vnet_address_space = "10.0.0.0/16"

tags = {
  environment = "learning"
  owner       = "deepanshu"
  cost-center = "finops"
}

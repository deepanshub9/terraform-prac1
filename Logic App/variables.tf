variable "resource_group_name" {
  type        = string
  description = "Name of the Azure Resource Group"
}

variable "location" {
  type        = string
  description = "Azure region — only these 5 are allowed by your subscription policy"
  default     = "germanywestcentral"

  validation {
    condition = contains([
      "switzerlandnorth",
      "germanywestcentral",
      "francecentral",
      "spaincentral",
      "norwayeast"
    ], var.location)
    error_message = "Allowed regions: switzerlandnorth, germanywestcentral, francecentral, spaincentral, norwayeast."
  }
}

variable "prefix" {
  type        = string
  description = "Short prefix used in all resource names (keep short, storage name has 24 char limit)"
}

variable "terraform_client_ip" {
  type        = string
  description = "Your local machine public IP — allows Terraform to reach storage data plane during apply"
}

variable "vnet_address_space" {
  type    = string
  default = "10.0.0.0/16"
}

variable "tags" {
  type    = map(string)
  default = {}
}

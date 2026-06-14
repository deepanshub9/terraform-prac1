variable "terraform_client_ip" { type = string }
variable "prefix" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "pe_subnet_id" { type = string }
variable "dns_zone_blob_id" { type = string }
variable "identity_principal_id" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}

variable "prefix" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "identity_principal_id" { type = string }
variable "terraform_client_ip" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}

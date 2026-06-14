variable "prefix" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "identity_id" { type = string }
variable "identity_client_id" { type = string }
variable "storage_account_name" { type = string }
variable "key_vault_uri" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}

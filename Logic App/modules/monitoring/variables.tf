variable "prefix" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "logic_app_id" { type = string }
variable "webapp_id" { type = string }
variable "key_vault_id" { type = string }
variable "storage_account_id" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}

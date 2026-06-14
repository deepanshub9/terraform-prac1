variable "prefix" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "subscription_id" { type = string }
variable "identity_id" { type = string }
variable "identity_client_id" { type = string }
variable "storage_account_name" { type = string }
variable "storage_primary_access_key" {
  type      = string
  sensitive = true
}
variable "workflow_runs_container_name" { type = string }
variable "file_share_name" { type = string }
variable "key_vault_uri" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}

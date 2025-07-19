variable "name" {}
variable "location" {}
variable "tags" {}
variable "rg" {}
variable "tenant_id" {}
variable "current_user_id" {}
variable "additional_users" { type = list}
variable "key_permissions" { type = list }
variable "secret_permissions" { type = list }
variable "certificate_permissions" { type = list }
variable "ip_rules" { type = list }
variable "subnet_ids" { type = list }
variable "enable" { 
    type = bool
    default = true
}
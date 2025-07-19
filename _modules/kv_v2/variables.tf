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
variable "secret_list" { 
    type = map(string) 
    default = {"secret_key1" = "secret_value1" , "secret_key2" = "secret_value2"}
}
variable "enable" { 
    type = bool
    default = true
}
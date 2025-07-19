variable "administrator_login" {}
variable "administrator_password" {}
variable "tags" {}
variable "sku" {}
#variable "private_dns_zone_id" { default="" }

variable "name" {}
variable "location" {}
variable "rg" {}
#variable "vnet_subnet_id" {}

variable "replica_needed" { 
    type = bool
    default = false 
}
variable "replica_name" { default = "" }
variable "replica_location" { default = "" }
# variable "replica_rg" { default = "" }
#variable "replica_vnet_subnet_id" {}
variable "enable" { 
    type = bool
    default = true
}
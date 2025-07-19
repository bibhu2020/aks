variable "name" {}
variable "location" {}
variable "tags" {}
variable "rg" {}
variable "size" {}
variable "username" {}
variable "password" {}
variable "enable" { 
    type = bool
    default = true
}

variable "vnet_subnet_id" {}

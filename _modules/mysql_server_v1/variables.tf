variable "administrator_login" {}
variable "administrator_password" {}
variable "tags" {}
variable "sku" {}

variable "name" {}
variable "location" {}
variable "rg" {}

variable "source_server_id" { default = "" }
variable "enable" { 
    type = bool
    default = true
}

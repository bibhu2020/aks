variable "name" {}
variable "location" {}
variable "tags" {}
variable "rg" {}
variable "virtual_network_subnet_ids" { type = list }
variable "ip_rules" { type = list }
variable "enable" { 
    type = bool
    default = true
}
variable "file_share_name" { default = "" }
variable "file_share_quota" { 
    type = number
    default = 50
}
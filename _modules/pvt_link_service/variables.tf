variable "name" {}
variable "location" {}
variable "tags" {}
variable "rg" {}

variable "load_balancer_name" {}

#variable load_balancer_frontend_ip_configuration_ids {type=list}
variable auto_approval_subscription_ids {type=list}
variable visibility_subscription_ids {type=list}

variable vnet_subnet_id {}
variable nat_ip_configuration_primary {}
variable nat_ip_configuration_secondary {}

variable "enable" { 
    type = bool
    default = true
}


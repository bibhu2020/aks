variable "enable" { 
    type = bool
    default = true
}
variable "name" {}
variable "location" {}
variable "tags" {}
variable "rg" {}
variable "vnet_address_cidr" {}
variable "subnets" {
    type = map(object({
        name = string
        cidr = list(string)
        service_endpoints = list(string)
        private_link_service_network_policies_enabled = bool 
    })) 
    default = {
        aks-subnet-default = {
            name: "aks-subnet-default"
            cidr: ["10.240.0.0/16"]
            service_endpoints: []
            private_link_service_network_policies_enabled: false 
        },
        aks-subnet-vnodes = {
            name: "aks-subnet-vnodes"
            cidr: ["10.241.0.0/16"]
            service_endpoints: []
            private_link_service_network_policies_enabled: false 
        },
    }
}


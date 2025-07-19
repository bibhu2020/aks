variable "tags" {}
variable "pvt_dns_group" {}
variable "pvt_dns_zone_name" {}
variable "pvt_dns_zone_rg" { description="Resource Group where the DNS zone exists." }
variable "pvt_dns_zone_id" {}

variable "pvt_endpoints" {
    type = list(object({
        name = string
        location = string
        rg = string
        subresource_names = list(string)
        pvt_connection_resource_id = string 
        subnet_id = string
        service_connection_name = string
    })) 
    default = [
        {
            name = ""
            location = ""
            rg = ""
            subresource_names = []
            pvt_connection_resource_id = "" 
            subnet_id = ""
            service_connection_name = ""
        }, {
            name = ""
            location = ""
            rg = ""
            subresource_names = []
            pvt_connection_resource_id = "" 
            subnet_id = ""
            service_connection_name = ""
        }
    ]
}

variable "enable" { 
    type = bool
    default = true
}

# variable "name" {}
# variable "location" {}
# variable "rg" {}
# variable "subresource_names" { type = list}
# variable "pvt_connection_resource_id" {} //the resource that needs the private endpoint
# variable "subnet_id" {} //subnet in which the pvt_endpoint will be assigned ip
# variable "service_connection_name" {}

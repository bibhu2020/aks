variable "name" {}
variable "location" {}
variable "tags" {}
variable "rg" {}
variable "pvt_dns_group" {}
variable "pvt_dns_zone_name" {}
variable "pvt_dns_zone_rg" { description="Resource Group where the DNS zone exists." }
variable "pvt_dns_zone_id" {}
variable "subresource_names" { type = list}
variable "pvt_connection_resource_id" {} //the resource that needs the private endpoint
variable "subnet_id" {} //subnet in which the pvt_endpoint will be assigned ip
variable "service_connection_name" {}
variable "enable" { 
    type = bool
    default = true
}
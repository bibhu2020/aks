resource "azurerm_private_endpoint" "pep" {
  for_each            = {for index, pep in var.pvt_endpoints : pep.name => pep}
  name                = each.value.name 
  location            = each.value.location
  resource_group_name = each.value.rg
  subnet_id           = each.value.subnet_id

  private_service_connection {
    name                           = each.value.service_connection_name 
    private_connection_resource_id = each.value.pvt_connection_resource_id
    subresource_names              = each.value.subresource_names //possible values listed here https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-overview#private-link-resource
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = var.pvt_dns_group
    private_dns_zone_ids = [var.pvt_dns_zone_id]
  }
}

# // create a A-record in the DNS zone mapping the resouce FQDN to its private IP (private IP is created by private connection)
# resource "azurerm_private_dns_a_record" "a_record" {
#   for_each            = {for pep in var.pvt_endpoints : pep.name => pep}
#   name                = format("%s",each.value.name)
#   zone_name           = var.pvt_dns_zone_name
#   resource_group_name = var.pvt_dns_zone_rg
#   ttl                 = 300
#   records             = [azurerm_private_endpoint.pep[each.key].private_service_connection.0.private_ip_address]
# }


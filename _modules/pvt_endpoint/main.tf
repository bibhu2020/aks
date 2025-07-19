resource "random_string" "random" {
  count = var.enable == true ? 1 : 0
  length           = 16
  special          = true
  override_special = "/@£$"
}

resource "azurerm_private_endpoint" "pep" {
  count = var.enable == true ? 1 : 0
  name                = var.name
  location            = var.location
  resource_group_name = var.rg
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = var.service_connection_name == "" ? random_string.random[0].result : var.service_connection_name
    private_connection_resource_id = var.pvt_connection_resource_id
    subresource_names              = var.subresource_names //possible values listed here https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-overview#private-link-resource
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = var.pvt_dns_group
    private_dns_zone_ids = [var.pvt_dns_zone_id]
  }
}

// create a A-record in the DNS zone mapping the resouce FQDN to its private IP (private IP is created by private connection)
resource "azurerm_private_dns_a_record" "a_record" {
  count = var.enable == true ? 1 : 0
  name                = format("%s-arec",var.name)
  zone_name           = var.pvt_dns_zone_name
  resource_group_name = var.pvt_dns_zone_rg
  ttl                 = 300
  records             = [azurerm_private_endpoint.pep[0].private_service_connection.0.private_ip_address]
}


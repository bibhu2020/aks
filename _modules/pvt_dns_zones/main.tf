resource "azurerm_private_dns_zone" "res" {
  for_each            = {for zone in var.dns_zones : zone.index => zone}
  name                = each.value.name
  resource_group_name = each.value.rg
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "res" {
  for_each            = {for zone in var.dns_zones : zone.index => zone}

  name                  = format("%s-%s-link", each.value.name, each.value.location)
  resource_group_name   = each.value.rg
  private_dns_zone_name = each.value.name
  virtual_network_id    = each.value.link_to_vnet

  depends_on = [ azurerm_private_dns_zone.res ]
}


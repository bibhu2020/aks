resource "azurerm_private_dns_zone" "res" {
  count               = var.enable == true ? 1 : 0
  name                = var.name
  resource_group_name = var.rg
  tags                = var.tags
}

resource "random_string" "random" {
  length           = 8
  special          = false
  upper = false
  lower = true 
}

resource "azurerm_private_dns_zone_virtual_network_link" "res" {
  count                 = var.enable == true ? 1 : 0

  name                  = random_string.random.result #format("%s-%s-link", var.name, var.location)
  resource_group_name   = var.rg
  private_dns_zone_name = var.name
  virtual_network_id    = var.vnet_id

  depends_on = [ azurerm_private_dns_zone.res ]
}


resource "azurerm_virtual_network" "vnet" {
  count = var.enable == true ? 1 : 0
  name                = var.name
  resource_group_name = var.rg
  location            = var.location
  address_space       = ["${var.vnet_address_cidr}"]
  tags                = var.tags
}

resource "azurerm_subnet" "subnet" {
  for_each            = {for index, snet in var.subnets : snet.name => snet}
  name                 = each.value.name
  address_prefixes     = each.value.cidr
  service_endpoints    = each.value.service_endpoints #list of Service endpoints to associate with the subnet
  resource_group_name  = var.rg
  virtual_network_name = var.name
  private_endpoint_network_policies_enabled = false
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled 
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

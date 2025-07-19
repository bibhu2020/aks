resource "azurerm_resource_group" "res" {
  count     = "${var.enable == true ? 1 : 0}"
  name      = var.name
  location  = var.location
  tags      = var.tags
}

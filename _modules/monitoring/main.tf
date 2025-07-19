resource "azurerm_log_analytics_workspace" "res" {
  count               = var.enable == true ? 1 : 0
  name                = var.name
  location            = var.location
  resource_group_name = var.rg
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

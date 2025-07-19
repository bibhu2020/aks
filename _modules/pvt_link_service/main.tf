data "azurerm_lb" "res" {
  name                = var.load_balancer_name
  resource_group_name = "${var.rg}-mc"
} 

resource "azurerm_private_link_service" "res" {
  count = var.enable == true ? 1 : 0
  name                = var.name 
  resource_group_name = var.rg
  location            = var.location

  auto_approval_subscription_ids              = var.auto_approval_subscription_ids
  visibility_subscription_ids                 = var.visibility_subscription_ids
  load_balancer_frontend_ip_configuration_ids = [data.azurerm_lb.res.frontend_ip_configuration.0.id] # [azurerm_lb.example.frontend_ip_configuration.0.id]

  nat_ip_configuration {
    name                       = "primary"
    private_ip_address         = var.nat_ip_configuration_primary
    private_ip_address_version = "IPv4"
    subnet_id                  = var.vnet_subnet_id
    primary                    = true
  }

  nat_ip_configuration {
    name                       = "secondary"
    private_ip_address         = var.nat_ip_configuration_secondary
    private_ip_address_version = "IPv4"
    subnet_id                  = var.vnet_subnet_id
    primary                    = false
  }
}
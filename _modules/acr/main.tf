resource "azurerm_container_registry" "res" {
  name                = var.name
  resource_group_name = var.rg
  location            = var.location
  sku                 = "Premium"
  admin_enabled       = false
  georeplications {
    location                = "South Central US"
    zone_redundancy_enabled = true
    tags                    = var.tags
  }
  georeplications {
    location                = "North Europe"
    zone_redundancy_enabled = true
    tags                    = var.tags
  }
  tags = var.tags
}


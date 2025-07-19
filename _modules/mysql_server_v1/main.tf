resource "azurerm_mysql_flexible_server" "sqlserver" {
  count                   = var.enable == true ? 1 : 0
  name                    = var.name
  resource_group_name     = var.rg
  location                = var.location
  tags                    = var.tags
  create_mode             = var.source_server_id == "" ? "Default" : "Replica"
  source_server_id        = var.source_server_id == "" ? null : var.source_server_id

  administrator_login    = var.administrator_login
  administrator_password = var.administrator_password
  backup_retention_days  = 14
  
  sku_name               = var.sku
  version                = "8.0.21"
  zone                   = var.source_server_id == "" ? "1" : "2"

  geo_redundant_backup_enabled = true
  high_availability {
    mode                      = "ZoneRedundant"
    standby_availability_zone = var.source_server_id == "" ? "2" : "1"
  }
  maintenance_window {
    day_of_week  = 0
    start_hour   = 8
    start_minute = 0
  }
  storage {
    iops    = 2040
    size_gb = 64
    auto_grow_enabled = true
  }
}

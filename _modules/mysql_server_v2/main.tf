resource "azurerm_mysql_flexible_server" "sqlserver" {
  count                   = var.enable == true ? 1 : 0 
  name                    = var.name
  resource_group_name     = var.rg
  location                = var.location
  tags                    = var.tags
  create_mode             = "Default"

  administrator_login    = var.administrator_login
  administrator_password = var.administrator_password
  backup_retention_days  = 14
  #delegated_subnet_id    = var.vnet_subnet_id
  #private_dns_zone_id    = var.private_dns_zone_id
  sku_name               = var.sku
  version                = "8.0.21"
  zone                   = "1"

  geo_redundant_backup_enabled = true
  high_availability {
    mode                      = "ZoneRedundant"
    standby_availability_zone = "2"
  }
  maintenance_window {
    day_of_week  = 2
    start_hour   = 9
    start_minute = 0
  }
  storage {
    iops    = 2040
    size_gb = 64
    auto_grow_enabled = true
  }
}


data "azurerm_mysql_flexible_server" "sqlserver" {
  count            = var.enable == true ? 1 : 0 
  depends_on = [ azurerm_mysql_flexible_server.sqlserver ]
  name                = var.name
  resource_group_name = var.rg
}

resource "time_sleep" "wait_15_mins" {
  count            = var.enable == true ? 1 : 0 
  depends_on = [data.azurerm_mysql_flexible_server.sqlserver]
  create_duration = "15m"
}

resource "azurerm_mysql_flexible_server" "sqlserver_replica1" {
  depends_on              = [time_sleep.wait_15_mins]
  count                   = var.enable == true &&  var.replica_needed == true ? 1 : 0 
  name                    = format("%s",var.replica_name)
  resource_group_name     = var.rg
  location                = var.replica_location
  tags                    = var.tags
  create_mode             = "Replica"
  source_server_id        = var.enable == true ? data.azurerm_mysql_flexible_server.sqlserver[0].id : null

  administrator_login    = var.administrator_login
  administrator_password = var.administrator_password
  backup_retention_days  = 7
  #delegated_subnet_id    = var.vnet_subnet_id
  #private_dns_zone_id    = var.private_dns_zone_id
  sku_name               = var.sku
  version                = "8.0.21"
  # zone                   = "2"

  geo_redundant_backup_enabled = true
  # high_availability {
  #   mode                      = "ZoneRedundant"
  #   standby_availability_zone = "1"
  # }
  maintenance_window {
    day_of_week  = 0
    start_hour   = 9
    start_minute = 0
  }
  storage {
    iops    = 2040
    size_gb = 64
    auto_grow_enabled = true
  }
}

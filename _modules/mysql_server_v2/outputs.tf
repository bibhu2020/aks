output "id" {
  value = length(azurerm_mysql_flexible_server.sqlserver) > 0 ? azurerm_mysql_flexible_server.sqlserver[0].id : null
}

output "primary_server_id" {
  value = length(azurerm_mysql_flexible_server.sqlserver) > 0 ? azurerm_mysql_flexible_server.sqlserver[0].id : null
}

output "replica_server_id" {
  value = length(azurerm_mysql_flexible_server.sqlserver_replica1) > 0 ? azurerm_mysql_flexible_server.sqlserver_replica1[0].id : null
}

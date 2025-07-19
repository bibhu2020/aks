output "id" {
  value = length(azurerm_mysql_flexible_server.sqlserver) > 0 ? azurerm_mysql_flexible_server.sqlserver[0].id : null
}

output "ws" {
  value = length(azurerm_log_analytics_workspace.res) > 0 ? azurerm_log_analytics_workspace.res[0] : null
}

output "ws_aks_id" {
  value = length(azurerm_log_analytics_workspace.res) > 0 ? azurerm_log_analytics_workspace.res[0].id : null
}


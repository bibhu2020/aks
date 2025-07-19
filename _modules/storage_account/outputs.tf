output "id" {
    value = length(azurerm_storage_account.res) > 0 ? azurerm_storage_account.res[0].id : null
  
}

output "name" {
    value = length(azurerm_storage_account.res) > 0 ? azurerm_storage_account.res[0].name : null
  
}

output "primary_access_key" {
  value = length(azurerm_storage_account.res) > 0 ? azurerm_storage_account.res[0].primary_access_key : null
}

output "secondary_access_key" {
  value = length(azurerm_storage_account.res) > 0 ? azurerm_storage_account.res[0].secondary_access_key : null
}

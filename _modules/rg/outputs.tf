output "name" {
  value = length(azurerm_resource_group.res) > 0 ?  azurerm_resource_group.res[0].name : null
}

output "id" {
  value = length(azurerm_resource_group.res) > 0 ?  azurerm_resource_group.res[0].id : null
}



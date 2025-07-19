output "vnet" {
  value = length(azurerm_virtual_network.vnet) > 0 ?  azurerm_virtual_network.vnet[0] : null
}

output "id" {
  value = length(azurerm_virtual_network.vnet) > 0 ?  azurerm_virtual_network.vnet[0].id : null
}

output "subnets" {
  value = length(azurerm_subnet.subnet) > 0 ?  azurerm_subnet.subnet : null
}

# output "default_subnet_id" {
#   value = length(azurerm_subnet.subnet["aks-subnet-default"]) > 0 ?  azurerm_subnet.subnet["aks-subnet-default"].id : null
# }

# output "vnodes_subnet_id" {
#   value = length(azurerm_subnet.subnet["aks-subnet-vnodes"]) > 0 ?  azurerm_subnet.subnet["aks-subnet-vnodes"].id : null
# }

# output "pe_storage_subnet_id" {
#   value = length(azurerm_subnet.subnet["aks-subnet-pe-storage"]) > 0 ?  azurerm_subnet.subnet["aks-subnet-pe-storage"].id : null
# }

# output "pe_kv_subnet_id" {
#   value = length(azurerm_subnet.subnet["aks-subnet-pe-kv"]) > 0 ?  azurerm_subnet.subnet["aks-subnet-pe-kv"].id : null
# }

# output "pe_database_subnet_id" {
#   value = length(azurerm_subnet.subnet["aks-subnet-pe-database"]) > 0 ?  azurerm_subnet.subnet["aks-subnet-pe-database"].id : null
# }





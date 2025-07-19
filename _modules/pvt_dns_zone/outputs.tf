output "id" {
  value = length(azurerm_private_dns_zone.res) > 0 ?  azurerm_private_dns_zone.res[0].id : null
}
output "name" {
  value = var.name
}


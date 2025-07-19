output "id" {
    value = length(azurerm_key_vault.kv) > 0 ? azurerm_key_vault.kv[0].id : null
}
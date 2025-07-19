//store the secret list in the keyvault secret
resource "azurerm_key_vault_secret" "secret" {
  for_each     = var.secret_list 
  name         = each.key
  value        = each.value 
  key_vault_id = var.key_vault_id
}
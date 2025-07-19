resource "azurerm_key_vault" "kv" {
  count = var.enable == true ? 1 : 0
  
  name                        = var.name
  location                    = var.location
  resource_group_name         = var.rg
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 7
  #purge_protection_enabled    = false //Bug: false value set is not working. so, leave it unset for it to work.

  sku_name = "standard"

  access_policy {
    tenant_id = var.tenant_id
    object_id = var.current_user_id
    key_permissions = var.key_permissions
    secret_permissions = var.secret_permissions
    certificate_permissions = var.certificate_permissions
  }

  network_acls {
    # The Default Action to use when no rules match from ip_rules / 
    # virtual_network_subnet_ids. Possible values are Allow and Deny
    default_action = "Deny"

    # Allows all azure services to access your keyvault. Can be set to 'None'
    bypass         = "AzureServices"

    # The list of allowed ip addresses.
    ip_rules       = var.ip_rules

    virtual_network_subnet_ids = var.subnet_ids

  }

  tags = var.tags
}

resource "azurerm_role_assignment" "assignment" {
  count           = var.enable == true ? "${length(var.additional_users)}" : 0
  scope                = azurerm_key_vault.kv[0].id
  role_definition_name = "Key Vault Reader"
  principal_id         = "${element(var.additional_users, count.index)}"
}

resource "azurerm_key_vault_access_policy" "policy" {
  count           = var.enable == true ? "${length(var.additional_users)}" : 0
  key_vault_id    = azurerm_key_vault.kv[0].id
  tenant_id       = var.tenant_id
  object_id       = "${element(var.additional_users, count.index)}"

  key_permissions         = var.key_permissions
  secret_permissions      = var.secret_permissions
  certificate_permissions = var.certificate_permissions
}


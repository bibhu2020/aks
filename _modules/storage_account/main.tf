resource "azurerm_storage_account" "res" {
  count = var.enable == true ? 1 : 0
  name                          = var.name
  resource_group_name           = var.rg

  location                      = var.location
  account_tier                  = "Standard"
  account_replication_type      = "RAGZRS"
  min_tls_version               = "TLS1_2"
  public_network_access_enabled = false

  # network_rules {
  #   default_action              = "Deny"
  #   ip_rules                    = var.ip_rules
  #   virtual_network_subnet_ids  = var.virtual_network_subnet_ids
  # }

  tags = var.tags
}

resource "azurerm_storage_share" "fileshare" {
  count                = var.file_share_name == "" ? 0 : 1
  name                 = var.file_share_name
  storage_account_name = azurerm_storage_account.res[0].name
  quota                = var.file_share_quota
}


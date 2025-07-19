###### Get Access to Previously Created Resources
############################################################################################
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

data "azurerm_kubernetes_cluster" "aks_cluster" {
    count                       = 1
    name                        = local.aksclustername
    resource_group_name         = local.aksrg
}

data "azurerm_kubernetes_cluster" "draks_cluster" {
    count                       = var.create_dr == true ? 1 : 0
    name                        = local.draksclustername
    resource_group_name         = local.draksrg
}

data "azurerm_storage_account" "aks_sa_media" {
  name                = replace(format("%s-media", local.aksclustername),"-","")
  resource_group_name = local.aksappsrg
}

data "azurerm_storage_account" "aks_sa_log" {
  name                = replace(format("%s-logs", local.aksclustername),"-","")
  resource_group_name = local.aksappsrg
}

data "azurerm_storage_account" "aks_sa_backup" {
  name                = replace(format("%s-backups", local.aksclustername),"-","")
  resource_group_name = local.aksappsrg
}

################################################################################################

resource "azurerm_resource_group" "vault" {
  name                            = format("%s-backup-rg", var.app)
  location                        = var.location
}

resource "azurerm_data_protection_resource_guard" "vault" {
  name                            = format("%s-resourceguard", local.aksclustername)
  location                        = resource.azurerm_resource_group.vault.location
  resource_group_name             = resource.azurerm_resource_group.vault.name
}

resource "azurerm_recovery_services_vault" "vault" {
  name                            = format("%s-recovery-vault", local.aksclustername)
  location                        = resource.azurerm_resource_group.vault.location
  resource_group_name             = resource.azurerm_resource_group.vault.name
  sku                             = "Standard"

  soft_delete_enabled             = true
  storage_mode_type               = "GeoRedundant"
  cross_region_restore_enabled    = true

  tags                            = local.tags
}

resource "azurerm_recovery_services_vault_resource_guard_association" "vault" {
  #name                            = format("%s-vaultproxy", local.aksclustername)
  vault_id                        = azurerm_recovery_services_vault.vault.id
  resource_guard_id               = azurerm_data_protection_resource_guard.vault.id
}

resource "azurerm_backup_policy_file_share" "vault" {
  name                            = format("%s-backup-policy1", local.aksclustername)
  resource_group_name             = resource.azurerm_resource_group.vault.name
  recovery_vault_name             = azurerm_recovery_services_vault.vault.name

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 30
  }
}

resource "azurerm_backup_container_storage_account" "protection-container-media" {
  resource_group_name             = resource.azurerm_resource_group.vault.name
  recovery_vault_name             = resource.azurerm_recovery_services_vault.vault.name
  storage_account_id              = data.azurerm_storage_account.aks_sa_media.id
}

resource "azurerm_backup_protected_file_share" "media_riskiq" {
  resource_group_name             = resource.azurerm_resource_group.vault.name
  recovery_vault_name             = resource.azurerm_recovery_services_vault.vault.name
  source_storage_account_id       = data.azurerm_storage_account.aks_sa_media.id
  source_file_share_name          = "riskiq"
  backup_policy_id                = resource.azurerm_backup_policy_file_share.vault.id
}

resource "azurerm_backup_protected_file_share" "media_secblog" {
  resource_group_name             = resource.azurerm_resource_group.vault.name
  recovery_vault_name             = resource.azurerm_recovery_services_vault.vault.name
  source_storage_account_id       = data.azurerm_storage_account.aks_sa_media.id
  source_file_share_name          = "secblog"
  backup_policy_id                = resource.azurerm_backup_policy_file_share.vault.id
}




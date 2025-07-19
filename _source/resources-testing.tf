
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

data "azurerm_virtual_network" "aks_vnet" {
  name                 = local.aksvnet
  resource_group_name  = local.aksrg
}

data "azurerm_virtual_network" "draks_vnet" {
  name                 = local.draksvnet
  resource_group_name  = local.draksrg
}

data "azurerm_subnet" "aks_subnet_default" {
  name                 = local.akssubnets["aks-subnet-default"].name
  virtual_network_name = local.aksvnet
  resource_group_name  = local.aksrg
}

data "azurerm_subnet" "draks_subnet_default" {
  name                 = local.akssubnets["aks-subnet-default"].name
  virtual_network_name = local.draksvnet
  resource_group_name  = local.draksrg
}

data "azurerm_subnet" "aks_subnet_vnodes" {
  name                 = local.akssubnets["aks-subnet-vnodes"].name
  virtual_network_name = local.aksvnet
  resource_group_name  = local.aksrg
}

data "azurerm_subnet" "draks_subnet_vnodes" {
  name                 = local.akssubnets["aks-subnet-vnodes"].name
  virtual_network_name = local.draksvnet
  resource_group_name  = local.draksrg
}

//get the CSI KV Driver managed identity. The identity is auto-created when the CSI pluging is enabled.
//the identity is always prefixed with "azurekeyvaultsecretsprovider-"
//this identity must be given read access KV for AKS to read the value.
data "azurerm_user_assigned_identity" "aks_cluster" {
  count               = 1
  name                = "azurekeyvaultsecretsprovider-${local.aksclustername}"
  resource_group_name = "${local.aksrg}-mc"
}

data "azurerm_user_assigned_identity" "draks_cluster" {
  count               = var.create_dr == true ? 1 : 0
  name                = "azurekeyvaultsecretsprovider-${local.draksclustername}"
  resource_group_name = "${local.draksrg}-mc"
}

###### Deploy the Persistent Volumes, Persisten Volume Claim, SecretProviderClass, and Secrets
###### this is for the backup storage account
############################################################################################
module "persistent_volume1" {
  source                                    = "../_modules/helm_az_fileshare_pv"

  application_name                          = "base"
  application_namespace                     = "base" 
  application_version                       = "1.0.5"

  aks_kv_csi_client_id                      = data.azurerm_user_assigned_identity.aks_cluster[0].client_id
  aks_tenant_id                             = data.azuread_client_config.current.tenant_id

  storage_account_name                      = "aksocdeveastusbackups" #"${module.aks_sa_backup.name}"
  storage_account_resource_group_name       = "aksoc-dev-eastus-apps-rg" #local.aksappsrg
  storage_account_key_vault_name            = "aksoc-dev-eastus-kv1" #data.azurerm_key_vault.kv.name
  storage_account_name_in_key_vault         = "aksocdeveastusbackups-name" # "${module.aks_sa_backup.name}-name"
  storage_account_access_key_in_key_vault   = "aksocdeveastusbackups-key" #"${module.aks_sa_backup.name}-key"
  storage_account_fileshare_folder_name     = "backups" 
}

module "persistent_volume2" {
  source                                    = "../_modules/helm_az_fileshare_pv"
  enable                                    = var.create_dr
  providers                                 = {
                                                helm = helm.dr
                                                kubernetes = kubernetes.dr
                                              }
  application_name                          = "base"
  application_namespace                     = "base" 
  application_version                       = "1.0.5"

  aks_kv_csi_client_id                      = data.azurerm_user_assigned_identity.draks_cluster[0].client_id
  aks_tenant_id                             = data.azuread_client_config.current.tenant_id

  storage_account_name                      = "aksocdeveastusbackups" #"${module.aks_sa_backup.name}"
  storage_account_resource_group_name       = "aksoc-dev-eastus-apps-rg" #local.aksappsrg
  storage_account_key_vault_name            = "aksoc-dev-eastus-kv1" #data.azurerm_key_vault.kv.name
  storage_account_name_in_key_vault         = "aksocdeveastusbackups-name" # "${module.aks_sa_backup.name}-name"
  storage_account_access_key_in_key_vault   = "aksocdeveastusbackups-key" #"${module.aks_sa_backup.name}-key"
  storage_account_fileshare_folder_name     = "backups" 
}



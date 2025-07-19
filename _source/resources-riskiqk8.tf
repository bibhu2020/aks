locals {
    app_name = "riskiq"
    app_kv_name = format("%s-%s-%s-kv", var.app, var.env, local.app_name)

    app_mysql_server = format("%s-%s-sql", local.prefix, local.app_name)
    drapp_mysql_server = format("%s-%s-sql", local.drprefix, local.app_name)
    app_rg_name = format("%s-%s-rg", local.prefix, local.app_name)
    drapp_rg_name = format("%s-%s-rg", local.drprefix, local.app_name)

}

###### Get Access to Previously Created Resources
############################################################################################
data "azurerm_key_vault" "base_kv" {
  name                    = local.akskv 
  resource_group_name     = local.aksappsrg
}

data "azurerm_key_vault" "app_kv" {
  name                    = local.app_kv_name 
  resource_group_name     = local.app_rg_name
}


data "azurerm_storage_account" "media" {
  name                    = replace(format("%s-media", local.aksclustername),"-","")
  resource_group_name     = local.aksappsrg
}

data "azurerm_storage_account" "logs" {
  name                    = replace(format("%s-logs", local.aksclustername),"-","")
  resource_group_name     = local.aksappsrg
}

data "azurerm_storage_account" "backups" {
  name                    = replace(format("%s-backups", local.aksclustername),"-","")
  resource_group_name     = local.aksappsrg
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

###### Create Namespaces in both the Clusters
############################################################################################
module "namespace_cluster1" {
  source                                    = "../_modules/_apps/namespace"
  namespace                                 = local.app_name 
}
module "namespace_cluster2" {
  source                                    = "../_modules/_apps/namespace"
  enable                                    = var.create_dr
  providers                                 = {
                                                helm = helm.dr
                                                kubernetes = kubernetes.dr
                                              }  
  namespace                                 = local.app_name 
}

##### Create PV and PVC for db backup storage
###########################################################################################
module "backup_storage_mount_cluster1" {
  source                                    = "../_modules/_apps/storage_mountv2"
  depends_on                                = [ module.namespace_cluster1 ]

  application_name                          = local.app_name
  application_namespace                     = local.app_name
  application_version                       = "1.0.3"

  aks_kv_csi_client_id                      = data.azurerm_user_assigned_identity.aks_cluster[0].client_id
  aks_tenant_id                             = data.azuread_client_config.current.tenant_id

  storage_account_name                      = data.azurerm_storage_account.backups.name
  storage_account_resource_group_name       = data.azurerm_storage_account.backups.resource_group_name
  storage_account_key_vault_name            = data.azurerm_key_vault.base_kv.name
  storage_account_name_in_key_vault         = "${data.azurerm_storage_account.backups.name}-name"
  storage_account_access_key_in_key_vault   = "${data.azurerm_storage_account.backups.name}-key"
  storage_account_fileshare_folder_name     = local.app_name
}

module "backup_storage_mount_cluster2" {
  source                                    = "../_modules/_apps/storage_mountv2"
  depends_on                                = [ module.namespace_cluster2 ]

  enable                                    = var.create_dr
  providers                                 = {
                                                helm = helm.dr
                                                kubernetes = kubernetes.dr
                                              }

  application_name                          = local.app_name
  application_namespace                     = local.app_name
  application_version                       = "1.0.3"

  aks_kv_csi_client_id                      = var.create_dr == true ? data.azurerm_user_assigned_identity.draks_cluster[0].client_id : null
  aks_tenant_id                             = data.azuread_client_config.current.tenant_id

  storage_account_name                      = data.azurerm_storage_account.backups.name
  storage_account_resource_group_name       = data.azurerm_storage_account.backups.resource_group_name
  storage_account_key_vault_name            = data.azurerm_key_vault.base_kv.name
  storage_account_name_in_key_vault         = "${data.azurerm_storage_account.backups.name}-name"
  storage_account_access_key_in_key_vault   = "${data.azurerm_storage_account.backups.name}-key"
  storage_account_fileshare_folder_name     = local.app_name
}

##### Create PV and PVC for log storage
###########################################################################################
module "log_storage_mount_cluster1" {
  source                                    = "../_modules/_apps/storage_mountv2"
  depends_on                                = [ module.namespace_cluster1 ]

  application_name                          = local.app_name
  application_namespace                     = local.app_name
  application_version                       = "1.0.2"

  aks_kv_csi_client_id                      = data.azurerm_user_assigned_identity.aks_cluster[0].client_id
  aks_tenant_id                             = data.azuread_client_config.current.tenant_id

  storage_account_name                      = data.azurerm_storage_account.logs.name
  storage_account_resource_group_name       = data.azurerm_storage_account.logs.resource_group_name
  storage_account_key_vault_name            = data.azurerm_key_vault.base_kv.name
  storage_account_name_in_key_vault         = "${data.azurerm_storage_account.logs.name}-name"
  storage_account_access_key_in_key_vault   = "${data.azurerm_storage_account.logs.name}-key"
  storage_account_fileshare_folder_name     = local.app_name
}

module "log_storage_mount_cluster2" {
  source                                    = "../_modules/_apps/storage_mountv2"
  depends_on                                = [ module.namespace_cluster2 ]

  enable                                    = var.create_dr
  providers                                 = {
                                                helm = helm.dr
                                                kubernetes = kubernetes.dr
                                              }

  application_name                          = local.app_name
  application_namespace                     = local.app_name
  application_version                       = "1.0.2"

  aks_kv_csi_client_id                      = var.create_dr == true ? data.azurerm_user_assigned_identity.draks_cluster[0].client_id : null
  aks_tenant_id                             = data.azuread_client_config.current.tenant_id

  storage_account_name                      = data.azurerm_storage_account.logs.name
  storage_account_resource_group_name       = data.azurerm_storage_account.logs.resource_group_name
  storage_account_key_vault_name            = data.azurerm_key_vault.base_kv.name
  storage_account_name_in_key_vault         = "${data.azurerm_storage_account.logs.name}-name"
  storage_account_access_key_in_key_vault   = "${data.azurerm_storage_account.logs.name}-key"
  storage_account_fileshare_folder_name     = local.app_name
}

# ###### Create PV and PVC for media storage
# ############################################################################################
module "media_storage_mount_cluster1" {
  source                                    = "../_modules/_apps/storage_mountv2"
  depends_on                                = [ module.namespace_cluster1 ]

  application_name                          = local.app_name
  application_namespace                     = local.app_name
  application_version                       = "1.0.2"

  aks_kv_csi_client_id                      = data.azurerm_user_assigned_identity.aks_cluster[0].client_id
  aks_tenant_id                             = data.azuread_client_config.current.tenant_id

  storage_account_name                      = data.azurerm_storage_account.media.name
  storage_account_resource_group_name       = data.azurerm_storage_account.media.resource_group_name
  storage_account_key_vault_name            = data.azurerm_key_vault.base_kv.name
  storage_account_name_in_key_vault         = "${data.azurerm_storage_account.media.name}-name"
  storage_account_access_key_in_key_vault   = "${data.azurerm_storage_account.media.name}-key"
  storage_account_fileshare_folder_name     = local.app_name
}

module "media_storage_mount_cluster2" {
  source                                    = "../_modules/_apps/storage_mountv2"
  enable                                    = var.create_dr
  depends_on                                = [ module.namespace_cluster2 ]

  providers                                 = {
                                                helm = helm.dr
                                                kubernetes = kubernetes.dr
                                              }

  application_name                          = local.app_name
  application_namespace                     = local.app_name
  application_version                       = "1.0.2"

  aks_kv_csi_client_id                      = var.create_dr == true ? data.azurerm_user_assigned_identity.draks_cluster[0].client_id : null
  aks_tenant_id                             = data.azuread_client_config.current.tenant_id

  storage_account_name                      = data.azurerm_storage_account.media.name
  storage_account_resource_group_name       = data.azurerm_storage_account.media.resource_group_name
  storage_account_key_vault_name            = data.azurerm_key_vault.base_kv.name
  storage_account_name_in_key_vault         = "${data.azurerm_storage_account.media.name}-name"
  storage_account_access_key_in_key_vault   = "${data.azurerm_storage_account.media.name}-key"
  storage_account_fileshare_folder_name     = local.app_name
}

###### Create SecretStorageProvider class for the KV that stores the WordPress Secrets
############################################################################################
module "kv_secret_mount_cluster1" {
  source                                    = "../_modules/_apps/kv_secret"
  depends_on                                = [ module.namespace_cluster1 ]

  application_name                          = local.app_name
  application_namespace                     = local.app_name
  application_version                       = "1.0.3"

  kv_name                                   = data.azurerm_key_vault.app_kv.name 
  kv_csi_client_id                          = data.azurerm_user_assigned_identity.aks_cluster[0].client_id
  kv_tenant_id                              = data.azuread_client_config.current.tenant_id
  key1 = "DOMAIN-NAME"
  key2 = "WORDPRESS-CONFIG-EXTRA"
  key3 = "WORDPRESS-DB-HOST"
  key4 = "WORDPRESS-DB-NAME"
  key5 = "WORDPRESS-DB-PASSWORD"
  key6 = "WORDPRESS-DB-USER"
  key7 = "WORDPRESS-HOME"
  key8 = "WORDPRESS-SITEURL"
  key9 = "dummy-secret"
  key10 = "dummy-secret"
  key11 = "dummy-secret"
  key12 = "dummy-secret"
  key13 = "dummy-secret"
  key14 = "dummy-secret"
  key15 = "dummy-secret"
  key16 = "dummy-secret"
  key17 = "dummy-secret"
  key18 = "dummy-secret"
  key19 = "dummy-secret"
  key20 = "dummy-secret"
  key21 = "dummy-secret"
  key22 = "dummy-secret"
  key23 = "dummy-secret"
  key24 = "dummy-secret"
  key25 = "dummy-secret"
  key26 = "dummy-secret"
  key27 = "dummy-secret"
  key28 = "dummy-secret"
  key29 = "dummy-secret"
  key30 = "dummy-secret"
  key31 = "dummy-secret"
  key32 = "dummy-secret"
  key33 = "dummy-secret"
  key34 = "dummy-secret"
  key35 = "dummy-secret"
}

module "kv_secret_mount_cluster2" {
  source                                    = "../_modules/_apps/kv_secret"
  depends_on                                = [ module.namespace_cluster2 ]

  enable                                    = var.create_dr
  providers                                 = {
                                                helm = helm.dr
                                                kubernetes = kubernetes.dr
                                              }
                                              
  application_name                          = local.app_name
  application_namespace                     = local.app_name
  application_version                       = "1.0.3"

  kv_name                                   = data.azurerm_key_vault.app_kv.name 
  kv_csi_client_id                          = var.create_dr == true ? data.azurerm_user_assigned_identity.draks_cluster[0].client_id : null
  kv_tenant_id                              = data.azuread_client_config.current.tenant_id
  key1 = "DOMAIN-NAME"
  key2 = "WORDPRESS-CONFIG-EXTRA"
  key3 = "WORDPRESS-DB-HOST"
  key4 = "WORDPRESS-DB-NAME"
  key5 = "WORDPRESS-DB-PASSWORD"
  key6 = "WORDPRESS-DB-USER"
  key7 = "WORDPRESS-HOME"
  key8 = "WORDPRESS-SITEURL"
  key9 = "dummy-secret"
  key10 = "dummy-secret"
  key11 = "dummy-secret"
  key12 = "dummy-secret"
  key13 = "dummy-secret"
  key14 = "dummy-secret"
  key15 = "dummy-secret"
  key16 = "dummy-secret"
  key17 = "dummy-secret"
  key18 = "dummy-secret"
  key19 = "dummy-secret"
  key20 = "dummy-secret"
  key21 = "dummy-secret"
  key22 = "dummy-secret"
  key23 = "dummy-secret"
  key24 = "dummy-secret"
  key25 = "dummy-secret"
  key26 = "dummy-secret"
  key27 = "dummy-secret"
  key28 = "dummy-secret"
  key29 = "dummy-secret"
  key30 = "dummy-secret"
  key31 = "dummy-secret"
  key32 = "dummy-secret"
  key33 = "dummy-secret"
  key34 = "dummy-secret"
  key35 = "dummy-secret"
}

###### Create SecretStorageProvider class for the KV that stores the TLS certificate
############################################################################################
module "kv_tls_secret_mount_cluster1" {
  source                                    = "../_modules/_apps/kv_tls"
  depends_on                                = [ module.namespace_cluster1 ]

  application_name                          = local.app_name
  application_namespace                     = local.app_name
  application_version                       = "1.0.4"

  kv_name                                   = local.akskv 
  kv_csi_client_id                          = data.azurerm_user_assigned_identity.aks_cluster[0].client_id
  kv_tenant_id                              = data.azuread_client_config.current.tenant_id
  kv_tls_certificate_name                   = var.ingress_tls_name  
}

module "kv_tls_secret_mount_cluster2" {
  source                                    = "../_modules/_apps/kv_tls"
  depends_on                                = [ module.namespace_cluster2 ]

  enable                                    = var.create_dr
  providers                                 = {
                                                helm = helm.dr
                                                kubernetes = kubernetes.dr
                                              }  

  application_name                          = local.app_name
  application_namespace                     = local.app_name
  application_version                       = "1.0.4"

  kv_name                                   = local.akskv
  kv_csi_client_id                          = var.create_dr == true ? data.azurerm_user_assigned_identity.draks_cluster[0].client_id : null
  kv_tenant_id                              = data.azuread_client_config.current.tenant_id
  kv_tls_certificate_name                   = var.ingress_tls_name 
}

locals {
    app_name = "translator"
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
  key1 = "AccountID"
  key2 = "LicenseKey"
  key3 = "STAGE-DOMAIN-NAME"
  key4 = "WORDPRESS-AUTH-KEY"
  key5 = "WORDPRESS-AUTH-SALT"
  key6 = "WORDPRESS-LOGGED-IN-KEY"
  key7 = "WORDPRESS-LOGGED-IN-SALT"
  key8 = "WORDPRESS-NONCE-KEY"
  key9 = "WORDPRESS-NONCE-SALT"
  key10 = "WORDPRESS-SECURE-AUTH-KEY"
  key11 = "WORDPRESS-SECURE-AUTH-SALT"
  key12 = "DOMAIN-NAME"
  key13 = "WORDPRESS-BASIC-PASSWD"
  key14 = "WORDPRESS-BASIC-USER"
  key15 = "WORDPRESS-CONFIG-EXTRA"
  key16 = "WORDPRESS-HOME"
  key17 = "WORDPRESS-HTTP-HOST"
  key18 = "WORDPRESS-SITEURL"
  key19 = "WPMS-MAIL-FROM"
  key20 = "WPMS-MAIL-FROM-NAME"
  key21 = "WPMS-MAILER"
  key22 = "WPMS-SENDGRID-API-KEY"
  key23 = "WORDPRESS-DB-PASSWORD"
  key24 = "WORDPRESS-DB-USER"
  key25 = "WORDPRESS-DB-HOST"
  key26 = "WORDPRESS-DB-NAME"
  key27 = "translator-dummy"
  key28 = "translator-dummy"
  key29 = "translator-dummy"
  key30 = "translator-dummy"
  key31 = "translator-dummy"
  key32 = "translator-dummy"
  key33 = "translator-dummy"
  key34 = "translator-dummy"
  key35 = "translator-dummy"
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
  key1 = "AccountID"
  key2 = "LicenseKey"
  key3 = "STAGE-DOMAIN-NAME"
  key4 = "WORDPRESS-AUTH-KEY"
  key5 = "WORDPRESS-AUTH-SALT"
  key6 = "WORDPRESS-LOGGED-IN-KEY"
  key7 = "WORDPRESS-LOGGED-IN-SALT"
  key8 = "WORDPRESS-NONCE-KEY"
  key9 = "WORDPRESS-NONCE-SALT"
  key10 = "WORDPRESS-SECURE-AUTH-KEY"
  key11 = "WORDPRESS-SECURE-AUTH-SALT"
  key12 = "DOMAIN-NAME"
  key13 = "WORDPRESS-BASIC-PASSWD"
  key14 = "WORDPRESS-BASIC-USER"
  key15 = "WORDPRESS-CONFIG-EXTRA"
  key16 = "WORDPRESS-HOME"
  key17 = "WORDPRESS-HTTP-HOST"
  key18 = "WORDPRESS-SITEURL"
  key19 = "WPMS-MAIL-FROM"
  key20 = "WPMS-MAIL-FROM-NAME"
  key21 = "WPMS-MAILER"
  key22 = "WPMS-SENDGRID-API-KEY"
  key23 = "WORDPRESS-DB-PASSWORD"
  key24 = "WORDPRESS-DB-USER"
  key25 = "WORDPRESS-DB-HOST"
  key26 = "WORDPRESS-DB-NAME"
  key27 = "translator-dummy"
  key28 = "translator-dummy"
  key29 = "translator-dummy"
  key30 = "translator-dummy"
  key31 = "translator-dummy"
  key32 = "translator-dummy"
  key33 = "translator-dummy"
  key34 = "translator-dummy"
  key35 = "translator-dummy"
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

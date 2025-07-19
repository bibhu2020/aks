locals {
    app_name = "cloudhub"
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
  application_version                       = "1.0.5"

  kv_name                                   = data.azurerm_key_vault.app_kv.name 
  kv_csi_client_id                          = data.azurerm_user_assigned_identity.aks_cluster[0].client_id
  kv_tenant_id                              = data.azuread_client_config.current.tenant_id
  key1 = "RSA-FORCE-RESTRICTION"
  key2 = "SKIP-FORCE-WP-LOGIN-DIRECT"
  key3 = "TENUPSSO-DISABLE"
  key4 = "WORDPRESS-CONFIG-EXTRA"
  key5 = "WORDPRESS-HOME"
  key6 = "WORDPRESS-SITEURL"
  key7 = "WP-ENVIRONMENT-TYPE"
  key8 = "MICROSOFT-QUEUE-ACCOUNT-NAME"
  key9 = "CELA-API-KEY"
  key10 = "DOMAIN-NAME"
  key11 = "EP-HOST"
  key12 = "EP-INDEX-PREFIX"
  key13 = "ES-SHIELD"
  key14 = "MICROSOFT-COMMENTS-PII-KEY"
  key15 = "WORDPRESS-AUTH-KEY"
  key16 = "WORDPRESS-AUTH-SALT"
  key17 = "WORDPRESS-DB-HOST"
  key18 = "WORDPRESS-DB-NAME"
  key19 = "WORDPRESS-DB-PASSWORD"
  key20 = "WORDPRESS-DB-USER"
  key21 = "WORDPRESS-LOGGED-IN-KEY"
  key22 = "WORDPRESS-LOGGED-IN-SALT"
  key23 = "WORDPRESS-NONCE-KEY"
  key24 = "WORDPRESS-NONCE-SALT"
  key25 = "WORDPRESS-SECURE-AUTH-KEY"
  key26 = "WORDPRESS-SECURE-AUTH-SALT"
  key27 = "MICROSOFT-QUEUE-ACCESS-KEY"
  key28 = "WORDPRESS-HTTP-HOST"
  key29 = "WPMS-SMTP-APIKEY"
  key30 = "WPMS-API-ENDPOINT"
  key31 = "WPMS-SENDER"
  key32 = "cloudhub-dummy-secret"
  key33 = "cloudhub-dummy-secret"
  key34 = "cloudhub-dummy-secret"
  key35 = "cloudhub-dummy-secret"
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
  application_version                       = "1.0.5"

  kv_name                                   = data.azurerm_key_vault.app_kv.name 
  kv_csi_client_id                          = var.create_dr == true ? data.azurerm_user_assigned_identity.draks_cluster[0].client_id : null
  kv_tenant_id                              = data.azuread_client_config.current.tenant_id
  key1 = "RSA-FORCE-RESTRICTION"
  key2 = "SKIP-FORCE-WP-LOGIN-DIRECT"
  key3 = "TENUPSSO-DISABLE"
  key4 = "WORDPRESS-CONFIG-EXTRA"
  key5 = "WORDPRESS-HOME"
  key6 = "WORDPRESS-SITEURL"
  key7 = "WP-ENVIRONMENT-TYPE"
  key8 = "MICROSOFT-QUEUE-ACCOUNT-NAME"
  key9 = "CELA-API-KEY"
  key10 = "DOMAIN-NAME"
  key11 = "EP-HOST"
  key12 = "EP-INDEX-PREFIX"
  key13 = "ES-SHIELD"
  key14 = "MICROSOFT-COMMENTS-PII-KEY"
  key15 = "WORDPRESS-AUTH-KEY"
  key16 = "WORDPRESS-AUTH-SALT"
  key17 = "WORDPRESS-DB-HOST"
  key18 = "WORDPRESS-DB-NAME"
  key19 = "WORDPRESS-DB-PASSWORD"
  key20 = "WORDPRESS-DB-USER"
  key21 = "WORDPRESS-LOGGED-IN-KEY"
  key22 = "WORDPRESS-LOGGED-IN-SALT"
  key23 = "WORDPRESS-NONCE-KEY"
  key24 = "WORDPRESS-NONCE-SALT"
  key25 = "WORDPRESS-SECURE-AUTH-KEY"
  key26 = "WORDPRESS-SECURE-AUTH-SALT"
  key27 = "MICROSOFT-QUEUE-ACCESS-KEY"
  key28 = "WORDPRESS-HTTP-HOST"
  key29 = "WPMS-SMTP-APIKEY"
  key30 = "WPMS-API-ENDPOINT"
  key31 = "WPMS-SENDER"
  key32 = "cloudhub-dummy-secret"
  key33 = "cloudhub-dummy-secret"
  key34 = "cloudhub-dummy-secret"
  key35 = "cloudhub-dummy-secret"
}

###### Create SecretStorageProvider class for the KV that stores the TLS certificate
############################################################################################
module "kv_tls_secret_mount_cluster1" {
  source                                    = "../_modules/_apps/kv_tls"
  depends_on                                = [ module.namespace_cluster1 ]

  application_name                          = local.app_name
  application_namespace                     = local.app_name
  application_version                       = "1.0.3"

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
  application_version                       = "1.0.3"

  kv_name                                   = local.akskv
  kv_csi_client_id                          = var.create_dr == true ? data.azurerm_user_assigned_identity.draks_cluster[0].client_id : null
  kv_tenant_id                              = data.azuread_client_config.current.tenant_id
  kv_tls_certificate_name                   = var.ingress_tls_name 
}

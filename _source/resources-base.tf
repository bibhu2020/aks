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

data "azurerm_virtual_network" "aks_vnet" {
  count                = 1
  name                 = local.aksvnet
  resource_group_name  = local.aksrg
}

data "azurerm_virtual_network" "draks_vnet" {
  count                = var.create_dr == true ? 1 : 0
  name                 = local.draksvnet
  resource_group_name  = local.draksrg
}

data "azurerm_subnet" "aks_subnet_default" {
  count                = 1
  name                 = local.akssubnets["aks-subnet-default"].name
  virtual_network_name = local.aksvnet
  resource_group_name  = local.aksrg
}

data "azurerm_subnet" "draks_subnet_default" {
  count                = var.create_dr == true ? 1 : 0
  name                 = local.akssubnets["aks-subnet-default"].name
  virtual_network_name = local.draksvnet
  resource_group_name  = local.draksrg
}

data "azurerm_subnet" "aks_subnet_vnodes" {
  count                = 1
  name                 = local.akssubnets["aks-subnet-vnodes"].name
  virtual_network_name = local.aksvnet
  resource_group_name  = local.aksrg
}

data "azurerm_subnet" "draks_subnet_vnodes" {
  count                = var.create_dr == true ? 1 : 0
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
###### Create the apps resource group that holds all common resources
############################################################################################
module "rg_aksapps" {
  source = "../_modules/rg"

  name     = local.aksappsrg
  location = local.location
  tags     = local.tags
}

module "drrg_aksapps" {
  source = "../_modules/rg"
  enable = var.create_dr

  name     = local.draksappsrg
  location = local.drlocation
  tags     = local.tags
}


###### Create Storage Account for db backup files
############################################################################################
module "aks_sa_media" {
  depends_on              = [module.rg_aksapps, module.drrg_aksapps, data.azurerm_subnet.aks_subnet_vnodes]
  source                  = "../_modules/storage_account"

  name                    = replace(format("%s-media", local.aksclustername),"-","")
  location                = local.location
  tags                    = local.tags
  rg                      = local.aksappsrg
  ip_rules                = [ "${chomp(data.http.myip.response_body)}", "72.178.126.108", "167.220.148.0/22", "131.107.147.0/24", "131.107.159.0/24", "131.107.160.0/24", "131.107.174.0/24", "167.220.24.0/24", "167.220.26.0/24", "167.220.238.0/27", "167.220.238.128/27", "167.220.238.192/27", "167.220.238.64/27", "167.220.232.0/23", "167.220.255.0/25", "167.220.242.0/27", "167.220.242.128/27", "167.220.242.192/27", "167.220.242.64/27", "94.245.87.0/24", "167.220.196.0/23", "194.69.104.0/25", "191.234.97.0/26", "167.220.0.0/23", "167.220.2.0/24", "167.220.226.0/23", "131.107.132.16/28", "131.107.132.32/28", "157.58.212.64/26", "157.58.212.128/26", "157.58.213.64/26", "157.58.213.192/26", "157.58.214.128/26", "157.58.214.192/26", "167.220.70.64/26", "167.220.76.192/26", "167.220.77.64/26", "167.220.80.192/26", "167.220.81.128/26", "167.220.81.192/26", "131.107.1.128/25", "131.107.8.0/25", "167.220.204.128/26", "167.220.204.192/26", "167.220.205.0/26", "167.220.205.64/26", "20.99.254.208/29", "20.99.255.72/29", "20.99.254.224/29", "20.99.255.136/29", "20.120.200.56/29"]
  virtual_network_subnet_ids = [ data.azurerm_subnet.aks_subnet_vnodes[0].id ]
}

module "aks_sa_log" {
  depends_on              = [module.rg_aksapps, module.drrg_aksapps, data.azurerm_subnet.aks_subnet_vnodes]
  source                  = "../_modules/storage_account"

  name                    = replace(format("%s-logs", local.aksclustername),"-","")
  location                = local.location
  tags                    = local.tags
  rg                      = local.aksappsrg
  ip_rules                = [ "${chomp(data.http.myip.response_body)}", "72.178.126.108", "167.220.148.0/22", "131.107.147.0/24", "131.107.159.0/24", "131.107.160.0/24", "131.107.174.0/24", "167.220.24.0/24", "167.220.26.0/24", "167.220.238.0/27", "167.220.238.128/27", "167.220.238.192/27", "167.220.238.64/27", "167.220.232.0/23", "167.220.255.0/25", "167.220.242.0/27", "167.220.242.128/27", "167.220.242.192/27", "167.220.242.64/27", "94.245.87.0/24", "167.220.196.0/23", "194.69.104.0/25", "191.234.97.0/26", "167.220.0.0/23", "167.220.2.0/24", "167.220.226.0/23", "131.107.132.16/28", "131.107.132.32/28", "157.58.212.64/26", "157.58.212.128/26", "157.58.213.64/26", "157.58.213.192/26", "157.58.214.128/26", "157.58.214.192/26", "167.220.70.64/26", "167.220.76.192/26", "167.220.77.64/26", "167.220.80.192/26", "167.220.81.128/26", "167.220.81.192/26", "131.107.1.128/25", "131.107.8.0/25", "167.220.204.128/26", "167.220.204.192/26", "167.220.205.0/26", "167.220.205.64/26", "20.99.254.208/29", "20.99.255.72/29", "20.99.254.224/29", "20.99.255.136/29", "20.120.200.56/29"]
  virtual_network_subnet_ids = [ data.azurerm_subnet.aks_subnet_vnodes[0].id ]
}


module "aks_sa_backup" {
  depends_on              = [module.rg_aksapps, module.drrg_aksapps, data.azurerm_subnet.aks_subnet_vnodes]
  source                  = "../_modules/storage_account"

  name                    = replace(format("%s-backups", local.aksclustername),"-","")
  location                = local.location
  tags                    = local.tags
  rg                      = local.aksappsrg
  ip_rules                = [ "${chomp(data.http.myip.response_body)}", "72.178.126.108", "167.220.148.0/22", "131.107.147.0/24", "131.107.159.0/24", "131.107.160.0/24", "131.107.174.0/24", "167.220.24.0/24", "167.220.26.0/24", "167.220.238.0/27", "167.220.238.128/27", "167.220.238.192/27", "167.220.238.64/27", "167.220.232.0/23", "167.220.255.0/25", "167.220.242.0/27", "167.220.242.128/27", "167.220.242.192/27", "167.220.242.64/27", "94.245.87.0/24", "167.220.196.0/23", "194.69.104.0/25", "191.234.97.0/26", "167.220.0.0/23", "167.220.2.0/24", "167.220.226.0/23", "131.107.132.16/28", "131.107.132.32/28", "157.58.212.64/26", "157.58.212.128/26", "157.58.213.64/26", "157.58.213.192/26", "157.58.214.128/26", "157.58.214.192/26", "167.220.70.64/26", "167.220.76.192/26", "167.220.77.64/26", "167.220.80.192/26", "167.220.81.128/26", "167.220.81.192/26", "131.107.1.128/25", "131.107.8.0/25", "167.220.204.128/26", "167.220.204.192/26", "167.220.205.0/26", "167.220.205.64/26", "20.99.254.208/29", "20.99.255.72/29", "20.99.254.224/29", "20.99.255.136/29", "20.120.200.56/29"]
  virtual_network_subnet_ids = [ data.azurerm_subnet.aks_subnet_vnodes[0].id ]
}

###### Give AKS cluster read/write access to the storage accounts
############################################################################################
module "role_assignments" {
  depends_on    = [
  data.azurerm_kubernetes_cluster.aks_cluster, 
  data.azurerm_kubernetes_cluster.draks_cluster, 
  module.aks_sa_backup, 
  module.aks_sa_media, 
  module.aks_sa_log]

  source        = "../_modules/role_assignments"
  
  role_assignments =  var.create_dr == true ? { 
        "assignment1" = {
            scope = module.aks_sa_media.id
            role  = "Storage Account Contributor"
            principal_id = data.azurerm_kubernetes_cluster.aks_cluster[0].identity[0].principal_id
        }
        "assignment2" = {
            scope = module.aks_sa_media.id
            role  = "Storage Account Contributor"
            principal_id = data.azurerm_kubernetes_cluster.aks_cluster[0].kubelet_identity[0].object_id
        }
        "assignment3" = {
            scope = module.aks_sa_media.id
            role  = "Storage Account Contributor"
            principal_id = data.azurerm_kubernetes_cluster.draks_cluster[0].identity[0].principal_id
        }
        "assignment4" = {
            scope = module.aks_sa_media.id
            role  = "Storage Account Contributor"
            principal_id = data.azurerm_kubernetes_cluster.draks_cluster[0].kubelet_identity[0].object_id
        }
        "assignment5" = {
            scope = module.aks_sa_log.id
            role  = "Storage Account Contributor"
            principal_id = data.azurerm_kubernetes_cluster.aks_cluster[0].identity[0].principal_id
        }
        "assignment6" = {
            scope = module.aks_sa_log.id
            role  = "Storage Account Contributor"
            principal_id = data.azurerm_kubernetes_cluster.aks_cluster[0].kubelet_identity[0].object_id
        }
        "assignment7" = {
            scope = module.aks_sa_log.id
            role  = "Storage Account Contributor"
            principal_id = data.azurerm_kubernetes_cluster.draks_cluster[0].identity[0].principal_id
        }
        "assignment8" = {
            scope = module.aks_sa_log.id
            role  = "Storage Account Contributor"
            principal_id = data.azurerm_kubernetes_cluster.draks_cluster[0].kubelet_identity[0].object_id
        }
        "assignment9" = {
            scope = module.aks_sa_backup.id
            role  = "Storage Account Contributor"
            principal_id = data.azurerm_kubernetes_cluster.aks_cluster[0].identity[0].principal_id
        }
        "assignment10" = {
            scope = module.aks_sa_backup.id
            role  = "Storage Account Contributor"
            principal_id = data.azurerm_kubernetes_cluster.aks_cluster[0].kubelet_identity[0].object_id
        }
        "assignment11" = {
            scope = module.aks_sa_backup.id
            role  = "Storage Account Contributor"
            principal_id = data.azurerm_kubernetes_cluster.draks_cluster[0].identity[0].principal_id
        }
        "assignment12" = {
            scope = module.aks_sa_backup.id
            role  = "Storage Account Contributor"
            principal_id = data.azurerm_kubernetes_cluster.draks_cluster[0].kubelet_identity[0].object_id
        }
      } : { 
        "assignment1" = {
            scope = module.aks_sa_media.id
            role  = "Storage Account Contributor"
            principal_id = data.azurerm_kubernetes_cluster.aks_cluster[0].identity[0].principal_id
        }
        "assignment2" = {
            scope = module.aks_sa_media.id
            role  = "Storage Account Contributor"
            principal_id = data.azurerm_kubernetes_cluster.aks_cluster[0].kubelet_identity[0].object_id
        }
        "assignment3" = {
            scope = module.aks_sa_log.id
            role  = "Storage Account Contributor"
            principal_id = data.azurerm_kubernetes_cluster.aks_cluster[0].identity[0].principal_id
        }
        "assignment4" = {
            scope = module.aks_sa_log.id
            role  = "Storage Account Contributor"
            principal_id = data.azurerm_kubernetes_cluster.aks_cluster[0].kubelet_identity[0].object_id
        }
        "assignment5" = {
            scope = module.aks_sa_backup.id
            role  = "Storage Account Contributor"
            principal_id = data.azurerm_kubernetes_cluster.aks_cluster[0].identity[0].principal_id
        }
        "assignment6" = {
            scope = module.aks_sa_backup.id
            role  = "Storage Account Contributor"
            principal_id = data.azurerm_kubernetes_cluster.aks_cluster[0].kubelet_identity[0].object_id
        }
      }
}

###### Create Private DNS Zones
###### It stores the FQDN and IP Mappings for all private endpoints.
############################################################################################
module "pvt_dns_zone_primary_storage" {
  depends_on              = [data.azurerm_virtual_network.aks_vnet,data.azurerm_virtual_network.draks_vnet, module.rg_aksapps]
  source                  = "../_modules/pvt_dns_zone"
  enable                  = true 

  name                    = "privatelink.file.core.windows.net" 
  rg                      = local.aksappsrg
  tags                    = local.tags

  vnet_id                 = data.azurerm_virtual_network.aks_vnet[0].id
}
data "azurerm_private_dns_zone" "pvt_dns_zone_primary_storage" {
  count               = 1
  depends_on          = [ module.pvt_dns_zone_primary_storage ]
  name                = "privatelink.file.core.windows.net"
  resource_group_name = local.aksappsrg
}

module "pvt_dns_zone_secondary_storage" {
  depends_on              = [data.azurerm_virtual_network.aks_vnet,data.azurerm_virtual_network.draks_vnet, module.drrg_aksapps]
  source                  = "../_modules/pvt_dns_zone"
  enable                  = var.create_dr 

  name                    = "privatelink.file.core.windows.net" 
  rg                      = local.draksappsrg
  tags                    = local.tags

  vnet_id                 = var.create_dr == true ? data.azurerm_virtual_network.draks_vnet[0].id : null
}
data "azurerm_private_dns_zone" "pvt_dns_zone_secondary_storage" {
  count               = var.create_dr == true ? 1 : 0
  depends_on          = [ module.pvt_dns_zone_secondary_storage ]
  name                = "privatelink.file.core.windows.net"
  resource_group_name = local.draksappsrg
}

module "pvt_dns_zone_primary_mysql" {
  depends_on              = [data.azurerm_virtual_network.aks_vnet,data.azurerm_virtual_network.draks_vnet, module.rg_aksapps]
  source                  = "../_modules/pvt_dns_zone"
  enable                  = true 

  name                    = "privatelink.mysql.database.azure.com" #local.aksvnet_pvt_dns_zone
  rg                      = local.aksappsrg
  tags                    = local.tags

  vnet_id                 = data.azurerm_virtual_network.aks_vnet[0].id
}
data "azurerm_private_dns_zone" "pvt_dns_zone_primary_mysql" {
  count               = 1
  depends_on          = [ module.pvt_dns_zone_primary_mysql ]
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = local.aksappsrg
}

module "pvt_dns_zone_secondary_mysql" {
  depends_on              = [data.azurerm_virtual_network.aks_vnet,data.azurerm_virtual_network.draks_vnet, module.drrg_aksapps]
  source                  = "../_modules/pvt_dns_zone"
  enable                  = var.create_dr 

  name                    = "privatelink.mysql.database.azure.com" #local.aksvnet_pvt_dns_zone
  rg                      = local.draksappsrg
  tags                    = local.tags

  vnet_id                 = var.create_dr == true ? data.azurerm_virtual_network.draks_vnet[0].id : null
}
data "azurerm_private_dns_zone" "pvt_dns_zone_secondary_mysql" {
  count               = var.create_dr == true ? 1 : 0
  depends_on          = [ module.pvt_dns_zone_secondary_mysql ]
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = local.draksappsrg
}

###
module "pvt_dns_zone_primary_kv" {
  depends_on              = [data.azurerm_virtual_network.aks_vnet,data.azurerm_virtual_network.draks_vnet, module.rg_aksapps]
  source                  = "../_modules/pvt_dns_zone"
  enable                  = true 

  name                    = "privatelink.vaultcore.azure.net" #local.aksvnet_pvt_dns_zone
  rg                      = local.aksappsrg
  tags                    = local.tags

  vnet_id                 = data.azurerm_virtual_network.aks_vnet[0].id
}
data "azurerm_private_dns_zone" "pvt_dns_zone_primary_kv" {
  count               = 1
  depends_on          = [ module.pvt_dns_zone_primary_kv ]
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = local.aksappsrg
}

module "pvt_dns_zone_secondary_kv" {
  depends_on              = [data.azurerm_virtual_network.aks_vnet,data.azurerm_virtual_network.draks_vnet, module.drrg_aksapps]
  source                  = "../_modules/pvt_dns_zone"
  enable                  = var.create_dr 

  name                    = "privatelink.vaultcore.azure.net" #local.aksvnet_pvt_dns_zone
  rg                      = local.draksappsrg
  tags                    = local.tags

  vnet_id                 = var.create_dr == true ? data.azurerm_virtual_network.draks_vnet[0].id : null
}
data "azurerm_private_dns_zone" "pvt_dns_zone_secondary_kv" {
  count               = var.create_dr == true ? 1 : 0
  depends_on          = [ module.pvt_dns_zone_secondary_kv ]
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = local.draksappsrg
}

# ###### Store the storage keys in the Key Vault
# ############################################################################################
module "aks_kv" {
  depends_on              = [ data.azurerm_user_assigned_identity.aks_cluster, 
                              data.azurerm_user_assigned_identity.draks_cluster, 
                              module.rg_aksapps,
                              module.role_assignments,
                              module.aks_sa_media, 
                              module.aks_sa_log, 
                              module.aks_sa_backup]
  source                  = "../_modules/kv_v2" 

  name                    = local.akskv 
  location                = local.location
  tags                    = local.tags
  rg                      = local.aksappsrg
  tenant_id               = data.azuread_client_config.current.tenant_id
  current_user_id         = data.azuread_client_config.current.object_id
  additional_users        = var.create_dr == false ? [ 
      data.azurerm_user_assigned_identity.aks_cluster[0].principal_id
    ] : [ 
      data.azurerm_user_assigned_identity.aks_cluster[0].principal_id, 
      data.azurerm_user_assigned_identity.draks_cluster[0].principal_id
    ]
  key_permissions         = ["Create", "Get", "List", "Purge", "Recover", "Delete"]
  secret_permissions      = ["Get", "List", "Purge", "Recover", "Set", "Delete"]
  certificate_permissions = ["Create", "Get", "List", "Purge", "Recover", "Update", "Delete"]
  ip_rules                = [ "${chomp(data.http.myip.response_body)}", "72.178.126.108", "167.220.148.0/22", "131.107.147.0/24", "131.107.159.0/24", "131.107.160.0/24", "131.107.174.0/24", "167.220.24.0/24", "167.220.26.0/24", "167.220.238.0/27", "167.220.238.128/27", "167.220.238.192/27", "167.220.238.64/27", "167.220.232.0/23", "167.220.255.0/25", "167.220.242.0/27", "167.220.242.128/27", "167.220.242.192/27", "167.220.242.64/27", "94.245.87.0/24", "167.220.196.0/23", "194.69.104.0/25", "191.234.97.0/26", "167.220.0.0/23", "167.220.2.0/24", "167.220.226.0/23", "131.107.132.16/28", "131.107.132.32/28", "157.58.212.64/26", "157.58.212.128/26", "157.58.213.64/26", "157.58.213.192/26", "157.58.214.128/26", "157.58.214.192/26", "167.220.70.64/26", "167.220.76.192/26", "167.220.77.64/26", "167.220.80.192/26", "167.220.81.128/26", "167.220.81.192/26", "131.107.1.128/25", "131.107.8.0/25", "167.220.204.128/26", "167.220.204.192/26", "167.220.205.0/26", "167.220.205.64/26", "20.99.254.208/29", "20.99.255.72/29", "20.99.254.224/29", "20.99.255.136/29", "20.120.200.56/29"]
  subnet_ids              = var.create_dr == true ? [ 
      data.azurerm_subnet.aks_subnet_vnodes[0].id,
      data.azurerm_subnet.draks_subnet_vnodes[0].id 
    ] : [ 
      data.azurerm_subnet.aks_subnet_vnodes[0].id
    ]

  secret_list = {
    "${module.aks_sa_media.name}-name"  = "${module.aks_sa_media.name}" , 
    "${module.aks_sa_media.name}-key"   = "${module.aks_sa_media.primary_access_key}",
    "${module.aks_sa_log.name}-name"    = "${module.aks_sa_log.name}" , 
    "${module.aks_sa_log.name}-key"     = "${module.aks_sa_log.primary_access_key}",
    "${module.aks_sa_backup.name}-name" = "${module.aks_sa_backup.name}" , 
    "${module.aks_sa_backup.name}-key"  = "${module.aks_sa_backup.primary_access_key}",
  }
}

# ###### Create private endpoint for the storage accounts. 
# ###### One end point in primary subnet, and the other in the secondary subnet
# ############################################################################################
module "private_endpoints_primary_storage_media" {
  depends_on              = [module.aks_sa_media, data.azurerm_private_dns_zone.pvt_dns_zone_primary_storage]
  source                  = "../_modules/pvt_endpoints"

  pvt_dns_group               = local.aksvnet_pvt_dns_group
  pvt_dns_zone_id             = data.azurerm_private_dns_zone.pvt_dns_zone_primary_storage[0].id
  pvt_dns_zone_name           = data.azurerm_private_dns_zone.pvt_dns_zone_primary_storage[0].name
  pvt_dns_zone_rg             = data.azurerm_private_dns_zone.pvt_dns_zone_primary_storage[0].resource_group_name
  tags                        = local.tags

  pvt_endpoints               = [
                                  {
                                    name                        = replace(format("%s-medias-pep", local.aksclustername),"-","")
                                    #a_record_name               = module.aks_sa_backup.name
                                    location                    = local.location
                                    rg                          = local.aksappsrg
                                    subresource_names           = ["file"]
                                    pvt_connection_resource_id  = module.aks_sa_media.id
                                    subnet_id                   = data.azurerm_subnet.aks_subnet_vnodes[0].id
                                    service_connection_name     = replace(format("%s-medias-pvtcon", local.aksclustername),"-","")
                                  }
                                ]
}
module "private_endpoints_primary_storage_logs" {
  depends_on              = [module.aks_sa_log, data.azurerm_private_dns_zone.pvt_dns_zone_primary_storage]
  source                  = "../_modules/pvt_endpoints"

  pvt_dns_group               = local.aksvnet_pvt_dns_group
  pvt_dns_zone_id             = data.azurerm_private_dns_zone.pvt_dns_zone_primary_storage[0].id
  pvt_dns_zone_name           = data.azurerm_private_dns_zone.pvt_dns_zone_primary_storage[0].name
  pvt_dns_zone_rg             = data.azurerm_private_dns_zone.pvt_dns_zone_primary_storage[0].resource_group_name
  tags                        = local.tags

  pvt_endpoints               = [
                                  {
                                    name                        = replace(format("%s-logs-pep", local.aksclustername),"-","")
                                    #a_record_name               = module.aks_sa_backup.name
                                    location                    = local.location
                                    rg                          = local.aksappsrg
                                    subresource_names           = ["file"]
                                    pvt_connection_resource_id  = module.aks_sa_log.id
                                    subnet_id                   = data.azurerm_subnet.aks_subnet_vnodes[0].id
                                    service_connection_name     = replace(format("%s-logs-pvtcon", local.aksclustername),"-","")
                                  }
                                ]
}
module "private_endpoints_primary_storage_backups" {
  depends_on              = [module.aks_sa_backup, data.azurerm_private_dns_zone.pvt_dns_zone_primary_storage]
  source                  = "../_modules/pvt_endpoints"

  pvt_dns_group               = local.aksvnet_pvt_dns_group
  pvt_dns_zone_id             = data.azurerm_private_dns_zone.pvt_dns_zone_primary_storage[0].id
  pvt_dns_zone_name           = data.azurerm_private_dns_zone.pvt_dns_zone_primary_storage[0].name
  pvt_dns_zone_rg             = data.azurerm_private_dns_zone.pvt_dns_zone_primary_storage[0].resource_group_name
  tags                        = local.tags

  pvt_endpoints               = [
                                  {
                                    name                        = replace(format("%s-backups-pep", local.aksclustername),"-","")
                                    #a_record_name               = module.aks_sa_backup.name
                                    location                    = local.location
                                    rg                          = local.aksappsrg
                                    subresource_names           = ["file"]
                                    pvt_connection_resource_id  = module.aks_sa_backup.id
                                    subnet_id                   = data.azurerm_subnet.aks_subnet_vnodes[0].id
                                    service_connection_name     = replace(format("%s-backups-pvtcon", local.aksclustername),"-","")
                                  }
                                ]
}

module "private_endpoints_secondary_storage_media" {
  depends_on              = [module.aks_sa_media, data.azurerm_private_dns_zone.pvt_dns_zone_secondary_storage]
  source                  = "../_modules/pvt_endpoints"

  pvt_dns_group               = local.aksvnet_pvt_dns_group
  pvt_dns_zone_id             = var.create_dr == true ? data.azurerm_private_dns_zone.pvt_dns_zone_secondary_storage[0].id : null
  pvt_dns_zone_name           = var.create_dr == true ? data.azurerm_private_dns_zone.pvt_dns_zone_secondary_storage[0].name : null
  pvt_dns_zone_rg             = var.create_dr == true ? data.azurerm_private_dns_zone.pvt_dns_zone_secondary_storage[0].resource_group_name : null
  tags                        = local.tags

  pvt_endpoints               = var.create_dr == true ? [
                                  {
                                    name                        = replace(format("%s-media-pep", local.draksclustername),"-","")
                                    #a_record_name               = module.aks_sa_backup.name
                                    location                    = local.drlocation
                                    rg                          = local.draksappsrg
                                    subresource_names           = ["file"]
                                    pvt_connection_resource_id  = module.aks_sa_media.id
                                    subnet_id                   = data.azurerm_subnet.draks_subnet_vnodes[0].id
                                    service_connection_name     = replace(format("%s-media-pvtcon", local.draksclustername),"-","")
                                  }
                                ] : []
}
module "private_endpoints_secondary_storage_logs" {
  depends_on              = [module.aks_sa_log, data.azurerm_private_dns_zone.pvt_dns_zone_secondary_storage]
  source                  = "../_modules/pvt_endpoints"

  pvt_dns_group               = local.aksvnet_pvt_dns_group
  pvt_dns_zone_id             = var.create_dr == true ? data.azurerm_private_dns_zone.pvt_dns_zone_secondary_storage[0].id : null
  pvt_dns_zone_name           = var.create_dr == true ? data.azurerm_private_dns_zone.pvt_dns_zone_secondary_storage[0].name : null
  pvt_dns_zone_rg             = var.create_dr == true ? data.azurerm_private_dns_zone.pvt_dns_zone_secondary_storage[0].resource_group_name : null
  tags                        = local.tags

  pvt_endpoints               = var.create_dr == true ? [
                                  {
                                    name                        = replace(format("%s-logs-pep", local.draksclustername),"-","")
                                    #a_record_name               = module.aks_sa_backup.name
                                    location                    = local.drlocation
                                    rg                          = local.draksappsrg
                                    subresource_names           = ["file"]
                                    pvt_connection_resource_id  = module.aks_sa_log.id
                                    subnet_id                   = data.azurerm_subnet.draks_subnet_vnodes[0].id
                                    service_connection_name     = replace(format("%s-logs-pvtcon", local.draksclustername),"-","")
                                  }
                                ] : []
}
module "private_endpoints_secondary_storage_backups" {
  depends_on              = [module.aks_sa_backup, data.azurerm_private_dns_zone.pvt_dns_zone_secondary_storage]
  source                  = "../_modules/pvt_endpoints"

  pvt_dns_group               = local.aksvnet_pvt_dns_group
  pvt_dns_zone_id             = var.create_dr == true ? data.azurerm_private_dns_zone.pvt_dns_zone_secondary_storage[0].id : null
  pvt_dns_zone_name           = var.create_dr == true ? data.azurerm_private_dns_zone.pvt_dns_zone_secondary_storage[0].name : null
  pvt_dns_zone_rg             = var.create_dr == true ? data.azurerm_private_dns_zone.pvt_dns_zone_secondary_storage[0].resource_group_name : null
  tags                        = local.tags

  pvt_endpoints               = var.create_dr == true ? [
                                  {
                                    name                        = replace(format("%s-backups-pep", local.draksclustername),"-","")
                                    #a_record_name               = module.aks_sa_backup.name
                                    location                    = local.drlocation
                                    rg                          = local.draksappsrg
                                    subresource_names           = ["file"]
                                    pvt_connection_resource_id  = module.aks_sa_backup.id
                                    subnet_id                   = data.azurerm_subnet.draks_subnet_vnodes[0].id
                                    service_connection_name     = replace(format("%s-backups-pvtcon", local.draksclustername),"-","")
                                  }
                                ] : []
}

#
module "private_endpoints_primary_kv_base" {
  depends_on              = [module.aks_kv, data.azurerm_private_dns_zone.pvt_dns_zone_primary_kv]
  source                  = "../_modules/pvt_endpoints"

  pvt_dns_group               = local.aksvnet_pvt_dns_group
  pvt_dns_zone_id             = data.azurerm_private_dns_zone.pvt_dns_zone_primary_kv[0].id
  pvt_dns_zone_name           = data.azurerm_private_dns_zone.pvt_dns_zone_primary_kv[0].name
  pvt_dns_zone_rg             = data.azurerm_private_dns_zone.pvt_dns_zone_primary_kv[0].resource_group_name
  tags                        = local.tags

  pvt_endpoints               = [
                                  {
                                    name                        = replace(format("%s-basekv-pep", local.aksclustername),"-","")
                                    #a_record_name               = module.aks_sa_backup.name
                                    location                    = local.location
                                    rg                          = local.aksappsrg
                                    subresource_names           = ["vault"]
                                    pvt_connection_resource_id  = module.aks_kv.id
                                    subnet_id                   = data.azurerm_subnet.aks_subnet_vnodes[0].id
                                    service_connection_name     = replace(format("%s-basekv-pvtcon", local.aksclustername),"-","")
                                  }
                                ]
}
module "private_endpoints_secondary_kv_base" {
  depends_on              = [module.aks_kv, data.azurerm_private_dns_zone.pvt_dns_zone_secondary_kv]
  source                  = "../_modules/pvt_endpoints"

  pvt_dns_group               = local.aksvnet_pvt_dns_group
  pvt_dns_zone_id             = var.create_dr == true ? data.azurerm_private_dns_zone.pvt_dns_zone_secondary_kv[0].id : null
  pvt_dns_zone_name           = var.create_dr == true ? data.azurerm_private_dns_zone.pvt_dns_zone_secondary_kv[0].name : null
  pvt_dns_zone_rg             = var.create_dr == true ? data.azurerm_private_dns_zone.pvt_dns_zone_secondary_kv[0].resource_group_name : null
  tags                        = local.tags

  pvt_endpoints               = var.create_dr == true ? [
                                  {
                                    name                        = replace(format("%s-basekv-pep", local.draksclustername),"-","")
                                    #a_record_name               = module.aks_sa_backup.name
                                    location                    = local.drlocation
                                    rg                          = local.draksappsrg
                                    subresource_names           = ["vault"]
                                    pvt_connection_resource_id  = module.aks_kv.id
                                    subnet_id                   = data.azurerm_subnet.draks_subnet_vnodes[0].id
                                    service_connection_name     = replace(format("%s-basekv-pvtcon", local.draksclustername),"-","")
                                  }
                                ] : []
}


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
  count = 1
  name                 = local.aksvnet
  resource_group_name  = local.aksrg
}

data "azurerm_virtual_network" "draks_vnet" {
  count                       = var.create_dr == true ? 1 : 0
  name                 = local.draksvnet
  resource_group_name  = local.draksrg
}

data "azurerm_subnet" "aks_subnet_default" {
  count = 1
  name                 = local.akssubnets["aks-subnet-default"].name
  virtual_network_name = local.aksvnet
  resource_group_name  = local.aksrg
}

data "azurerm_subnet" "draks_subnet_default" {
  count                       = var.create_dr == true ? 1 : 0
  name                 = local.akssubnets["aks-subnet-default"].name
  virtual_network_name = local.draksvnet
  resource_group_name  = local.draksrg
}

data "azurerm_subnet" "aks_subnet_vnodes" {
  count = 1
  name                 = local.akssubnets["aks-subnet-vnodes"].name
  virtual_network_name = local.aksvnet
  resource_group_name  = local.aksrg
}

data "azurerm_subnet" "draks_subnet_vnodes" {
  count                       = var.create_dr == true ? 1 : 0
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


data "azurerm_private_dns_zone" "pvt_dns_zone_primary_storage" {
  count = 1
  name                = "privatelink.file.core.windows.net"
  resource_group_name = local.aksappsrg
}
data "azurerm_private_dns_zone" "pvt_dns_zone_secondary_storage" {
  count                       = var.create_dr == true ? 1 : 0
  name                = "privatelink.file.core.windows.net"
  resource_group_name = local.draksappsrg
}
data "azurerm_private_dns_zone" "pvt_dns_zone_primary_mysql" {
  count = 1
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = local.aksappsrg
}
data "azurerm_private_dns_zone" "pvt_dns_zone_secondary_mysql" {
  count                       = var.create_dr == true ? 1 : 0
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = local.draksappsrg
}
data "azurerm_private_dns_zone" "pvt_dns_zone_primary_kv" {
  count = 1 
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = local.aksappsrg
}
data "azurerm_private_dns_zone" "pvt_dns_zone_secondary_kv" {
  count                       = var.create_dr == true ? 1 : 0
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = local.draksappsrg
}


###### Create the apps resource group that holds all application specific resources
############################################################################################
module "rg_apps" {
  source = "../_modules/rg"

  name     = local.app_rg_name
  location = local.location
  tags     = local.tags
}

module "drrg_apps" {
  source = "../_modules/rg"
  enable = var.create_dr

  name     = local.drapp_rg_name
  location = local.drlocation
  tags     = local.tags
}


###### Create the Mysql Flex server 
############################################################################################
module "app_mysql" {
  depends_on              = [module.rg_apps, module.drrg_apps]
  enable                  = var.in_cluster_db == false ? true : false 

  source                  = "../_modules/mysql_server_v2"
  sku                     = "GP_Standard_D2ds_v4" 
  tags                    = local.tags 
  
  administrator_login     = "azureuser"
  administrator_password  = var.windows_vm_pwd

  name                    = local.app_mysql_server
  location                = "East US 2"
  rg                      = local.app_rg_name 

  replica_needed          = var.in_cluster_db == true ? false : var.create_dr
  replica_name            = local.drapp_mysql_server
  replica_location        = local.drlocation 

}

###### Create a KV to store wordpress secrets
############################################################################################
module "aks_app_kv" {
  depends_on              = [data.azurerm_user_assigned_identity.aks_cluster, 
                              data.azurerm_user_assigned_identity.draks_cluster, module.app_mysql]
  source                  = "../_modules/kv_v2" 

  name                    = local.app_kv_name
  location                = local.location
  tags                    = local.tags
  rg                      = local.app_rg_name
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
      var.create_dr == true ? data.azurerm_subnet.draks_subnet_vnodes[0].id : null 
    ] : [ 
      data.azurerm_subnet.aks_subnet_vnodes[0].id
    ]

  secret_list = { }
}

#### Create Private Endpoints for SQL Server and KV
############################################################################################
module "private_endpoints_primary_kv_app" {
  depends_on              = [module.aks_app_kv, data.azurerm_private_dns_zone.pvt_dns_zone_primary_kv]
  source                  = "../_modules/pvt_endpoints"

  pvt_dns_group               = local.aksvnet_pvt_dns_group
  pvt_dns_zone_id             = data.azurerm_private_dns_zone.pvt_dns_zone_primary_kv[0].id
  pvt_dns_zone_name           = data.azurerm_private_dns_zone.pvt_dns_zone_primary_kv[0].name
  pvt_dns_zone_rg             = local.app_rg_name
  tags                        = local.tags

  pvt_endpoints               = [
                                  {
                                    name                        = replace(format("%s-pep1", local.app_kv_name),"-","")
                                    #a_record_name               = module.aks_sa_backup.name
                                    location                    = local.location
                                    rg                          = local.app_rg_name
                                    subresource_names           = ["vault"]
                                    pvt_connection_resource_id  = module.aks_app_kv.id
                                    subnet_id                   = data.azurerm_subnet.aks_subnet_vnodes[0].id
                                    service_connection_name     = replace(format("%s-pvtcon1", local.app_kv_name),"-","")
                                  }
                                ]
}
module "private_endpoints_secondary_kv_app" {
  depends_on              = [module.aks_app_kv, data.azurerm_private_dns_zone.pvt_dns_zone_secondary_kv]
  source                  = "../_modules/pvt_endpoints"

  pvt_dns_group               = local.aksvnet_pvt_dns_group
  pvt_dns_zone_id             = var.create_dr == true ? data.azurerm_private_dns_zone.pvt_dns_zone_secondary_kv[0].id : null
  pvt_dns_zone_name           = var.create_dr == true ? data.azurerm_private_dns_zone.pvt_dns_zone_secondary_kv[0].name : null
  pvt_dns_zone_rg             = local.app_rg_name
  tags                        = local.tags

  pvt_endpoints               = var.create_dr == true ? [
                                  {
                                    name                        = replace(format("%s-pep2", local.app_kv_name),"-","")
                                    #a_record_name               = module.aks_sa_backup.name
                                    location                    = local.drlocation
                                    rg                          = local.drapp_rg_name
                                    subresource_names           = ["vault"]
                                    pvt_connection_resource_id  = module.aks_app_kv.id
                                    subnet_id                   = var.create_dr == true ? data.azurerm_subnet.draks_subnet_vnodes[0].id : null 
                                    service_connection_name     = replace(format("%s-pvtcon2", local.app_kv_name),"-","")
                                  }
                                ] : []
}

#####
module "private_endpoints_primary_sql" {
  depends_on              = [module.app_mysql, data.azurerm_private_dns_zone.pvt_dns_zone_primary_mysql]
  source                  = "../_modules/pvt_endpoints"

  pvt_dns_group               = local.aksvnet_pvt_dns_group
  pvt_dns_zone_id             = data.azurerm_private_dns_zone.pvt_dns_zone_primary_mysql[0].id
  pvt_dns_zone_name           = data.azurerm_private_dns_zone.pvt_dns_zone_primary_mysql[0].name 
  pvt_dns_zone_rg             = local.app_rg_name
  tags                        = local.tags

  pvt_endpoints               = var.in_cluster_db == false ? [
                                  {
                                    name                        = replace(format("%s-pep1", local.app_mysql_server),"-","")
                                    #a_record_name               = module.aks_sa_backup.name
                                    location                    = local.location
                                    rg                          = local.app_rg_name
                                    subresource_names           = ["mysqlServer"]
                                    pvt_connection_resource_id  = var.in_cluster_db == false ? module.app_mysql.primary_server_id : null
                                    subnet_id                   = data.azurerm_subnet.aks_subnet_vnodes[0].id
                                    service_connection_name     = replace(format("%s-pvtcon2", local.app_mysql_server),"-","")
                                  }
                                ] : []
}
module "private_endpoints_secondary_sql" {
  depends_on              = [module.app_mysql, data.azurerm_private_dns_zone.pvt_dns_zone_secondary_mysql]
  source                  = "../_modules/pvt_endpoints"

  pvt_dns_group               = local.aksvnet_pvt_dns_group
  pvt_dns_zone_id             = var.create_dr == true ? data.azurerm_private_dns_zone.pvt_dns_zone_secondary_mysql[0].id : null
  pvt_dns_zone_name           = var.create_dr == true ? data.azurerm_private_dns_zone.pvt_dns_zone_secondary_mysql[0].name : null
  pvt_dns_zone_rg             = local.app_rg_name
  tags                        = local.tags

  pvt_endpoints               = var.in_cluster_db == false ? [
                                  {
                                    name                        = replace(format("%s-pep2", local.app_mysql_server),"-","")
                                    #a_record_name               = module.aks_sa_backup.name
                                    location                    = local.drlocation
                                    rg                          = local.drapp_rg_name
                                    subresource_names           = ["mysqlServer"]
                                    pvt_connection_resource_id  = (var.create_dr == true  && var.in_cluster_db == false) ? module.app_mysql.primary_server_id : null
                                    subnet_id                   = var.create_dr == true ? data.azurerm_subnet.draks_subnet_vnodes[0].id : null
                                    service_connection_name     = replace(format("%s-pvtcon", local.app_mysql_server),"-","")
                                  }
                                ] : []
}

module "private_endpoints_primary_sql_replica" {
  depends_on              = [module.app_mysql, data.azurerm_private_dns_zone.pvt_dns_zone_primary_mysql]
  source                  = "../_modules/pvt_endpoints"

  pvt_dns_group               = local.aksvnet_pvt_dns_group
  pvt_dns_zone_id             = data.azurerm_private_dns_zone.pvt_dns_zone_primary_mysql[0].id
  pvt_dns_zone_name           = data.azurerm_private_dns_zone.pvt_dns_zone_primary_mysql[0].name
  pvt_dns_zone_rg             = local.app_rg_name
  tags                        = local.tags

  pvt_endpoints               = var.in_cluster_db == false ? [
                                  {
                                    name                        = replace(format("%s-pep1", local.drapp_mysql_server),"-","")
                                    #a_record_name               = module.aks_sa_backup.name
                                    location                    = local.location
                                    rg                          = local.app_rg_name
                                    subresource_names           = ["mysqlServer"]
                                    pvt_connection_resource_id  = var.in_cluster_db == false ? module.app_mysql.replica_server_id : null
                                    subnet_id                   = data.azurerm_subnet.aks_subnet_vnodes[0].id
                                    service_connection_name     = replace(format("%s-pvtcon2", local.drapp_mysql_server),"-","")
                                  }
                                ] : []
}
module "private_endpoints_secondary_sql_replica" {
  depends_on              = [module.app_mysql, data.azurerm_private_dns_zone.pvt_dns_zone_secondary_mysql]
  source                  = "../_modules/pvt_endpoints"

  pvt_dns_group               = local.aksvnet_pvt_dns_group
  pvt_dns_zone_id             = var.create_dr == true ? data.azurerm_private_dns_zone.pvt_dns_zone_secondary_mysql[0].id : null
  pvt_dns_zone_name           = var.create_dr == true ? data.azurerm_private_dns_zone.pvt_dns_zone_secondary_mysql[0].name : null
  pvt_dns_zone_rg             = local.app_rg_name
  tags                        = local.tags

  pvt_endpoints               = var.in_cluster_db == false ? [
                                  {
                                    name                        = replace(format("%s-pep2", local.drapp_mysql_server),"-","")
                                    #a_record_name               = module.aks_sa_backup.name
                                    location                    = local.drlocation
                                    rg                          = local.drapp_rg_name
                                    subresource_names           = ["mysqlServer"]
                                    pvt_connection_resource_id  = var.in_cluster_db == false ? module.app_mysql.replica_server_id : null
                                    subnet_id                   = var.create_dr == true ? data.azurerm_subnet.draks_subnet_vnodes[0].id : null
                                    service_connection_name     = replace(format("%s-pvtcon", local.drapp_mysql_server),"-","")
                                  }
                                ] : []
}

###### Give AKS cluster read/write access to the resource groups
############################################################################################
module "role_assignments" {
  depends_on    = [
  data.azurerm_kubernetes_cluster.aks_cluster, 
  data.azurerm_kubernetes_cluster.draks_cluster, 
  module.rg_apps, 
  module.drrg_apps]

  source        = "../_modules/role_assignments"
  
  role_assignments =  var.create_dr == true ? { 
        "assignment1" = {
            scope = module.rg_apps.id
            role  = "Contributor"
            principal_id = data.azurerm_kubernetes_cluster.aks_cluster[0].identity[0].principal_id
        }
        "assignment2" = {
            scope = module.drrg_apps.id
            role  = "Contributor"
            principal_id = data.azurerm_kubernetes_cluster.draks_cluster[0].kubelet_identity[0].object_id
        }
      } : { 
        "assignment1" = {
            scope = module.rg_apps.id
            role  = "Contributor"
            principal_id = data.azurerm_kubernetes_cluster.aks_cluster[0].identity[0].principal_id
        }
      }
}

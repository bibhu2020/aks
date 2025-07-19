//get my public IP Address (where I am executing the terraform)
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

###### Create Resource Groups
############################################################################################
//create resource group for AKS resources
module "rg_aks" {
  source = "../_modules/rg"
  enable = true 

  name     = local.aksrg
  location = local.location
  tags     = local.tags
}

//create resource group for AKS resources
module "drrg_aks" {
  source = "../_modules/rg"
  enable = var.create_dr

  name     = local.draksrg
  location = local.drlocation
  tags     = local.tags
}

###### Create Virtual Network and Subnets
############################################################################################
module "vnet_aks" {
  source = "../_modules/vnet"
  enable = true 

  name                        = local.aksvnet
  location                    = local.location
  tags                        = local.tags
  rg                          = local.aksrg
  vnet_address_cidr           = local.aksvnet_address_cidr
  subnets                     = local.akssubnets

  depends_on = [
    module.rg_aks
  ]
}

module "drvnet_aks" {
  source = "../_modules/vnet"
  enable = var.create_dr

  name                        = local.draksvnet
  location                    = local.drlocation
  tags                        = local.tags
  rg                          = local.draksrg
  vnet_address_cidr           = local.draksvnet_address_cidr
  subnets                     = var.create_dr == true ? local.drakssubnets : {}

  depends_on = [
    module.drrg_aks
  ]
}


# ###### Create Private DNS Zone
# ###### It stores the FQDN and IP Mappings for all private endpoints.
# ###### It's global and visible to all regions
# ############################################################################################
# # module "pvt_dns_zone_file" {
# #   depends_on              = [module.vnet_aks, module.drvnet_aks]
# #   source                  = "../_modules/pvt_dns_zone"
# #   enable                  = true 

# #   name                    = "privatelink.file.core.windows.net" #local.aksvnet_pvt_dns_zone
# #   rg                      = local.aksrg
# #   tags                    = local.tags

# #   virtual_network_ids      = {"vnet1" = module.vnet_aks.id , "vnet2" = module.drvnet_aks.id}
# # }

# ###### Get Access to Pre-created AAD group that would be used as AKS cluster admin
# ###### cloudblogs-aks-cluster-admin-qa or cloudblogs-aks-cluster-admin-prod orcloudblogs-aks-cluster-admin-ppe
# ############################################################################################
module "aad_group" {
  source = "../_modules/aad"

  aad_group_name = var.aks_admin_aad_group 
}

###### Create SSH Key that would be used to access AKS woker nodes. Store in KV for future use.
############################################################################################
module "ssh_key" {
  source = "../_modules/ssh"
}

###### Create Monitoring resources
###### Log Analytics Workspace for AKS to log diagnostics
############################################################################################
module "ws_aks" {
  source = "../_modules/monitoring"
  enable = true 

  name     = format("%s-ws",local.aksrg)
  location = local.location
  tags     = local.tags
  rg       = local.aksrg

  depends_on = [
    module.rg_aks
  ]
}

module "drws_aks" {
  source = "../_modules/monitoring"
  enable = var.create_dr 

  name     = format("%s-ws",local.draksrg)
  location = local.drlocation
  tags     = local.tags
  rg       = local.draksrg

  depends_on = [
    module.drrg_aks
  ]
}

###### Create Azure Container Registry
###### Stores all Docker Images. This is a global resource for both primary and secondary cluster
############################################################################################
//create ACR
module "acr_aks" {
  source = "../_modules/acr"

  name     = local.aksacrname
  location = local.location
  tags     = local.tags
  rg       = local.aksrg

  depends_on = [
    module.rg_aks
  ]
}

module "acr_uploads" {
  source = "../_modules/acr_uploads"

  images          = [
    {
      registry      = local.ingress_controller_source_registry
      name          = local.ingress_controller_image
      tag           = local.ingress_controller_image_tag
      acr_registry  = local.ingress_controller_acr_registry
    },
    {
      registry      = local.ingress_controller_source_registry
      name          = local.ingress_controller_patch_image
      tag           = local.ingress_controller_patch_image_tag
      acr_registry  = local.ingress_controller_acr_registry
    },
    {
      registry      = local.ingress_controller_source_registry
      name          = local.ingress_controller_default_image
      tag           = local.ingress_controller_default_image_tag
      acr_registry  = local.ingress_controller_acr_registry
    },
    # {
    #   registry      = "docker.io"
    #   name          = "wordpress"
    #   tag           = "6.3.2-php8.2-apache"
    #   acr_registry  = local.ingress_controller_acr_registry
    # },
  ]

  depends_on = [
    module.acr_aks
  ]
}

###### Create a Virtual Machine
###### This VM is used to access the resources confined to vNets.
############################################################################################
module "aks_vm" {
  depends_on = [module.vnet_aks]
  source = "../_modules/vm"
  enable = true 

  name     = local.aksvnet_vm_name
  location = local.location
  tags     = local.tags
  rg       = local.aksrg
  size     = "Standard_F2" 
  username = "azureuser"
  password = var.windows_vm_pwd
  vnet_subnet_id = module.vnet_aks.subnets["aks-subnet-vnodes"].id
}
module "draks_vm" {
  depends_on = [module.drvnet_aks]
  source = "../_modules/vm"
  enable = var.create_dr

  name     = local.aksvnet_vm_name
  location = local.drlocation
  tags     = local.tags
  rg       = local.draksrg
  size     = "Standard_F2" 
  username = "azureuser"
  password = var.windows_vm_pwd
  vnet_subnet_id = var.create_dr == true ? module.drvnet_aks.subnets["aks-subnet-vnodes"].id : null
}

###### Create the AKS Cluster
###### Also add the ingress controller to it.
############################################################################################
module "aks_cluster" {
  source = "../_modules/aks"
  enable = true   

  name     = local.aksclustername
  location = local.location
  tags     = local.tags
  rg       = local.aksrg

  aks_admin_group_object_ids = [module.aad_group.azuread_group_id]
  admin_user                 = "azureuser"
  ssh_public_key             = module.ssh_key.public_key_openssh
  subnet_default_id          = module.vnet_aks.subnets["aks-subnet-default"].id
  network_plugin             = "azure"
  network_policy             = "azure"
  service_cidr               = "10.0.0.0/16"
  dns_service_ip             = "10.0.0.10"
  log_analytics_workspace_id = module.ws_aks.ws_aks_id

  depends_on = [
    module.vnet_aks,
    module.ws_aks,
    module.ssh_key
  ]
}

data "azurerm_kubernetes_cluster" "aks_cluster" {
    count                       = 1
    name                        = local.aksclustername
    resource_group_name         = local.aksrg
    depends_on                  = [ module.aks_cluster ]
}

module "draks_cluster" {
  source = "../_modules/aks"
  enable = var.create_dr   

  name     = local.draksclustername
  location = local.drlocation
  tags     = local.tags
  rg       = local.draksrg

  aks_admin_group_object_ids = [module.aad_group.azuread_group_id]
  admin_user                 = "azureuser"
  ssh_public_key             = module.ssh_key.public_key_openssh
  subnet_default_id          = var.create_dr == true ? module.drvnet_aks.subnets["aks-subnet-default"].id : null
  network_plugin             = "azure"
  network_policy             = "azure"
  service_cidr               = "10.0.0.0/16"
  dns_service_ip             = "10.0.0.10"
  log_analytics_workspace_id = module.drws_aks.ws_aks_id

  depends_on = [
    module.drvnet_aks,
    module.drws_aks,
    module.ssh_key
  ]
}

data "azurerm_kubernetes_cluster" "draks_cluster" {
    count                       = var.create_dr ? 1 : 0
    name                        = local.draksclustername
    resource_group_name         = local.draksrg
    depends_on                  = [ module.draks_cluster ]
}


###### Write the kubeconfig file to local machine so that you can access AKS cluster
############################################################################################
resource "local_file" "kubeconfig_cluster_primary" {
  depends_on = [data.azurerm_kubernetes_cluster.aks_cluster]
  filename   = local.kubeconfig
  content    = data.azurerm_kubernetes_cluster.aks_cluster[0].kube_config_raw
}
resource "local_file" "kubeconfig_cluster_secondary" {
  count = var.create_dr == true ? 1 : 0
  depends_on = [data.azurerm_kubernetes_cluster.draks_cluster]
  filename   = local.drkubeconfig
  content    = data.azurerm_kubernetes_cluster.draks_cluster[0].kube_config_raw
}


###### Store the SSH key in Key Vault
############################################################################################
module "aks_ssh_kv" {
  depends_on              = [ module.vnet_aks, module.drvnet_aks  ]
  source                  = "../_modules/kv_v2" 

  name                    = local.sshkv
  location                = local.location
  tags                    = local.tags
  rg                      = local.aksrg
  tenant_id               = data.azuread_client_config.current.tenant_id
  current_user_id         = data.azuread_client_config.current.object_id
  additional_users        = []
  secret_permissions      = ["Get", "List", "Purge", "Recover", "Set", "Delete"]
  key_permissions         = []
  certificate_permissions = []
  # key_permissions         = ["Create", "Get", "List", "Purge", "Recover", "Delete"]
  # certificate_permissions = ["Create", "Get", "List", "Purge", "Recover", "Update", "Delete"]
  ip_rules                = [ "${chomp(data.http.myip.response_body)}", "72.178.126.108", "167.220.148.0/22", "131.107.147.0/24", "131.107.159.0/24", "131.107.160.0/24", "131.107.174.0/24", "167.220.24.0/24", "167.220.26.0/24", "167.220.238.0/27", "167.220.238.128/27", "167.220.238.192/27", "167.220.238.64/27", "167.220.232.0/23", "167.220.255.0/25", "167.220.242.0/27", "167.220.242.128/27", "167.220.242.192/27", "167.220.242.64/27", "94.245.87.0/24", "167.220.196.0/23", "194.69.104.0/25", "191.234.97.0/26", "167.220.0.0/23", "167.220.2.0/24", "167.220.226.0/23", "131.107.132.16/28", "131.107.132.32/28", "157.58.212.64/26", "157.58.212.128/26", "157.58.213.64/26", "157.58.213.192/26", "157.58.214.128/26", "157.58.214.192/26", "167.220.70.64/26", "167.220.76.192/26", "167.220.77.64/26", "167.220.80.192/26", "167.220.81.128/26", "167.220.81.192/26", "131.107.1.128/25", "131.107.8.0/25", "167.220.204.128/26", "167.220.204.192/26", "167.220.205.0/26", "167.220.205.64/26", "20.99.254.208/29", "20.99.255.72/29", "20.99.254.224/29", "20.99.255.136/29", "20.120.200.56/29"]
  subnet_ids              = var.create_dr == false ? [ 
      module.vnet_aks.subnets["aks-subnet-vnodes"].id
    ] : [ 
      module.vnet_aks.subnets["aks-subnet-vnodes"].id, 
      module.drvnet_aks.subnets["aks-subnet-vnodes"].id 
    ]

  secret_list             = {
      "ssh-public-key-openssh"    = "${module.ssh_key.public_key_openssh}" , 
      "ssh-public-key-pem"        = "${module.ssh_key.public_key_pem}",
      "ssh-private-key-openssh"   = "${module.ssh_key.private_key_openssh}",
      "ssh-private-key-pem"       = "${module.ssh_key.private_key_pem}",
  }
}
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

data "azurerm_container_registry" "acr_aks" {
  name                = local.aksacrname
  resource_group_name = local.aksrg
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

###### AKS Permissions
###### give aks permission to network so that it can assign ip to the load balancer while installing ingress controller
###### also permission to ACR so that AKS can pull down the images.
############################################################################################
module "role_assignments" {
  depends_on    = [
    data.azurerm_kubernetes_cluster.aks_cluster, 
    data.azurerm_kubernetes_cluster.draks_cluster
  ]
  source        = "../_modules/role_assignments"
  
  role_assignments =  var.create_dr == true ? { 
        "assignment1" = {
            scope = data.azurerm_virtual_network.aks_vnet[0].id
            role  = "Network Contributor"
            principal_id = data.azurerm_kubernetes_cluster.aks_cluster[0].identity[0].principal_id
        }
        "assignment2" = {
            scope = data.azurerm_virtual_network.draks_vnet[0].id
            role  = "Network Contributor"
            principal_id = var.create_dr == true ? data.azurerm_kubernetes_cluster.draks_cluster[0].identity[0].principal_id : null
        }
        "assignment3" = {
            scope = data.azurerm_container_registry.acr_aks.id
            role  = "AcrPull"
            principal_id = data.azurerm_kubernetes_cluster.aks_cluster[0].kubelet_identity[0].object_id
        }
        "assignment4" = {
            scope = data.azurerm_container_registry.acr_aks.id
            role  = "AcrPull"
            principal_id = var.create_dr == true ? data.azurerm_kubernetes_cluster.draks_cluster[0].kubelet_identity[0].object_id : null
        }
      } : { 
        "assignment1" = {
            scope = data.azurerm_virtual_network.aks_vnet[0].id
            role  = "Network Contributor"
            principal_id = data.azurerm_kubernetes_cluster.aks_cluster[0].identity[0].principal_id
        }
        "assignment2" = {
            scope = data.azurerm_container_registry.acr_aks.id
            role  = "AcrPull"
            principal_id = data.azurerm_kubernetes_cluster.aks_cluster[0].kubelet_identity[0].object_id
        }
      }
}

###### Install Ingress Controller into the AKS cluster
###### It also deploys a test application to verify ingress controller installation status
###### ingress controller installation installs an internal load balancer
###### command to test ingress: 
###### kubectl logs ingress-test-client -n ingress --kubeconfig ${local.kubeconfig}
###### kubectl logs ingress-test-client -n ingress --kubeconfig ${local.drkubeconfig}
############################################################################################
module "ingress_aks" {
  source = "../_modules/helm_ingress"
  enable = true

  ingress_controller_lb_ip                = local.ingress_controller_lb_ip
  ingress_controller_image_repository_url = local.ingress_controller_acr_url
  ingress_controller_image_image          = local.ingress_controller_image
  ingress_controller_image_tag            = local.ingress_controller_image_tag
  ingress_controller_patch_image_image    = local.ingress_controller_patch_image
  ingress_controller_patch_image_tag      = local.ingress_controller_patch_image_tag
  ingress_controller_default_image_image  = local.ingress_controller_default_image
  ingress_controller_default_image_tag    = local.ingress_controller_default_image_tag

  ingress_tls_secret_name                         = "ingress-tls-secret"
  ingress_tls_secret_namespace                    = "ingress"
  ingress_tls_secret_keyvault_name                = local.akskv #"aksoc-dev-eastus-kv1"
  ingress_tls_certificate_name                    = var.ingress_tls_name
  ingress_tls_secret_provider_managed_identity    = data.azurerm_user_assigned_identity.aks_cluster[0].client_id
  ingress_tenant_id                               = data.azuread_client_config.current.tenant_id

  depends_on = [
    data.azurerm_kubernetes_cluster.aks_cluster,
    module. role_assignments
  ]
}

module "dringress_aks" {
  source = "../_modules/helm_ingress"
  enable = var.create_dr
  providers = {
    helm = helm.dr
    kubernetes = kubernetes.dr
  }

  ingress_controller_lb_ip                = local.ingress_controller_lb_ip
  ingress_controller_image_repository_url = local.ingress_controller_acr_url
  ingress_controller_image_image          = local.ingress_controller_image
  ingress_controller_image_tag            = local.ingress_controller_image_tag
  ingress_controller_patch_image_image    = local.ingress_controller_patch_image
  ingress_controller_patch_image_tag      = local.ingress_controller_patch_image_tag
  ingress_controller_default_image_image  = local.ingress_controller_default_image
  ingress_controller_default_image_tag    = local.ingress_controller_default_image_tag

  ingress_tls_secret_name                      = "ingress-tls-secret"
  ingress_tls_secret_namespace                 = "ingress"
  ingress_tls_secret_keyvault_name             = local.akskv #"aksoc-dev-eastus-kv1kv"
  ingress_tls_certificate_name                 = var.ingress_tls_name
  ingress_tls_secret_provider_managed_identity = var.create_dr == true ? data.azurerm_user_assigned_identity.draks_cluster[0].client_id : null
  ingress_tenant_id                            = data.azuread_client_config.current.tenant_id

  depends_on = [
    data.azurerm_kubernetes_cluster.draks_cluster,
    module.role_assignments
  ]
}

# ###### Create Private Link Service pointing to Ingress Load Balancer
# ###### Private Link Service is used by AFD to connect to the Load Balacer / AKS Cluster
# ############################################################################################
# resource "time_sleep" "wait_5_mins" {
#   depends_on = [module.ingress_aks, module.dringress_aks]
#   create_duration = "5m"
# }

# module "privatel_link_service" {
#   depends_on = [module.ingress_aks, time_sleep.wait_5_mins]
#   enable     = true 

#   source = "../_modules/pvt_link_service"

#   name     = local.aksclustername
#   location = local.location
#   tags     = local.tags
#   rg       = local.aksrg

#   #load_balancer_frontend_ip_configuration_ids = []
#   load_balancer_name             = "kubernetes-internal"
#   auto_approval_subscription_ids = [var.subscription_id]
#   visibility_subscription_ids    = [var.subscription_id]

#   vnet_subnet_id                 = data.azurerm_subnet.aks_subnet_default.id
#   nat_ip_configuration_primary   = local.pvt_link_service_nat_ip_configuration_primary
#   nat_ip_configuration_secondary = local.pvt_link_service_nat_ip_configuration_secondary
# }

# module "drprivatel_link_service" {
#   depends_on = [module.dringress_aks, time_sleep.wait_5_mins]
#   enable     = var.create_dr 

#   source = "../_modules/pvt_link_service"

#   name     = local.draksclustername
#   location = local.drlocation
#   tags     = local.tags
#   rg       = local.draksrg

#   #load_balancer_frontend_ip_configuration_ids = []
#   load_balancer_name             = "kubernetes-internal"
#   auto_approval_subscription_ids = [var.subscription_id]
#   visibility_subscription_ids    = [var.subscription_id]

#   vnet_subnet_id                 = data.azurerm_subnet.draks_subnet_default.id
#   nat_ip_configuration_primary   = local.pvt_link_service_nat_ip_configuration_primary
#   nat_ip_configuration_secondary = local.pvt_link_service_nat_ip_configuration_secondary
# }

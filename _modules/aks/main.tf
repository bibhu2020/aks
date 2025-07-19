resource "azurerm_kubernetes_cluster" "aks" {
  count               = var.enable == true ? 1 : 0
  name                = var.name
  location            = var.location
  resource_group_name = var.rg
  dns_prefix          = "${var.name}-k8s"
  #kubernetes_version  = var.kubernetes_version

  sku_tier            = "Premium"
  support_plan        = "AKSLongTermSupport"

  node_resource_group = "${var.rg}-mc"

  local_account_disabled = true 

  # hosts AKS using system managed identity 
  identity {
    type              = "SystemAssigned"
  }

  azure_active_directory_role_based_access_control {
    managed                = true
    admin_group_object_ids = var.aks_admin_group_object_ids
    azure_rbac_enabled     = true
  }

  linux_profile {
    admin_username    = var.admin_user

    ssh_key {
      key_data        = var.ssh_public_key
    }
  }

  default_node_pool {
    name                = "systempool"
    node_count          = 2
    vm_size             = "Standard_D8s_v3" #"Standard_D2_v2"
    type                = "VirtualMachineScaleSets"
    zones               = var.location == "westus" ? [] : ["1", "2"]
    enable_auto_scaling = true
    min_count           = 2
    max_count           = 8
    node_labels         = {"nodepool-type" : "system", "node-os" : "linux", "app" : "system"}

    # Required for advanced networking
    vnet_subnet_id      = var.subnet_default_id
  }

  network_profile {
    network_plugin        = var.network_plugin
    network_policy        = var.network_policy
    load_balancer_sku     = "standard"
    #docker_bridge_cidr   = var.docker_bridge_cidr
    service_cidr          = var.service_cidr
    dns_service_ip        = var.dns_service_ip
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  # Enable CSI plugins for external azure storages
  storage_profile {
    #blob_driver_enabled          = true
    #disk_driver_enabled          = true
    file_driver_enabled           = true
    #snapshot_controller_enabled  = true
  }

  # Enable CSI plugins for Key Vault
  # this creates a managed identity with name "azurekeyvaultsecretsprovider-${ak_cluster_name} in the -mc resource group"
  # this id must be given access to the KV that AKS needs to access.
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  tags                       = var.tags
}

# resource "random_string" "random" {
#   length           = 8
#   special          = false
#   lower            = true
#   upper            = false
# }

# resource "azurerm_kubernetes_cluster_node_pool" "workernode" {
#   depends_on = [ azurerm_kubernetes_cluster.aks ]
#   count = var.enable == true ? 1 : 0
#   name                  = format("user%s", random_string.random.result)
#   mode                  = "User"
#   kubernetes_cluster_id = azurerm_kubernetes_cluster.aks[0].id
#   vm_size               = "Standard_DS2_v2"
#   enable_auto_scaling = true
#   min_count           = 4
#   max_count           = 30
#   node_labels         = {
#       "nodepool-type" : "user", 
#       "node-os" : "linux", 
#       "app" : "onecloud-apps"
#     }
#   priority            = "Regular"

#   # Required for advanced networking
#   vnet_subnet_id = var.subnet_default_id

#   tags = var.tags
# }

# Assign AAD groups as the aks cluster admin
# resource "azurerm_role_assignment" "admin" {
#   for_each             = toset(var.aks_admin_group_object_ids)
#   scope                = azurerm_kubernetes_cluster.aks[0].id
#   role_definition_name = "Azure Kubernetes Service Cluster User Role"
#   principal_id         = each.value
# }


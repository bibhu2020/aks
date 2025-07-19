resource "random_string" "random" {
  length           = 8
  special          = false
  lower            = true
  upper            = false
}

resource "azurerm_kubernetes_cluster_node_pool" "workernode" {
  for_each                = {for node in var.workernode_list : node.name => node}
  name                    = format("user%s", random_string.random.result)
  mode                    = "User"
  kubernetes_cluster_id   = each.value.kubernetes_cluster_id
  vm_size                 = "Standard_D8s_v3" #"Standard_DS2_v2"
  #type                   = "VirtualMachineScaleSets"
  enable_auto_scaling     = true
  min_count               = 4
  max_count               = 30
  node_labels             = each.value.node_labels
  priority                = "Regular"

  # Required for advanced networking
  vnet_subnet_id          = each.value.subnet_id

  tags                    = var.tags
}

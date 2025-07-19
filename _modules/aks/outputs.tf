output "aks" {
  value = length(azurerm_kubernetes_cluster.aks) > 0 ? azurerm_kubernetes_cluster.aks[0] : null
}

output "id" {
  value = length(azurerm_kubernetes_cluster.aks) > 0 ? azurerm_kubernetes_cluster.aks[0].id : null
}

output "client_key" {
  value = length(azurerm_kubernetes_cluster.aks) > 0 ? azurerm_kubernetes_cluster.aks[0].kube_config.0.client_key : null
}

output "client_certificate" {
  value = length(azurerm_kubernetes_cluster.aks) > 0 ? azurerm_kubernetes_cluster.aks[0].kube_config.0.client_certificate : null
}

output "cluster_ca_certificate" {
  value = length(azurerm_kubernetes_cluster.aks) > 0 ? azurerm_kubernetes_cluster.aks[0].kube_config.0.cluster_ca_certificate : null
}

output "kube_config_raw" {
  value = length(azurerm_kubernetes_cluster.aks) > 0 ? azurerm_kubernetes_cluster.aks[0].kube_config_raw : null
  #sensitive = false
}

output "host" {
  value = length(azurerm_kubernetes_cluster.aks) > 0 ? azurerm_kubernetes_cluster.aks[0].kube_config.0.host : null
  #sensitive = false
}

output "kubelet_identity_id" {
  value = length(azurerm_kubernetes_cluster.aks) > 0 ? azurerm_kubernetes_cluster.aks[0].kubelet_identity[0].object_id : null
  #sensitive = false
}

output "principal_id" {
  value = length(azurerm_kubernetes_cluster.aks) > 0 ? azurerm_kubernetes_cluster.aks[0].identity[0].principal_id : null
  #sensitive = false
}





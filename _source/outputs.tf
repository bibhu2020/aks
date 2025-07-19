# output "my_public_ip" {
#   value = "${chomp(data.http.myip.response_body)}"
# }

# output "rg_aks" {
#   value = length(module.rg_aks) > 0 ? "Resource Group is created successfully." : null
# }

# output "subnets_pe_kv_id" {
#   value = module.vnet_aks.subnets["aks-subnet-pe-kv"].id
# }

# output "subnets_pe_kv" {
#   value = module.vnet_aks.subnets["aks-subnet-pe-kv"]
# }


# output "vnet_aks" {
#   value = length(module.vnet_aks) > 0 ? "vNet is created successfully." : null
# }

# output "subnets" {
#   value = module.vnet_aks.subnets
# }

# output "add_aks" {
#   value = module.add_aks
# }

# output "add_aks_id" {
#   value = [module.add_aks.azuread_group_id]
# }

# output "acr_aks" {
#   value = module.acr_aks
#   sensitive = true
# }

# output "ssh_key" {
#   value = module.ssh_key
#   sensitive = true
# }

# output "ssh_public_key" {
#   value = module.ssh_key.tls_public_key
#   sensitive = true
# }

# output "ws_aks" {
#   value = module.ws_aks
#   sensitive = true
# }

# output "ws_aks_id" {
#   value = module.ws_aks.ws_aks_id
# }

# output "app_resource_group" {
#   value = local.aksappsrg
# }

# output "app_dr_resource_group" {
#   value = local.draksappsrg
# }

# output "kube_config_raw" {
#   value = module.aks_cluster.kube_config_raw
#   sensitive = true
# }

# output "host" {
#   value = module.aks_cluster.host
#   sensitive = true
# }

output "configure" {
  value = <<CONFIGURE

AKS Cluster is sucessfully created. Run the following commands to verify the AKS nodes.

$ export KUBECONFIG=${local.kubeconfig}
$ export KUBECONFIG=${local.drkubeconfig}
$ kubectl get nodes
OR
$ kubectl get nodes --kubeconfig ${local.kubeconfig}
$ kubectl get nodes --kubeconfig ${local.drkubeconfig}

Test the ingress deployment by executing the following commands:
$ kubectl get pods -n ingress
$ kubectl logs ingress-test-client -n ingress
OR
$ kubectl logs ingress-test-client -n ingress --kubeconfig ${local.kubeconfig}
$ kubectl logs ingress-test-client -n ingress --kubeconfig ${local.drkubeconfig}

Application resources shall be created in rg: ${local.aksappsrg}
Application DR resources shall be created in rg: ${local.draksappsrg}

CONFIGURE
}


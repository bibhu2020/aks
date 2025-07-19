# output "subnets" {
#     value = data.azurerm_virtual_network.aks_vnet 
# }

output "clientid" {
  value = data.azurerm_user_assigned_identity.aks_cluster[0].client_id
}

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

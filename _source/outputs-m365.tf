#output "mysql_id" {
#    value = module.app_mysql.id
#}
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
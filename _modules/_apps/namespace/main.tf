resource "kubernetes_namespace" "namespace" {
  count       = var.enable == true ? 1 : 0 
  metadata {
    name = var.namespace
  }
}


resource "helm_release" "serviceaccount" {
  count = var.enable == true ? 1 : 0
  name       = "serviceaccount"
  namespace  = var.namespace
  chart      = format("%s/serviceaccount", path.module)
  version    = "1.0.0"

  set {
    name  = "serviceAccount.name"
    value = "${var.namespace}-sa"
  }

  set {
    name  = "serviceAccount.namespace"
    value = var.namespace
  }
  
  depends_on = [
    kubernetes_namespace.namespace
  ]
}



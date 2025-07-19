resource "helm_release" "kv_mount" {
  count      = var.enable == true ? 1 : 0 
  name       = "${var.kv_name}"
  chart      = format("%s/helm", path.module)
  namespace  = "${var.application_namespace}"
  version    = "${var.application_version}"

  set {
    name  = "application.name"
    value = "${var.application_name}"
  }
  set {
    name  = "application.namespace"
    value = "${var.application_namespace}"
  }
  set {
    name  = "application.version"
    value = "${var.application_version}"
  }

  set {
    name  = "k8secret.name"
    value = "${var.application_name}-tls-secret"
  }
  set {
    name  = "k8secret.providerClassName"
    value = "${var.application_name}-tls-secret"
  }

  set {
    name  = "keyVault.name"
    value = "${var.kv_name}"
  }  
  set {
    name  = "keyVault.kvCsiClientId"
    value = "${var.kv_csi_client_id}"
  }
  set {
    name  = "keyVault.tenantId"
    value = "${var.kv_tenant_id}"
  }
  set {
    name  = "keyVault.tlsCertificateName"
    value = "${var.kv_tls_certificate_name}"
  }
}

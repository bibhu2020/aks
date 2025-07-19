resource "kubernetes_namespace" "ingress" {
  count       = var.enable == true ? 1 : 0 
  metadata {
    name = "ingress"
  }
}

resource "helm_release" "ingress" {
  count = var.enable == true ? 1 : 0
  name       = "ingress"
#  repository = "https://kubernetes.github.io/ingress-nginx" #if you want to deploy from remote repository.
#  chart      = "ingress-nginx"
  chart      = format("%s/ingress-controller-helm-charts/ingress-nginx-4.5.2", path.module)
  version    = "4.5.2"
  namespace  = kubernetes_namespace.ingress[0].metadata.0.name  
  #create_namespace = true 
  set {
    name  = "controller.kind"
    value = "Deployment"  #Possible Values: Deployment, Daemonset, Both
  }
  set {
    name  = "controller.replicaCount"
    value = 3
  }
  set {
    name  = "controller.autoscaling.minReplicas"
    value = 3
  }
  set {
    name  = "controller.autoscaling.minReplicas"
    value = 6
  }
    set {
    name  = "controller.autoscaling.targetMemoryUtilizationPercentage"
    value = 80
  }
  set {
    name  = "controller.autoscaling.targetCPUUtilizationPercentage"
    value = 90
  }
  # passing the secret (namespace/secret) that stores default fallback certificate for all HTTPS request
  set {
    name  = "controller.wildcardTLS.secret"
    value = "${kubernetes_namespace.ingress[0].metadata.0.name}/ingress-tls-secret"
  }
  set {
    name  = "controller.nodeSelector.kubernetes\\.io/os"
    value = "linux"
  }

  set {
    name  = "controller.nodeSelector.app"
    value = "system"
  }

  set {
    name  = "controller.image.registry"
    value = var.ingress_controller_image_repository_url
  }
  set {
    name  = "controller.image.image"
    value = var.ingress_controller_image_image
  }
  set {
    name  = "controller.image.tag"
    value = var.ingress_controller_image_tag
  }
  set {
    name  = "controller.image.digest"
    value = ""
  }

  set {
    name  = "controller.admissionWebhooks.patch.nodeSelector.kubernetes\\.io/os"
    value = "linux"
  }
  set {
    name  = "controller.admissionWebhooks.patch.nodeSelector.app"
    value = "system"
  }

  set {
    name  = "controller.service.loadBalancerIP"
    value = var.ingress_controller_lb_ip
  }
  set { #Creates internal load balancer and exposes the ingress service through it.
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-internal"
    value = true
  }
  # turn on this flag if you want the private link service to be created automatically.
  # set { #Creates private link service 
  #  name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-pls-create"
  #  value = true
  #}
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-health-probe-request-path"
    value = "/healthz"
  }

  set {
    name  = "controller.admissionWebhooks.patch.image.registry"
    value = var.ingress_controller_image_repository_url
  }
  set {
    name  = "controller.admissionWebhooks.patch.image.image"
    value = var.ingress_controller_patch_image_image
  }
  set {
    name  = "controller.admissionWebhooks.patch.image.tag"
    value = var.ingress_controller_patch_image_tag
  }
  set {
    name  = "controller.admissionWebhooks.patch.image.digest"
    value = ""
  }

  set {
    name  = "defaultBackend.nodeSelector.kubernetes\\.io/os"
    value = "linux"
  }

  set {
    name  = "defaultBackend.nodeSelector.app"
    value = "system"
  }

  set {
    name  = "defaultBackend.image.registry"
    value = var.ingress_controller_image_repository_url
  }
  set {
    name  = "defaultBackend.image.image"
    value = var.ingress_controller_default_image_image
  }
  set {
    name  = "defaultBackend.image.tag"
    value = var.ingress_controller_default_image_tag
  }

  set {
    name  = "controller.resources.requests.memory"
    value = "500Mi"
  }
  set {
    name  = "controller.resources.requests.cpu"
    value = "500m"
  }
  set {
    name  = "controller.resources.limits.memory"
    value = "1Gi"
  }
  set {
    name  = "controller.resources.limits.cpu"
    value = "1"
  }

  ## Replaces the Ingress default cert with a valid tls so that AFD can receive a valid certificate.
  set {
    name  = "controller.defaultTLS.secret"
    value = "${var.ingress_tls_secret_namespace}/${var.ingress_tls_secret_name}"
  }

  depends_on = [ kubernetes_namespace.ingress ]

}


resource "helm_release" "ingresstlsloader" {
  count = var.enable == true ? 1 : 0
  name       = "ingresstlsloader"
  namespace  = kubernetes_namespace.ingress[0].metadata.0.name
  chart      = format("%s/ingresstls", path.module)
  version    = "3.0.1"

  set {
    name  = "ingress.tlsSecretName"
    value = var.ingress_tls_secret_name
  }
  set {
    name  = "ingress.tlsSecretNamespace"
    value = var.ingress_tls_secret_namespace
  }
  set {
    name  = "ingress.secretKeyVaultName"
    value = var.ingress_tls_secret_keyvault_name
  }
  set {
    name  = "ingress.certificateInKeyVault"
    value = var.ingress_tls_certificate_name
  }
  set {
    name  = "ingress.secretProviderIdentity"
    value = var.ingress_tls_secret_provider_managed_identity
  }
  set {
    name  = "ingress.tenantId"
    value = var.ingress_tenant_id
  }
  set {
    name  = "ingress.secretLoaderImageRepository"
    value = var.ingress_controller_image_repository_url
  }


  depends_on = [
    helm_release.ingress
  ]
}
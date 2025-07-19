resource "kubernetes_namespace" "ns" {
  count       = var.enable == true ? 1 : 0
  metadata {
    name = var.application_namespace
  }
}

resource "helm_release" "kv2secret" {
  count      = var.enable == true ? 1 : 0 
  depends_on = [ kubernetes_namespace.ns ]
  name       = "${var.application_name}-azure-file-${var.storage_account_name}"
  chart      = format("%s/azurestorage", path.module)
  namespace  = "${var.application_namespace}"
  version    = "${var.application_version}"

  # values = [
  #   file("${path.module}/storagepv/values.yaml")
  # ]

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
    name  = "aks.kvCsiClientId"
    value = "${var.aks_kv_csi_client_id}"
  }
  set {
    name  = "aks.tenantId"
    value = "${var.aks_tenant_id}"
  }


  set {
    name  = "storageAccount.name"
    value = "${var.storage_account_name}"
  }
  set {
    name  = "storageAccount.resourceGroupName"
    value = "${var.storage_account_resource_group_name}"
  }
  set {
    name  = "storageAccount.keyVaultName"
    value = "${var.storage_account_key_vault_name}"
  }
  set {
    name  = "storageAccount.keyVaultSecretNameForStorageAccountName"
    value = "${var.storage_account_name_in_key_vault}"
  }
  set {
    name  = "storageAccount.keyVaultSecretNameForStorageAccountAccessKey"
    value = "${var.storage_account_access_key_in_key_vault}"
  }
  set {
    name  = "storageAccount.fileShareName"
    value = "${var.storage_account_fileshare_folder_name}"
  }

  set {
    name  = "secret.name"
    value = "${var.storage_account_key_vault_name}-secret"
  }
  set {
    name  = "secret.providerClassName"
    value = "${var.storage_account_key_vault_name}-spc"
  }
  set {
    name  = "persistentVolume.name"
    value = "${var.storage_account_name}-${var.storage_account_fileshare_folder_name}-pv"
  }
  set {
    name  = "persistentVolume.volumeHandler"
    value = "${var.storage_account_name}-${var.storage_account_fileshare_folder_name}-handle"
  }
  set {
    name  = "persistentVolumeClaim.name"
    value = "${var.storage_account_name}-${var.storage_account_fileshare_folder_name}-pvc"
  }



}

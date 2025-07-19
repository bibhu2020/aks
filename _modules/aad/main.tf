data "azuread_group" "res" {
  display_name     = var.aad_group_name #"cloudblogs-aks-cluster-admin-${var.aadenv}"
  security_enabled = true
}

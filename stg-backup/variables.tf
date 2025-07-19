variable "app" {
  type = string
}
variable "env" {
  type = string
}
# variable "aadenv" {
#   type = string
# } #this tells you which environment AAD group to use for access control
variable "homepath" {
  type = string
}

variable "subscription_id" {
  description = "Azure subscripttion id."
  type        = string
}
variable "tenant_id" {
  description = "Azure tenant id."
  type        = string
}

variable "location" {
  description = "Region in where AKS resources will be created."
  type        = string
}

variable "drlocation" {
  description = "Secondary Region in where AKS DR resources will be created."
  type        = string
}

variable "windows_vm_pwd" {
  description = "Windows VM / SQL Server Password:"
  type = string
}

variable "create_dr" {
  description = "create a disaster recovery environment."
  type = bool
}

variable "KVSUFFIX" {
  description = "this is an environment variable that is used to create unique Key Vault name on every run. This is must since KV update is not permitted."
  type = string
}

variable "aks_admin_aad_group" {
  description = "this is the aad group for AKS cluster admin."
  type = string
}

variable "ingress_tls_name" {
  description = "tls (name of tls stored in base KV) that is used for internal encrypted communication."
  type = string
}

variable "in_cluster_db" {
  description = "do you want host the db within the cluster or outside?"
  type = bool
}


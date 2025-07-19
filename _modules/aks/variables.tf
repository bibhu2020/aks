variable "name" {}
variable "location" {}
variable "tags" {}
variable "rg" {}
variable "admin_user" {}
variable "ssh_public_key" { sensitive = true }
variable "subnet_default_id" {}
variable "kubernetes_version" { default = "1.28.3" }

variable "network_plugin" {}
variable "network_policy" {}
variable "service_cidr" {}
variable "dns_service_ip" {}

variable "aks_admin_group_object_ids" { type = list(any) }
variable "log_analytics_workspace_id" {}
variable "enable" { 
    type = bool
    default = true
}
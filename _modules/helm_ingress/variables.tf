variable "ingress_controller_image_image" {
  type = string
}
variable "ingress_controller_image_tag" {
  type = string
}
variable "ingress_controller_image_repository_url" {
  type = string
}
variable "ingress_controller_lb_ip" {
  type = string
}
variable "ingress_controller_patch_image_image" {
  type = string
}
variable "ingress_controller_patch_image_tag" {
  type = string
}
variable "ingress_controller_default_image_image" {
  type = string
}
variable "ingress_controller_default_image_tag" {
  type = string
}
variable "enable" { 
    type = bool
    default = true
}
variable "ingress_tls_secret_name" { type = string }
variable "ingress_tls_secret_namespace" { type = string }
variable "ingress_tls_secret_keyvault_name" { type = string }
variable "ingress_tls_certificate_name" { type = string }
variable "ingress_tls_secret_provider_managed_identity" { type = string }
variable "ingress_tenant_id" { type = string }

variable application_name {}
variable application_namespace {}
variable application_version { default = "1.0.0" }

variable kv_name {}
variable kv_csi_client_id {}
variable kv_tls_certificate_name {}
variable kv_tenant_id {}

variable enable {
    type = bool
    default = true 
}
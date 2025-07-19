variable application_name {}
variable application_namespace {}
variable application_version { default = "1.0.0" }
variable aks_kv_csi_client_id {}
variable aks_tenant_id {}

variable storage_account_name {}
variable storage_account_resource_group_name {}
variable storage_account_key_vault_name {} # name of the key vault that stores the storage access key
variable storage_account_name_in_key_vault {}
variable storage_account_access_key_in_key_vault {}
variable storage_account_fileshare_folder_name {}
variable "enable" { 
    type = bool
    default = true
}
variable "install_test_pods" { 
    type=bool 
    default = false  
}
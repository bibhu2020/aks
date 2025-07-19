variable "key_vault_id" {}
variable "secret_list" { 
    type = map(string) 
    default = {"secret_key1" = "secret_value1" , "secret_key2" = "secret_value2"}
}

variable "role_assignments" { 
    type = map(object({
        scope = string
        role = string
        principal_id = string
    })) 
    default = {
        key1 = {
            scope = "scope1"
            role  = "role1"
            principal_id = "id1"
        }
        key2 = {
            scope = "scope2"
            role  = "role2"
            principal_id = "id2"
        }
    }
}

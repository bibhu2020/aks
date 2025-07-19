variable "tags" {}

variable "dns_zones" {
    type = list(object({
        index = number
        name = string
        rg = string
        location = string
        link_to_vnet = string
    })) 
    default = [
        {
            index = 1
            name = ""
            rg = ""
            location = ""
            link_to_vnet = ""
        }, {
            index = 2
            name = ""
            rg = ""
            location = ""
            link_to_vnet = ""
        }
    ]
}

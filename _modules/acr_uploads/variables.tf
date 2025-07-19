variable images {
    type = list(object({
        registry = string
        name = string
        tag = string
        acr_registry = string
    })) 
    default = [
        {
            registry = ""
            name = ""
            tag = "" 
            acr_registry = ""
        }, {
            registry = ""
            name = ""
            tag = "" 
            acr_registry = ""
        }
    ]
}

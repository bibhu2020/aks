variable tags { default = "" }
variable workernode_list  {
    type = list(object({
        name                  = string
        kubernetes_cluster_id = string
        subnet_id = string
        vm_size = string
        max_count = number
        min_count = number
        node_labels = map(string)
    })) 
    default = [
        {
            name                    = "value"
            kubernetes_cluster_id   = ""
            subnet_id               = ""
            vm_size                 = "Standard_DS2_v2"
            max_count               = 20
            min_count               = 2
            node_labels             =   {
                                        "nodepool-type" : "user", 
                                        "node-os" : "linux", 
                                        "app" : "onecloud-apps"
                                    }
        }, {
            name                    = "value"
            kubernetes_cluster_id   = ""
            subnet_id               = ""
            vm_size                 = "Standard_DS2_v2"
            max_count               = 20
            min_count               = 2
            node_labels             =   {
                                        "nodepool-type" : "user", 
                                        "node-os" : "linux", 
                                        "app" : "onecloud-apps"
                                    }
        }
    ]
}
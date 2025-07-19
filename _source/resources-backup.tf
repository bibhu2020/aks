###### Get Access to Previously Created Resources
############################################################################################
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

data "azurerm_kubernetes_cluster" "aks_cluster" {
    count                       = 1
    name                        = local.aksclustername
    resource_group_name         = local.aksrg
}

data "azurerm_kubernetes_cluster" "draks_cluster" {
    count                       = var.create_dr == true ? 1 : 0
    name                        = local.draksclustername
    resource_group_name         = local.draksrg
}

###### Create the apps resource group that holds all common resources
############################################################################################
module "rg_aksapps" {
  source = "../_modules/rg"

  name     = "backups-rg"
  location = "centralus"
  tags     = local.tags
}

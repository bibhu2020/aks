# Configure the Azure provider
terraform {
  backend "azurerm" {
  }

  required_providers {
    azurerm = {
      source  = "registry.terraform.io/hashicorp/azurerm"
      version = "3.87.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.47.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }
    # mssql = {
    #   source = "betr-io/mssql"
    #   version = "0.2.5"
    # }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "= 2.24.0"
      configuration_aliases = [ kubernetes.dr ]
    }
    helm = {
      source  = "hashicorp/helm"
      version = "= 2.12.1"
      configuration_aliases = [ helm.dr ]
    }
  }

  required_version = ">= 1.1.0"
}

provider "tls" {
  # Configuration options
}

provider "azurerm" {
  use_oidc        = true
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  # client_id       = var.AzureSPNAppId
  # client_secret   = var.AzureSPNPwd
  # tenant_id       = var.AzureTenantId
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy = true 
      recover_soft_deleted_key_vaults = true 
    }
  }
}
## Environment variables
#ARM_USE_MSI=true
#ARM_SUBSCRIPTION_ID=xxx-yyy-zzz
#ARM_TENANT_ID=xxx-yyy-zzz


provider "azuread" {
  # Configuration options
}

## This configuration works with AKS Local Account enabled. It uses 
# provider "kubernetes" {
#   host                   = data.azurerm_kubernetes_cluster.aks_cluster[0].kube_admin_config.0.host
#   client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks_cluster[0].kube_admin_config.0.client_certificate)
#   client_key             = base64decode(data.azurerm_kubernetes_cluster.aks_cluster[0].kube_admin_config.0.client_key)
#   cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks_cluster[0].kube_admin_config.0.cluster_ca_certificate)
#   # load_config_file       = false 
#   # config_path    = local.kubeconfig
#   # config_context = local.aksclustername
# }
# https://developer.hashicorp.com/terraform/language/providers/configuration

# provider "kubernetes" {
#   alias                  = "dr"
#   host                   = var.create_dr == true ? data.azurerm_kubernetes_cluster.draks_cluster[0].kube_admin_config.0.host : ""
#   client_certificate     = base64decode(var.create_dr == true ? data.azurerm_kubernetes_cluster.draks_cluster[0].kube_admin_config.0.client_certificate : "")
#   client_key             = base64decode(var.create_dr == true ? data.azurerm_kubernetes_cluster.draks_cluster[0].kube_admin_config.0.client_key : "")
#   cluster_ca_certificate = base64decode(var.create_dr == true ? data.azurerm_kubernetes_cluster.draks_cluster[0].kube_admin_config.0.cluster_ca_certificate : "")
#   # config_path    = local.drkubeconfig
#   # config_context = local.draksclustername
# }
# provider "helm" {
#   debug = true
#   kubernetes {
#     host                   = data.azurerm_kubernetes_cluster.aks_cluster[0].kube_admin_config.0.host
#     client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks_cluster[0].kube_admin_config.0.client_certificate)
#     client_key             = base64decode(data.azurerm_kubernetes_cluster.aks_cluster[0].kube_admin_config.0.client_key)
#     cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks_cluster[0].kube_admin_config.0.cluster_ca_certificate)
#     # config_path    = local.kubeconfig
#     # config_context = local.aksclustername
#   }
# }
# provider "helm" {
#   alias                     = "dr"
#   debug = true
#   kubernetes {
#     host                   = var.create_dr == true ? data.azurerm_kubernetes_cluster.draks_cluster[0].kube_admin_config.0.host : ""
#     client_certificate     = base64decode(var.create_dr == true ? data.azurerm_kubernetes_cluster.draks_cluster[0].kube_admin_config.0.client_certificate : "")
#     client_key             = base64decode(var.create_dr == true ? data.azurerm_kubernetes_cluster.draks_cluster[0].kube_admin_config.0.client_key : "")
#     cluster_ca_certificate = base64decode(var.create_dr == true ? data.azurerm_kubernetes_cluster.draks_cluster[0].kube_admin_config.0.cluster_ca_certificate : "")
#     # config_path    = local.drkubeconfig
#     # config_context = local.draksclustername
#   }
# }


provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.aks_cluster[0].kube_config.0.host
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks_cluster[0].kube_config.0.cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args = [
      "get-token",
      "--login",
      "azurecli",
      "--server-id",
      "6dae42f8-4368-4678-94ff-3960e28e3630", # Azure Kubernetes Service AAD Server. It's a hard-coded value. Azure Kubernetes Service (AKS) AAD Server is a feature that enables Azure Active Directory (AAD) integration with AKS clusters. 
      "|",
      "jq",
      ".status.token"
    ]
  }
}


provider "kubernetes" {
  alias                  = "dr"
  host                   = var.create_dr == true ? data.azurerm_kubernetes_cluster.draks_cluster[0].kube_config.0.host : ""
  cluster_ca_certificate = base64decode(var.create_dr == true ? data.azurerm_kubernetes_cluster.draks_cluster[0].kube_config.0.cluster_ca_certificate: "")

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args = [
      "get-token",
      "--login",
      "azurecli",
      "--server-id",
      "6dae42f8-4368-4678-94ff-3960e28e3630", # Azure Kubernetes Service AAD Server. It's a hard-coded value. Azure Kubernetes Service (AKS) AAD Server is a feature that enables Azure Active Directory (AAD) integration with AKS clusters. 
      "|",
      "jq",
      ".status.token"
    ]
  }
}
provider "helm" {
  debug = true
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.aks_cluster[0].kube_config.0.host
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks_cluster[0].kube_config.0.cluster_ca_certificate)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "kubelogin"
      args = [
        "get-token",
        "--login",
        "azurecli",
        "--server-id",
        "6dae42f8-4368-4678-94ff-3960e28e3630", # Azure Kubernetes Service AAD Server. It's a hard-coded value. Azure Kubernetes Service (AKS) AAD Server is a feature that enables Azure Active Directory (AAD) integration with AKS clusters. 
        "|",
        "jq",
        ".status.token"
      ]
    }
  }
}
provider "helm" {
  alias                     = "dr"
  debug = true
  kubernetes {
    host                   = var.create_dr == true ? data.azurerm_kubernetes_cluster.draks_cluster[0].kube_config.0.host : ""
    cluster_ca_certificate = base64decode(var.create_dr == true ? data.azurerm_kubernetes_cluster.draks_cluster[0].kube_config.0.cluster_ca_certificate: "")

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "kubelogin"
      args = [
        "get-token",
        "--login",
        "azurecli",
        "--server-id",
        "6dae42f8-4368-4678-94ff-3960e28e3630", # Azure Kubernetes Service AAD Server. It's a hard-coded value. Azure Kubernetes Service (AKS) AAD Server is a feature that enables Azure Active Directory (AAD) integration with AKS clusters. 
        "|",
        "jq",
        ".status.token"
      ]
    }
  }
}

# provider "kubectl" {
#   host                   = data.azurerm_kubernetes_cluster.aks_cluster[0].kube_admin_config.0.host
#   client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks_cluster[0].kube_admin_config.0.client_certificate)
#   client_key             = base64decode(data.azurerm_kubernetes_cluster.aks_cluster[0].kube_admin_config.0.client_key)
#   cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks_cluster[0].kube_admin_config.0.cluster_ca_certificate)
#   load_config_file       = false
# }
# provider "kubectl" {
#   alias                  = "dr"
#   host                   = data.azurerm_kubernetes_cluster.draks_cluster[0].kube_admin_config.0.host
#   client_certificate     = base64decode(data.azurerm_kubernetes_cluster.draks_cluster[0].kube_admin_config.0.client_certificate)
#   client_key             = base64decode(data.azurerm_kubernetes_cluster.draks_cluster[0].kube_admin_config.0.client_key)
#   cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.draks_cluster[0].kube_admin_config.0.cluster_ca_certificate)
#   load_config_file       = false
# }

locals {
  tags                              = { Environment = "${var.env}", ow-env = "${var.env}" , Project = "${var.app}-${var.env}", ow-project = "${var.app}-${var.env}", Status = "InUse", skip-cloudgov-Kubernetes_AADAuth = "1"}
  kubeconfig                        = format("%s/.kube/%sconfig", var.homepath, var.env)
  drkubeconfig                      = format("%s/.kube/%sdrconfig", var.homepath, var.env)

  location                          = var.location
  prefix                            = format("%s-%s-%s", var.app, var.env, var.location)
  aksrg                             = format("%s-rg", local.prefix)
  aksappsrg                         = format("%s-base-rg", local.prefix)
  aksclustername                    = format("%s", local.prefix)
  aksvnet                           = format("%s-vnet", local.prefix)
  aksvnet_address_cidr              = "10.0.0.0/8"
  akssubnets                          = {
                                          aks-subnet-default = {
                                            name: "aks-subnet-default"
                                            cidr: ["10.240.0.0/16"]
                                            service_endpoints: ["Microsoft.AzureActiveDirectory","Microsoft.Web", "Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.ContainerRegistry", "Microsoft.Sql"]
                                            private_link_service_network_policies_enabled: false 
                                          },
                                          aks-subnet-vnodes = {
                                            name: "aks-subnet-vnodes"
                                            cidr: ["10.241.0.0/16"]
                                            service_endpoints: ["Microsoft.AzureActiveDirectory","Microsoft.Web", "Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.ContainerRegistry", "Microsoft.Sql"]
                                            private_link_service_network_policies_enabled: false 
                                          },
                                          # aks-subnet-pe-storage = {
                                          #   name: "aks-subnet-pe-storage"
                                          #   cidr: ["10.242.1.0/24"]
                                          #   service_endpoints: ["Microsoft.Storage"]
                                          #   private_link_service_network_policies_enabled: false 
                                          # },
                                          # aks-subnet-pe-kv = {
                                          #   name: "aks-subnet-pe-kv"
                                          #   cidr: ["10.242.2.0/24"]
                                          #   service_endpoints: ["Microsoft.KeyVault"]
                                          #   private_link_service_network_policies_enabled: false 
                                          # },
                                          # aks-subnet-pe-database = {
                                          #   name: "aks-subnet-pe-database"
                                          #   cidr: ["10.242.3.0/24"]
                                          #   service_endpoints: []
                                          #   private_link_service_network_policies_enabled: false 
                                          # },
                                          # aks-subnet-pvt-linkservice = {
                                          #   name: "aks-subnet-pvt-linkservice"
                                          #   cidr: ["10.242.7.0/24"]
                                          #   service_endpoints: []
                                          #   private_link_service_network_policies_enabled: false 
                                          # },
                                        }
  aksvnet_vm_name                   = format("%s-%s-vm", var.app, var.env)
  aksvnet_pvt_dns_group             = format("%s-pvt-dns-grp", local.drprefix)
  
  drlocation                          = var.drlocation
  drprefix                            = format("%s-%s-%s", var.app, var.env, var.drlocation)
  draksrg                             = format("%s-rg", local.drprefix)
  draksappsrg                         = format("%s-base-rg", local.drprefix)
  draksclustername                    = format("%s", local.drprefix)
  draksvnet                           = format("%s-vnet", local.drprefix)
  draksvnet_address_cidr              = "10.0.0.0/8"
  drakssubnets                        = {
                                          aks-subnet-default = {
                                            name: "aks-subnet-default"
                                            cidr: ["10.240.0.0/16"]
                                            service_endpoints: ["Microsoft.AzureActiveDirectory","Microsoft.Web", "Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.ContainerRegistry", "Microsoft.Sql"]
                                            private_link_service_network_policies_enabled: false 
                                          },
                                          aks-subnet-vnodes = {
                                            name: "aks-subnet-vnodes"
                                            cidr: ["10.241.0.0/16"]
                                            service_endpoints: ["Microsoft.AzureActiveDirectory","Microsoft.Web", "Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.ContainerRegistry", "Microsoft.Sql"]
                                            private_link_service_network_policies_enabled: false 
                                          },
                                          # aks-subnet-pe-storage = {
                                          #   name: "aks-subnet-pe-storage"
                                          #   cidr: ["10.242.4.0/24"]
                                          #   service_endpoints: ["Microsoft.Storage"]
                                          #   private_link_service_network_policies_enabled: false 
                                          # },
                                          # aks-subnet-pe-kv = {
                                          #   name: "aks-subnet-pe-kv"
                                          #   cidr: ["10.242.5.0/24"]
                                          #   service_endpoints: ["Microsoft.KeyVault"]
                                          #   private_link_service_network_policies_enabled: false 
                                          # },
                                          # aks-subnet-pe-database = {
                                          #   name: "aks-subnet-pe-database"
                                          #   cidr: ["10.242.6.0/24"]
                                          #   service_endpoints: []
                                          #   private_link_service_network_policies_enabled: false 
                                          # },
                                          # aks-subnet-pvt-linkservice = {
                                          #   name: "aks-subnet-pvt-linkservice"
                                          #   cidr: ["10.242.8.0/24"]
                                          #   service_endpoints: []
                                          #   private_link_service_network_policies_enabled: false  
                                          # },
                                        }
  draksvnet_vm_name                   = format("%s-%s-vm", var.app, var.env)


  aksacrname      = format("%s%sacr", var.app, var.env)
  aksmonitoringws = format("%s-ws", local.prefix)
  akskv           = format("%s-kv1", local.prefix)
  sshkv           = format("ssh-%s-kv", var.KVSUFFIX)

  akswindowsnodeuser = "azureuser"


  pvt_link_service_nat_ip_configuration_primary   = "10.240.20.51"
  pvt_link_service_nat_ip_configuration_secondary = "10.240.20.52"

  ingress_controller_lb_ip             = "10.240.20.42"
  ingress_controller_source_registry   = "registry.k8s.io"
  ingress_controller_image             = "ingress-nginx/controller"
  ingress_controller_image_tag         = "v1.2.1"
  ingress_controller_patch_image       = "ingress-nginx/kube-webhook-certgen"
  ingress_controller_patch_image_tag   = "v1.1.1"
  ingress_controller_default_image     = "defaultbackend-amd64"
  ingress_controller_default_image_tag = "1.5"
  ingress_controller_acr_registry      = local.aksacrname
  ingress_controller_acr_url           = format("%s.azurecr.io", local.aksacrname)
}

data "azurerm_client_config" "current" {}

data "azuread_client_config" "current" {}





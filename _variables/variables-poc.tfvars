app             = "aksoc"
env             = "poc"
aks_admin_aad_group  = "cloudblogs-aks-cluster-admin-qa"
subscription_id = "46e5da92-f07b-4876-9e40-d7e3ced34a05" # Limabean
tenant_id       = "72f988bf-86f1-41af-91ab-2d7cd011db47"
location        = "eastus"
drlocation      = "westus"
homepath        = "/home/azureuser" #$HOME value on the machine you are running the script.
create_dr       = false // create disaster recovery environment
ingress_tls_name =  "onecert-cloudblogsakspoc"
in_cluster_db = true  
owner           = "v-bimishra"
co-owner        = "v-nikhilma"
ow-workitem     = "https://dev.azure.com/GDCBADE/Web%20Development/_queries/edit/368251/?triage=true"

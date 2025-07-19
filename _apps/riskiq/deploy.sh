cd ./akscluster

# Deploying riskiq into DEV/POC
helm upgrade --install riskiq -n riskiq ./_apps/riskiq \
    --set   application.namespace=riskiq \
    --set   application.name=riskiq \
    --set   application.hostHeader=riskiq.cloudblogsaksstg.microsoft.com \
    --set   application.image.repository="aksocdevacr.azurecr.io/riskiq-stage" \
    --set   application.image.tag="43762" \
    --set   application.secrets.secretLoaderImage="aksocdevacr.azurecr.io/onecloud-health-probe:v1" \
    --set   application.secrets.secretRefName="aksoc-dev-riskiq-kv" \
    --set   application.secrets.secretProviderClass="aksoc-dev-riskiq-kv" \
    --set   application.storages.mediaStore.persistentVolumeClaim="aksocdeveastusmedia-riskiq" \
    --set   application.storages.mediaStore.secretProviderClass="aksocdeveastusmedia-aksoc-dev-eastus-kv1" \
    --set   application.storages.logStore.persistentVolumeClaim="aksocdeveastuslogs-riskiq" \
    --set   application.storages.logStore.secretProviderClass="aksocdeveastuslogs-aksoc-dev-eastus-kv1" \
    --set   application.storages.backupStore.persistentVolumeClaim="aksocdeveastusbackups-riskiq" \
    --set   application.storages.backupStore.secretProviderClass="aksocdeveastusbackups-aksoc-dev-eastus-kv1" \
    --set   application.databases.mysql.inClusterDb=false \
    --set   application.databases.mysql.host="aksoc-dev-eastus-riskiq-sql.mysql.database.azure.com" \
    --set   application.databases.mysql.image="aksocdevacr.azurecr.io/mysql:8.0" \
    --set   application.databases.mysql.xtrabackupImage="aksocdevacr.azurecr.io/xtrabackup:1.0" \
    --set   application.resources.primaryResourceGroup="aksoc-dev-eastus-riskiq-rg" \
    --set   application.resources.primaryLocation="eastus" \
    --set   application.cronJobs.dbBackup.enabled=true \
    --set   application.cronJobs.dbBackup.image="aksocdevacr.azurecr.io/onecloud-mysql-client:v1" \
    --set   application.cronJobs.dbBackup.dbServer="riskiq-dbhost" \
    --set   service.type=ClusterIP \
    --set   service.port=80 \
    --set   autoscaling.enabled=true \
    --set   autoscaling.minReplicas=2 \
    --set   autoscaling.maxReplicas=4 \
    --set   autoscaling.targetCPUUtilizationPercentage=80 \
    --set   autoscaling.targetMemoryUtilizationPercentage=80 


# Deploying riskiq into Staging
helm upgrade --install riskiq -n riskiq ./_apps/riskiq \
    --set   application.namespace=riskiq \
    --set   application.name=riskiq \
    --set   application.hostHeader=riskiq.cloudblogsaksstg.microsoft.com \
    --set   application.image.repository="aksocstgacr.azurecr.io/riskiq-stage" \
    --set   application.image.tag="48067" \
    --set   application.secrets.secretLoaderImage="aksocstgacr.azurecr.io/onecloud-health-probe:v1" \
    --set   application.secrets.secretRefName="aksoc-stg-riskiq-kv" \
    --set   application.secrets.secretProviderClass="aksoc-stg-riskiq-kv" \
    --set   application.storages.mediaStore.persistentVolumeClaim="aksocstgeastusmedia-riskiq" \
    --set   application.storages.mediaStore.secretProviderClass="aksocstgeastusmedia-aksoc-stg-eastus-kv1" \
    --set   application.storages.logStore.persistentVolumeClaim="aksocstgeastuslogs-riskiq" \
    --set   application.storages.logStore.secretProviderClass="aksocstgeastuslogs-aksoc-stg-eastus-kv1" \
    --set   application.storages.backupStore.persistentVolumeClaim="aksocstgeastusbackups-riskiq" \
    --set   application.storages.backupStore.secretProviderClass="aksocstgeastusbackups-aksoc-stg-eastus-kv1" \
    --set   application.databases.mysql.inClusterDb=true \
    --set   application.databases.mysql.host="mysql-0.mysql-headless-svc.riskiq.svc.cluster.local" \
    --set   application.databases.mysql.image="aksocstgacr.azurecr.io/mysql:8.0" \
    --set   application.databases.mysql.xtrabackupImage="aksocstgacr.azurecr.io/xtrabackup:1.0" \
    --set   application.resources.primaryResourceGroup="aksoc-stg-eastus-riskiq-rg" \
    --set   application.resources.primaryLocation="eastus" \
    --set   application.cronJobs.dbBackup.enabled=true \
    --set   application.cronJobs.dbBackup.image="aksocstgacr.azurecr.io/onecloud-mysql-client:v1" \
    --set   application.cronJobs.dbBackup.dbServer="riskiq-dbhost" \
    --set   service.type=ClusterIP \
    --set   service.port=80 \
    --set   autoscaling.enabled=true \
    --set   autoscaling.minReplicas=2 \
    --set   autoscaling.maxReplicas=4 \
    --set   autoscaling.targetCPUUtilizationPercentage=50 \
    --set   autoscaling.targetMemoryUtilizationPercentage=70 


# Deploying riskiq into ppe
helm upgrade --install riskiq -n riskiq ./_apps/riskiq \
    --set   application.namespace=riskiq \
    --set   application.name=riskiq \
    --set   application.hostHeader=riskiq.cloudblogs-prep.microsoft.com \
    --set   application.image.repository="aksocppeacr.azurecr.io/riskiq-stage" \
    --set   application.image.tag="48067" \
    --set   application.secrets.secretLoaderImage="aksocppeacr.azurecr.io/onecloud-health-probe:v1" \
    --set   application.secrets.secretRefName="aksoc-ppe-riskiq-kv" \
    --set   application.secrets.secretProviderClass="aksoc-ppe-riskiq-kv" \
    --set   application.storages.mediaStore.persistentVolumeClaim="aksocppeeastusmedia-riskiq" \
    --set   application.storages.mediaStore.secretProviderClass="aksocppeeastusmedia-aksoc-ppe-eastus-kv1" \
    --set   application.storages.logStore.persistentVolumeClaim="aksocppeeastuslogs-riskiq" \
    --set   application.storages.logStore.secretProviderClass="aksocppeeastuslogs-aksoc-ppe-eastus-kv1" \
    --set   application.storages.backupStore.persistentVolumeClaim="aksocppeeastusbackups-riskiq" \
    --set   application.storages.backupStore.secretProviderClass="aksocppeeastusbackups-aksoc-ppe-eastus-kv1" \
    --set   application.databases.mysql.inClusterDb=true \
    --set   application.databases.mysql.host="aksoc-ppe-eastus-riskiq-sql.mysql.database.azure.com" \
    --set   application.databases.mysql.image="aksocppeacr.azurecr.io/mysql:8.0" \
    --set   application.databases.mysql.xtrabackupImage="aksocppeacr.azurecr.io/xtrabackup:1.0" \
    --set   application.resources.primaryResourceGroup="aksoc-ppe-eastus-riskiq-rg" \
    --set   application.resources.primaryLocation="eastus" \
    --set   application.cronJobs.dbBackup.enabled=true \
    --set   application.cronJobs.dbBackup.image="aksocppeacr.azurecr.io/onecloud-mysql-client:v1" \
    --set   application.cronJobs.dbBackup.dbServer="riskiq-dbhost" \
    --set   service.type=ClusterIP \
    --set   service.port=80 \
    --set   autoscaling.enabled=true \
    --set   autoscaling.minReplicas=2 \
    --set   autoscaling.maxReplicas=4 \
    --set   autoscaling.targetCPUUtilizationPercentage=50 \
    --set   autoscaling.targetMemoryUtilizationPercentage=70     



cd ./akscluster

# Deploying cloudblog into DEV
helm upgrade --install cloudblog -n cloudblog ./_apps/cloudblog \
    --set   application.namespace=cloudblog \
    --set   application.name=cloudblog \
    --set   application.hostHeader=cloudblog.cloudblogsaksstg.microsoft.com \
    --set   application.image.repository="aksocdevacr.azurecr.io/cloudblog-stage" \
    --set   application.image.tag="43762" \
    --set   application.secrets.secretLoaderImage="aksocdevacr.azurecr.io/onecloud-health-probe:v1" \
    --set   application.secrets.secretRefName="aksoc-dev-cloudblog-kv" \
    --set   application.secrets.secretProviderClass="aksoc-dev-cloudblog-kv" \
    --set   application.storages.mediaStore.persistentVolumeClaim="aksocdeveastusmedia-cloudblog" \
    --set   application.storages.mediaStore.secretProviderClass="aksocdeveastusmedia-aksoc-dev-eastus-kv1" \
    --set   application.storages.logStore.persistentVolumeClaim="aksocdeveastuslogs-cloudblog" \
    --set   application.storages.logStore.secretProviderClass="aksocdeveastuslogs-aksoc-dev-eastus-kv1" \
    --set   application.storages.backupStore.persistentVolumeClaim="aksocdeveastusbackups-cloudblog" \
    --set   application.storages.backupStore.secretProviderClass="aksocdeveastusbackups-aksoc-dev-eastus-kv1" \
    --set   application.databases.mysql.inClusterDb=false \
    --set   application.databases.mysql.host="aksoc-dev-eastus-cloudblog-sql.mysql.database.azure.com" \
    --set   application.databases.mysql.image="aksocdevacr.azurecr.io/mysql:8.0" \
    --set   application.databases.mysql.xtrabackupImage="aksocdevacr.azurecr.io/xtrabackup:1.0" \
    --set   application.resources.primaryResourceGroup="aksoc-dev-eastus-cloudblog-rg" \
    --set   application.resources.primaryLocation="eastus" \
    --set   application.cronJobs.dbBackup.enabled=true \
    --set   application.cronJobs.dbBackup.image="aksocdevacr.azurecr.io/onecloud-mysql-client:v1" \
    --set   application.cronJobs.dbBackup.dbServer="cloudblog-dbhost" \
    --set   service.type=ClusterIP \
    --set   service.port=80 \
    --set   autoscaling.enabled=true \
    --set   autoscaling.minReplicas=2 \
    --set   autoscaling.maxReplicas=4 \
    --set   autoscaling.targetCPUUtilizationPercentage=80 \
    --set   autoscaling.targetMemoryUtilizationPercentage=80 



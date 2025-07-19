cd ./akscluster

# Deploying secblog into DEV
helm upgrade --install secblog -n secblog ./_apps/secblog \
    --set   application.namespace=secblog \
    --set   application.name=secblog \
    --set   application.hostHeader=secblog.cloudblogsaksstg.microsoft.com \
    --set   application.image.repository="aksocdevacr.azurecr.io/securityblog-stage" \
    --set   application.image.tag="47986" \
    --set   application.secrets.secretLoaderImage="aksocdevacr.azurecr.io/onecloud-health-probe:v1" \
    --set   application.secrets.secretRefName="aksoc-dev-secblog-kv" \
    --set   application.secrets.secretProviderClass="aksoc-dev-secblog-kv" \
    --set   application.storages.mediaStore.persistentVolumeClaim="aksocdeveastusmedia-secblog" \
    --set   application.storages.mediaStore.secretProviderClass="aksocdeveastusmedia-aksoc-dev-eastus-kv1" \
    --set   application.storages.logStore.persistentVolumeClaim="aksocdeveastuslogs-secblog" \
    --set   application.storages.logStore.secretProviderClass="aksocdeveastuslogs-aksoc-dev-eastus-kv1" \
    --set   application.storages.backupStore.persistentVolumeClaim="aksocdeveastusbackups-secblog" \
    --set   application.storages.backupStore.secretProviderClass="aksocdeveastusbackups-aksoc-dev-eastus-kv1" \
    --set   application.databases.mysql.inClusterDb=false \
    --set   application.databases.mysql.host="aksoc-dev-eastus-secblog-sql.mysql.database.azure.com" \
    --set   application.databases.mysql.image="aksocdevacr.azurecr.io/mysql:8.0" \
    --set   application.databases.mysql.xtrabackupImage="aksocdevacr.azurecr.io/xtrabackup:1.0" \
    --set   application.resources.primaryResourceGroup="aksoc-dev-eastus-secblog-rg" \
    --set   application.resources.primaryLocation="eastus" \
    --set   application.cronJobs.dbBackup.enabled=false \
    --set   application.cronJobs.dbBackup.image="aksocdevacr.azurecr.io/onecloud-mysql-client:v1" \
    --set   application.cronJobs.dbBackup.dbServer="secblog-dbhost" \
    --set   service.type=ClusterIP \
    --set   service.port=80 \
    --set   autoscaling.enabled=true \
    --set   autoscaling.minReplicas=2 \
    --set   autoscaling.maxReplicas=6 \
    --set   autoscaling.targetCPUUtilizationPercentage=50 \
    --set   autoscaling.targetMemoryUtilizationPercentage=70 

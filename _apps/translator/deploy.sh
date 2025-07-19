cd ./akscluster

# Deploying translator into DEV
helm upgrade --install translator -n translator ./_apps/translator \
    --set   application.namespace=translator \
    --set   application.name=translator \
    --set   application.hostHeader=translator.cloudblogsaksstg.microsoft.com \
    --set   application.image.repository="aksocdevacr.azurecr.io/translator-stage" \
    --set   application.image.tag="44248" \
    --set   application.secrets.secretLoaderImage="aksocdevacr.azurecr.io/onecloud-nginx-web:v1" \
    --set   application.secrets.secretRefName="aksoc-dev-translator-kv" \
    --set   application.secrets.secretProviderClass="aksoc-dev-translator-kv" \
    --set   application.storages.mediaStore.persistentVolumeClaim="aksocdeveastusmedia-translator" \
    --set   application.storages.mediaStore.secretProviderClass="aksocdeveastusmedia-aksoc-dev-eastus-kv1" \
    --set   application.storages.logStore.persistentVolumeClaim="aksocdeveastuslogs-translator" \
    --set   application.storages.logStore.secretProviderClass="aksocdeveastuslogs-aksoc-dev-eastus-kv1" \
    --set   application.storages.backupStore.persistentVolumeClaim="aksocdeveastusbackups-translator" \
    --set   application.storages.backupStore.secretProviderClass="aksocdeveastusbackups-aksoc-dev-eastus-kv1" \
    --set   application.databases.mysql.inClusterDb=false \
    --set   application.databases.mysql.host="aksoc-dev-eastus-translator-sql.mysql.database.azure.com" \
    --set   application.databases.mysql.image="aksocdevacr.azurecr.io/mysql:8.0" \
    --set   application.databases.mysql.xtrabackupImage="aksocdevacr.azurecr.io/xtrabackup:1.0" \
    --set   application.resources.primaryResourceGroup="aksoc-dev-eastus-translator-rg" \
    --set   application.resources.primaryLocation="eastus" \
    --set   application.cronJobs.dbBackup.enabled=false \
    --set   application.cronJobs.dbBackup.image="aksocdevacr.azurecr.io/onecloud-mysql-client:v1" \
    --set   application.cronJobs.dbBackup.dbServer="translator-dbhost" \
    --set   service.type=ClusterIP \
    --set   service.port=80 \
    --set   autoscaling.enabled=true \
    --set   autoscaling.minReplicas=2 \
    --set   autoscaling.maxReplicas=4 \
    --set   autoscaling.targetCPUUtilizationPercentage=80 \
    --set   autoscaling.targetMemoryUtilizationPercentage=80 

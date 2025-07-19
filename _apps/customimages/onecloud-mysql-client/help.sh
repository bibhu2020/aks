docker build -t mysqlbackup:v1 .
az acr login -n aksocdevacr.azurecr.io
docker tag mysqlbackup:v1 aksocdevacr.azurecr.io/mysqlbackup:v1
docker push aksocdevacr.azurecr.io/mysqlbackup:v1


kubectl run nginx --image=nginx --dry-run=client -o yaml
kubectl create cronjob testjob --image=mysql --schedule='0/5 * * * ?' -- echo 'hello' --dry-run=client -o yaml

kubectl create job --from=cronjob/secblog-dbbackup run1 -n secblog

kubectl logs -n secblog cronjob.batch/secblog-dbbackup

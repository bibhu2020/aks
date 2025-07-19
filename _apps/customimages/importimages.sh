#######Import Images
####### it importes 3rd party images into the ACR
#############################################################################################
# login into ACR first
#az login
az account set --subscription 46e5da92-f07b-4876-9e40-d7e3ced34a05 #433cb7d3-bac1-4059-bacf-afb085b7a62b
az acr login --name aksocpocacr

az acr import \
  --name aksocpocacr \
  --source registry.k8s.io/ingress-nginx/controller:v1.2.1 \
  --image ingress-nginx/controller:v1.2.1

az acr import \
  --name aksocpocacr \
  --source registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.1.1 \
  --image ingress-nginx/kube-webhook-certgen:v1.1.1

az acr import \
  --name aksocpocacr \
  --source registry.k8s.io/defaultbackend-amd64:1.5 \
  --image defaultbackend-amd64:1.5

az acr import \
  --name aksocpocacr \
  --source gcr.io/google-samples/xtrabackup:1.0 \
  --image xtrabackup:1.0

az acr import \
  --name aksocpocacr \
  --source docker.io/library/python:3.9-slim \
  --image python:3.9-slim

az acr import \
  --name aksocpocacr \
  --source docker.io/library/mysql:8.3 \
  --image mysql:8.3

# az acr import \
#   --name aksocpocacr \
#   --source docker.io/library/mysql:5.7 \
#   --image mysql:5.7

# az acr import \
#   --name aksocpocacr \
#   --source docker.io/library/busybox:1.36.1 \
#   --image busybox:1.36.1

# az acr import \
#   --name aksocpocacr \
#   --source docker.io/library/nginx:latest \
#   --image nginx:latest

# az acr import \
#   --name aksocpocacr \
#   --source docker.io/library/nginx:1.25.4 \
#   --image nginx:1.25.4

# az acr import \
#   --name aksocpocacr \
#   --source docker.io/nginxinc/nginx-unprivileged:latest \
#   --image nginx-unprivileged:latest

# az acr import \
#   --name aksocpocacr \
#   --source mcr.microsoft.com/dotnet/core/aspnet \
#   --image aspnet

# az acr import \
#   --name aksocpocacr \
#   --source docker.io/library/node:latest \
#   --image node:latest

#######Custom Images
####### Build Custom Images
#############################################################################################
# onecloud base container
docker build -t onecloud-base:v1 -f ./_apps/customimages/onecloud-base/Dockerfile ./_apps/customimages/onecloud-base \
  && docker tag onecloud-base:v1 aksocpocacr.azurecr.io/onecloud-base:v1 \
  && docker push aksocpocacr.azurecr.io/onecloud-base:v1

# onecloud base container - v2 (contains npm serve package)
docker build -t onecloud-base:v2 -f ./_apps/customimages/onecloud-base/Dockerfile ./_apps/customimages/onecloud-base \
  && docker tag onecloud-base:v2 aksocpocacr.azurecr.io/onecloud-base:v2 \
  && docker push aksocpocacr.azurecr.io/onecloud-base:v2

# onecloud cronjob container
docker build -t onecloud-cron-job:v1 -f ./_apps/customimages/onecloud-cron-job/Dockerfile ./_apps/customimages/onecloud-cron-job \
  && docker tag onecloud-cron-job:v1 aksocpocacr.azurecr.io/onecloud-cron-job:v1 \
  && docker push aksocpocacr.azurecr.io/onecloud-cron-job:v1

# mysql client
docker build -t onecloud-mysql-client:v1.5 -f ./_apps/customimages/onecloud-mysql-client/Dockerfile ./_apps/customimages/onecloud-mysql-client \
  && docker tag onecloud-mysql-client:v1.5 aksocpocacr.azurecr.io/onecloud-mysql-client:v1.5 \
  && docker push aksocpocacr.azurecr.io/onecloud-mysql-client:v1.5

# health probe
docker build -t onecloud-health-probe:v1.1 -f ./_apps/customimages/onecloud-health-probe/Dockerfile ./_apps/customimages/onecloud-health-probe \
  && docker tag onecloud-health-probe:v1.1 aksocpocacr.azurecr.io/onecloud-health-probe:v1.1 \
  && docker push aksocpocacr.azurecr.io/onecloud-health-probe:v1.1


# # job container
# docker build -t onecloud-cron-job:v1 -f ./_apps/customimages/onecloud-cron-job/Dockerfile ./_apps/customimages/onecloud-cron-job \
#   && docker tag onecloud-cron-job:v1 aksocpocacr.azurecr.io/onecloud-cron-job:v1 \
#   && docker push aksocpocacr.azurecr.io/onecloud-cron-job:v1


# # mysql server
# docker build -t onecloud-mysql-server:v1 -f ./_apps/customimages/onecloud-mysql-server/Dockerfile ./_apps/customimages/onecloud-mysql-server \
#   && docker tag onecloud-mysql-server:v1 aksocpocacr.azurecr.io/onecloud-mysql-server:v1 \
#   && docker push aksocpocacr.azurecr.io/onecloud-mysql-server:v1

# # nginx web (not being used now)
# docker build -t onecloud-nginx-web:v1 -f ./_apps/customimages/onecloud-nginx-web/Dockerfile ./_apps/customimages/onecloud-nginx-web \
#   && docker tag onecloud-nginx-web:v1 aksocpocacr.azurecr.io/onecloud-nginx-web:v1 \
#   && docker push aksocpocacr.azurecr.io/onecloud-nginx-web:v1


docker build -t onecloud-riskiq:v1.1 -f ./_apps/customimages/onecloud-riskiq/Dockerfile ./_apps/customimages/onecloud-riskiq \
  && docker tag onecloud-riskiq:v1.1 aksocpocacr.azurecr.io/onecloud-riskiq:v1.1 \
  && docker push aksocpocacr.azurecr.io/onecloud-riskiq:v1.1


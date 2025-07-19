## Import the docker nginx image into ACR
az acr login --name aksocstgacr

az acr import \
  --name aksocstgacr \
  --source docker.io/library/nginx:1.25.4 \
  --image nginx:1.25.4

az acr import \
  --name aksocppeacr \
  --source docker.io/nginxinc/nginx-unprivileged:latest \
  --image nginx-unprivileged:latest



## Build an underprivilleged nginx
// build the docker image
docker build . -t oc-nginx-unprivileged:v1
// tag the image
docker tag oc-nginx-unprivileged:v1 aksocstgacr.azurecr.io/oc-nginx-unprivileged:v1
// upload the image into ACR
docker push aksocstgacr.azurecr.io/oc-nginx-unprivileged:v1


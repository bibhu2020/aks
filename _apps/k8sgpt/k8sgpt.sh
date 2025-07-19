########## k8sgpt open source community soure code: https://github.com/k8sgpt-ai/k8sgpt

# Installing CLI (It runs on the user computer on demand basis)
# https://docs.k8sgpt.ai/getting-started/getting-started/
# https://www.youtube.com/watch?v=7WA8XVrod2Y

# Step1: takes you the OpenAI site to grab an API key
k8sgpt generate #takes you the OpenAI site (Open AI is the default AI)

# Step2: Authenticate to Open AI. The command below uses "Ope AI chat gpt 3.5". It prompts you enter the API key.
k8sgpt auth add --backend openai -m gpt-3.5-turbo 

# Step3: scan the current K8 context / cluster
k8sgpt analyze
k8sgpt analyze --filter=Pod
k8sgpt analyze --explain --filter=Pod # It explains the issues in the cluster and proposes possible fix.
k8sgpt analyze --explain --filter=Pod -o json | jq . # this generates explanation and proposed fixes in json and feeds to jq

# Installing k8sgpt Operator (It runs k8sgpt continiously 24x7 within the cluster that scans the cluster regularly.)
# https://docs.k8sgpt.ai/getting-started/in-cluster-operator/
# https://www.youtube.com/watch?v=hb4du-oK0KY

# Step1: This installs the Operator into the cluster, which will await a K8sGPT resource before anything happens.
helm repo add k8sgpt https://charts.k8sgpt.ai/
helm repo update
helm install k8sgpt k8sgpt/k8sgpt-operator -n k8sgpt-system --create-namespace --values values.yaml
helm upgrade k8sgpt k8sgpt/k8sgpt-operator -n k8sgpt-system --create-namespace --values values.yaml

# Step2: Store the OpenAI key in a K8 secret.
export OPENAI_TOKEN=<tbd>
kubectl create secret generic k8sgpt-secret --from-literal=openai-api-key=$OPENAI_TOKEN -n k8sgpt-system

# Step3: Deploying a K8sGPT resource. The resource is a scan instruction to the operator. You can have n number of such resources.
# my below K8sGPT resource instructs to scan all resources in default namespace
kubectl delete -f - << EOF
apiVersion: core.k8sgpt.ai/v1alpha1
kind: K8sGPT
metadata:
  name: k8sgpt-scanner-default
  namespace: default
spec:
  ai:
    enabled: true
    model: gpt-3.5-turbo
    backend: openai
    secret:
      name: k8sgpt-secret
      key: openai-api-key
    # anonymized: false
    # language: english
  noCache: false
  version: v0.3.13
  # filters:
  #   - Ingress
  # sink:
  #   type: slack
  #   webhook: <webhook-url>
  # extraOptions:
  #   backstage:
  #     enabled: true
EOF

# Step4: Read the results
sudo apt install -y jq # jq formats the json
kubectl get results -o json | jq .

# k8sgpt security scanner (uses trivy open-source security scanner)

# Step1: Activate trivy
k8sgpt integration activate trivy

# Step2: see the integration in the filter list
k8sgpt filter list

# Step3: 
k8sgpt analyze --filter=VulnerabilityReport

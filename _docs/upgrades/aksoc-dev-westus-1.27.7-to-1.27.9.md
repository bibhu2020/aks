# Patching aksoc-dev-westus AKS Cluster version 1.27.7 to 1.27.9
This document describes the step by step approach you MUST follow to upgrade your kubernetes version. It ensures no corruption of the cluster, and outage during the upgrade process.

## Step0: Set the ENV variables (validate correctness) 
Setup the environment variables for script execution.

```
export AKS_REGION=westus
export AKS_VERSION_CURRENT=1.27.7
export AKS_VERSION_UPGRADE=1.27.9
export AKS_CLUSTER_AZ_SUBSCRIPTION_ID=dc276571-9aac-4771-8451-c6ab5a4e058a
export AKS_CLUSTER_NAME=aksoc-dev-westus
export AKS_CLUSTER_RESOURCE_GROUP=aksoc-dev-westus-rg
export AKS_SYS_LIVE_NODE_POOL=systempool
export AKS_USR_LIVE_NODE_POOL=userpool2
export AKS_SYS_NODE_LABELS="app=system node-os=linux nodepool-type=system"
export AKS_USR_NODE_LABELS="app=cloudblogs node-os=linux nodepool-type=user"

export AKS_NODE_VM_SIZE="Standard_D8s_v3"
export AKS_SYS_TEMP_NODE_POOL=tmpsysndpool
export AKS_USR_TEMP_NODE_POOL=tmpusrndpool
export AKS_MIN_NODE_COUNT=2
export AKS_MAX_NODE_COUNT=20
```

## Step1: Check your node upgrade eligibility
ASK version upgrade is always sequential. You should skip a version and upgrade the cluster. This could cause unexpected damages to the cluster. You must find out your eligibility first.

E.g. if you are in version 1.27.7, You can go to the next version 1.27.9. You should not skip to 1.28.5.

```
// Available versions in a region
az aks get-versions -l $AKS_REGION -o table

// What's my AKS clusters eligibility.
// This shows you what is your current version, and what sequence of upgrade you should follow
az aks get-upgrades -g $AKS_CLUSTER_RESOURCE_GROUP -n $AKS_CLUSTER_NAME --output table

// This shows your the kubernetes version on control-panel, and each node pool.
az aks show -g $AKS_CLUSTER_RESOURCE_GROUP -n $AKS_CLUSTER_NAME| grep -E "orchestratorVersion|kubernetesVersion"

*orchestratorVersion refers to nodepool version
*kubernetesVersion refers to control-panel version

```

**Note:** correct the ENV variable AKS_VERSION_CURRENT and AKS_VERSION_UPGRADE based on your eligibility.


## Step2: Set the Context
Ensure you are in the right azure subscription and in the right kubernete context/cluster. You may otherwise break your cluster.

```
az account set --subscription $AKS_CLUSTER_AZ_SUBSCRIPTION_ID \
    && az account show

kubectl config use-context $AKS_CLUSTER_NAME \
        && kubectl config get-contexts
```
## Step3: Create Temporary Node Pools
We MUST create the temporary node pools to off-load the payloads to them from the LIVE nodes. Once the LIVE nodes are freed (cordoned), you are safe to perform the upgrade on them.
```
// create temporary system nodepool
az aks nodepool add \
  --resource-group $AKS_CLUSTER_RESOURCE_GROUP \
  --cluster-name $AKS_CLUSTER_NAME \
  --name $AKS_SYS_TEMP_NODE_POOL \
  --kubernetes-version $AKS_VERSION_CURRENT \
  --labels $AKS_SYS_NODE_LABELS \
  --node-vm-size $AKS_NODE_VM_SIZE \
  --node-count $AKS_MIN_NODE_COUNT \
  --min-count $AKS_MIN_NODE_COUNT \
  --max-count $AKS_MAX_NODE_COUNT \
  --mode system \
  --enable-cluster-autoscaler 

// check the node pool status. (you must see the nodepools are in READY status)
kubectl get nodes -owide | grep $AKS_SYS_TEMP_NODE_POOL 

// create temporary user nodepool
az aks nodepool add \
  --resource-group $AKS_CLUSTER_RESOURCE_GROUP \
  --cluster-name $AKS_CLUSTER_NAME \
  --name $AKS_USR_TEMP_NODE_POOL \
  --kubernetes-version $AKS_VERSION_CURRENT \
  --labels $AKS_USR_NODE_LABELS \
  --node-vm-size $AKS_NODE_VM_SIZE \
  --node-count $AKS_MIN_NODE_COUNT \
  --min-count $AKS_MIN_NODE_COUNT \
  --max-count $AKS_MAX_NODE_COUNT \
  --mode user \
  --enable-cluster-autoscaler 

// check the node pool status. (you must see the nodepools are in READY status)
kubectl get nodes -owide | grep $AKS_USR_TEMP_NODE_POOL 
```
At this point, the temporary nodes are ready to take on the payloads.

## Step4: Cordon LIVE Nodes / Nodepools
Cordoning is a process of removing the nodes from the future schedueling of PODs. Draining is the process of removing the PODs/Payloads from the node. The below script loops through each node in your LIVE node pools, cordons & drains them.

By doing so, we are asking Kuberentes to hands off the payload to the temporary nodes which has the matching labels. It then frees up the LIVE nodes for upgrade. Let's do it.

```
// Cordon the user pool
./_docs/upgrades/cordon.sh $AKS_USR_LIVE_NODE_POOL

// You must see the nodes in SchedulingDisabled status.
kubectl get nodes -owide | grep $AKS_USR_LIVE_NODE_POOL

// You should not see any PODs (except Daemonset PODs running on the user POOL)
kubectl get pods -A  -owide | grep $AKS_USR_LIVE_NODE_POOL

// Cordon the system pool
./_docs/upgrades/cordon.sh $AKS_SYS_LIVE_NODE_POOL

// You must see the nodes in SchedulingDisabled status.
kubectl get nodes -owide | grep $AKS_SYS_LIVE_NODE_POOL

// You should not see any PODs (except Daemonset PODs running on the system POOL)
kubectl get pods -A  -owide | grep $AKS_SYS_LIVE_NODE_POOL

```
**Note:** Before you take the next step, you MUST validate the cluster health and the applications running on it. At this point, the payloads are moved to the temporary nodes. Your application is LIVE from the temporary nodes. Hence, the application validation at this points is MUST.

## Step5: Check Your Cluster Elgibility Again
```
az aks get-upgrades -g $AKS_CLUSTER_RESOURCE_GROUP -n $AKS_CLUSTER_NAME --output table
```

## Step6: Upgrade Control Panel / Master Nodes
Control Panel or Master Node is concealed by the AKS. You can't see it on the portal. But this needs upgrade.

```
// upgrade control panel
az aks upgrade -g $AKS_CLUSTER_RESOURCE_GROUP  -n  $AKS_CLUSTER_NAME  --kubernetes-version $AKS_VERSION_UPGRADE --control-plane-only

// verify the kubernetes version on the control panel
az aks show -g $AKS_CLUSTER_RESOURCE_GROUP  -n  $AKS_CLUSTER_NAME | grep -E "orchestratorVersion|kubernetesVersion"

```

## Step7: Upgrade System Nodes / Nodepools

```
// upgrade system node pool
az aks nodepool upgrade --resource-group $AKS_CLUSTER_RESOURCE_GROUP --cluster-name $AKS_CLUSTER_NAME --kubernetes-version $AKS_VERSION_UPGRADE --name $AKS_SYS_LIVE_NODE_POOL

// verify the kubernetes version on the system nodepool
az aks show -g $AKS_CLUSTER_RESOURCE_GROUP  -n  $AKS_CLUSTER_NAME | grep -E "orchestratorVersion|kubernetesVersion"

```

## Step8: Upgrade User Nodes / Nodepools
```
az aks nodepool upgrade --resource-group $AKS_CLUSTER_RESOURCE_GROUP --cluster-name $AKS_CLUSTER_NAME --kubernetes-version $AKS_VERSION_UPGRADE --name $AKS_USR_LIVE_NODE_POOL

// verify the kubernetes version on the user nodepool
az aks show -g $AKS_CLUSTER_RESOURCE_GROUP  -n  $AKS_CLUSTER_NAME | grep -E "orchestratorVersion|kubernetesVersion"
```

## Step9: Uncordn LIVE Nodes / Nodepools
Now that the nodepools are upgraded. Let's bring them LIVE to take on the payloads. The process that does this is called uncordoning. 

```
// Uncordon the user pool
./_docs/upgrades/uncordon.sh $AKS_USR_LIVE_NODE_POOL

// You should see the nodes in READY status only.
kubectl get nodes -owide | grep $AKS_USR_LIVE_NODE_POOL

// Uncordon the system pool
./_docs/upgrades/uncordon.sh $AKS_SYS_LIVE_NODE_POOL

// You should see the nodes in READY status only.
kubectl get nodes -owide | grep $AKS_SYS_LIVE_NODE_POOL
```
**Note:** Before you take the next step, you MUST validate the cluster health and the applications running on it. 

## Step10: Cordon Temporary Nodes / Nodepools
Now that our LIVE nodes are upgrades and ready to take the payloads. We must cordon / drain-off the payloads from the Temporary nodes.

```
// Cordon the system pool
./_docs/upgrades/cordon.sh $AKS_SYS_TEMP_NODE_POOL

// You must see the nodes in SchedulingDisabled status.
kubectl get nodes -owide | grep $AKS_SYS_TEMP_NODE_POOL

// You should see app and/or ingress pods running on the nodes
kubectl get pods -A  -owide | grep $AKS_SYS_TEMP_NODE_POOL

// Cordon the user pool
./_docs/upgrades/cordon.sh $AKS_USR_TEMP_NODE_POOL

// You must see the nodes in SchedulingDisabled status.
kubectl get nodes -owide | grep $AKS_USR_TEMP_NODE_POOL

// You should see app and/or ingress pods running on the nodes
kubectl get pods -A  -owide | grep $AKS_USR_TEMP_NODE_POOL
```
**Note:** Before you take the next step, you MUST validate the cluster health and the applications running on it. At this points, all application pods are transferred the LIVE nodes, and the application is being served from the LIVE nodes.

## Step11: Delete Temporary Nodes / Nodepools
You can now destroy the temporary nodes

```
// Delete the user temporary node pool
az aks nodepool delete \
    --resource-group $AKS_CLUSTER_RESOURCE_GROUP \
    --cluster-name $AKS_CLUSTER_NAME \
    --name $AKS_USR_TEMP_NODE_POOL

// Delete the sys temporary node pool
az aks nodepool delete \
    --resource-group $AKS_CLUSTER_RESOURCE_GROUP \
    --cluster-name $AKS_CLUSTER_NAME \
    --name $AKS_SYS_TEMP_NODE_POOL
```
## Step12: Am I fully Upgraded?
Read the Microsoft LTS support. https://learn.microsoft.com/en-us/azure/aks/long-term-support
Our AKS cluster is on LTS (Long Term Support) version. Hence, we can't upgrade our cluster to the next version until the next LTS version is released.

As on today, the LTS version is 1.27*.

If you are not LTS version, you can check your eligibility for next upgrade, and repeat the upgrade process.
```
// What's my AKS clusters eligibility.
// This shows you what is your current version, and what sequence of upgrade you should follow
az aks get-upgrades -g $AKS_CLUSTER_RESOURCE_GROUP -n $AKS_CLUSTER_NAME --output table
```


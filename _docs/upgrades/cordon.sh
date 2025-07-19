#!/bin/bash

# Check if node pool name argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <node_pool_name>"
    exit 1
fi

# Retrieve node names in the specified node pool
node_pool_name=$1
node_names=$(kubectl get nodes -owide | awk /^aks-$node_pool_name-/ | awk '{print $1}')
echo $node_names

# Cordon each node in the node pool
for node_name in $node_names; do
    echo "Cordoning node $node_name"
    kubectl cordon $node_name
    kubectl drain $node_name --force --ignore-daemonsets --delete-emptydir-data 
done

echo "Cordoning completed for all nodes in node pool $node_pool_name"

kubectl get nodes -owide | awk /^aks-$node_pool_name-/




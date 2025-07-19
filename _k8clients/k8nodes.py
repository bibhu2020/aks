import sys
from kubernetes import client, config

config.load_kube_config()
v1 = client.CoreV1Api()
# ret = v1.list_namespaces_pod('riskiq', watch=False)
ret = v1.list_node()
nodes = ret.items

for node in nodes:
    print("\n Kubernetes node name is: " + str(node.metadata.labels['kubernetes.io/hostname']))
    print(" => Kuberente node image name is: " + str(node.status.node_info.os_image))
    for j in node.status.addresses:
        print(" => Node address type is: " + str(j.type) + " for " + str(j.address))

ret = v1.list_pod_for_all_namespaces()
for pod in ret.items: 
    print(pod)



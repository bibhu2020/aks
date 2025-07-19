# Cluster Go-Live Checklist
- [X] Install right SSL certficate
- [X] Make sure the cluster is N-1 k8 version. (We are LTS versio 1.27.9)
- [X] Diagnostic logging is turned on for both (passive & active) cluster. (to their respective Log Workspace)
- [X] Diagnostic logging is turned on for SQL Servers (both passive & active).
- [X] An AFD endpoint is created to monitor the cluster health using App Insight. (monitor both active and passive cluster)
- [ ] Make sure no non-ACR image is referred in the cluster. (Nikhil will create ticket for Defender Alerts)
- [X] Make sure no security alert in S360 and in AZ scanner (https://dst-azts.azurewebsites.net/).
- [X] Make sure access control has been put in place.
- [X] Make sure grafana monitoring is in place.
- [X] Make sure alerts are configured to monitor the cluster.
- [X] Make sure resource limits and node affinity is defined for ingress controller
- [ ] (optional) Make sure AAD groups are Security type instead of Microsoft365 TYPE.
- [ ] AKS cluster backups - Bibhu
- [X] Validate worker node weekly patching schedule and kured restart
- [X] Make sure pipelines are configured correctly - For now WRITE RBAC is given
- [X] CNAMES for certificate domains
- [ ] Move the secrets to the sidecar containers. - Good to have
- [T] kubectl rollout history must reflect the last committed label
- [T] Whitelisting akamai IP in AFD
- [X] Ensure all AFD endpoints are protected from direct access. - Create a ticket on why WAF is not blocking requests with HEADER mismatch.

# Cluster Health Check Checklist
- [X] Cluster Health Check is Conifugred in App Insight.
- [X] Cluster Health is monitored in Grafana.
- [X] Cluster Health Alerts is configured in Grafana.
- [X] Log into each vNet VM and confirm the resource address resolution.
- [X] Browser the loadbalancer ip (https://10.240.20.42) from vNet VM. You should see the valid certificate on browser.
- [X] Verify that load tansfers to secondary when primary cluster is down.
- [X] Verify all pods are running. No failure or restart in the cluster in last 1 hour.


# Application Go-Live Checklist - RISKIQ
- [X] Sign-off from stakeholders
- [X] App Monitoring and alerts in place
- [X] Diagnostics setup on SQL Server
- [X] dB backups 
- [ ] media backups
- [ ] storage account backups in vault
- [X] Geneva monitoring for the enduser URL.
- [ ] Block non-akamai traffic to AFD endpoints.

# Monitoring Checklist
- [X] - Diagnostic settings on AKS, load balancer, and SQL server.
- [X] - Configure AppInsight to monitor the cluster availability.
- [X] - Make sure app monitor is showing outage when app is missing in a cluster.
- [ ] - Make sure alerts are configured for each apps & each cluster.
- [ ] - Alerts are capable to distinguish the environments and applications.

# Security Checklist (Best Practices)
- [ ] (Optional) Make sure image scan in CI/CD pipeline before pushing to ACR
- [X] Make sure image scan is turned on in ACR (to scan vulnerabilities discovered after build) - Defender scan is already there.
- [X] Make sure the container is not running using root (a breach has access to the cluster). Instead use a service account with role bindings.
- [X] Turn off Local Account access on the cluster
- [X] Turn on Role-based access using AAD and K8 Role Bindings
- [ ] (Will be looked into later) Make sure a securitycontext is defined for the POD with least privilege access.
- [X] Define network rules (network policies) in K8 cluster to restrict communication between PODs.
- [ ] (Optional) Use Service Mesh Sidecar (Istio or Open Mesh) to restrict communication between services (note: network policies restrict communication between PODs, not between services) - Optional (this comes with a performance cost)
- [ ] (Optional) Enable TLS between PODs - Optional (this comes with a performance cost)
- [X] Secure contents in K8 Secretes (default encryption is base64 and is not very secure. Ideally you should use 3rd party encryption)
- [X] Secure etcd database in master node (incase of cloud managed K8, master node is taken care by the cloud provider.)
- [X] Protect your application data (Our data is not sensitive. We are using the security provided by cloud. Restricted dB access to a vNet)
- [X] Protect backups (1 months data backup in a separate storage account, and the storage is encrypted and restricted to vNet)
- [X] Enable Security Policy (incase of Azure, its called Azure Policy). It makes sure you have certain security in place. (like POD is not running under root)
- [X] Setup Disaster Recovery (a parallel cluster or a quick plan to restore from backup)

# Automations - To be done
- [ ] Create a K8 job to restore db from storage
- [ ] Create a Cronjob to backup media files once per day
- [ ] Create a Cronjob prune the images in the nodes
- [ ] Create a shell script that would take the deployment name and bash into a POD
- [ ] Script to rotate the AFD monitoring header X-ONECLOUD-SOURCE key (update WAF and app insight monitors)
- [ ] Generate server patching, and restart details from the cluster.


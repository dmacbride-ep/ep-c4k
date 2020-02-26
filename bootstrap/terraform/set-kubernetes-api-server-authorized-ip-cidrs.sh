#!/usr/bin/env bash

# this script is required until they fix a bug in the azurerm Terraform provider which prevents us from enbling
# this feature and cluster autoscaler at the same time

info() {
  echo "INFO: $1"
}

error() {
  echo "ERROR: $1"
  exit 1
}

# check for dependencies
info "checking dependencies"
for prog in echo "az"; do
  which ${prog} &> /dev/null
  [ $? -eq 0 ] || error "need a copy of ${prog} installed for set-kubernetes-api-server-authorized-ip-cidrs.sh"
done

# if azure_k8s_api_server_authorized_ip_ranges isn't set, no config change is needed
if [ "${azure_k8s_api_server_authorized_ip_ranges}" == "" ]; then
  info "azure_k8s_api_server_authorized_ip_ranges isn't set, so no config change is needed in set-kubernetes-api-server-authorized-ip-cidrs.sh"
  exit 0
fi

# login to Azure
info "logging into Azure"
az login --service-principal --tenant ${azure_service_principal_tenant_id} \
  --username ${azure_service_principal_app_id} --password ${azure_service_principal_password} &> /dev/null
[ $? -eq 0 ] || error "failed to login to Azure in set-kubernetes-api-server-authorized-ip-cidrs.sh"

# set the authorized IP CIDRs
# we include the public IP of the load balancer for the AKS cluster as this while be the source address
# for Kubernetes API requests that originate inside the cluster
info "setting the authorized IP ranges for the Kubernetes API"
nodeResourceGroup=$(az aks show --resource-group "${resource_group_name}" --name "${kubernetes_cluster_name}" --query nodeResourceGroup -o tsv)
[ $? -eq 0 ] || error "failed to get the node resource group in set-kubernetes-api-server-authorized-ip-cidrs.sh"

loadBalancerIP=( $(az network public-ip list --resource-group "${nodeResourceGroup}" --query '[].ipAddress' -o tsv) )
[ $? -eq 0 ] || error "failed to get the public IP of the load balancer in set-kubernetes-api-server-authorized-ip-cidrs.sh"
[ "${#loadBalancerIP[@]}" -eq 1 ] || error "expecting only one public IP assigned to the cluster, found: ${loadBalancerIP[*]}"

az aks update --resource-group "${resource_group_name}" --name "${kubernetes_cluster_name}" \
  --api-server-authorized-ip-ranges "${loadBalancerIP[0]}/32,${azure_k8s_api_server_authorized_ip_ranges}"
[ $? -eq 0 ] || error "failed to set the authorized IP ranges in set-kubernetes-api-server-authorized-ip-cidrs.sh"

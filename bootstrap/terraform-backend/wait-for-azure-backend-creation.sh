#!/usr/bin/env bash

# this script is required until they fix a bug in the azurerm Terraform provider which doesn't wait
# until a Storage Account is complete provisioning

info() {
  echo "INFO: $1"
}

error() {
  echo "ERROR: $1"
  exit 1
}

# check for dependencies
info "checking dependencies"
for prog in echo "az jq"; do
  which ${prog} &> /dev/null
  [ $? -eq 0 ] || error "need a copy of ${prog} installed for set-kubernetes-api-server-authorized-ip-cidrs.sh"
done

# login to Azure
info "logging into Azure"
az login --service-principal --tenant ${azure_service_principal_tenant_id} \
  --username ${azure_service_principal_app_id} --password ${azure_service_principal_password} &> /dev/null
[ $? -eq 0 ] || error "failed to login to Azure in set-kubernetes-api-server-authorized-ip-cidrs.sh"

# wait until the Storage Account is provisioned
info "waiting for the Storage Account to be provisioned"
timeoutTime=$(date '+%s' --date='now + 10 minutes')
while [ "$(az storage account show --resource-group "${resource_group_name}" --name "${azure_backend_storage_account_name}" | jq -r '.provisioningState')" != "Succeeded" ]; do
  currentTime="$(date '+%s' --date='now')"
  if [ ${currentTime} -gt ${timeoutTime} ]; then
    error "timeout waiting for the Storage Account to be provisioned"
  fi
  sleep 5
done
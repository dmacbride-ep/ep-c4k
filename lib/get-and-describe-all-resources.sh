#!/usr/bin/env bash

error() {
  echo "ERROR: $1"
  errorOccurred="true"
}

info() {
  echo "INFO: $1"
}

#### MAIN BODY ####

filenamePrefix="$1"
if [ "$filenamePrefix" == "" ]; then
  error "need to provide the filenamePrefix"
fi

info "getting all resources"
kubectl get all --all-namespaces -o yaml > "${filenamePrefix}-all-resources.yaml" || \
  error "couldn't get all the resources"

info "describing all resources"
kubectl describe all --all-namespaces > "${filenamePrefix}-all-resource-descriptions.txt" || \
  error "couldn't describe all the resources"

if [ "${errorOccurred}" == "true" ]; then
  exit 1
fi
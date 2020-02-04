#!/usr/bin/env bash

# this script is based off of: https://www.terraform.io/docs/providers/external/data_source.html#processing-json-in-shell-scripts
# and is required until Azure fixes: https://github.com/terraform-providers/terraform-provider-azurerm/issues/4030

error() {
  echo "ERROR: $1"
  exit 1
}

# check for dependencies
for prog in echo "curl jq grep sed sort tail"; do
  which ${prog} &> /dev/null
  [ $? -eq 0 ] || error "need a copy of ${prog} installed for find-latest-cluster-autoscaler-version.sh"
done

# read input JSON and convert to environment variables
variablesToExtract="kubernetes_version=\(.kubernetes_version)"
eval "$(jq -r "@sh \"${variablesToExtract}\"")"
[ $? -eq 0 ] || error "failed to extract environment variables from input JSON in find-latest-cluster-autoscaler-version.sh"

# this is the latest version of Cluster Autoscaler for the version of Kubernetes being used
cluster_autoscaler_version=$(curl \
--silent https://api.github.com/repos/kubernetes/autoscaler/releases \
| jq -r ".[].tag_name" | grep "^cluster-autoscaler-${kubernetes_version}" \
| grep -v "alpha\|beta" | sed "s/cluster-autoscaler-//g" \
| sort -V | tail -1)
[ "${cluster_autoscaler_version}" != "" ] || error "failed to parse out the latest version of Cluster Autoscaler in find-latest-cluster-autoscaler-version.sh"

# return the result on stdout
jq -n --arg cluster_autoscaler_version "${cluster_autoscaler_version}" '{"cluster_autoscaler_version":$cluster_autoscaler_version}'

#!/usr/bin/bash

# check for dependencies
for prog in echo "curl jq sed"; do
  which ${prog} &> /dev/null
  [ $? -eq 0 ] || error "need a copy of ${prog} installed for $0"
done

#####################################
#
# Functions
#
#####################################

debug() {
  echo "DEBUG: $1"
}

info() {
  echo "INFO: $1"
}

error() {
  echo "ERROR: $1"
  exit 1
}

# $1: regex to use when validating
# $2: error string
# $3: var array to validate
validate_var_array() {
  testRegex=$1
  shift
  errorString=$1
  shift
  varArray=("$@")

  # Check required variables are set
  for varName in ${varArray[*]}; do
    # Use Bash variable indirection
    # https://unix.stackexchange.com/questions/251893/get-environment-variable-by-variable-name
    varValue=${!varName}

    if [[ -z "$varValue" ]]; then
      errorInEnvVarCheck "\$$varName must be set."
    elif ! [[ $varValue =~ $testRegex ]] ; then
      # only log invalid value of env var if it is not secret
      if ! [[ "${doNotLog[*]}" == *"$varName"* ]]; then
        errorInEnvVarCheck "\$$varName ($varValue) $errorString."
      else
        errorInEnvVarCheck "\$$varName $errorString."
      fi
    fi
  done
}

validate_json_or_empty_var_array() {
  errorString=$1
  shift
  varArray=("$@")

  # Check required variables are json strings
  for varName in ${varArray[*]}; do
    # Use Bash variable indirection
    # https://unix.stackexchange.com/questions/251893/get-environment-variable-by-variable-name
    varValue=${!varName}
    if [ ! -z "$varValue" ] && ! jq -n --argjson data "$varValue" '.'; then
      # only log invalid value of env var if it is not secret
      if ! [[ "${doNotLog[*]}" == *"$varName"* ]]; then
        errorInEnvVarCheck "\$$varName ($varValue) $errorString."
      else
        errorInEnvVarCheck "\$$varName $errorString."
      fi
    fi
  done
}

errorInEnvVarCheck() {
  echo "ERROR: $1 ❌" >&2
  errorInEnvVars=true
}

validateEnvVars() {
  errorInEnvVars=false

  ## Supporting regexs
  whitespaceRegEx='[^[[:space:]]*'
  numericRegEx='^[0-9]+$'
  alphanumericRegEx="^[a-zA-Z0-9]+$"
  lowerAlphanumericRegEx="^[a-z0-9]+$"
  # This allows the Azure style db username (<usename>@<hostname>)
  dbUserRegEx="^[a-zA-Z0-9]+(@[a-zA-Z0-9\.]+)?$"
  classNameRegEx='^([a-zA-Z_$][a-zA-Z0-9_$]*\.)*[a-zA-Z_$][a-zA-Z0-9_$]*$'
  # See http url examples here: https://regex101.com/r/WU48Hv/7
  httpURLRegEx='^(((https?):\/\/)?[a-zA-Z0-9_-]+(\.[a-zA-Z0-9_-]+)*\.?(:[0-9]+)?(\/[^[[:space:]]*)?)$'
  # See jdbc url examples here: https://regex101.com/r/0RdOcU/5
  jdbcURLRegEx='^jdbc:[a-zA-z:]+@?(\/\/)?[a-zA-z0-9\.]+(:[0-9]+)?\/?:?[a-zA-Z0-9$_-]+\??[^[:space:]]+$'
  filePathRegEx='^(\/)?([^\/[:space:]]+(\/)?)+$'
  booleanRegEx='^(true|false)$'
  servicePrincipalRegEx='^[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}$'
  servicePrincipalPasswordRegEx="^[a-zA-Z0-9-]+$"
  storageAccountRegEx="^[a-z0-9]{3,24}$"
  domainRegEx='^(([a-zA-Z0-9](-?[a-zA-Z0-9])*)\.)*[a-zA-Z](-?[a-zA-Z0-9])+\.[a-zA-Z]{2,}$'
  wildcardDomainListRegEx='(^\[ *\]$|^\[ *\"(\*\.)?(([a-zA-Z0-9](-?[a-zA-Z0-9])*)\.)*[a-zA-Z](-?[a-zA-Z0-9])+\.[a-zA-Z]{2,}\"(, *\"(\*\.)?(([a-zA-Z0-9](-?[a-zA-Z0-9])*)\.)*[a-zA-Z](-?[a-zA-Z0-9])+\.[a-zA-Z]{2,}\")* *\]$)'
  gitBranchRegEx='^[0-9a-zA-Z_.-]+(\/[0-9a-zA-Z_.-]+)?$'
  versionNumberRegEx='^[0-9]+(\.[0-9]+)*$'
  gitSSHRepoURLRegEx='^[[:alnum:]]+@(([a-zA-Z](-?[a-zA-Z0-9])*)\.)*[a-zA-Z](-?[a-zA-Z0-9])+\.[a-zA-Z]{2,}:(\/)?([^\/[:space:]]+(\/)?)+$'
  azureVMSizeRegEx='^[a-zA-Z0-9]+[a-zA-Z0-9_]*[a-zA-Z0-9]+$'
  allowedCIDRListRegex='^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}(,[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2})*$'
  CIDRRangeRegex='^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$'
  azureK8sAuthorizedIpRangeListRegex='^\[ *"[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}"(,\ ?"[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}")*\ *]$'

  ## Env var validation requirements if the TF_VAR_bootstrap_mode is setup-new-cluster, clean, or show
  notEmpty=( "TF_VAR_bootstrap_mode" "TF_VAR_domain" )
  isDomain=( "TF_VAR_domain" )
  if [ "${TF_VAR_cloud}" == "azure" ]; then
    isNumeric=( "TF_VAR_azure_aks_min_node_count" )
    isAzureVMSize=( "TF_VAR_azure_aks_vm_size" )
  fi

  ## Validation json objects
  isJsonOrEmpty=( "TF_VAR_bootstrap_extras_properties" )

  ## Specify which env vars should not be logged
  doNotLog=( "TF_VAR_azure_service_principal_password" "TF_VAR_ep_repository_password" )

  ## Validate TF_VAR_kubernetes_cluster_name if in setup-new-cluster
  if [ "${TF_VAR_bootstrap_mode}" == "setup-new-cluster" ]; then
    notEmpty+=( "TF_VAR_kubernetes_cluster_name" )
    isAlphnumeric+=( "TF_VAR_kubernetes_cluster_name" )
  fi
  ## There are more env vars to validate if the TF_VAR_bootstrap_mode is setup
  if [ "${TF_VAR_bootstrap_mode}" == "setup" ]; then
    notEmpty+=( "TF_VAR_ep_repository_user" "TF_VAR_ep_repository_password"  "TF_VAR_git_credential_username" "TF_VAR_git_ssh_host_key" "TF_VAR_jenkins_allowed_cidr" \
      "TF_VAR_cloudops_for_kubernetes_repo_url" "TF_VAR_cloudops_for_kubernetes_default_branch" "TF_VAR_ep_commerce_repo_url" "TF_VAR_ep_commerce_default_branch" \
      "TF_VAR_docker_repo_url" "TF_VAR_docker_default_branch" "TF_VAR_nexus_repo_username" "TF_VAR_nexus_repo_password" "TF_VAR_nexus_base_uri" "TF_VAR_oracle_jdk_download_url" \
      "TF_VAR_jdk_folder_name" "TF_VAR_maven_download_url" "TF_VAR_maven_folder_name" "TF_VAR_tomcat_version" "TF_VAR_default_account_management_release_package_url" )
    isAlphanumeric+=( "TF_VAR_ep_repository_user" "TF_VAR_ep_repository_password" "TF_VAR_git_credential_username" "TF_VAR_nexus_repo_username" "TF_VAR_nexus_repo_password" )
    isHTTPURL=( "TF_VAR_nexus_base_uri" "TF_VAR_oracle_jdk_download_url" "TF_VAR_maven_download_url" "TF_VAR_ep_cortex_maven_repo_url" "TF_VAR_ep_commerce_engine_maven_repo_url" \
    "TF_VAR_ep_accelerators_maven_repo_url" "TF_VAR_default_account_management_release_package_url" )
    isFilePath=( "TF_VAR_jdk_folder_name" "TF_VAR_maven_folder_name" )
    isGitBranch=( "TF_VAR_cloudops_for_kubernetes_default_branch" "TF_VAR_ep_commerce_default_branch" "TF_VAR_docker_default_branch" )
    isGitSSHRepoURL=( "TF_VAR_cloudops_for_kubernetes_repo_url" "TF_VAR_ep_commerce_repo_url" "TF_VAR_docker_repo_url" )
    isVersionNumber=( "TF_VAR_tomcat_version" )
    isAllowedCIDRList=( "TF_VAR_jenkins_allowed_cidr" "TF_VAR_nexus_allowed_cidr" )
    isCIDRRange=( "TF_VAR_aws_kubernetes_cluster_vpc_cidr" )
    isBoolean=( "TF_VAR_jenkins_trust_all_certificates" )
    if [ "${TF_VAR_cloud}" == "aws" ]; then
      notEmpty+=( "TF_VAR_aws_access_key_id" "TF_VAR_aws_access_key_id" "TF_VAR_aws_secret_access_key" \
       "TF_VAR_aws_region" "TF_VAR_aws_backend_s3_bucket" "TF_VAR_aws_backend_s3_bucket_key" \
       "TF_VAR_aws_backend_dynamodb_table" )
    elif [ "${TF_VAR_cloud}" == "azure" ]; then
      notEmpty+=( "TF_VAR_azure_subscription_id" "TF_VAR_azure_service_principal_tenant_id" "TF_VAR_azure_service_principal_app_id" \ "TF_VAR_azure_service_principal_password" \ "TF_VAR_azure_aks_vm_size" "TF_VAR_azure_aks_min_node_count" "TF_VAR_azure_location" "TF_VAR_azure_aks_ssh_key" "TF_VAR_azure_k8s_api_server_authorized_ip_ranges" )
      isLowerAlphaNumeric+=( "TF_VAR_azure_resource_group_name" )
      isAlphanumeric+=( "TF_VAR_azure_acr_instance_name" "TF_VAR_azure_backend_blob_name" )
      isServicePrincipal=( "TF_VAR_azure_subscription_id" "TF_VAR_azure_service_principal_tenant_id" "TF_VAR_azure_service_principal_app_id" )
      isServicePrincipalPassword=( "TF_VAR_azure_service_principal_password" )
      isStorageAccount=( "TF_VAR_azure_backend_storage_account_name" )
      isAzureK8sAuthorizedIpRangeList=( "TF_VAR_azure_k8s_api_server_authorized_ip_ranges" )
    else
      error "missing validation step for cloud \"${TF_VAR_cloud}\""
    fi
  fi

  # Validate env vars against regexes
  validate_var_array "$whitespaceRegEx" "must not be empty and must include more than just whitespace" "${notEmpty[@]}"
  validate_var_array "$numericRegEx" "must be an integer" "${isNumeric[@]}"
  validate_var_array "$alphanumericRegEx" "must be alphanumeric" "${isAlphanumeric[@]}"
  validate_var_array "$lowerAlphanumericRegEx" "must be lowercase alphanumeric" "${isLowerAlphaNumeric[@]}"
  validate_var_array "$httpURLRegEx" "must be a valid HTTP URL" "${isHTTPURL[@]}"
  validate_var_array "$booleanRegEx" "must be true or false" "${isBoolean[@]}"
  validate_var_array "$filePathRegEx" "must be a valid file system path" "${isFilePath[@]}"
  validate_var_array "$servicePrincipalRegEx" "must be a correctly formatted Service Principal" "${isServicePrincipal[@]}"
  validate_var_array "$servicePrincipalPasswordRegEx" "must be a correctly formatted Service Principal password" "${isServicePrincipalPassword[@]}"
  validate_var_array "$storageAccountRegEx" "must be a correctly formatted Azure Storage Account" "${isStorageAccount[@]}"
  validate_var_array "$domainRegEx" "must be a correctly formatted, fully qualified domain name" "${isDomain[@]}"
  validate_var_array "$wildcardDomainListRegEx" ""
  validate_var_array "$gitBranchRegEx" "must be a valid git branch" "${isGitBranch[@]}"
  validate_var_array "$gitSSHRepoURLRegEx" "must be a valid git ssh repo url" "${isGitSSHRepoURL[@]}"
  validate_var_array "$versionNumberRegEx" "must be a valid version number" "${isVersionNumber[@]}"
  validate_var_array "$azureVMSizeRegEx" "must be a valid Azure virtual machine size" "${isAzureVMSize[@]}"
  validate_var_array "$allowedCIDRListRegex" "must be a valid IP address CIDR list" "${isAllowedCIDRList[@]}"
  validate_var_array "$CIDRRangeRegex" "must be a valid IP address CIDR range" "${isCIDRRange[@]}"
  validate_var_array "$azureK8sAuthorizedIpRangeListRegex" "must be a valid list of Azure kubernetes allowed IP ranges" "${isAzureK8sAuthorizedIpRangeList[@]}"
  validate_json_or_empty_var_array "must be json or empty" "${isJsonOrEmpty[@]}"

  # validate the value of env vars that can't be checked with regexes
  [ "${TF_VAR_bootstrap_mode}" != "setup" ] && \
    [ "${TF_VAR_bootstrap_mode}" != "cleanup" ] && \
    [ "${TF_VAR_bootstrap_mode}" != "show" ] && \
    [ "${TF_VAR_bootstrap_mode}" != "setup-new-cluster" ] && \
    error "the TF_VAR_bootstrap_mode is not either 'setup', 'setup-new-cluster', 'cleanup', or 'show'"

  if [ "${TF_VAR_cloud}" == "azure" ]; then
  ( echo "${TF_VAR_azure_aks_ssh_key}" | ssh-keygen -l -f /dev/stdin &> /dev/null ) || \
    error "value provided for TF_VAR_azure_aks_ssh_key does not look like an ssh public key"
  fi

  if [ "${TF_VAR_bootstrap_mode}" == "setup" ]; then
    [ -f /root/.ssh/git_id_rsa ] || \
      error "could not find git ssh key at /root/.ssh/git_id_rsa (the key volume mounted at /secrets/git_id_rsa should have been copied to /root/.ssh/git_id_rsa)"
    ( ssh-keygen -l -f /root/.ssh/git_id_rsa &> /dev/null ) || \
      error "key provided at /root/.ssh/git_id_rsa does not look like a ssh private key"
  fi

  # if we are passed a cert verify it is valid
  if [ "${TF_VAR_bootstrap_mode}" == "setup" ] || [ "${TF_VAR_bootstrap_mode}" == "setup-new-cluster" ]; then
    if [ -f /secrets/haproxy_default_cert.crt ] && [ -f /secrets/haproxy_default_cert.key ]; then
      certModulus=$(openssl x509 -noout -modulus -in /secrets/haproxy_default_cert.crt) || error "cert provided at /secrets/haproxy_default_cert.crt is not valid"
      keyModulus=$(openssl rsa -noout -modulus -in /secrets/haproxy_default_cert.key) || error "key provided at /secrets/haproxy_default_cert.key is not valid"

      if [ "${certModulus}" != "${keyModulus}" ]; then
        error "cert or key provided at /secrets/haproxy_default_cert.crt or /secrets/haproxy_default.cert_key are not a valid https certificate"
      fi
    fi
  fi

  if [ "${errorInEnvVars}" == "true" ]; then
    error "problems found with env vars. Exiting."
  fi
}

validateEnvVars

#!/usr/bin/env bash

#####################################
#
# Constants
#
#####################################

# this is the major and minor version of Kubernetes to run in the Kubernetes cluster
# the latest sub-minor version will be found and used
export TF_VAR_kubernetes_version='1.14'

# this makes the output of Terraform less noisy.
# for details on what this does: https://learn.hashicorp.com/terraform/development/running-terraform-in-automation#controlling-terraform-output-in-automation
export TF_IN_AUTOMATION="true"

# this prevents Terraform for asking for variabel values
export TF_INPUT=0

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

warning() {
  echo "WARNING: $1"
}

error() {
  echo "ERROR: $1"
  exit 1
}

prepareSSHKey() {
  info "preparing the ssh key"

  info "copying the git private key out of the mounted volume, and updating it's file permissions"
  mkdir -p /root/.ssh
  cp /secrets/git_id_rsa /root/.ssh/ || error "could not find git ssh key at /secrets/git_id_rsa"
  chmod 600 /root/.ssh/git_id_rsa

  info "done preparing the ssh key"
}

prepareTerraform() {
  info "preparing Terraform"

  if [ "${TF_VAR_cloud}" == "aws" ]; then
    cat > /root/bootstrap/terraform/backend.tf <<ENDOFHEREDOC
terraform {
  backend "s3" {
    bucket         = "${TF_VAR_aws_backend_s3_bucket}"
    key            = "${TF_VAR_aws_backend_s3_bucket_key}"
    dynamodb_table = "${TF_VAR_aws_backend_dynamodb_table}"
    region         = "${TF_VAR_aws_region}"

    access_key = "${TF_VAR_aws_access_key_id}"
    secret_key = "${TF_VAR_aws_secret_access_key}"
  }
}
ENDOFHEREDOC
  elif [ "${TF_VAR_cloud}" == "azure" ]; then
    debug "creating /root/bootstrap/terraform/backend.tf"
    cat > /root/bootstrap/terraform/backend.tf <<ENDOFHEREDOC
terraform {
  backend "azurerm" {
    subscription_id = "${TF_VAR_azure_subscription_id}"
    tenant_id       = "${TF_VAR_azure_service_principal_tenant_id}"
    client_id       = "${TF_VAR_azure_service_principal_app_id}"
    client_secret   = "${TF_VAR_azure_service_principal_password}"

    resource_group_name = "${TF_VAR_azure_resource_group_name}"

    storage_account_name = "${TF_VAR_azure_backend_storage_account_name}"
    container_name       = "${TF_VAR_azure_backend_container_name}"
    key                  = "${TF_VAR_azure_backend_blob_name}"
  }
}
ENDOFHEREDOC
  else
    error "preparing Terraform for cloud ${TF_VAR_cloud} is unsupported"
  fi
  info "done preparing Terraform"
}

prepareAWSCredentialsFile() {
  info "preparing the AWS credentials file"

  mkdir -p ~/.aws/
  cat > ~/.aws/credentials <<ENDOFHEREDOC
[default]
aws_access_key_id = ${TF_VAR_aws_access_key_id}
aws_secret_access_key = ${TF_VAR_aws_secret_access_key}
ENDOFHEREDOC

  info "done preparing the AWS credentials file"
}

loginToCloud() {
  info "logging into cloud"

  if [ "${TF_VAR_cloud}" == "aws" ]; then
    prepareAWSCredentialsFile
  elif [ "${TF_VAR_cloud}" == "azure" ]; then
    info "separate cloud credentials not required for Azure"
  else
    error "loginToCloud unimplemented for cloud ${TF_VAR_cloud}"
  fi

  info "done logging into cloud"
}

initializeTerraformForBackendManagement() {
  info "initializing Terraform"
  terraform init -input=false \
    || error "could not initialize Terraform local backend"

  info "importing Terraform resources (if they exist)"
  if [ "${TF_VAR_cloud}" == "aws" ]; then
    terraform import 'aws_s3_bucket.terraform_backend[0]' ${TF_VAR_aws_backend_s3_bucket}
    terraform import 'aws_dynamodb_table.terraform_backend[0]' ${TF_VAR_aws_backend_dynamodb_table}
  elif [ "${TF_VAR_cloud}" == "azure" ]; then
    terraform import 'azurerm_storage_account.terraform_backend[0]' "/subscriptions/${TF_VAR_azure_subscription_id}/resourceGroups/${TF_VAR_azure_resource_group_name}/providers/Microsoft.Storage/storageAccounts/${TF_VAR_azure_backend_storage_account_name}"
    terraform import 'azurerm_storage_container.terraform_backend[0]' "https://${TF_VAR_azure_backend_storage_account_name}.blob.core.windows.net/${TF_VAR_azure_backend_container_name}"
  else
    error "importing Terraform resources for cloud ${TF_VAR_cloud} not supported in initializeTerraformForBackendManagement"
  fi
}

createTerraformBackend() {
  info "creating the Terraform backend (if needed)"

  cd /root/bootstrap/terraform-backend \
    || error "Terraform backend code does not exist"

  initializeTerraformForBackendManagement

  info "planning Terraform config (for the backend)"
  terraform plan -input=false \
    || error "failed to plan backend for Terraform"

  info "applying Terraform config (for the backend)"
  terraform apply -auto-approve -input=false \
    || error "failed to create backend for Terraform"

  info "Terraform backend creation complete"
}

destroyTerraformBackend() {
  info "destroying the Terraform backend"

  cd /root/bootstrap/terraform-backend \
    || error "Terraform backend code does not exist"

  # the azurerm provider seems to have a couple bugs related to Azure Storage:
  # * it tries to delete the storage account without deleting the storage container first
  # * it claims that a storage account has failed to delete when it successfully deletes
  # to work around these bugs, we use the Azure CLI to delete the backend intead
  if [ "${TF_VAR_cloud}" == "azure" ]; then
    info "logging into Azure"
    az login --service-principal --tenant "${TF_VAR_azure_service_principal_tenant_id}" --username "${TF_VAR_azure_service_principal_app_id}" --password "${TF_VAR_azure_service_principal_password}" \
      || error "failed to login to Azure"

    info "destroying Terraform backend (using Azure CLI)"
    az storage account delete --resource-group "${TF_VAR_azure_resource_group_name}" --name "${TF_VAR_azure_backend_storage_account_name}" --yes \
      || error "failed to destroy the backend for Terraform (just the storage account)"
  else
    info "destroying Terraform backend (using Terraform)"
    terraform destroy -auto-approve -input=false \
      || error "failed to destroy the backend for Terraform"
  fi

  info "destroying the Terraform backend complete"
}

createEKSCluster() {
  info "creating the EKS cluster (if needed)"

  # check if the cluster exists
  eksctl get cluster \
    --name ${TF_VAR_kubernetes_cluster_name} \
    --region ${TF_VAR_aws_region} \
    --timeout=10m
  if [ $? -eq 0 ]; then
    info "EKS cluster already exists"
  else
    info "EKS cluster doesn't already exist"
    mo --fail-not-set /root/bootstrap/eksctl.yaml.mo-template > /root/bootstrap/eksctl.yaml \
      || error "could not detemplatize the eksctl.yaml file"
    warning "creating the EKS cluster will take about 10-30 minutes with no output displayed"

    if [ "${TF_VAR_aws_region}" == "us-east-1" ]; then
      export aws_region_us_east_1=true
    else
      export aws_region_us_east_1=false
    fi
    eksctl create cluster \
      --config-file=/root/bootstrap/eksctl.yaml \
      --timeout=120m \
      || error "could not create EKS cluster"
  fi

  info "done creating the EKS cluster (if needed)"
}

deleteEKSCluster() {
  info "deleting the EKS cluster (if needed)"

  eksctl get cluster \
    --name ${TF_VAR_kubernetes_cluster_name} \
    --region ${TF_VAR_aws_region} \
    --timeout=10m
  if [ $? -eq 0 ]; then
    info "EKS cluster exists"
    mo --fail-not-set /root/bootstrap/eksctl.yaml.mo-template > /root/bootstrap/eksctl.yaml \
      || error "could not detemplatize the eksctl.yaml file"
    eksctl delete cluster \
      --wait \
      --config-file=/root/bootstrap/eksctl.yaml \
      --timeout=60m \
      || error "failed to delete EKS cluster"
  else
    info "EKS cluster doesn't exist"
  fi

  info "done deleting the EKS cluster (if needed)"
}

setupKubeConfigFile() {
  info "setting up the ~/.kube/config file"

  if [ "${TF_VAR_cloud}" == "aws" ]; then
    eksctl get cluster \
      --name ${TF_VAR_kubernetes_cluster_name} \
      --region ${TF_VAR_aws_region} \
      --timeout=10m
    if [ $? -ne 0 ]; then
      info "EKS cluster does not exist"
      if [ "${TF_VAR_bootstrap_mode}" == "setup" ]; then
        error "could not find the EKS cluster in setupKubeConfigFile"
      elif [ "${TF_VAR_bootstrap_mode}" == "cleanup" ]; then
        # if the EKS cluster doesn't exist in cleanup mode, the bootstrap Terraform workspace has already had
        # everything inside it deleted, the bootstrap workspace has been deleted, and all that remains is deleting
        # the backend for AWS. Under these conditions, a non-existent EKS cluster is ok.
        return
      else
        error "setupKubeConfigFile cannot handle non-existent EKS cluster in bootstrap mode ${TF_VAR_bootstrap_mode}"
      fi
    fi

    eksctl utils write-kubeconfig \
      --cluster ${TF_VAR_kubernetes_cluster_name} \
      --region ${TF_VAR_aws_region} \
      --timeout=10m \
      || error "could not create ~/.kube/config file for EKS cluster"
  elif [ "${TF_VAR_cloud}" == "azure" ]; then
    info "setting up the ~/.kube/config file unneccesary for Azure (as Kubernetes credentials are managed inside Terraform)."
  else
    error "cloud ${TF_VAR_cloud} unsupported in setupKubeConfigFile"
  fi

  info "done setting up the ~/.kube/config file"
}

setupResources() {
  info "setting up resources"

  cd /root/bootstrap/terraform \
    || error "Terraform code does not exist"

  info "initializing Terraform"
  terraform init -input=false -reconfigure \
    || error "could not initialize Terraform"

  info "switching to bootstrap workspace"
  terraform workspace select bootstrap \
    || terraform workspace new bootstrap \
    || error "failed to create and/or select bootstrap workspace"

  info "validate terraform variables"
  terraform apply -target=null_resource.variableValidation \
    -auto-approve -input=false \
    || error "failed to create and validated Terraform environment variables (for most of the resources)"

  if [ "${TF_VAR_cloud}" == "aws" ]; then
    createEKSCluster
  elif [ "${TF_VAR_cloud}" == "azure" ]; then
    info "creating Kubernetes cluster in Azure is done within Terraform"
  else
    error "creating Kubernetes clusters in cloud ${TF_VAR_cloud} is unsupported"
  fi

  setupKubeConfigFile

  info "plan changes (for most of the resources)"
  terraform plan -input=false \
    || error "failed to plan Terraform based resources (for most of the resources)"

  info "apply changes (for most of the resources)"
  terraform apply -auto-approve -input=false \
    || error "failed to create Terraform based resources (for most of the resources)"

  info "done setting up resources"
}

showResources() {
  info "show the created resources"

  if [ "${TF_VAR_cloud}" == "aws" ]; then
    info "showing the eks cluster"
    eksctl get cluster \
      --name ${TF_VAR_kubernetes_cluster_name} \
      --region ${TF_VAR_aws_region} \
      --timeout=10m
  fi

  cd /root/bootstrap/terraform \
    || error "Terraform code does not exist"

  info "initializing Terraform"
  terraform init -input=false \
    || error "could not initialize Terraform"

  info "showing the outputs of the bootstrap workspace"
  terraform workspace select bootstrap \
    || error "could not switch to the bootstrap workspace"
  terraform output -json

  info "done showing the created resources"
}

cleanupResources() {
  info "cleaning up resources"

  setupKubeConfigFile

  cd /root/bootstrap/terraform \
    || error "could not switch to bootstrap Terraform code directory"
  terraform init -input=false \
    || error "failed to initialize Terraform in the /root/bootstrap/terraform directory"

  # if workspaces other than bootstrap and default exist, fail
  # any extra workspaces (and the resources they track) need to be removed beforehand
  # to ensure that they've been removed before we delete the Kubernetes cluster
  tfWorkspaceList=$(terraform workspace list | tr -d ' *' | sed '/^$/d')
  if [ "$(echo "${tfWorkspaceList}" | grep -E -v '^bootstrap$|^default$')" != "" ]; then
    error "Terraform workspaces other than bootstrap and default exist. Resources in these workspaces and the workspaces themselves will need to be removed and the Terraform state corrected before retrying. Workspaces: ${tfWorkspaceList}"
  fi

  # if the default workspace is not empty, fail
  # if there are resources in the default workspace, we don't know how they were created
  # as a result, we take a position of safety and don't delete anything else
  terraform workspace select default \
    || error "failed to switch to the default workspace"
  if [ "$(terraform state list 2> /dev/null)" != "" ]; then
    error "default workspace is not empty"
  fi

  # `terraform destroy` everything in the bootstrap workspace
  # and the workspace itself (if the bootstrap workspace exists)
  if [ "$(terraform workspace list | tr -d ' *' | grep -E '^bootstrap$')" == "bootstrap" ]; then
    info "destroying everything in the bootstrap workspace"
    terraform workspace select bootstrap \
      || error "failed to switch to the bootstrap workspace"
    terraform destroy -auto-approve -input=false \
      || error "failed to destroy Terraform resources in the bootstrap workspace"

    # if the bootstrap workspace is empty, delete it, otherwise fail
    if [ "$(terraform state list 2> /dev/null)" == "" ]; then
      info "deleting the bootstrap workspace"
      terraform workspace select default \
        || error "failed to switch to the default workspace"
      terraform workspace delete bootstrap \
        || error "failed to delete workspace bootstrap"
    else
      error "workspace bootstrap is not empty"
    fi
  fi
  # destroy the Kubernetes cluster
  if [ "${TF_VAR_cloud}" == "aws" ]; then
    deleteEKSCluster
  elif [ "${TF_VAR_cloud}" == "azure" ]; then
    info "destroying the Kubernetes cluster in Azure is done within Terraform"
  else
    error "destroying Kubernetes clusters in cloud ${TF_VAR_cloud} is unsupported"
  fi

  info "done cleaning up resources"
}

createTerraformFiles() {
  info "creating Terraform files"

  # make sure that the volume mapping was set
  [ -d "/localcode" ] || error "need to volume map local copy of cloudops-for-kubernetes code to /localcode"

  # make sure that the volume mapped directory looks like the cloudops-for-kubernetes repo
  for dirToCheck in bootstrap bootstrap/terraform bootstrap/terraform-backend terraform; do
    [ -d "/localcode/${dirToCheck}" ] || error "volume mapped directory does not contain ${dirToCheck} directory"
  done

  # copy or generate backend config
  cp /root/bootstrap/terraform/backend.tf /localcode/bootstrap/terraform/backend.tf || \
    error "failed to copy backend.tf into bootstrap/terraform directory"
  cp /root/bootstrap/terraform/backend.tf /localcode/terraform/ || \
    error "failed to copy backend.tf into terraform directory"

  # generate bootstrap.tfvars file
  env | grep '^[[:space:]]*TF_VAR_' \
      | sed -E 's|^[[:space:]]*TF_VAR_([a-zA-Z0-9_-]+)=(.*)$|\1 = "\2"|g' \
      | sed -E 's|^azure_k8s_api_server_authorized_ip_ranges = "(.*)"$|azure_k8s_api_server_authorized_ip_ranges = \1|g' \
      | sed -E 's|^additional_ecr_repos = "(.*)"$|additional_ecr_repos = \1|g' \
      | sed -E 's|^self_signed_cert_sans = "(.*)"$|self_signed_cert_sans = \1|g' \
      | sort > /localcode/bootstrap/terraform/bootstrap.tfvars || \
    error "failed to generate bootstrap/terraform/bootstrap.tfvars"

  # generate credentials.tfvars file
  if [ "${TF_VAR_cloud}" == "aws" ]; then
    cat > "/localcode/terraform/credentials.tfvars" <<ENDOFFILE
cloud                      = "aws"
aws_access_key_id          = "${TF_VAR_aws_access_key_id}"
aws_secret_access_key      = "${TF_VAR_aws_secret_access_key}"
aws_region                 = "${TF_VAR_aws_region}"
aws_backend_s3_bucket      = "${TF_VAR_aws_backend_s3_bucket}"
aws_backend_s3_bucket_key  = "${TF_VAR_aws_backend_s3_bucket_key}"
aws_backend_dynamodb_table = "${TF_VAR_aws_backend_dynamodb_table}"
ENDOFFILE
  elif [ "${TF_VAR_cloud}" == "azure" ]; then
    cat > "/localcode/terraform/credentials.tfvars" <<ENDOFFILE
cloud = "azure"

azure_subscription_id             = "${TF_VAR_azure_subscription_id}"
azure_service_principal_tenant_id = "${TF_VAR_azure_service_principal_tenant_id}"
azure_service_principal_app_id    = "${TF_VAR_azure_service_principal_app_id}"
azure_service_principal_password  = "${TF_VAR_azure_service_principal_password}"

azure_resource_group_name = "${TF_VAR_azure_resource_group_name}"

azure_backend_storage_account_name = "${TF_VAR_azure_backend_storage_account_name}"
azure_backend_container_name       = "${TF_VAR_azure_backend_container_name}"
azure_backend_blob_name            = "${TF_VAR_azure_backend_blob_name}"
ENDOFFILE
  else
    error "unknown cloud when generating credentials.tfvars"
  fi

  info "done creating Terraform files"
}

setupNewCluster() {
  error "setupNewCluster has not been implemented yet"
}

#####################################
#
# Main body
#
#####################################

info "starting bootstrap"

info "bootstrap mode is ${TF_VAR_bootstrap_mode}"

prepareSSHKey
prepareTerraform

if [ "${TF_VAR_bootstrap_mode}" == "create-terraform-files" ]; then
  createTerraformFiles
  exit 0
fi

loginToCloud
createTerraformBackend

# begin setup/cleanup/show
if [ "${TF_VAR_bootstrap_mode}" == "setup" ]; then
  setupResources
elif [ "${TF_VAR_bootstrap_mode}" == "show" ]; then
  showResources
elif [ "${TF_VAR_bootstrap_mode}" == "setup-new-cluster" ]; then
  setupNewCluster
elif [ "${TF_VAR_bootstrap_mode}" == "cleanup" ]; then
  cleanupResources
  destroyTerraformBackend
else
  error "unknown bootstrap mode"
fi

info "bootstrap complete"

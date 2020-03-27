import java.time.LocalDateTime
import groovy.lang.Binding

// values that we use across the Jenkinsfiles
secretsDirectory = new File("/secret/jenkins-secrets").exists() ? new File("/secret/jenkins-secrets") : new File("/var/jenkins_secrets");
cloud = new File(secretsDirectory, "cloud").exists() ? new File(secretsDirectory, "cloud").text.trim() : "azure";
kubernetesClusterName = new File(secretsDirectory, "kubernetesClusterName").text.trim();

azureSubscriptionId = new File(secretsDirectory, "azureSubscriptionId").text.trim();
azureServicePrincipalTenantId = new File(secretsDirectory, "azureServicePrincipalTenantId").text.trim();
azureServicePrincipalAppId = new File(secretsDirectory, "azureServicePrincipalAppId").text.trim();
azureServicePrincipalPassword = new File(secretsDirectory, "azureServicePrincipalPassword").text.trim();
resourceGroupName = new File(secretsDirectory, "resourceGroupName").text.trim();
azureBackendStorageAccountName = new File(secretsDirectory, "azureBackendStorageAccountName").text.trim();
azureBackendContainerName = new File(secretsDirectory, "azureBackendContainerName").text.trim();
azureBackendBlobName = new File(secretsDirectory, "azureBackendBlobName").text.trim();

awsRegion = new File(secretsDirectory, "awsRegion").text.trim();
awsAccessKeyId = new File(secretsDirectory, "awsAccessKeyId").text.trim();
awsSecretAccessKey = new File(secretsDirectory, "awsSecretAccessKey").text.trim();
awsBackendS3Bucket = new File(secretsDirectory, "awsBackendS3Bucket").text.trim();
awsBackendS3BucketKey = new File(secretsDirectory, "awsBackendS3BucketKey").text.trim();
awsBackendDynamoDBTable = new File(secretsDirectory, "awsBackendDynamoDBTable").text.trim();

dockerRegistryAddress = new File(secretsDirectory, "dockerRegistryAddress").text.trim();
nexusRepoUsername = new File(secretsDirectory, "nexusRepoUsername").text.trim();
nexusRepoPassword = new File(secretsDirectory, "nexusRepoPassword").text.trim();
nexusBaseUri = new File(secretsDirectory, "nexusBaseUri").text.trim();

TF_PLAN_OUT_FILE = "tfplan"

def gitShallowClone(String gitUrl, String gitRef, String gitCredentialId) {
	return checkout([
		poll: false,
		scm: [
			$class: 'GitSCM',
			branches: [[name: gitRef]],
			doGenerateSubmoduleConfigurations: false,
			extensions: [[$class: 'CloneOption', depth: 10, noTags: true, reference: '', shallow: true]],
			submoduleCfg: [],
			userRemoteConfigs: [[credentialsId: gitCredentialId, url: gitUrl]]
		]
	])
}

// functions that we use across the Jenkinsfiles
def loginToDockerRegistry() {
  if(cloud.equals("azure")) {
    labelledShell label: 'Login to the Docker Registry', script: """set +x
      cat /jenkins-secrets/dockerRegistryPassword | img login --username \$(cat /jenkins-secrets/dockerRegistryUsername) --password-stdin \$(cat /jenkins-secrets/dockerRegistryAddress)
    """
  } else if(cloud.equals("aws")) {
    loginToAWS()
    labelledShell label: 'Login to the Docker Registry', script: """set +x
      eval \$(aws ecr get-login --no-include-email | sed 's/docker login/img login/')
    """
  }
  else {
    error "Login to Docker Registry for cloud ${cloud} unimplemented."
  }
}

def loginToKubernetesCluster(String nameOfCluster) {
  if(cloud.equals("azure")) {
    loginToKubernetesCluster(resourceGroupName, nameOfCluster)
  } else if(cloud.equals("aws")) {
    labelledShell(label: 'Login to the Kubernetes cluster', script: """
      eksctl utils write-kubeconfig --region "${awsRegion}" --name "${nameOfCluster}"
    """)
  } else {
    throw new Exception("loginToKubernetesCluster(String nameOfCluster) unimplmented for cloud " + cloud)
  }
}

def loginToKubernetesCluster(String resourceGroupOfCluster, String nameOfCluster) {
  if(cloud.equals("azure")) {
    labelledShell(label: 'Login to the Kubernetes cluster', script: """
      for I in \$(seq 1 10); do
        failLogin=false
        az aks get-credentials --overwrite-existing --resource-group "${resourceGroupOfCluster}" --name "${nameOfCluster}" || failLogin=true
        if [ \$failLogin != true ]; then
          exit 0
        fi
        sleep 1
      done
      exit 1
    """)
  } else {
    throw new Exception("loginToKubernetesCluster(String resourceGroupOfCluster, String nameOfCluster) unimplmented for cloud " + cloud)
  }
}

def loginToCloud() {
  if(cloud.equals("azure")) {
    loginToAzure()
  } else if(cloud.equals("aws")) {
    loginToAWS()
  } else {
    throw new Exception("cloud " + cloud + " unsupported")
  }
}

def loginToAWS() {
  labelledShell label: 'Login to AWS', script: """
    # don't show the credentials in the Jenkins logs
    set +x
    mkdir -p ~/.aws
    chmod 700 ~/.aws

    echo "[default]" > ~/.aws/config
    echo "region = ${awsRegion}" >> ~/.aws/config
    chmod 600 ~/.aws/config

    echo "[default]" > ~/.aws/credentials
    echo "aws_access_key_id = ${awsAccessKeyId}" >> ~/.aws/credentials
    echo "aws_secret_access_key = ${awsSecretAccessKey}" >> ~/.aws/credentials
    chmod 600 ~/.aws/credentials
    set -x
  """
}

def loginToAzure() {
  labelledShell label: 'Login to Azure', script: """
    # don't show the credentials in the Jenkins logs
    set +x
    az login --service-principal \
      --tenant "${azureServicePrincipalTenantId}" \
      --username "${azureServicePrincipalAppId}" \
      --password "${azureServicePrincipalPassword}"
    set -x
  """
}

def loginToBootstrappedCloud() {
  if(cloud.equals("azure")) {
    loginToBootstrappedAzure()
  } else if(cloud.equals("aws")) {
    loginToBootstrappedAWS()
  } else {
    throw new Exception("cloud " + cloud + " unsupported")
  }
}

def loginToBootstrappedAzure() {
  labelledShell label: 'Login to Azure', script: """
    # don't show the credentials in the Jenkins logs
    set +x
    az login --service-principal \
      --tenant "${params.azureServicePrincipalTenantId}" \
      --username "${params.azureServicePrincipalAppId}" \
      --password "${params.azureServicePrincipalPassword}"
    set -x
  """
}

def loginToBootstrappedAWS() {
  labelledShell label: 'Login to AWS', script: """
    # don't show the credentials in the Jenkins logs
    set +x
    mkdir -p ~/.aws
    chmod 700 ~/.aws

    echo "[default]" > ~/.aws/config
    echo "region = ${params.region}" >> ~/.aws/config
    chmod 600 ~/.aws/config

    echo "[default]" > ~/.aws/credentials
    echo "aws_access_key_id = ${params.awsAccessKeyId}" >> ~/.aws/credentials
    echo "aws_secret_access_key = ${params.awsSecretAccessKey}" >> ~/.aws/credentials
    chmod 600 ~/.aws/credentials
    set -x
  """
}

def loginToTerraform() {
  labelledShell label: 'Populate credentials.tf file', script: """
    cat > "./credentials.tf" <<ENDOFFILE
variable "cloud" {
  type    = string
  default = "${cloud}"
}

variable "aws_access_key_id" {
  type    = string
  default = "${awsAccessKeyId}"
}

variable "aws_secret_access_key" {
  type    = string
  default = "${awsSecretAccessKey}"
}

variable "aws_region" {
  type    = string
  default = "${awsRegion}"
}

variable "aws_backend_s3_bucket" {
  type    = string
  default = "${awsBackendS3Bucket}"
}

variable "aws_backend_s3_bucket_key" {
  type    = string
  default = "${awsBackendS3BucketKey}"
}

variable "aws_backend_dynamodb_table" {
  type    = string
  default = "${awsBackendDynamoDBTable}"
}

variable "azure_subscription_id" {
  type    = string
  default = "${azureSubscriptionId}"
}

variable "azure_service_principal_tenant_id" {
  type    = string
  default = "${azureServicePrincipalTenantId}"
}

variable "azure_service_principal_app_id" {
  type    = string
  default = "${azureServicePrincipalAppId}"
}

variable "azure_service_principal_password" {
  type    = string
  default = "${azureServicePrincipalPassword}"
}

variable "azure_resource_group_name" {
  type    = string
  default = "${resourceGroupName}"
}

variable "azure_backend_storage_account_name" {
  type    = string
  default = "${azureBackendStorageAccountName}"
}

variable "azure_backend_container_name" {
  type    = string
  default = "${azureBackendContainerName}"
}

variable "azure_backend_blob_name" {
  type    = string
  default = "${azureBackendBlobName}"
}
ENDOFFILE
      """
  if(cloud.equals("aws")) {
    labelledShell label: 'Populate backend.tf file', script: """
    cat > "./backend.tf" <<ENDOFFILE
terraform {
  backend "s3" {
    bucket         = "${awsBackendS3Bucket}"
    key            = "${awsBackendS3BucketKey}"
    dynamodb_table = "${awsBackendDynamoDBTable}"
    region         = "${awsRegion}"
    access_key     = "${awsAccessKeyId}"
    secret_key     = "${awsSecretAccessKey}"
  }
}
ENDOFFILE
      """
  } else if(cloud.equals("azure")) {
    labelledShell label: 'Populate backend.tf file', script: """
      cat > "./backend.tf" <<ENDOFFILE
terraform {
  backend "azurerm" {
    subscription_id      = "${azureSubscriptionId}"
    tenant_id            = "${azureServicePrincipalTenantId}"
    client_id            = "${azureServicePrincipalAppId}"
    client_secret        = "${azureServicePrincipalPassword}"
    resource_group_name  = "${resourceGroupName}"
    storage_account_name = "${azureBackendStorageAccountName}"
    container_name       = "${azureBackendContainerName}"
    key                  = "${azureBackendBlobName}"
  }
}
ENDOFFILE
      """
  }
}

List getTerraformWorkspaceNames() {
  List terraformWorkspaceNames = labelledShell(label: 'Get Terraform workspace names', returnStdout: true, script: """
    terraform workspace list | tr -d ' *' | tr '\n' ' '
    """).trim().split(' ');
  return terraformWorkspaceNames
}

List getKubernetesNamespaceNames() {
  List namespaceNames = labelledShell(label: 'Get Kubernetes Namespace names', returnStdout: true, script: """
    kubectl get ns -o 'jsonpath={.items[*].metadata.name}'
    """).trim().split(' ');
  return namespaceNames
}

String generateTerraformWorkspaceName(String clusterName, String kubernetesNamespace, String directory, String instanceName) {
  return generateTerraformWorkspaceName(clusterName, kubernetesNamespace, directory) + ".instance.${instanceName}"
}

String generateTerraformWorkspaceName(String clusterName, String kubernetesNamespace, String directory) {
  return "cluster.${clusterName}.namespace.${kubernetesNamespace}.directory.${directory}"
}

// this ensures that:
// 1. if the Terraform workspace doesn't exist, that it is created
// 2. if the Kubernetes Namespace doesn't exist, that it is created
def createTerraformWorkspaceAndKubernetesNamespace(String terraformWorkspaceName, String kubernetesNamespace) {
  labelledShell(label: 'Initialize Terraform', script: """
    terraform init -reconfigure -get-plugins=false
  """)
  List terraformWorkspaceNameList = getTerraformWorkspaceNames()
  if(terraformWorkspaceNameList.indexOf(terraformWorkspaceName) == -1) {
    labelledShell(label: 'Creating Terraform Workspace', script: """
      terraform workspace new "${terraformWorkspaceName}"
    """)
  }
  List namespaceNames = getKubernetesNamespaceNames()
  if(namespaceNames.indexOf(kubernetesNamespace) == -1) {
    labelledShell(label: 'Creating the Kubernetes Namespace', script: """
      kubectl create ns "${kubernetesNamespace}"
      """)
  }
}

// this ensures that if the Terraform workspace is empty:
// 1. that the Terraform workspace is deleted
// 2. that the Kubernetes Namespace is deleted
// for the parameters passed,
def deleteTerraformWorkspaceAndKubernetesNamespace(String terraformWorkspaceName, String kubernetesNamespace) {
  labelledShell(label: 'Initialize Terraform', script: """
    terraform init -reconfigure -get-plugins=false
  """)
  List terraformWorkspaceNameList = getTerraformWorkspaceNames()
  if(terraformWorkspaceNameList.indexOf(terraformWorkspaceName) >= 0) {
    labelledShell(label: 'Selecting Terraform Workspace', script: """#!/bin/bash
      terraform workspace select "${terraformWorkspaceName}"
    """)
    String terraformStateLength = labelledShell(label: 'Get Terraform state length', returnStdout: true, script: """
      terraform show -json | jq '.values.root_module.resources | length'
      """).trim();
    if(terraformStateLength.equals("0")) {
      labelledShell(label: 'Deleting Terraform Workspace', script: """#!/bin/bash
        terraform workspace select default
        terraform workspace delete "${terraformWorkspaceName}"
      """)
    }
  }
  List namespaceNames = getKubernetesNamespaceNames()
  if(namespaceNames.indexOf(kubernetesNamespace) >= 0) {
    String numOfKubernetesResourcesInNamespace = labelledShell(label: 'Get number of Kubernetes resources in Namespace', returnStdout: true, script: """
      kubectl get deployments,services,ingresses,configmaps,secrets,persistentvolumeclaims -n "${kubernetesNamespace}" -o json | jq '.items | map(select( .type != "kubernetes.io/service-account-token" )) | length'
      """).trim();
    if(numOfKubernetesResourcesInNamespace.equals("0")) {
      labelledShell(label: 'Deleting the Kubernetes Namespace', script: """
        kubectl delete ns "${kubernetesNamespace}"
        """)
    }
  }
}

String getJenkinsDescription(Boolean isDestroyMode) {
  String jenkinsBuildDescription = null
  if(isDestroyMode) {
    jenkinsBuildDescription = "Destroy"
  } else {
    jenkinsBuildDescription = "Apply"
  }

  String rebuildString = ""
  List rebuilds =
    currentBuild.getBuildCauses().findAll {   it._class == 'com.sonyericsson.rebuild.RebuildCause' \
                                           && it.upstreamProject == currentBuild.fullProjectName }
  if (rebuilds.size() > 0) {
    rebuildString = "\nRebuilds #" + rebuilds[0].upstreamBuild
  }

  return jenkinsBuildDescription + rebuildString
}

// Get the terraform command to use for the desired behaviour
String getTerraformCommand(Boolean isDestroyMode, Boolean isPlanMode) {
  if(isDestroyMode && isPlanMode) {
    return "plan -destroy"
  } else if(isDestroyMode) {
    return "destroy"
  } else if(! isPlanMode) {
    return "apply"
  } else {
    return "plan"
  }
}

// Get the parameters to pass to the terraform command
String getTerraformParams(Boolean isDestroyMode, Boolean isPlanMode) {
  if(isDestroyMode || ! isPlanMode) {
    return ""
  } else {
    return TF_PLAN_OUT_FILE
  }
}

String getTfPlanOutFile() {
  return TF_PLAN_OUT_FILE
}

// the line below is required because of a quirk in how Jenkins + Groovy handles dynamically loaded code
return this

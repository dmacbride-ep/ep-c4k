resource "kubernetes_secret" "jenkins-secrets" {
  count      = terraform.workspace == "bootstrap" ? 1 : 0
  depends_on = [azurerm_kubernetes_cluster.hub]

  metadata {
    name = "jenkins-secrets"
  }

  data = {
    # Cloud Agnostic
    "cloud"                 = "${var.cloud}"
    "kubernetesClusterName" = "${var.kubernetes_cluster_name}"

    # AWS
    "awsRegion"          = "${var.cloud == "aws" ? "${var.aws_region}" : null}"
    "awsAccessKeyId"     = "${var.cloud == "aws" ? "${var.aws_access_key_id}" : null}"
    "awsSecretAccessKey" = "${var.cloud == "aws" ? "${var.aws_secret_access_key}" : null}"
    # AWS + Terraform Backend
    "awsBackendS3Bucket"      = "${var.cloud == "aws" ? "${var.aws_backend_s3_bucket}" : null}"
    "awsBackendS3BucketKey"   = "${var.cloud == "aws" ? "${var.aws_backend_s3_bucket_key}" : null}"
    "awsBackendDynamoDBTable" = "${var.cloud == "aws" ? "${var.aws_backend_dynamodb_table}" : null}"

    # Azure
    "azureSubscriptionId"           = "${var.cloud == "azure" ? "${var.azure_subscription_id}" : null}"
    "azureServicePrincipalTenantId" = "${var.cloud == "azure" ? "${var.azure_service_principal_tenant_id}" : null}"
    "azureServicePrincipalAppId"    = "${var.cloud == "azure" ? "${var.azure_service_principal_app_id}" : null}"
    "azureServicePrincipalPassword" = "${var.cloud == "azure" ? "${var.azure_service_principal_password}" : null}"
    "resourceGroupName"             = "${var.cloud == "azure" ? "${var.azure_resource_group_name}" : null}"
    # Azure + Terraform Backend
    "azureBackendStorageAccountName" = "${var.cloud == "azure" ? "${var.azure_backend_storage_account_name}" : null}"
    "azureBackendContainerName"      = "${var.cloud == "azure" ? "${var.azure_backend_container_name}" : null}"
    "azureBackendBlobName"           = "${var.cloud == "azure" ? "${var.azure_backend_blob_name}" : null}"

    # DNS
    "domainName" = "${var.domain}"

    # Git
    "gitCredentialUsername"              = "${var.git_credential_username}"
    "gitCredentialPrivateKey"            = "${file(var.git_credential_private_key_path)}"
    "gitSSHHostKey"                      = "${var.git_ssh_host_key}"
    "cloudOpsForKubernetesRepoURL"       = "${var.cloudops_for_kubernetes_repo_url}"
    "cloudOpsForKubernetesDefaultBranch" = "${var.cloudops_for_kubernetes_default_branch}"
    "epCommerceRepoURL"                  = "${var.ep_commerce_repo_url}"
    "epCommerceDefaultBranch"            = "${var.ep_commerce_default_branch}"
    "dockerRepoURL"                      = "${var.docker_repo_url}"
    "dockerDefaultBranch"                = "${var.docker_default_branch}"

    # Jenkins
    "jenkinsTrustAllCertificates" = "${var.jenkins_trust_all_certificates}"

    # Nexus`
    "nexusRepoUsername"            = "${var.nexus_repo_username}"
    "nexusRepoPassword"            = "${var.nexus_repo_password}"
    "epRepositoryUser"             = "${var.ep_repository_user}"
    "epRepositoryPassword"         = "${var.ep_repository_password}"
    "epCortexMavenRepoUrl"         = "${var.ep_cortex_maven_repo_url}"
    "epCommerceEngineMavenRepoUrl" = "${var.ep_commerce_engine_maven_repo_url}"
    "epAcceleratorsMavenRepoUrl"   = "${var.ep_accelerators_maven_repo_url}"
    "nexusBaseUri"                 = "${var.nexus_base_uri}"

    # Docker
    "dockerRegistryPassword" = "${var.cloud == "azure" ? "${azurerm_container_registry.acr[0].admin_password}" : null}"
    "dockerRegistryUsername" = "${var.cloud == "azure" ? "${azurerm_container_registry.acr[0].admin_username}" : null}"
    "dockerRegistryAddress"  = "${var.cloud == "azure" ? "${azurerm_container_registry.acr[0].login_server}" : split("/", aws_ecr_repository.ecr-repo["jenkins/docker-agent"].repository_url)[0]}"

    # External dependencies
    "oracleJdkDownloadUrl"       = "${var.oracle_jdk_download_url}"
    "jdkFolderName"              = "${var.jdk_folder_name}"
    "mavenDownloadUrl"           = "${var.maven_download_url}"
    "mavenFolderName"            = "${var.maven_folder_name}"
    "tomcatVersion"              = "${var.tomcat_version}"
    "defaultAmReleasePackageUrl" = "${var.default_account_management_release_package_url}"

    # Extras
    "bootstrapExtrasProperties" = "${var.bootstrap_extras_properties}"
  }

  type = "Opaque"
}

data "template_file" "jenkins-helm-values" {
  template = "${file("jenkins-helm-values.yaml.tmpl")}"
  vars = {
    jenkins_allowed_cidr = "${var.jenkins_allowed_cidr}",
    subdomain_name       = "${var.kubernetes_cluster_name}",
    dns_zone_name        = "${var.domain}"
  }
}

data "helm_repository" "stable" {
  name = "stable"
  url  = "https://kubernetes-charts.storage.googleapis.com/"
}

resource "helm_release" "jenkins" {
  count      = terraform.workspace == "bootstrap" ? 1 : 0
  depends_on = [kubernetes_deployment.tiller_deploy, kubernetes_secret.jenkins-secrets, kubernetes_deployment.kube_state_metrics, azurerm_kubernetes_cluster.hub]

  name       = "jenkins"
  repository = data.helm_repository.stable.metadata.0.name
  chart      = "jenkins"
  version    = "1.4.3"
  timeout    = "1800"

  values = [
    "${data.template_file.jenkins-helm-values.rendered}"
  ]

}

output "jenkins_link" {
  value = "${var.cloud == "aws" ? "https://${replace("${aws_route53_record.eks-cluster-ingress-controller-record[0].fqdn}", "*", "jenkins")}" : "https://jenkins.${var.kubernetes_cluster_name}.${var.domain}"}"
}

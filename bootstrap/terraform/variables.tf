variable "bootstrap_mode" {
  type = string
}

variable "cloud" {
  type = string
}

variable "kubernetes_cluster_name" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "enable_new_relic_agent" {
  type    = bool
  default = false
}

variable "new_relic_license_key" {
  type    = string
  default = null
}

variable "new_relic_cluster_name" {
  type    = string
  default = null
}

variable "aws_access_key_id" {
  type    = string
  default = null
}

variable "aws_secret_access_key" {
  type    = string
  default = null
}

variable "aws_region" {
  type    = string
  default = null
}

variable "aws_backend_s3_bucket" {
  type    = string
  default = null
}

variable "aws_backend_s3_bucket_key" {
  type    = string
  default = null
}

variable "aws_backend_dynamodb_table" {
  type    = string
  default = null
}

variable "azure_subscription_id" {
  type    = string
  default = null
}

variable "azure_service_principal_tenant_id" {
  type    = string
  default = null
}

variable "azure_service_principal_app_id" {
  type    = string
  default = null
}

variable "azure_service_principal_password" {
  type    = string
  default = null
}

variable "azure_resource_group_name" {
  type    = string
  default = null
}

variable "azure_location" {
  type    = string
  default = null
}

variable "azure_backend_storage_account_name" {
  type    = string
  default = null
}

variable "azure_backend_container_name" {
  type    = string
  default = null
}

variable "azure_backend_blob_name" {
  type    = string
  default = null
}

variable "azure_aks_vm_size" {
  type    = string
  default = null
}

variable "azure_aks_min_node_count" {
  type    = string
  default = null
}

variable "azure_k8s_api_server_authorized_ip_ranges" {
  type    = set(string)
  default = []
}

variable "azure_aks_ssh_key" {
  type    = string
  default = null
}

variable "azure_acr_instance_name" {
  type    = string
  default = null
}

variable "haproxy_cert_path" {
  type    = string
  default = "/secrets/haproxy_default_cert.crt"
}

variable "haproxy_key_path" {
  type    = string
  default = "/secrets/haproxy_default_cert.key"
}

variable "domain" {
  type = string
}

variable "jenkins_allowed_cidr" {
  type = string
}

variable "jenkins_trust_all_certificates" {
  type    = string
  default = "false"
}

variable "git_credential_username" {
  type = string
}

variable "git_credential_private_key_path" {
  type    = string
  default = "/root/.ssh/git_id_rsa"
}

variable "git_ssh_host_key" {
  type = string
}

variable "cloudops_for_kubernetes_repo_url" {
  type = string
}

variable "cloudops_for_kubernetes_default_branch" {
  type = string
}

variable "ep_commerce_repo_url" {
  type = string
}

variable "ep_commerce_default_branch" {
  type = string
}

variable "docker_repo_url" {
  type = string
}

variable "docker_default_branch" {
  type = string
}

variable "nexus_repo_username" {
  type = string
}

variable "nexus_repo_password" {
  type = string
}

variable "extra_nexus_repository_config_path" {
  type    = string
  default = "/extras/extra-nexus-repositories.xml"
}

variable "nexus_allowed_cidr" {
  type = string
}

variable "ep_repository_user" {
  type = string
}

variable "ep_repository_password" {
  type = string
}

variable "ep_cortex_maven_repo_url" {
  type = string
}

variable "ep_commerce_engine_maven_repo_url" {
  type = string
}

variable "ep_accelerators_maven_repo_url" {
  type = string
}

variable "nexus_base_uri" {
  type = string
}

variable "oracle_jdk_download_url" {
  type = string
}

variable "jdk_folder_name" {
  type = string
}

variable "maven_download_url" {
  type = string
}

variable "maven_folder_name" {
  type = string
}

variable "tomcat_version" {
  type = string
}

variable "default_account_management_release_package_url" {
  type = string
}

variable "bootstrap_extras_properties" {
  type    = string
  default = null
}

variable "self_signed_cert_sans" {
  type    = list(string)
  default = []
}

variable "additional_ecr_repos" {
  type    = list(string)
  default = []
}

resource "null_resource" "variableValidation" {
  provisioner "local-exec" {
    when    = create
    command = "bash ./validate-variables.sh"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "bash ./validate-variables.sh"
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}

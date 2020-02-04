###############################################
# EP stack ConfigMap, Deployments, and Services
###############################################

variable "docker_image_tag" {
  type = string
}

variable "database_name" {
  type = string
}

variable "enable_debug" {
  type = string
}

variable "enable_jmx" {
  type = string
}

variable "ep_resourcing_profile" {
  type = string
}

variable "ep_smtp_host" {
  type = string
}

variable "ep_smtp_port" {
  type = string
}

variable "ep_smtp_scheme" {
  type = string
}

variable "ep_smtp_user" {
  type = string
}

variable "ep_smtp_pass" {
  type = string
}

variable "ep_tests_enable_ui" {
  type = string
}

variable "ep_changesets_enabled" {
  type = string
}

variable "ep_commerce_envname" {
  type = string
}

variable "ep_x_jvm_args" {
  type = string
}

variable "jms_name" {
  type = string
}

variable "jmx_auth" {
  type = string
}

variable "kubernetes_namespace" {
  type = string
}

variable "namespace" {
  type = string
}

variable "registry_address" {
  type = string
}

################
# Data Sync Tool
################

variable "deploy_dst_webapp" {
  type = string
}

variable "target_jms_name" {
  type = string
}

variable "target_namespace" {
  type = string
}

########################
# Target Database Secret
########################

variable "target_database_name" {
  type = string
}

###########
# Info Page
###########

variable "cluster_name" {
  type = string
}

variable "dns_sub_domain" {
  type = string
}

variable "full_domain_name" {
  type = string
}

variable "include_deployment_info_page" {
  type = string
}

variable "info_page_allowed_cidr" {
  type = string
}

############################
# Horizontal Pod Autoscalers
############################

variable "include_horizontal_pod_autoscalers" {
  type = string
}

###########
# Ingresses
###########

variable "include_ingresses" {
  type = string
}

variable "cm_allowed_cidr" {
  type = string
}

variable "integration_allowed_cidr" {
  type = string
}

variable "cortex_allowed_cidr" {
  type = string
}

variable "studio_allowed_cidr" {
  type = string
}

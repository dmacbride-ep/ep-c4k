variable "kubernetes_namespace" {
  type = string
}

variable "kubernetes_cluster_name" {
  type = string
}

variable "allowed_cidrs" {
  type = string
}

variable "registry_address" {
  type = string
}

variable "root_domain_name" {
  type = string
}

variable "docker_tag" {
  type = string
}

variable "account_management_database_name" {
  type = string
}

variable "account_management_activemq_name" {
  type = string
}

variable "private_jwt_key" {
  type = string
}

variable "public_jwt_key" {
  type = string
}

variable "api_access_token" {
  type    = string
  default = ""
}

variable "include_keycloak" {
  type = bool
}

variable "keycloak_database_name" {
  type = string
}

variable "oidc_discovery_url" {
  type = string
}

variable "oidc_client_id" {
  type = string
}

variable "oidc_client_secret" {
  type    = string
  default = ""
}

variable "oidc_token_scope" {
  type = string
}

variable "oidc_group_key" {
  type = string
}

variable "oidc_group_value_for_associates" {
  type = string
}

variable "oidc_group_value_for_seller_users" {
  type = string
}

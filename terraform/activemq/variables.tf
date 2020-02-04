variable "kubernetes_cluster_name" {
  type = string
}

variable "domain" {
  type = string
}

variable "kubernetes_namespace" {
  type = string
}

variable "activemq_service_name" {
  type = string
}

variable "jms_name" {
  type = string
}

variable "activemq_allowed_cidr" {
  type = string
}

variable "registry_secret" {
  type = string
}

variable "registry_address" {
  type = string
}

variable "docker_image_namespace" {
  type = string
}

variable "docker_image_tag" {
  type = string
}

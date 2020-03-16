variable "azure_location" {
  type    = string
  default = null
}

variable "kubernetes_namespace" {
  type = string
}

variable "root_username" {
  type = string
}

variable "root_password" {
  type = string
}

variable "database_hostname" {
  type = string
}

variable "database_server_url" {
  type = string
}

variable "database_name" {
  type = string
  default = ""
}

variable "database_username" {
  type = string
  default = ""
}

variable "database_password" {
  type = string
  default = ""
}

variable "target_resource_group" {
  type    = string
  default = null
}
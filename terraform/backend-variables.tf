variable "cloud" {
  type = string
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
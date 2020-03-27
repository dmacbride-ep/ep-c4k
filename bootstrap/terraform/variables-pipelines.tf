
# login credentials for the nightly ci pipelines

## C4K master

variable "awsAccessKeyIdMaster" {
  type    = string
  default = ""
}

variable "awsSecretAccessKeyMaster" {
  type    = string
  default = ""
}

variable "azureServicePrincipalAppIdMaster" {
  type    = string
  default = ""
}

variable "azureServicePrincipalPasswordMaster" {
  type    = string
  default = ""
}

## C4K 2.0

variable "awsAccessKeyId20" {
  type    = string
  default = ""
}

variable "awsSecretAccessKey20" {
  type    = string
  default = ""
}

variable "azureServicePrincipalAppId20" {
  type    = string
  default = ""
}

variable "azureServicePrincipalPassword20" {
  type    = string
  default = ""
}

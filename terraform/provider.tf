provider "aws" {
  version = "~> 2.14"

  # for details on why we can't set null when not running against AWS, see:
  # https://github.com/terraform-providers/terraform-provider-aws/issues/5584#issuecomment-418950776
  region     = var.cloud == "aws" ? "${var.aws_region}" : null
  access_key = var.cloud == "aws" ? "${var.aws_access_key_id}" : "not_a_real_access_key_but_cant_be_null"
  secret_key = var.cloud == "aws" ? "${var.aws_secret_access_key}" : "not_a_real_secret_key_but_cant_be_null"

  skip_region_validation      = var.cloud == "aws" ? false : true
  skip_credentials_validation = var.cloud == "aws" ? false : true
  skip_requesting_account_id  = var.cloud == "aws" ? false : true
}

provider "azurerm" {
  version = "= 1.37"

  subscription_id = var.cloud == "azure" ? "${var.azure_subscription_id}" : "not_a_real_subscription_id_but_cant_be_null"
  tenant_id       = var.cloud == "azure" ? "${var.azure_service_principal_tenant_id}" : "not_a_real_tenant_id_but_cant_be_null"
  client_id       = var.cloud == "azure" ? "${var.azure_service_principal_app_id}" : "not_a_real_client_id_but_cant_be_null"
  client_secret   = var.cloud == "azure" ? "${var.azure_service_principal_password}" : "not_a_real_client_secret_but_cant_be_null"

  skip_credentials_validation = var.cloud == "azure" ? false : true
  skip_provider_registration  = var.cloud == "azure" ? false : true
}

provider "kubernetes" {
  version = "= 1.10"
}

provider "helm" {
  version = "~> 0.10"
}

provider "random" {
  version = "~> 2.2"
}

provider "template" {
  version = "~> 2.1"
}

provider "null" {
  version = "~> 2.1"
}

provider "tls" {
  version = "~> 2.0"
}

provider "http" {
  version = "~> 1.1"
}

locals {
  cloud_backend_name = {
    "azure" = "azurerm"
    "aws"   = "s3"
  }
  cloud_backend_config = {
    "aws" = {
      bucket         = "${var.cloud == "aws" ? "${var.aws_backend_s3_bucket}" : null}"
      key            = "${var.cloud == "aws" ? "${var.aws_backend_s3_bucket_key}" : null}"
      dynamodb_table = "${var.cloud == "aws" ? "${var.aws_backend_dynamodb_table}" : null}"
      region         = "${var.cloud == "aws" ? "${var.aws_region}" : null}"
      access_key     = "${var.cloud == "aws" ? "${var.aws_access_key_id}" : null}"
      secret_key     = "${var.cloud == "aws" ? "${var.aws_secret_access_key}" : null}"
    }
    "azure" = {
      subscription_id      = "${var.cloud == "azure" ? "${var.azure_subscription_id}" : null}"
      tenant_id            = "${var.cloud == "azure" ? "${var.azure_service_principal_tenant_id}" : null}"
      client_id            = "${var.cloud == "azure" ? "${var.azure_service_principal_app_id}" : null}"
      client_secret        = "${var.cloud == "azure" ? "${var.azure_service_principal_password}" : null}"
      resource_group_name  = "${var.cloud == "azure" ? "${var.azure_resource_group_name}" : null}"
      storage_account_name = "${var.cloud == "azure" ? "${var.azure_backend_storage_account_name}" : null}"
      container_name       = "${var.cloud == "azure" ? "${var.azure_backend_container_name}" : null}"
      key                  = "${var.cloud == "azure" ? "${var.azure_backend_blob_name}" : null}"
    }
  }
}

data "terraform_remote_state" "bootstrap" {
  backend = "${lookup(local.cloud_backend_name, var.cloud)}"
  config  = lookup(local.cloud_backend_config, var.cloud)

  workspace = "bootstrap"
}

resource "aws_route53_record" "activemq-record" {
  depends_on = [kubernetes_service.ep_activemq_service]
  count      = (var.cloud == "aws") && (terraform.workspace != "bootstrap") ? 1 : 0

  zone_id = data.terraform_remote_state.bootstrap.outputs.aws_route53_zone_id
  name    = "activemq-${var.activemq_service_name}.${var.kubernetes_namespace}.${var.kubernetes_cluster_name}.lb.${var.domain}"
  type    = "CNAME"
  ttl     = "60"
  records = ["${kubernetes_service.ep_activemq_service.load_balancer_ingress[0].hostname}"]
}

resource "azurerm_dns_a_record" "test" {
  depends_on = [kubernetes_service.ep_activemq_service]
  count      = (var.cloud == "azure") && (terraform.workspace != "bootstrap") ? 1 : 0

  name                = "activemq-${var.activemq_service_name}.${var.kubernetes_namespace}.${var.kubernetes_cluster_name}.lb"
  zone_name           = var.domain
  resource_group_name = var.azure_resource_group_name
  ttl                 = 60
  records             = ["${kubernetes_service.ep_activemq_service.load_balancer_ingress[0].ip}"]
}

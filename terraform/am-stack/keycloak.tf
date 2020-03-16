
locals {
  keycloak_admin_username   = "admin"
  keycloak_am_redirect_uris = var.include_keycloak ? "https://${local.am_ui_domain_name}/*,https://${local.am_api_domain_name}/*" : ""
  keycloak_domain_name      = var.include_keycloak ? "keycloak-${var.kubernetes_namespace}.${var.kubernetes_cluster_name}.${var.root_domain_name}" : ""

  haproxy_release_name          = "haproxy-ingress-global"
  cluster_public_ip             = jsondecode(data.http.cluster_public_ip.body).ip
  azure_cluster_subnet          = "10.1.0.0/16"
  allowed_cidrs_plus_cluster_ip = var.cloud == "azure" ? join(",", [local.azure_cluster_subnet], concat(split(",", var.allowed_cidrs), ["${local.cluster_public_ip}/32"])) : join(",", concat(split(",", var.allowed_cidrs), ["${local.cluster_public_ip}/32"]))
  keycloak_db_user     = var.include_keycloak ? "${lookup(data.kubernetes_secret.keycloak_db[0].data, "API_DB_USER")}" : ""
  keycloak_db_password = var.include_keycloak ? "${lookup(data.kubernetes_secret.keycloak_db[0].data, "API_DB_PASSWORD")}" : ""
  keycloak_db_name     = var.include_keycloak ? "${lookup(data.kubernetes_secret.keycloak_db[0].data, "API_DB_SCHEMA")}" : ""
  keycloak_db_host     = var.include_keycloak ? "ep-am-mysql-${var.keycloak_database_name}-service.${var.kubernetes_namespace}" : ""
}

data "template_file" "keycloak-helm-values" {
  count = var.include_keycloak ? 1 : 0

  template = "${file("keycloak-helm-values.yaml.tmpl")}"

  vars = {
    allowedCidrPlusClusterIp = local.allowed_cidrs_plus_cluster_ip
    keycloakDomainName       = local.keycloak_domain_name
    adminUsername            = local.keycloak_admin_username
    keycloakMysqlSecret      = "ep-am-mysql-${var.keycloak_database_name}-secret"
    keycloakMysqlPasswordKey = "API_DB_PASSWORD"
    keycloakDatabaseName     = local.keycloak_db_name
    keycloakDatabaseHost     = local.keycloak_db_host
    keycloakDatabaseUser     = local.keycloak_db_user
  }
}

data "kubernetes_secret" "keycloak_db" {
  count = var.include_keycloak ? 1 : 0

  metadata {
    name      = "ep-am-mysql-${var.keycloak_database_name}-secret"
    namespace = var.kubernetes_namespace
  }
}

data "http" "cluster_public_ip" {
  url = "https://ifconfig.co/json"
  request_headers = {
    Accept = "application/json"
  }
}

data "helm_repository" "codecentric" {
  count = var.include_keycloak ? 1 : 0

  name = "codecentric"
  url  = "https://codecentric.github.io/helm-charts"
}

resource "null_resource" "reset_keycloak_db" {
  count = var.include_keycloak ? 1 : 0

  provisioner "local-exec" {
    command = "mysql -u ${local.keycloak_db_user} -e 'drop database ${local.keycloak_db_name}; create database ${local.keycloak_db_name};'"

    environment = {
      MYSQL_PWD  = "${local.keycloak_db_password}"
      MYSQL_HOST = "${local.keycloak_db_host}"
    }
  }
}

resource "helm_release" "keycloak" {
  count      = var.include_keycloak ? 1 : 0
  depends_on = [null_resource.reset_keycloak_db]

  name          = "keycloak-${var.kubernetes_namespace}"
  repository    = data.helm_repository.codecentric[0].metadata.0.name
  chart         = "keycloak"
  namespace     = var.kubernetes_namespace
  version       = "6.0.4"
  recreate_pods = true

  values = [
    "${data.template_file.keycloak-helm-values[0].rendered}"
  ]
}

data "kubernetes_secret" "keycloak_password" {
  depends_on = [helm_release.keycloak]
  count      = var.include_keycloak ? 1 : 0

  metadata {
    name      = "keycloak-${var.kubernetes_namespace}-http"
    namespace = var.kubernetes_namespace
  }
}

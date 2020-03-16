locals {
  db-port              = "3306"
  db-connection-params = var.cloud == "azure" ? "?characterEncoding=UTF-8&useSSL=true&pinGlobalTxToPhysicalConnection=true&useLocalSessionState=true" : "?characterEncoding=UTF-8&useSSL=false&pinGlobalTxToPhysicalConnection=true&useLocalSessionState=true"
  db-username          = var.database_username != "" ? var.database_username : "epuser-${random_string.nonroot_username_suffix.result}"
  db-password          = var.database_password != "" ? var.database_password : random_string.nonroot_password.result
  db-database-name     = var.database_name != "" ? var.database_name : "elasticpathdb${random_string.database_suffix.result}"
}

resource "kubernetes_secret" "external_database_secret" {
  depends_on = [
    random_string.nonroot_password,
    random_string.nonroot_username_suffix,
    random_string.database_suffix
  ]
  metadata {
    name      = "ep-am-mysql-${local.db-database-name}-secret"
    namespace = var.kubernetes_namespace
  }

  data = {
    // env vars required by the AM API
    API_DB_USER             = var.cloud == "azure" ? "${local.db-username}@${var.database_hostname}" : local.db-username
    API_DB_PASSWORD         = local.db-password
    API_DB_DRIVER_CLASSNAME = "org.mariadb.jdbc.Driver"
    API_DB_SCHEMA           = local.db-database-name
    API_DB_CONNECTION_URL   = "jdbc:mysql://${var.database_server_url}:${local.db-port}/${local.db-database-name}${local.db-connection-params}"
  }
}

resource "random_string" "nonroot_password" {
  length  = 32
  upper   = true
  lower   = true
  number  = true
  special = false
}

resource "random_string" "nonroot_username_suffix" {
  length  = 5
  upper   = true
  lower   = true
  number  = true
  special = false
}

resource "random_string" "database_suffix" {
  length  = 8
  upper   = false
  lower   = true
  number  = true
  special = false
}

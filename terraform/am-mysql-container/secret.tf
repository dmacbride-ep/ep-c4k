locals {
  db-schema-name       = "AccountManagement${random_string.schema_suffix.result}"
  db-connection-params = "?autoReconnect=true&useUnicode=true&characterEncoding=UTF-8&useSSL=false"
}

resource "kubernetes_secret" "mysql_container_secret" {
  depends_on = [
    random_string.root_password,
    random_string.schema_suffix,
    random_string.nonroot_username_suffix,
    random_string.nonroot_password
  ]

  metadata {
    name      = "ep-am-mysql-${var.database_name}-secret"
    namespace = var.kubernetes_namespace
  }

  data = {
    // env vars required by the AM API
    API_DB_USER             = "epuser-${random_string.nonroot_username_suffix.result}"
    API_DB_PASSWORD         = random_string.nonroot_password.result
    API_DB_DRIVER_CLASSNAME = "org.mariadb.jdbc.Driver"
    API_DB_SCHEMA           = local.db-schema-name
    API_DB_CONNECTION_URL   = "jdbc:mysql://ep-am-mysql-${var.database_name}-service.${var.kubernetes_namespace}:3306/${local.db-schema-name}${local.db-connection-params}"

    // env vars required by the mysql image to create initial user and schema
    MYSQL_ROOT_PASSWORD = random_string.root_password.result
    MYSQL_USER          = "epuser-${random_string.nonroot_username_suffix.result}"
    MYSQL_PASSWORD      = random_string.nonroot_password.result
    MYSQL_DATABASE      = local.db-schema-name
  }
}

resource "random_string" "root_password" {
  length  = 32
  upper   = true
  lower   = true
  number  = true
  special = false
}

resource "random_string" "schema_suffix" {
  length  = 8
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

resource "random_string" "nonroot_password" {
  length  = 32
  upper   = true
  lower   = true
  number  = true
  special = false
}

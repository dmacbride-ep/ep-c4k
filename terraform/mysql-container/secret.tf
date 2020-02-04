locals {
  db-hostname          = "ep-mysql-${var.database_name}-service.${var.kubernetes_namespace}"
  db-port              = "3306"
  db-schema-name       = "ElasticPathDB${random_string.schema_suffix.result}"
  db-connection-params = "?characterEncoding=UTF-8&useSSL=false&pinGlobalTxToPhysicalConnection=true&useLocalSessionState=true"
}

resource "kubernetes_secret" "mysql_container_secret" {
  depends_on = [
    random_string.root_password,
    random_string.schema_suffix,
    random_string.nonroot_username_suffix,
    random_string.nonroot_password
  ]

  metadata {
    name      = "ep-mysql-${var.database_name}-secret"
    namespace = var.kubernetes_namespace
  }

  data = {
    EP_DB_HOSTNAME             = "${local.db-hostname}"
    EP_DB_PORT                 = "${local.db-port}"
    EP_DB_ROOT_USER            = "root"
    EP_DB_ROOT_PASS            = "${random_string.root_password.result}"
    EP_DB_JDBC_DRIVER_CLASS    = "com.mysql.jdbc.Driver"
    EP_DB_JDBC_XA_DRIVER_CLASS = "com.mysql.jdbc.jdbc2.optional.MysqlXADataSource"
    EP_DB_CONNECTION_PARAMS    = "${local.db-connection-params}"
    EP_DB_NAME_TYPE            = ""
    EP_DB_URL                  = "jdbc:mysql://${local.db-hostname}:${local.db-port}/${local.db-schema-name}${local.db-connection-params}"

    # the user listed below is created when the data-pop-tool is run
    EP_DB_NAME        = "${local.db-schema-name}"
    EP_DB_SCHEMA_NAME = "${local.db-schema-name}"
    EP_DB_USER        = "epuser-${random_string.nonroot_username_suffix.result}"
    EP_DB_USER_SHORT  = ""
    EP_DB_PASS        = "${random_string.nonroot_password.result}"
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
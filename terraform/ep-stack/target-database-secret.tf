data "kubernetes_secret" "existing_target_db_secret" {
  count = "${var.deploy_dst_webapp == "true" ? 1 : 0}"

  metadata {
    name      = "ep-mysql-${var.target_database_name}-secret"
    namespace = "${var.target_namespace}"
  }
}

resource "kubernetes_secret" "target_database_secrets" {
  count = var.deploy_dst_webapp == "true" ? 1 : 0

  metadata {
    name      = "target-database-secrets"
    namespace = var.kubernetes_namespace
  }

  data = data.kubernetes_secret.existing_target_db_secret[0].data
}
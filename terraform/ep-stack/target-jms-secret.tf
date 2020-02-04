data "kubernetes_secret" "existing_target_jms_secret" {
  count = "${var.deploy_dst_webapp == "true" ? 1 : 0}"

  metadata {
    name      = "ep-jms-${var.target_jms_name}-secret"
    namespace = "${var.target_namespace}"
  }
}

resource "kubernetes_secret" "target_jms_secrets" {
  count = var.deploy_dst_webapp == "true" ? 1 : 0

  metadata {
    name      = "target-jms-secrets"
    namespace = var.kubernetes_namespace
  }

  data = data.kubernetes_secret.existing_target_jms_secret[0].data
}
resource "kubernetes_persistent_volume_claim" "activemq_volume" {
  metadata {
    name      = "activemq-${var.jms_name}-volume"
    namespace = var.kubernetes_namespace
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "10Gi"
      }
    }

    storage_class_name = "fast-local"
  }

  wait_until_bound = true
}
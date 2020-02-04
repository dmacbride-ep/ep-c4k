resource "kubernetes_persistent_volume_claim" "mysql_pvc" {
  metadata {
    name      = "mysql-${var.database_name}-pvc"
    namespace = var.kubernetes_namespace
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
    storage_class_name = "slow-local"
  }

  wait_until_bound = true
}
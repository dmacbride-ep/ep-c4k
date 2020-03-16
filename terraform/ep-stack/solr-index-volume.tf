resource "kubernetes_persistent_volume_claim" "solr_index_volume" {
  metadata {
    name      = "solr-index-volume"
    namespace = var.kubernetes_namespace
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = local.commerce_profiles["searchmaster"][var.ep_resourcing_profile]["pvc-size"]
      }
    }
    storage_class_name = local.commerce_profiles["searchmaster"][var.ep_resourcing_profile]["storage-class"]
  }
}

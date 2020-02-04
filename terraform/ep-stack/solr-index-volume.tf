resource "kubernetes_persistent_volume_claim" "solr_index_volume" {
  metadata {
    name      = "solr-index-volume"
    namespace = var.kubernetes_namespace
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = local.ep_stack_resourcing_proflies["searchmaster"][var.ep_resourcing_profile]["pvc-size"]
      }
    }
    storage_class_name = local.ep_stack_resourcing_proflies["searchmaster"][var.ep_resourcing_profile]["storage-class"]
  }
}

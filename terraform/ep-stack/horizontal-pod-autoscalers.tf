resource "kubernetes_horizontal_pod_autoscaler" "ep_searchslave_hpa" {
  count = var.include_horizontal_pod_autoscalers == "true" ? 1 : 0

  metadata {
    name      = "ep-searchslave-hpa"
    namespace = var.kubernetes_namespace
    labels = {
      app = "ep-searchslave"
    }
  }
  spec {
    scale_target_ref {
      kind        = "Deployment"
      name        = "ep-searchslave-deployment"
      api_version = "apps/v1"
    }
    min_replicas                      = local.commerce_profiles["searchslave"][var.ep_resourcing_profile]["min-replicas"]
    max_replicas                      = local.commerce_profiles["searchslave"][var.ep_resourcing_profile]["max-replicas"]
    target_cpu_utilization_percentage = local.commerce_profiles["searchslave"][var.ep_resourcing_profile]["target-cpu-utilization"]
  }
}

resource "kubernetes_horizontal_pod_autoscaler" "ep_cortex_hpa" {
  count = var.include_horizontal_pod_autoscalers == "true" ? 1 : 0

  metadata {
    name      = "ep-cortex-hpa"
    namespace = var.kubernetes_namespace
    labels = {
      app = "ep-cortex"
    }
  }
  spec {
    scale_target_ref {
      kind        = "Deployment"
      name        = "ep-cortex-deployment"
      api_version = "apps/v1"
    }
    min_replicas                      = local.commerce_profiles["cortex"][var.ep_resourcing_profile]["min-replicas"]
    max_replicas                      = local.commerce_profiles["cortex"][var.ep_resourcing_profile]["max-replicas"]
    target_cpu_utilization_percentage = local.commerce_profiles["cortex"][var.ep_resourcing_profile]["target-cpu-utilization"]
  }
}

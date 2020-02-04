resource "kubernetes_service" "ep_activemq_service" {
  metadata {
    name      = "ep-activemq-${var.jms_name}-service"
    namespace = var.kubernetes_namespace
    labels = {
      app = "ep-activemq-${var.jms_name}"
    }
  }
  spec {
    port {
      name     = "ep-activemq-port-61616"
      protocol = "TCP"
      port     = 61616
    }
    port {
      name     = "ep-activemq-port-8161"
      protocol = "TCP"
      port     = 8161
    }
    selector = {
      app = "ep-activemq-${var.jms_name}"
    }
    type                        = "LoadBalancer"
    load_balancer_source_ranges = ["${var.activemq_allowed_cidr}"]
  }
}
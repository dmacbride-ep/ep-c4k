resource "kubernetes_service" "ep_mysql_service" {
  metadata {
    name      = "ep-mysql-${var.database_name}-service"
    namespace = var.kubernetes_namespace

    labels = {
      app = "ep-mysql-${var.database_name}"
    }
  }
  spec {
    port {
      name     = "ep-mysql-port-3306"
      protocol = "TCP"
      port     = 3306
    }
    selector = {
      app = "ep-mysql-${var.database_name}"
    }
    type = "ClusterIP"
  }
}
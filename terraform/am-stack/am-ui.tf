locals {
  am_ui_domain_name = "am-ui-${var.kubernetes_namespace}.${var.kubernetes_cluster_name}.${var.root_domain_name}"
}

resource "kubernetes_deployment" "am_ui_deployment" {
  metadata {
    name      = "am-ui-deployment"
    namespace = var.kubernetes_namespace

    labels = {
      app = "am-ui"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "am-ui"
      }
    }

    template {
      metadata {
        labels = {
          app = "am-ui"
        }
      }

      spec {
        container {
          name  = "am-ui"
          image = "${var.registry_address}/am/am-ui:${var.docker_tag}"

          port {
            container_port = 80
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.am-ui-secret.metadata[0].name
            }
          }

          resources {
            limits {
              cpu    = "200m"
              memory = "512Mi"
            }

            requests {
              cpu    = "200m"
              memory = "512Mi"
            }
          }

          liveness_probe {
            tcp_socket {
              port = "80"
            }

            initial_delay_seconds = 960
            timeout_seconds       = 4
            period_seconds        = 10
            failure_threshold     = 3
          }

          readiness_probe {
            tcp_socket {
              port = "80"
            }

            initial_delay_seconds = 1
            timeout_seconds       = 2
            period_seconds        = 10
            failure_threshold     = 3
          }

          image_pull_policy = "Always"
          tty               = true
        }

        restart_policy = "Always"
      }
    }

    progress_deadline_seconds = 1200
  }
}

resource "kubernetes_service" "am_ui_service" {
  metadata {
    name      = "am-ui-service"
    namespace = var.kubernetes_namespace

    labels = {
      app = "am-ui"
    }
  }

  spec {
    port {
      name     = "am-ui-port-80"
      protocol = "TCP"
      port     = 80
    }

    selector = {
      app = "am-ui"
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_secret" "am-ui-secret" {
  metadata {
    name      = "am-ui-secret"
    namespace = var.kubernetes_namespace
  }

  data = {
    INSTANCE_URL         = "https://${local.am_ui_domain_name}"
    COMMERCE_MANAGER_URL = "https://www.elasticpath.com"
    ADMIN_API_URL        = "https://${local.am_api_domain_name}/admin"
  }
}

resource "kubernetes_ingress" "am_ui_ingress" {
  metadata {
    name      = "am-ui-ingress"
    namespace = var.kubernetes_namespace

    annotations = {
      "ingress.kubernetes.io/load-balance"           = "least_conn"
      "ingress.kubernetes.io/secure-backends"        = "false"
      "ingress.kubernetes.io/use-proxy-protocol"     = "true"
      "ingress.kubernetes.io/whitelist-source-range" = join(",", split(",", var.allowed_cidrs))
      "kubernetes.io/ingress.class"                  = "haproxy"
    }
  }

  spec {
    tls {
      hosts = [local.am_ui_domain_name]
    }

    rule {
      host = local.am_ui_domain_name

      http {
        path {
          path = "/"

          backend {
            service_name = "am-ui-service"
            service_port = "80"
          }
        }
      }
    }
  }
}

locals {
  cluster_credentials_command = {
    "azure" = "az aks get-credentials --overwrite-existing --resource-group ${var.azure_resource_group_name == null ? "" : var.azure_resource_group_name} --name ${var.cluster_name}",
    "aws"   = "eksctl utils write-kubeconfig --region ${var.aws_region == null ? "" : var.aws_region} --name ${var.cluster_name}"
  }
  cluster_description = {
    "azure" = "Cluster Name: <b>${var.cluster_name}</b><br />Resource Group: <b>${var.azure_resource_group_name == null ? "" : var.azure_resource_group_name}</b>",
    "aws"   = "Cluster Name: <b>${var.cluster_name}</b>"
  }
}

resource "kubernetes_deployment" "info_page" {
  count = var.include_deployment_info_page == "true" ? 1 : 0

  metadata {
    name      = "info-page"
    namespace = var.kubernetes_namespace
    labels = {
      app = "info-page"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "info-page"
      }
    }
    template {
      metadata {
        labels = {
          app = "info-page"
        }
      }
      spec {
        container {
          name  = "info-page"
          image = "${var.registry_address}${var.namespace}/info-page:${var.docker_image_tag}"
          port {
            container_port = 80
          }
          env {
            name  = "DNS_SUB_DOMAIN"
            value = var.dns_sub_domain
          }
          env {
            name  = "EP_TESTS_ENABLE_UI"
            value = var.ep_tests_enable_ui
          }
          env {
            name  = "EP_CHANGESETS_ENABLED"
            value = var.ep_changesets_enabled
          }
          env {
            name  = "KUBERNETES_NAMESPACE"
            value = var.kubernetes_namespace
          }
          env_from {
            secret_ref {
              name = "ep-mysql-${var.database_name}-secret"
            }
          }
          env {
            name  = "FULL_DOMAIN_NAME"
            value = var.full_domain_name
          }
          env {
            name  = "CLUSTER_CREDENTIALS_COMMAND"
            value = local.cluster_credentials_command["${var.cloud}"]
          }
          env {
            name  = "CLUSTER_DESCRIPTION"
            value = local.cluster_description["${var.cloud}"]
          }
          resources {
            limits {
              cpu    = "100m"
              memory = "32Mi"
            }
            requests {
              cpu    = "100m"
              memory = "32Mi"
            }
          }
          image_pull_policy = "Always"
        }
        dns_config {
          option {
            name = "single-request-reopen"
          }
          option {
            name = "timeout"
            value = 3
          }
          option {
            name = "attempts"
            value = 3
          }
        }
        restart_policy = "Always"
      }
    }
  }
}

resource "kubernetes_service" "info_page" {
  count = var.include_deployment_info_page == "true" ? 1 : 0

  metadata {
    name      = "info-page"
    namespace = var.kubernetes_namespace
    labels = {
      app = "info-page"
    }
  }
  spec {
    port {
      name     = "info-page-port-80"
      protocol = "TCP"
      port     = 80
    }
    selector = {
      app = "info-page"
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_ingress" "info_page_ingress" {
  count = var.include_deployment_info_page == "true" ? 1 : 0

  metadata {
    name      = "info-page-ingress"
    namespace = var.kubernetes_namespace
    annotations = {
      "ingress.kubernetes.io/whitelist-source-range" = var.info_page_allowed_cidr
      "kubernetes.io/ingress.class"                  = "haproxy"
      "ingress.kubernetes.io/load-balance"           = "least_conn"
      "ingress.kubernetes.io/secure-backends"        = "false"
      "ingress.kubernetes.io/use-proxy-protocol"     = "true"
    }
  }
  spec {
    rule {
      host = var.full_domain_name
      http {
        path {
          path = "/"
          backend {
            service_name = "info-page"
            service_port = "80"
          }
        }
        path {
          path = "/admin"
          backend {
            service_name = "ep-activemq-service"
            service_port = "8161"
          }
        }
      }
    }
  }
}

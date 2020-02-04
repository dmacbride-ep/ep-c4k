locals {
  ingresses = (var.include_ingresses == "false" ? {} : {
    "cm" = {
      "allowed_cidr" = "${var.cm_allowed_cidr}"
      "path"         = "/cm/"
      "service"      = "ep-cm-service"
    }
    "integration" = {
      "allowed_cidr" = "${var.integration_allowed_cidr}"
      "path"         = "/integration"
      "service"      = "ep-integration-service"
    }
    "cortex" = {
      "allowed_cidr" = "${var.cortex_allowed_cidr}"
      "path"         = "/cortex"
      "service"      = "ep-cortex-service"
    }
    "studio" = {
      "allowed_cidr" = "${var.studio_allowed_cidr}"
      "path"         = "/studio"
      "service"      = "ep-cortex-service"
    }
  })
}

resource "kubernetes_ingress" "ep_ingress" {
  for_each = local.ingresses

  metadata {
    name      = "${var.ep_commerce_envname}-${each.key}-ingress"
    namespace = var.kubernetes_namespace
    annotations = {
      "ingress.kubernetes.io/load-balance"           = "least_conn"
      "ingress.kubernetes.io/secure-backends"        = "false"
      "ingress.kubernetes.io/use-proxy-protocol"     = "true"
      "ingress.kubernetes.io/whitelist-source-range" = each.value["allowed_cidr"]
      "kubernetes.io/ingress.class"                  = "haproxy"
    }
  }
  spec {
    tls {
      hosts = ["${var.full_domain_name}"]
    }
    rule {
      host = var.full_domain_name
      http {
        path {
          path = each.value["path"]
          backend {
            service_name = each.value["service"]
            service_port = "8080"
          }
        }
      }
    }
  }
}

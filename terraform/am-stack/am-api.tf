
locals {
  felix_webconsole_username = "admin"

  am_api_domain_name = "am-api-${var.kubernetes_namespace}.${var.kubernetes_cluster_name}.${var.root_domain_name}"
}

resource "kubernetes_deployment" "am_api_deployment" {
  metadata {
    name      = "am-api-deployment"
    namespace = var.kubernetes_namespace

    labels = {
      app = "am-api"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "am-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "am-api"
        }
      }

      spec {
        container {
          name  = "am-api"
          image = "${var.registry_address}/am/am-api:${var.docker_tag}"

          port {
            container_port = 8080
          }

          env {
            name  = "AM_API_SECRET_HASH"
            value = sha256(jsonencode(kubernetes_secret.am-api-secret.data))
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.am-api-secret.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = "ep-am-mysql-${var.account_management_database_name}-secret"
            }
          }

          env_from {
            secret_ref {
              name = "ep-jms-${var.account_management_activemq_name}-secret"
            }
          }

          resources {
            limits {
              cpu    = "2"
              memory = "2Gi"
            }

            requests {
              cpu    = "2"
              memory = "2Gi"
            }
          }

          liveness_probe {
            exec {
              command = ["/bin/bash", "-c", "curl -sSI localhost:8080/admin/healthcheck | grep HTTP.*200"]
            }

            initial_delay_seconds = 960
            timeout_seconds       = 4
            period_seconds        = 10
            failure_threshold     = 3
          }

          readiness_probe {
            exec {
              command = ["/bin/bash", "-c", "curl -sSI localhost:8080/admin/healthcheck | grep HTTP.*200"]
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

resource "kubernetes_service" "am_api_service" {
  metadata {
    name      = "am-api-service"
    namespace = var.kubernetes_namespace

    labels = {
      app = "am-api"
    }
  }

  spec {
    port {
      name     = "am-api-port-8080"
      protocol = "TCP"
      port     = 8080
    }

    selector = {
      app = "am-api"
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_secret" "am-api-secret" {
  metadata {
    name      = "am-api-secret"
    namespace = var.kubernetes_namespace
  }

  data = {
    AM_AUTH_JWT_PRIVATE_KEY = var.private_jwt_key
    AM_AUTH_JWT_PUBLIC_KEY  = var.public_jwt_key

    AM_AUTH_TOKEN_LIFETIME_SECONDS = 3600
    API_ACCESS_TOKEN               = "${var.api_access_token != "" ? var.api_access_token : random_string.api_access_token[0].result}"

    API_FELIX_WEBCONSOLE_USERNAME = local.felix_webconsole_username
    API_FELIX_WEBCONSOLE_PASSWORD = random_string.felix_webconsole_password.result

    # OpenID Connect related values
    AM_OIDC_DISCOVERY_URL                    = "${var.include_keycloak ? local.keycloak_oidc_discovery_url : var.oidc_discovery_url}"
    AM_OIDC_CLIENT_ID                        = "${var.include_keycloak ? local.keycloak_am_client_id : var.oidc_client_id}"
    AM_OIDC_CLIENT_SECRET                    = "${var.include_keycloak ? random_string.keycloak_am_secret[0].result : var.oidc_client_secret}"
    AM_OIDC_ID_TOKEN_SCOPE                   = "${var.include_keycloak ? local.keycloak_oidc_token_scope : var.oidc_token_scope}"
    AM_OIDC_ID_TOKEN_GROUP_KEY               = "${var.include_keycloak ? local.keycloak_oidc_token_group_key : var.oidc_group_key}"
    AM_OIDC_ID_TOKEN_ASSOCIATE_GROUP_VALUE   = "${var.include_keycloak ? local.keycloak_associates_role : var.oidc_group_value_for_associates}"
    AM_OIDC_ID_TOKEN_SELLER_USER_GROUP_VALUE = "${var.include_keycloak ? local.keycloak_seller_users_role : var.oidc_group_value_for_seller_users}"
  }
}

resource "random_string" "felix_webconsole_password" {
  length  = 16
  upper   = true
  lower   = true
  number  = true
  special = false
}

resource "random_string" "api_access_token" {
  count = var.api_access_token != "" ? 0 : 1

  length  = 32
  upper   = true
  lower   = true
  number  = true
  special = false
}

resource "kubernetes_ingress" "am_api_ingress" {
  metadata {
    name      = "am-api-ingress"
    namespace = var.kubernetes_namespace

    annotations = {
      "ingress.kubernetes.io/load-balance"           = "least_conn"
      "ingress.kubernetes.io/secure-backends"        = "false"
      "ingress.kubernetes.io/use-proxy-protocol"     = "true"
      "ingress.kubernetes.io/whitelist-source-range" = local.allowed_cidrs_plus_cluster_ip
      "kubernetes.io/ingress.class"                  = "haproxy"
    }
  }

  spec {
    tls {
      hosts = [local.am_api_domain_name]
    }

    rule {
      host = local.am_api_domain_name

      http {
        path {
          path = "/"

          backend {
            service_name = "am-api-service"
            service_port = "8080"
          }
        }
      }
    }
  }
}

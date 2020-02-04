
locals {
  keycloak_commerce_realm       = "Commerce"
  keycloak_am_client_id         = "account-management"
  keycloak_seller_users_role    = "seller-users"
  keycloak_associates_role      = "associates"
  keycloak_oidc_discovery_url   = "https://${local.keycloak_domain_name}/auth/realms/${local.keycloak_commerce_realm}/.well-known/openid-configuration"
  keycloak_oidc_token_scope     = ""
  keycloak_oidc_token_group_key = "roles"

  seller_admin_email = "seller.admin@example.com"
}

resource "kubernetes_job" "am_config_job" {
  count = var.include_keycloak ? 1 : 0

  metadata {
    name      = "am-config-job"
    namespace = var.kubernetes_namespace

    labels = {
      app = "am-config"
    }
  }

  spec {
    template {
      metadata {
        labels = {
          app = "am-config"
        }
      }

      spec {
        container {
          name  = "am-config"
          image = "${var.registry_address}/am/am-config:${var.docker_tag}"

          env_from {
            secret_ref {
              name = kubernetes_secret.am-config-secret[0].metadata[0].name
            }
          }

          env {
            name = "KEYCLOAK_MASTER_REALM_PASSWORD"

            value_from {
              secret_key_ref {
                name = "keycloak-${var.kubernetes_namespace}-http"
                key  = "password"
              }
            }
          }

          tty = true
        }

        restart_policy = "Never"
      }
    }
  }
}

resource "kubernetes_secret" "am-config-secret" {
  count = var.include_keycloak ? 1 : 0

  metadata {
    name      = "am-config-secret"
    namespace = var.kubernetes_namespace
  }

  data = {
    # Keycloak deployment dependent
    KEYCLOAK_URL               = "http://keycloak-${var.kubernetes_namespace}-http.${var.kubernetes_namespace}"
    KEYCLOAK_MASTER_REALM_USER = local.keycloak_admin_username

    # OpenID Connect related
    KEYCLOAK_COMMERCE_REALM_NAME                     = local.keycloak_commerce_realm
    KEYCLOAK_CLIENT_ACCOUNT_MANAGEMENT_CLIENT_ID     = local.keycloak_am_client_id
    KEYCLOAK_CLIENT_ACCOUNT_MANAGEMENT_REDIRECT_URIS = local.keycloak_am_redirect_uris
    KEYCLOAK_SELLER_USERS_ROLE                       = local.keycloak_seller_users_role
    KEYCLOAK_ASSOCIATES_ROLE                         = local.keycloak_associates_role
    KEYCLOAK_CLIENT_ACCOUNT_MANAGEMENT_SECRET        = random_string.keycloak_am_secret[0].result

    KEYCLOAK_MASTER_REALM_NAME                       = "master"
    KEYCLOAK_MASTER_REALM_CLIENT_ID                  = "admin-cli"
    KEYCLOAK_CLIENT_ACCOUNT_MANAGEMENT_PUBLIC_CLIENT = "false"
    KEYCLOAK_CLIENT_ACCOUNT_MANAGEMENT_AUTH_TYPE     = "client-secret"
    KEYCLOAK_CLIENT_ACCOUNT_MANAGEMENT_LOGIN_THEME   = "default"

    SMTP_HOST         = "notused"
    SMTP_PORT         = "3025"
    SMTP_FROM_EMAIL   = "identity@example.com"
    SMTP_FROM_DISPLAY = "Elastic Path Account Management"
    SMTP_STARTTLS     = "false"
    SMTP_USER         = "notused"
    SMTP_PASSWORD     = "notused"

    SELLER_ADMIN_EMAIL      = local.seller_admin_email
    SELLER_ADMIN_PASSWORD   = random_string.seller_admin_password[0].result
    SELLER_ADMIN_FIRST_NAME = "Seller"
    SELLER_ADMIN_LAST_NAME  = "Admin"
  }
}

resource "random_string" "seller_admin_password" {
  count = var.include_keycloak ? 1 : 0

  length  = 16
  upper   = true
  lower   = true
  number  = true
  special = false
}

resource "random_string" "keycloak_am_secret" {
  count = var.include_keycloak ? 1 : 0

  length  = 32
  upper   = true
  lower   = true
  number  = true
  special = false
}

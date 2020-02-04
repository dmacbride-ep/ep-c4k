
output "keycloak_url" {
  depends_on = [helm_release.keycloak]
  value      = var.include_keycloak ? "https://${local.keycloak_domain_name}" : "N/A"
}

output "keycloak_admin_password" {
  depends_on = [helm_release.keycloak]
  value      = var.include_keycloak ? "${lookup(data.kubernetes_secret.keycloak_password[0].data, "password")}" : "N/A"
}

output "keycloak_admin_username" {
  depends_on = [helm_release.keycloak]
  value      = var.include_keycloak ? local.keycloak_admin_username : "N/A"
}

output "seller_admin_username" {
  depends_on = [helm_release.keycloak]
  value      = var.include_keycloak ? local.seller_admin_email : "N/A"
}

output "seller_admin_password" {
  depends_on = [helm_release.keycloak]
  value      = var.include_keycloak ? random_string.seller_admin_password[0].result : "N/A"
}

output "felix_webconsole_username" {
  value = local.felix_webconsole_username
}

output "felix_webconsole_password" {
  value = random_string.felix_webconsole_password.result
}

output "account_management_api_url" {
  value = "https://${local.am_api_domain_name}"
}

output "account_management_api_studio_url" {
  value = "https://${local.am_api_domain_name}/studio"
}

output "account_management_ui_url" {
  value = "https://${local.am_ui_domain_name}"
}

output "public_jwt_key" {
  value = var.public_jwt_key
}

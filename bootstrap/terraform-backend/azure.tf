data "azurerm_resource_group" "rg" {
  count = "${var.cloud == "azure" ? 1 : 0}"

  name = "${var.azure_resource_group_name}"
}

resource "azurerm_storage_account" "terraform_backend" {
  count = var.cloud == "azure" ? 1 : 0

  name                     = var.azure_backend_storage_account_name
  resource_group_name      = data.azurerm_resource_group.rg[0].name
  location                 = var.azure_location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_storage_container" "terraform_backend" {
  count      = var.cloud == "azure" ? 1 : 0
  depends_on = [null_resource.depends_on_storage_account]

  name                  = var.azure_backend_container_name
  storage_account_name  = azurerm_storage_account.terraform_backend[0].name
  container_access_type = "private"
}

# this resource is here to force the terraform CLI to wait for the other resources in this file to be completed before returning
# by doing this, we can ensure that the backend is actually ready before it is used
resource "null_resource" "depends_on_storage_account" {
  count      = var.cloud == "azure" ? 1 : 0
  depends_on = [azurerm_storage_account.terraform_backend]

  # we just need a map with a static string to ensure that this null_resource is only created once,
  # and not recreated each time "terraform apply" is run
  triggers = {
    "static" = "string"
  }

  provisioner "local-exec" {
    command = "bash ./wait-for-azure-backend-creation.sh"
    environment = {
      azure_service_principal_tenant_id  = "${var.azure_service_principal_tenant_id}"
      azure_service_principal_app_id     = "${var.azure_service_principal_app_id}"
      azure_service_principal_password   = "${var.azure_service_principal_password}"
      resource_group_name                = "${data.azurerm_resource_group.rg[0].name}"
      azure_backend_storage_account_name = "${var.azure_backend_storage_account_name}"
    }
  }
}

data "azurerm_resource_group" "rg" {
  count = "${(var.cloud == "azure") && (terraform.workspace == "bootstrap") ? 1 : 0}"

  name = "${var.azure_resource_group_name}"
}

data "azurerm_kubernetes_service_versions" "current" {
  count = "${(var.cloud == "azure") && (terraform.workspace == "bootstrap") ? 1 : 0}"

  location = "${data.azurerm_resource_group.rg[0].location}"
  version_prefix = "${var.kubernetes_version}"
}

resource "azurerm_kubernetes_cluster" "hub" {
  count = (var.cloud == "azure") && (terraform.workspace == "bootstrap") ? 1 : 0
  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      default_node_pool[0].min_count,
      default_node_pool[0].max_count,
      api_server_authorized_ip_ranges]
  }

  name                = var.kubernetes_cluster_name
  location            = data.azurerm_resource_group.rg[0].location
  resource_group_name = data.azurerm_resource_group.rg[0].name
  dns_prefix          = var.kubernetes_cluster_name
  kubernetes_version  = data.azurerm_kubernetes_service_versions.current[0].latest_version

  # this is required until Azure fixes a bug in the azurerm Terraform provider which prevents us from using the
  # api_server_authorized_ip_ranges setting of azurerm_kubernetes_cluster when also enabling cluster autoscaler
  provisioner "local-exec" {
    command = "bash ./set-kubernetes-api-server-authorized-ip-cidrs.sh"
    environment = {
      azure_service_principal_tenant_id         = "${var.azure_service_principal_tenant_id}"
      azure_service_principal_app_id            = "${var.azure_service_principal_app_id}"
      azure_service_principal_password          = "${var.azure_service_principal_password}"
      resource_group_name                       = "${data.azurerm_resource_group.rg[0].name}"
      kubernetes_cluster_name                   = "${var.kubernetes_cluster_name}"
      azure_k8s_api_server_authorized_ip_ranges = "${join(",", var.azure_k8s_api_server_authorized_ip_ranges)}"
    }
  }

  service_principal {
    client_id     = var.azure_service_principal_app_id
    client_secret = var.azure_service_principal_password
  }

  default_node_pool {
    name                = "default"
    node_count          = var.azure_aks_min_node_count
    vm_size             = var.azure_aks_vm_size
    os_disk_size_gb     = 30
    type                = "VirtualMachineScaleSets"
    enable_auto_scaling = true
    min_count           = var.azure_aks_min_node_count
    max_count           = 100
    vnet_subnet_id      = azurerm_subnet.hub[0].id
  }

  addon_profile {
    kube_dashboard {
      enabled = true
    }
  }

  linux_profile {
    admin_username = "azureuser"
    ssh_key {
      key_data = var.azure_aks_ssh_key
    }
  }

  network_profile {
    network_plugin     = "azure"
    dns_service_ip     = "10.2.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
    service_cidr       = "10.2.0.0/24"
    load_balancer_sku  = "standard"
  }

  role_based_access_control {
    enabled = true
  }
}

resource "azurerm_subnet" "hub" {
  count = (var.cloud == "azure") && (terraform.workspace == "bootstrap") ? 1 : 0

  name                 = var.kubernetes_cluster_name
  resource_group_name  = data.azurerm_resource_group.rg[0].name
  address_prefix       = "10.1.0.0/16"
  virtual_network_name = azurerm_virtual_network.hub[0].name

  service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
}

resource "azurerm_virtual_network" "hub" {
  count = (var.cloud == "azure") && (terraform.workspace == "bootstrap") ? 1 : 0

  name                = var.kubernetes_cluster_name
  location            = data.azurerm_resource_group.rg[0].location
  resource_group_name = data.azurerm_resource_group.rg[0].name
  address_space       = ["10.1.0.0/16"]
}

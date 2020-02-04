data "azurerm_resource_group" "aks_cluster_resource_group" {
  name = "${var.resource_group}"
}

resource "azurerm_mysql_server" "database" {
  depends_on = [
    random_string.root_username_suffix,
    random_string.root_password,
  ]

  name                = var.database_name
  location            = data.azurerm_resource_group.aks_cluster_resource_group.location
  resource_group_name = data.azurerm_resource_group.aks_cluster_resource_group.name

  sku {
    name     = "GP_Gen5_4"
    capacity = 4
    tier     = "GeneralPurpose"
    family   = "Gen5"
  }

  storage_profile {
    storage_mb            = 1048576
    backup_retention_days = 7
    geo_redundant_backup  = "Enabled"
  }

  administrator_login          = "epadmin-${random_string.root_username_suffix.result}"
  administrator_login_password = random_string.root_password.result
  version                      = "5.7"
  ssl_enforcement              = "Enabled"
}


resource "azurerm_mysql_configuration" "setting" {
  for_each = {
    tx_isolation         = "READ-COMMITTED"
    character_set_server = "UTF8MB4"
    wait_timeout         = "5400"
  }

  name                = each.key
  resource_group_name = data.azurerm_resource_group.aks_cluster_resource_group.name
  server_name         = azurerm_mysql_server.database.name
  value               = each.value
}

data "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "${var.kubernetes_cluster_name}"
  resource_group_name = "${data.azurerm_resource_group.aks_cluster_resource_group.name}"
}

resource "azurerm_mysql_virtual_network_rule" "allow_from_aks_cluster" {
  for_each = zipmap(data.azurerm_kubernetes_cluster.aks_cluster.agent_pool_profile[*].name, data.azurerm_kubernetes_cluster.aks_cluster.agent_pool_profile[*].vnet_subnet_id)

  name                = "allow-from-aks-cluster-${var.kubernetes_cluster_name}-for-agent-pool-${each.key}"
  resource_group_name = data.azurerm_resource_group.aks_cluster_resource_group.name
  server_name         = azurerm_mysql_server.database.name
  subnet_id           = data.azurerm_kubernetes_cluster.aks_cluster.agent_pool_profile[0].vnet_subnet_id
}
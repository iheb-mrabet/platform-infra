data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "platform" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "platform" {
  name                = "${var.project_prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
}

resource "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.platform.name
  virtual_network_name = azurerm_virtual_network.platform.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_log_analytics_workspace" "platform" {
  name                = "${var.project_prefix}-logs"
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_registry" "platform" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.platform.name
  location            = azurerm_resource_group.platform.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_key_vault" "platform" {
  name                = var.key_vault_name
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
}

resource "azurerm_public_ip" "ingress" {
  name                = "ingress-public-ip"
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_kubernetes_cluster" "platform" {
  name                      = "${var.project_prefix}-aks"
  location                  = azurerm_resource_group.platform.location
  resource_group_name       = azurerm_resource_group.platform.name
  dns_prefix                = "${var.project_prefix}-aks"
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"

    service_cidr   = "10.2.0.0/16"
    dns_service_ip = "10.2.0.10"
  }

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_D2s_v7"
    vnet_subnet_id = azurerm_subnet.aks.id
  }

  identity {
    type = "SystemAssigned"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.platform.id
  }
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.platform.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.platform.kubelet_identity[0].object_id
}

resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = azurerm_resource_group.platform.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.platform.identity[0].principal_id
}

resource "azurerm_user_assigned_identity" "crossplane" {
  name                = "crossplane-identity"
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
}

resource "azurerm_federated_identity_credential" "crossplane" {
  name                = "crossplane-fic"
  resource_group_name = azurerm_resource_group.platform.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.platform.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.crossplane.id
  subject             = "system:serviceaccount:crossplane-system:provider-azure"
}

resource "azurerm_role_assignment" "crossplane_contributor" {
  scope                = azurerm_resource_group.platform.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.crossplane.principal_id
}
output "resource_group_name" {
  value = azurerm_resource_group.platform.name
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.platform.name
}

output "acr_login_server" {
  value = azurerm_container_registry.platform.login_server
}

output "ingress_public_ip" {
  value = azurerm_public_ip.ingress.ip_address
}

output "crossplane_client_id" {
  value = azurerm_user_assigned_identity.crossplane.client_id
}

output "oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.platform.oidc_issuer_url
}
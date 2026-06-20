package main

deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "azurerm_kubernetes_cluster"
  not rc.change.after.oidc_issuer_enabled
  msg := "AKS clusters must have OIDC issuer enabled for Workload Identity"
}

deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "azurerm_kubernetes_cluster"
  not rc.change.after.workload_identity_enabled
  msg := "AKS clusters must have Workload Identity enabled"
}

deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "azurerm_container_registry"
  rc.change.after.admin_enabled == true
  msg := "ACR admin user must be disabled"
}

deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "azurerm_public_ip"
  rc.change.after.sku != "Standard"
  msg := "Public IP must use Standard SKU for AKS LoadBalancer"
}
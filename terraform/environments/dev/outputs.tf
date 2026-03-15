output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "aks_cluster_name" {
  value = module.aks.cluster_name
}

output "acr_name" {
  value = azurerm_container_registry.this.name
}

output "key_vault_name" {
  value = azurerm_key_vault.this.name
}

output "log_analytics_workspace_name" {
  value = module.observability.log_analytics_workspace_name
}

output "oidc_issuer_url" {
  value = module.aks.oidc_issuer_url
}

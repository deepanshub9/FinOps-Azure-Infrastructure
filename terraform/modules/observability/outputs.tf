output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.this.id
}

output "log_analytics_workspace_name" {
  value = azurerm_log_analytics_workspace.this.name
}

output "action_group_id" {
  value = azurerm_monitor_action_group.platform.id
}

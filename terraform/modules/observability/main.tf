resource "azurerm_log_analytics_workspace" "this" {
  name                = var.log_analytics_workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}

resource "azurerm_monitor_action_group" "platform" {
  name                = var.action_group_name
  resource_group_name = var.resource_group_name
  short_name          = "agplat"
  tags                = var.tags

  email_receiver {
    name          = "primary"
    email_address = var.alert_email
  }
}

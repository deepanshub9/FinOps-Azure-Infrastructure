locals {
  base_name           = "${var.prefix}-${var.environment}"
  resource_group_name = "rg-${local.base_name}"
  tags                = merge(var.tags, { managed_by = "terraform" })
}

resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.tags
}

module "network" {
  source              = "../../modules/network"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  vnet_name           = "vnet-${local.base_name}"
  vnet_cidr           = "10.20.0.0/16"
  aks_subnet_name     = "snet-aks"
  aks_subnet_cidr     = "10.20.1.0/24"
  tags                = local.tags
}

module "observability" {
  source                       = "../../modules/observability"
  resource_group_name          = azurerm_resource_group.this.name
  location                     = azurerm_resource_group.this.location
  log_analytics_workspace_name = "law-${local.base_name}"
  log_retention_days           = var.log_retention_days
  action_group_name            = "ag-${local.base_name}"
  alert_email                  = var.budget_alert_email
  tags                         = local.tags
}

resource "azurerm_container_registry" "this" {
  name                = "acr${replace(local.base_name, "-", "")}${random_string.suffix.result}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Basic"
  admin_enabled       = false
  tags                = local.tags
}

resource "azurerm_key_vault" "this" {
  name                       = "kv-${local.base_name}-${random_string.suffix.result}"
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  tags                       = local.tags
}

module "aks" {
  source                     = "../../modules/aks"
  resource_group_name        = azurerm_resource_group.this.name
  location                   = azurerm_resource_group.this.location
  aks_name                   = "aks-${local.base_name}"
  dns_prefix                 = "aks-${local.base_name}"
  kubernetes_version         = var.kubernetes_version
  node_vm_size               = var.node_vm_size
  node_count                 = var.node_count
  max_pods                   = var.max_pods
  subnet_id                  = module.network.aks_subnet_id
  log_analytics_workspace_id = module.observability.log_analytics_workspace_id
  tags                       = local.tags
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity_object_id
}

# COST REDUCTION: AKS control-plane diagnostic settings disabled for dev.
# Re-enable by uncommenting when needed for debugging (adds ~$10/week to Log Analytics bill).
# resource "azurerm_monitor_diagnostic_setting" "aks_control_plane" {
#   name                       = "diag-aks-control-plane"
#   target_resource_id         = module.aks.cluster_id
#   log_analytics_workspace_id = module.observability.log_analytics_workspace_id
#   enabled_log { category = "kube-apiserver" }
#   enabled_log { category = "kube-controller-manager" }
#   enabled_log { category = "kube-scheduler" }
#   enabled_metric { category = "AllMetrics" }
# }

resource "azurerm_consumption_budget_resource_group" "this" {
  name              = "budget-${local.base_name}"
  resource_group_id = azurerm_resource_group.this.id
  amount            = var.budget_amount_usd
  time_grain        = "Monthly"

  time_period {
    start_date = var.budget_start_date
    end_date   = "2035-12-31T23:59:59Z"
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.budget_alert_email]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_emails = [var.budget_alert_email]
  }
}

data "azurerm_client_config" "current" {}

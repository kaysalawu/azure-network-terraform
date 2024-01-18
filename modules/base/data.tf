
data "azurerm_log_analytics_workspace" "this" {
  count               = var.log_analytics_workspace_name == null ? 0 : 1
  resource_group_name = var.resource_group
  name                = var.log_analytics_workspace_name
}

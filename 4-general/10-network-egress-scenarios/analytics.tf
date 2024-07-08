
####################################################
# vnet flow logs
####################################################

locals {
  vnet_flow_logs_queries = {
    # _VFL_Hub1_PL_In = templatefile("./queries/NTANetAnalytics/BandwidthIngressIp.txt", { Ip = local.hub1_spoke3_blob_pep_ip })
  }
}

# query pack

resource "azurerm_log_analytics_query_pack" "vnet_flow_logs" {
  name                = "${local.prefix}-vnet-flow-logs"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# queries

resource "azurerm_log_analytics_query_pack_query" "vnet_flow_logs_queries" {
  for_each      = local.vnet_flow_logs_queries
  query_pack_id = azurerm_log_analytics_query_pack.vnet_flow_logs.id
  body          = each.value
  display_name  = each.key
}


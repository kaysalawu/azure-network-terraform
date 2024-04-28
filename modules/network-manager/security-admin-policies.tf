
locals {
  network_manager = local.use_azapi ? azapi_resource.avnm[0] : azurerm_network_manager.avnm[0]
  policy_ng_spokes_prod_float = templatefile("../../policies/avnm/ng-spokes-prod-float.json", {
    NETWORK_GROUP_ID = azurerm_network_manager_network_group.ng_spokes_prod_float.id
    LAB_ID           = local.prefix
    ENV              = "prod"
    NODE_TYPE        = "float"
  })
  secadmin_rules_global = {
    "tcp-high-risk" = {
      description = "tcp-high-risk"
      action      = "Deny"
      direction   = "Inbound"
      priority    = 1
      protocol    = "Tcp"
      destination_port_ranges = [
        "20", "21", "23", "111", "119", "135", "161", "162", "445", "512", "514", "593", "873", "2049", "5800", "5900", "11211",
      ]
      source = [
        { address_prefix_type = "IPPrefix", address_prefix = "*" }
      ]
      destinations = [
        { address_prefix_type = "IPPrefix", address_prefix = "*" }
      ]
    },
    "udp-high-risk" = {
      description = "udp-high-risk"
      action      = "Deny"
      direction   = "Inbound"
      priority    = 2
      protocol    = "Udp"
      destination_port_ranges = [
        "111", "135", "162", "593", "2049",
      ]
      source = [
        { address_prefix_type = "IPPrefix", address_prefix = "*" }
      ]
      destinations = [
        { address_prefix_type = "IPPrefix", address_prefix = "*" }
      ]
    }
  }
}

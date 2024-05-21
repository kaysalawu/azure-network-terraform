
locals {
  megaport_vlan1         = 100
  megaport_vlan2         = 200
  megaport_vlan3         = 300
  express_route_location = "Dublin"
  megaport_location      = "Equinix LD5"
  bandwidth_in_mbps      = 50
}

provider "megaport" {
  alias                 = "mega"
  access_key            = var.megaport_access_key
  secret_key            = var.megaport_secret_key
  accept_purchase_terms = true
  delete_ports          = true
  environment           = "production"
}

variable "megaport_access_key" {}
variable "megaport_secret_key" {}

####################################################
# megaport
####################################################
/*
module "megaport" {
  source = "../../modules/megaport"
  providers = {
    megaport = megaport.mega
  }
  resource_group    = azurerm_resource_group.rg.name
  prefix            = lower("salawu-${local.prefix}")
  azure_location    = local.region1
  megaport_location = local.megaport_location

  mcr = [
    {
      name          = "mcr1"
      port_speed    = 1000
      requested_asn = local.megaport_asn
    },
  ]

  circuits = [
    {
      name                    = "${local.prefix}-er1"
      mcr_name                = "mcr1"
      location                = local.region1
      peering_location        = local.express_route_location
      bandwidth_in_mbps       = local.bandwidth_in_mbps
      requested_vlan          = local.megaport_vlan1
      enable_mcr_auto_peering = false
      enable_mcr_peering      = true

      ipv4_config = {
        primary_peer_address_prefix   = local.csp_range1
        secondary_peer_address_prefix = local.csp_range2
      }
    },
    {
      name                    = "${local.prefix}-er2"
      mcr_name                = "mcr1"
      location                = local.region1
      peering_location        = local.express_route_location
      bandwidth_in_mbps       = local.bandwidth_in_mbps
      requested_vlan          = local.megaport_vlan2
      enable_mcr_auto_peering = false
      enable_mcr_peering      = true

      ipv4_config = {
        primary_peer_address_prefix   = local.csp_range3
        secondary_peer_address_prefix = local.csp_range4
      }
      ipv6_config = {
        primary_peer_address_prefix   = local.csp_range3_v6
        secondary_peer_address_prefix = local.csp_range4_v6
      }
    },
    {
      name                    = "${local.prefix}-er3"
      mcr_name                = "mcr1"
      location                = local.region1
      peering_location        = local.express_route_location
      bandwidth_in_mbps       = local.bandwidth_in_mbps
      requested_vlan          = local.megaport_vlan3
      enable_mcr_auto_peering = false
      enable_mcr_peering      = true

      ipv4_config = {
        primary_peer_address_prefix   = local.csp_range5
        secondary_peer_address_prefix = local.csp_range6
      }
    },
  ]

  gateway_connections = [
    {
      express_route_circuit_name   = "${local.prefix}-er1",
      virtual_network_gateway_name = module.hub1.ergw_name
    },
    {
      express_route_circuit_name   = "${local.prefix}-er2",
      virtual_network_gateway_name = module.hub1.ergw_name
    },
    {
      express_route_circuit_name   = "${local.prefix}-er3",
      virtual_network_gateway_name = module.branch2.ergw_name
    },
  ]
}

###################################################
# dashboard
###################################################

locals {
  dashboard_vars = templatefile("./dashboard/system-dashboard.json", {
    ER1_CIRCUIT_NAME = module.megaport.express_route_circuit["${local.prefix}-er1"].name,
    ER2_CIRCUIT_NAME = module.megaport.express_route_circuit["${local.prefix}-er2"].name,
    ER1_CIRCUIT_ID   = module.megaport.express_route_circuit["${local.prefix}-er1"].id,
    ER2_CIRCUIT_ID   = module.megaport.express_route_circuit["${local.prefix}-er2"].id,
    HUB1_ERGW_ID     = module.hub1.ergw.id,
    HUB1_ERGW_NAME   = module.hub1.ergw_name,
  })
}

resource "azurerm_portal_dashboard" "express_route" {
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  name                 = "${local.prefix}-system-dashboard"
  dashboard_properties = local.dashboard_vars
}
*/

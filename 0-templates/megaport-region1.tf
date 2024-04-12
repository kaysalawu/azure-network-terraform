
locals {
  azure_asn              = 12706
  megaport_asn           = 64512
  megaport_vlan1         = 100
  megaport_vlan2         = 200
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
# megaport links
####################################################

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
      name                          = "${local.prefix}-hub2-er"
      connection_target             = "vnet"
      location                      = local.region1
      peering_location              = local.express_route_location
      bandwidth_in_mbps             = local.bandwidth_in_mbps
      requested_vlan                = local.megaport_vlan1
      mcr_name                      = "mcr1"
      primary_peer_address_prefix   = local.csp_range1
      secondary_peer_address_prefix = local.csp_range2
      virtual_network_gateway_id    = module.hub2.ergw.id
      peering_type                  = "AzurePrivatePeering"
    },
    {
      name                          = "${local.prefix}-branch2-er"
      connection_target             = "vnet"
      location                      = local.region1
      peering_location              = local.express_route_location
      bandwidth_in_mbps             = local.bandwidth_in_mbps
      requested_vlan                = local.megaport_vlan2
      mcr_name                      = "mcr1"
      primary_peer_address_prefix   = local.csp_range3
      secondary_peer_address_prefix = local.csp_range4
      virtual_network_gateway_id    = module.branch2.ergw.id
      peering_type                  = "AzurePrivatePeering"
    },
  ]
}

####################################################
# dashboard
####################################################

locals {
  hub2_er_dashboard_vars = {
    ER_CIRCUIT1 = module.megaport.expressroute_circuits["${local.prefix}-hub2-er"].id
  }
  dashboard_properties = templatefile("./dashboard/dashboard.json", local.hub2_er_dashboard_vars)
}

resource "azurerm_portal_dashboard" "hub2_er" {
  name                 = "${local.hub2_prefix}hub2-er-db"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = local.hub2_location
  tags                 = local.hub2_tags
  dashboard_properties = local.dashboard_properties
}
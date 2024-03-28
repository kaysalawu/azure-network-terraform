
locals {
  megaport_asn           = 64512
  megaport_vlan1         = 100
  megaport_vlan2         = 200
  megaport_vlan3         = 300
  megaport_vlan4         = 400
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
    # {
    #   name                          = "vhub1"
    #   connection_target             = "vwan"
    #   location                      = local.region1
    #   peering_location              = local.express_route_location
    #   bandwidth_in_mbps             = local.bandwidth_in_mbps
    #   requested_vlan                = local.megaport_vlan1
    #   mcr_name                      = "mcr1"
    #   primary_peer_address_prefix   = local.csp_range1
    #   secondary_peer_address_prefix = local.csp_range2
    #   express_route_gateway_id      = module.vhub1.ergw.id
    #   peering_type                  = "AzurePrivatePeering"
    # },
    # {
    #   name                          = "branch2"
    #   connection_target             = "vnet"
    #   location                      = local.region1
    #   peering_location              = local.express_route_location
    #   bandwidth_in_mbps             = local.bandwidth_in_mbps
    #   requested_vlan                = local.megaport_vlan2
    #   mcr_name                      = "mcr1"
    #   primary_peer_address_prefix   = local.csp_range3
    #   secondary_peer_address_prefix = local.csp_range4
    #   virtual_network_gateway_id    = module.branch2.ergw.id
    #   peering_type                  = "AzurePrivatePeering"
    # },
  ]
  depends_on = [
    # module.common,
    # module.vhub1,
    # module.branch2,
  ]
}

####################################################
# dashboard
####################################################

# locals {
#   hub1_er_dashboard_vars = {
#     ER_CIRCUIT1 = module.megaport.expressroute_circuits["vhub1"].id
#   }
#   dashboard_properties = templatefile("./dashboard/dashboard.json", local.hub1_er_dashboard_vars)
# }

# resource "azurerm_portal_dashboard" "hub1_er" {
#   name                 = "${local.hub1_prefix}hub1-er-db"
#   resource_group_name  = azurerm_resource_group.rg.name
#   location             = local.hub1_location
#   tags                 = local.hub1_tags
#   dashboard_properties = local.dashboard_properties
# }
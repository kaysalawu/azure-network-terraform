
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
      name                         = "${local.prefix}-er1"
      mcr_name                     = "mcr1"
      location                     = local.region1
      peering_location             = local.express_route_location
      bandwidth_in_mbps            = local.bandwidth_in_mbps
      requested_vlan               = local.megaport_vlan1
      virtual_network_gateway_name = module.hub1.ergw_name
      enable_mcr_auto_peering      = false
      enable_mcr_peering           = true

      ipv4_config = {
        primary_peer_address_prefix   = local.csp_range1
        secondary_peer_address_prefix = local.csp_range2
      }
    },
  ]
}

####################################################
# gateway connections
####################################################

# branch2

resource "azurerm_express_route_circuit_authorization" "er1_branch2" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.prefix}-er1-branch2"
  express_route_circuit_name = module.megaport.express_route_circuit["${local.prefix}-er1"].name
}

resource "azurerm_virtual_network_gateway_connection" "er1_branch2" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.prefix}-er1-branch2"
  location                   = local.region1
  type                       = "ExpressRoute"
  virtual_network_gateway_id = module.branch2.ergw.id
  authorization_key          = azurerm_express_route_circuit_authorization.er1_branch2.authorization_key
  express_route_circuit_id   = module.megaport.express_route_circuit["${local.prefix}-er1"].id
}


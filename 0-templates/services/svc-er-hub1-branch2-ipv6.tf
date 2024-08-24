
# This example shows how to run IPv6 over ExpressRoute private peering.
# ER circuit er1 only establishes layer 2 connection to megaport in order to bring the circuit up.
# Once the circuit is up, gateway connections from branch2 and hub1 are established to the circuit.
# Hairpinning over er1 allows branch2 to communicate directly with hub1.
# mcr1 is not in the data path in this scenario.

locals {
  megaport_vlan1         = 100
  megaport_vlan2         = 200
  megaport_vlan3         = 300
  express_route_location = "London"
  megaport_location      = "Global Switch London East"
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
      name              = "${local.prefix}-er1"
      mcr_name          = "mcr1"
      location          = local.region1
      peering_location  = local.express_route_location
      bandwidth_in_mbps = local.bandwidth_in_mbps
      requested_vlan    = local.megaport_vlan1

      primary_peer_address_prefix_ipv4   = local.csp_range1
      secondary_peer_address_prefix_ipv4 = local.csp_range2
      primary_peer_address_prefix_ipv6   = local.csp_range1_v6
      secondary_peer_address_prefix_ipv6 = local.csp_range2_v6

      # mcr_config_block creates layer2 and layer3 config on megaport and azure sides
      mcr_config = {
        enable_auto_peering    = false # auto-assign addresses
        create_private_peering = false # use provided addresses
      }

      # azure_config_block is only used when all mcr_config attributes are false
      # creates layer2 and layer3 config on azure and megaport sides
      azure_config = {
        create_ipv4_peering = true
        create_ipv6_peering = true
      }
    },
  ]

  gateway_connections = [
    {
      virtual_network_gateway_name = module.hub1.ergw_name
      express_route_circuit_name   = "${local.prefix}-er1"
    },
    {
      virtual_network_gateway_name = module.branch2.ergw_name
      express_route_circuit_name   = "${local.prefix}-er1"
    },
  ]

  depends_on = [
    module.hub1,
    module.branch2,
  ]
}

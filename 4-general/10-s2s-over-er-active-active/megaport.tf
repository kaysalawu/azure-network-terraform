
locals {
  megaport_asn           = 64512
  megaport_vlan          = 200
  express_route_location = "Dublin"
  megaport_location      = "Equinix DB1"
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
  megaport_location = "Equinix DC4"

  mcr = [
    {
      name          = "mcr"
      port_speed    = 1000
      requested_asn = local.megaport_asn
    }
  ]

  circuits = [
    # {
    #   name                          = "branch1"
    #   location                      = local.region1
    #   peering_location              = local.express_route_location
    #   bandwidth_in_mbps             = local.bandwidth_in_mbps
    #   requested_vlan                = 200
    #   mcr_name                      = "mcr"
    #   primary_peer_address_prefix   = local.csp_range1
    #   secondary_peer_address_prefix = local.csp_range2
    #   virtual_network_gateway_id    = module.branch1.ergw.id
    # },
    # {
    #   name                          = "hub1"
    #   location                      = local.region1
    #   peering_location              = local.express_route_location
    #   bandwidth_in_mbps             = local.bandwidth_in_mbps
    #   requested_vlan                = 201
    #   mcr_name                      = "mcr"
    #   primary_peer_address_prefix   = local.csp_range3
    #   secondary_peer_address_prefix = local.csp_range4
    #   virtual_network_gateway_id    = module.hub1.ergw.id
    # }
  ]
}

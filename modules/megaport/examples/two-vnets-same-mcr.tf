
locals {
  megaport_asn           = 64512
  megaport_vlan          = 200
  azure_location         = "eastus"
  express_route_location = "New York"
  megaport_location      = "Equinix NY9"
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
  prefix            = var.prefix
  azure_location    = local.azure_location
  megaport_location = local.mega_location

  mcr = [
    {
      name          = "mcr"
      port_speed    = 1000
      requested_asn = local.megaport_asn
    }
  ]

  circuits = [
    {
      name                          = "branch2"
      location                      = local.azure_location
      peering_location              = local.express_route_location
      bandwidth_in_mbps             = local.bandwidth_in_mbps
      requested_vlan                = 200
      mcr_name                      = "mcr"
      primary_peer_address_prefix   = "172.16.0.0/30"
      secondary_peer_address_prefix = "172.16.0.4/30"
      virtual_network_gateway_id    = azurerm_express_route_gateway.branch2.id
    },
    {
      name                          = "hub1"
      location                      = local.azure_location
      peering_location              = local.express_route_location
      bandwidth_in_mbps             = local.bandwidth_in_mbps
      requested_vlan                = 201
      mcr_name                      = "mcr"
      primary_peer_address_prefix   = "172.16.0.8/30"
      secondary_peer_address_prefix = "172.16.0.12/30"
      express_route_gateway_id      = azurerm_express_route_gateway.hub1.id
    }
  ]
}


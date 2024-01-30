
locals {
  express_route_location = "New York"
  megaport_location      = "Equinix NY9"
}

locals {
  megaport_prefix   = lower("salawu-${local.prefix}")
  megaport_asn      = 65111
  megaport_vlan_er1 = 100
  megaport_vlan_er2 = 200
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
    #   name                          = "branch2"
    #   location                      = local.region1
    #   peering_location              = local.express_route_location
    #   bandwidth_in_mbps             = local.bandwidth_in_mbps
    #   requested_vlan                = 200
    #   mcr_name                      = "mcr"
    #   primary_peer_address_prefix   = local.csp_range1
    #   secondary_peer_address_prefix = local.csp_range2
    #   virtual_network_gateway_id    = module.branch2.ergw.id
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
    #   express_route_gateway_id      = module.vhub1.ergw.id
    # }
  ]
}



# ####################################################
# # common
# ####################################################

# provider "megaport" {
#   username              = var.megaport_username
#   password              = var.megaport_password
#   accept_purchase_terms = true
#   delete_ports          = true
#   environment           = "production"
# }

# variable "megaport_username" {
#   description = "megaport username"
# }

# variable "megaport_password" {
#   description = "megaport password"
# }

# data "megaport_location" "thn" {
#   name    = "Telehouse North"
#   has_mcr = true
# }

# data "megaport_location" "equinix_am1" {
#   name    = "Equinix AM1"
#   has_mcr = true
# }

# data "megaport_location" "interxion_fra6" {
#   name    = "Interxion FRA6"
#   has_mcr = true
# }

# ####################################################
# # circuits
# ####################################################

# # hub1
# #------------------------

# # er1

# resource "azurerm_express_route_circuit" "er1" {
#   resource_group_name   = azurerm_resource_group.rg.name
#   name                  = "${local.prefix}-er1"
#   location              = local.hub1_location
#   service_provider_name = "Megaport"
#   peering_location      = "Frankfurt"
#   bandwidth_in_mbps     = 50
#   sku {
#     tier   = "Standard"
#     family = "MeteredData"
#   }
# }

# resource "azurerm_express_route_circuit_authorization" "hub1_er1" {
#   resource_group_name        = azurerm_resource_group.rg.name
#   name                       = "${local.hub1_prefix}er1"
#   express_route_circuit_name = azurerm_express_route_circuit.er1.name
# }

# # er1x

# resource "azurerm_express_route_circuit" "er1x" {
#   resource_group_name   = azurerm_resource_group.rg.name
#   name                  = "${local.prefix}-er1x"
#   location              = local.hub1_location
#   service_provider_name = "Megaport"
#   peering_location      = "Frankfurt"
#   bandwidth_in_mbps     = 50
#   sku {
#     tier   = "Standard"
#     family = "MeteredData"
#   }
# }

# resource "azurerm_express_route_circuit_authorization" "branch1_er1x" {
#   resource_group_name        = azurerm_resource_group.rg.name
#   name                       = "${local.branch1_prefix}er1x"
#   express_route_circuit_name = azurerm_express_route_circuit.er1x.name
# }

# # er2

# resource "azurerm_express_route_circuit" "er2" {
#   resource_group_name   = azurerm_resource_group.rg.name
#   name                  = "${local.prefix}-er2"
#   location              = local.hub1_location
#   service_provider_name = "Megaport"
#   peering_location      = "Amsterdam"
#   bandwidth_in_mbps     = 50
#   sku {
#     tier   = "Standard"
#     family = "MeteredData"
#   }
# }

# resource "azurerm_express_route_circuit_authorization" "hub1_er2" {
#   resource_group_name        = azurerm_resource_group.rg.name
#   name                       = "${local.hub1_prefix}er2"
#   express_route_circuit_name = azurerm_express_route_circuit.er2.name
# }

# # er2x

# resource "azurerm_express_route_circuit" "er2x" {
#   resource_group_name   = azurerm_resource_group.rg.name
#   name                  = "${local.prefix}-er2x"
#   location              = local.hub1_location
#   service_provider_name = "Megaport"
#   peering_location      = "Amsterdam"
#   bandwidth_in_mbps     = 50
#   sku {
#     tier   = "Standard"
#     family = "MeteredData"
#   }
# }

# resource "azurerm_express_route_circuit_authorization" "branch1_er2x" {
#   resource_group_name        = azurerm_resource_group.rg.name
#   name                       = "${local.branch1_prefix}er2x"
#   express_route_circuit_name = azurerm_express_route_circuit.er2x.name
# }

# # ####################################################
# # # megaport
# # ####################################################

# # # mcr
# # #----------------------------

# # er1

# resource "megaport_mcr" "er1" {
#   mcr_name    = "${local.megaport_prefix}-er1"
#   location_id = data.megaport_location.interxion_fra6.id
#   router {
#     port_speed    = 1000
#     requested_asn = local.megaport_asn
#   }
# }

# # er2

# resource "megaport_mcr" "er2" {
#   mcr_name    = "${local.megaport_prefix}-er1"
#   location_id = data.megaport_location.equinix_am1.id
#   router {
#     port_speed    = 1000
#     requested_asn = local.megaport_asn
#   }
# }

# # connection
# #----------------------------

# # er1

# resource "megaport_azure_connection" "er1" {
#   vxc_name   = "${local.megaport_prefix}-er1"
#   rate_limit = 50
#   a_end {
#     requested_vlan = local.megaport_vlan_er1
#   }
#   csp_settings {
#     service_key = azurerm_express_route_circuit.er1.service_key
#     attached_to = megaport_mcr.er1.id
#     peerings {
#       private_peer   = true
#       microsoft_peer = false
#     }
#   }
# }

# # er1x

# resource "megaport_azure_connection" "er1x" {
#   vxc_name   = "${local.megaport_prefix}-er1x"
#   rate_limit = 50
#   a_end {
#     requested_vlan = local.megaport_vlan_er1x
#   }
#   csp_settings {
#     service_key = azurerm_express_route_circuit.er1x.service_key
#     attached_to = megaport_mcr.er1.id
#     peerings {
#       private_peer   = true
#       microsoft_peer = false
#     }
#   }
# }

# # er2

# resource "megaport_azure_connection" "er2" {
#   vxc_name   = "${local.megaport_prefix}-er2"
#   rate_limit = 50
#   a_end {
#     requested_vlan = local.megaport_vlan_er2
#   }
#   csp_settings {
#     service_key = azurerm_express_route_circuit.er2.service_key
#     attached_to = megaport_mcr.er2.id
#     peerings {
#       private_peer   = true
#       microsoft_peer = false
#     }
#   }
# }

# # er2x

# resource "megaport_azure_connection" "er2x" {
#   vxc_name   = "${local.megaport_prefix}-er2x"
#   rate_limit = 50
#   a_end {
#     requested_vlan = local.megaport_vlan_er2x
#   }
#   csp_settings {
#     service_key = azurerm_express_route_circuit.er2x.service_key
#     attached_to = megaport_mcr.er2.id
#     peerings {
#       private_peer   = true
#       microsoft_peer = false
#     }
#   }
# }

# ####################################################
# # gateway
# ####################################################

# # hub1

# resource "azurerm_virtual_network_gateway_connection" "hub1_er1" {
#   resource_group_name        = azurerm_resource_group.rg.name
#   name                       = "${local.hub1_prefix}er1"
#   location                   = local.hub1_location
#   type                       = "ExpressRoute"
#   virtual_network_gateway_id = module.hub1.ergw.id
#   authorization_key          = azurerm_express_route_circuit_authorization.hub1_er1.authorization_key
#   express_route_circuit_id   = azurerm_express_route_circuit.er1.id
#   depends_on = [
#     megaport_azure_connection.er1
#   ]
# }

# resource "azurerm_virtual_network_gateway_connection" "hub1_er2" {
#   resource_group_name        = azurerm_resource_group.rg.name
#   name                       = "${local.hub1_prefix}er2"
#   location                   = local.hub1_location
#   type                       = "ExpressRoute"
#   virtual_network_gateway_id = module.hub1.ergw.id
#   authorization_key          = azurerm_express_route_circuit_authorization.hub1_er2.authorization_key
#   express_route_circuit_id   = azurerm_express_route_circuit.er2.id
#   depends_on = [
#     megaport_azure_connection.er2
#   ]
# }

# # branch1

# resource "azurerm_virtual_network_gateway_connection" "branch1_er1x" {
#   resource_group_name        = azurerm_resource_group.rg.name
#   name                       = "${local.branch1_prefix}er1x"
#   location                   = local.branch1_location
#   type                       = "ExpressRoute"
#   virtual_network_gateway_id = module.branch1.ergw.id
#   authorization_key          = azurerm_express_route_circuit_authorization.branch1_er1x.authorization_key
#   express_route_circuit_id   = azurerm_express_route_circuit.er1x.id
#   depends_on = [
#     megaport_azure_connection.er1x
#   ]
# }

# resource "azurerm_virtual_network_gateway_connection" "branch1_er2x" {
#   resource_group_name        = azurerm_resource_group.rg.name
#   name                       = "${local.branch1_prefix}er2x"
#   location                   = local.branch1_location
#   type                       = "ExpressRoute"
#   virtual_network_gateway_id = module.branch1.ergw.id
#   authorization_key          = azurerm_express_route_circuit_authorization.branch1_er2x.authorization_key
#   express_route_circuit_id   = azurerm_express_route_circuit.er2x.id
#   depends_on = [
#     megaport_azure_connection.er2x
#   ]
# }

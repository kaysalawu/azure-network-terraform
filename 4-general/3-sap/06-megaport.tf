
# locals
#------------------------
locals {
  megaport_prefix          = lower("salawu-${local.prefix}")
  megaport_asn             = 65111
  megaport_hub1_er_circuit = "100"
}

####################################################
# common
####################################################

provider "megaport" {
  username              = var.megaport_username
  password              = var.megaport_password
  accept_purchase_terms = true
  delete_ports          = true
  environment           = "production"
}

variable "megaport_username" {
  description = "megaport username"
}

variable "megaport_password" {
  description = "megaport password"
}

data "megaport_location" "location" {
  name    = "Telehouse North"
  has_mcr = true
}

####################################################
# circuits
####################################################

# hub1
#------------------------

# er

resource "azurerm_express_route_circuit" "hub1_er_circuit" {
  resource_group_name   = azurerm_resource_group.rg.name
  name                  = "${local.hub1_prefix}er-circuit"
  location              = local.hub1_location
  service_provider_name = "Megaport"
  peering_location      = "London"
  bandwidth_in_mbps     = 50
  sku {
    tier   = "Standard"
    family = "MeteredData"
  }
}

resource "azurerm_express_route_circuit_authorization" "hub1_er_circuit" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub1_prefix}er-circuit"
  express_route_circuit_name = azurerm_express_route_circuit.hub1_er_circuit.name
}

####################################################
# megaport
####################################################

# mcr
#----------------------------

resource "megaport_mcr" "megaport_mcr" {
  mcr_name    = "${local.megaport_prefix}-mcr"
  location_id = data.megaport_location.location.id
  router {
    port_speed    = 1000
    requested_asn = local.megaport_asn
  }
}

# connection
#----------------------------

# hub1

resource "megaport_azure_connection" "azure_vcx_hub1_er" {
  vxc_name   = "${local.megaport_prefix}-azure-vcx-hub1-er"
  rate_limit = 50
  a_end {
    requested_vlan = local.megaport_hub1_er_circuit
  }
  csp_settings {
    service_key = azurerm_express_route_circuit.hub1_er_circuit.service_key
    attached_to = megaport_mcr.megaport_mcr.id
    peerings {
      private_peer   = true
      microsoft_peer = false
    }
  }
}

####################################################
# gateway
####################################################

# hub1

resource "azurerm_virtual_network_gateway_connection" "azure_vcx_hub1_er" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub1_prefix}-azure-vcx-hub1-er"
  location                   = local.hub1_location
  type                       = "ExpressRoute"
  virtual_network_gateway_id = module.hub1.ergw.id
  authorization_key          = azurerm_express_route_circuit_authorization.hub1_er_circuit.authorization_key
  express_route_circuit_id   = azurerm_express_route_circuit.hub1_er_circuit.id
  depends_on = [
    megaport_azure_connection.azure_vcx_hub1_er
  ]
}


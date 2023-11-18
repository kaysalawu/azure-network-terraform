
# locals
#------------------------
locals {
  megaport_prefix          = lower("salawu-${local.prefix}")
  megaport_asn_mcr1        = 65011
  megaport_asn_mcr2        = 65022
  megaport_er1_onprem_vlan = "150"
  megaport_er2_onprem_vlan = "200"
  megaport_er2_hub_vlan    = "210"
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
  name    = "Equinix AM1"
  has_mcr = true
}

####################################################
# circuits
####################################################

# er1

resource "azurerm_express_route_circuit" "er1" {
  resource_group_name   = azurerm_resource_group.rg.name
  name                  = "${local.prefix}-er1"
  location              = local.hub_location
  service_provider_name = "Megaport"
  peering_location      = "Amsterdam"
  bandwidth_in_mbps     = 50
  sku {
    tier   = "Premium"
    family = "MeteredData"
  }
}

resource "azurerm_express_route_circuit_authorization" "er1_onprem" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.prefix}-er1-onprem"
  express_route_circuit_name = azurerm_express_route_circuit.er1.name
}

resource "azurerm_express_route_circuit_authorization" "er1_gr" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.prefix}-er1-gr"
  express_route_circuit_name = azurerm_express_route_circuit.er1.name
}

# er2

resource "azurerm_express_route_circuit" "er2" {
  resource_group_name   = azurerm_resource_group.rg.name
  name                  = "${local.prefix}-er2"
  location              = local.hub_location
  service_provider_name = "Megaport"
  peering_location      = "Amsterdam"
  bandwidth_in_mbps     = 50
  sku {
    tier   = "Premium"
    family = "MeteredData"
  }
}

resource "azurerm_express_route_circuit_authorization" "er2_onprem" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.prefix}-er2-onprem"
  express_route_circuit_name = azurerm_express_route_circuit.er2.name
}

resource "azurerm_express_route_circuit_authorization" "er2_hub" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.prefix}-er2-hub"
  express_route_circuit_name = azurerm_express_route_circuit.er2.name
}

####################################################
# megaport
####################################################

# mcr
#----------------------------

# mcr1

resource "megaport_mcr" "mcr1" {
  mcr_name    = "${local.megaport_prefix}-mcr1"
  location_id = data.megaport_location.location.id
  router {
    port_speed    = 1000
    requested_asn = local.megaport_asn_mcr1
  }
}

# mcr2

resource "megaport_mcr" "mcr2" {
  mcr_name    = "${local.megaport_prefix}-mcr2"
  location_id = data.megaport_location.location.id
  router {
    port_speed    = 1000
    requested_asn = local.megaport_asn_mcr2
  }
}

# connection
#----------------------------

# mcr1

resource "megaport_azure_connection" "mcr1_er1_onprem" {
  vxc_name   = "${local.megaport_prefix}-mcr1-er1-onprem"
  rate_limit = 50
  a_end {
    requested_vlan = local.megaport_er1_onprem_vlan
  }
  csp_settings {
    service_key = azurerm_express_route_circuit.er1.service_key
    attached_to = megaport_mcr.mcr1.id
    peerings {
      private_peer   = true
      microsoft_peer = false
    }
  }
}

# mcr2

resource "megaport_azure_connection" "mcr2_er2_onprem" {
  vxc_name   = "${local.megaport_prefix}-mcr2-er2-onprem"
  rate_limit = 50
  a_end {
    requested_vlan = local.megaport_er2_onprem_vlan
  }
  csp_settings {
    service_key = azurerm_express_route_circuit.er2.service_key
    attached_to = megaport_mcr.mcr2.id
    peerings {
      private_peer   = true
      microsoft_peer = false
    }
  }
}

resource "megaport_azure_connection" "mcr2_er2_hub" {
  vxc_name   = "${local.megaport_prefix}-mcr2-er2-hub"
  rate_limit = 50
  a_end {
    requested_vlan = local.megaport_er2_hub_vlan
  }
  csp_settings {
    service_key = azurerm_express_route_circuit.er2.service_key
    attached_to = megaport_mcr.mcr2.id
    peerings {
      private_peer   = true
      microsoft_peer = false
    }
  }
}

####################################################
# gateway
####################################################

# connection
#----------------------------

# onprem

resource "azurerm_virtual_network_gateway_connection" "onprem_er1" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.onprem_prefix}er1"
  location                   = local.onprem_location
  type                       = "ExpressRoute"
  virtual_network_gateway_id = module.onprem.ergw.id
  authorization_key          = azurerm_express_route_circuit_authorization.er1_onprem.authorization_key
  express_route_circuit_id   = azurerm_express_route_circuit.er1.id
  depends_on = [
    megaport_azure_connection.mcr1_er1_onprem
  ]
}

resource "azurerm_virtual_network_gateway_connection" "onprem_er2" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.onprem_prefix}er2"
  location                   = local.onprem_location
  type                       = "ExpressRoute"
  virtual_network_gateway_id = module.onprem.ergw.id
  authorization_key          = azurerm_express_route_circuit_authorization.er2_onprem.authorization_key
  express_route_circuit_id   = azurerm_express_route_circuit.er2.id
  depends_on = [
    megaport_azure_connection.mcr2_er2_onprem
  ]
}

# hub

resource "azurerm_virtual_network_gateway_connection" "hub_er2" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub_prefix}er2"
  location                   = local.hub_location
  type                       = "ExpressRoute"
  virtual_network_gateway_id = module.hub.ergw.id
  authorization_key          = azurerm_express_route_circuit_authorization.er2_hub.authorization_key
  express_route_circuit_id   = azurerm_express_route_circuit.er2.id
  depends_on = [
    megaport_azure_connection.mcr2_er2_hub
  ]
}

locals {
  er_files = {
    "output/er-scripts.sh" = local.er_scripts
  }
  er_scripts = templatefile("er-scripts.sh", {
    RG                   = azurerm_resource_group.rg.name
    ER1_CIRCUIT          = azurerm_express_route_circuit.er1.name
    ER2_CIRCUIT          = azurerm_express_route_circuit.er2.name
    ER1_CONNECTION       = azurerm_virtual_network_gateway_connection.onprem_er1.name
    ER2_CONNECTION       = azurerm_virtual_network_gateway_connection.onprem_er2.name
    ER1_PEERING_LOCATION = "Amsterdam"
    ER2_PEERING_LOCATION = "Amsterdam"
    NIC_CORE1            = local.core1_bak_srv_nic
    NIC_CORE2            = local.core2_bak_srv_nic
    NIC_YELLOW           = local.yellow_vm_nic
    NIC_ONPREM           = local.onprem_bak_srv_nic
  })
}

resource "local_file" "er_files" {
  for_each = local.er_files
  filename = each.key
  content  = each.value
}

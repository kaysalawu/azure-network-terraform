
# locals
#------------------------
locals {
  megaport_prefix         = lower("salawu-${local.prefix}")
  megaport_asn            = 65111
  megaport_vlan_er_native = "100"
  megaport_vlan_er_avs    = "200"
  megaport_vlan_er_oci    = "300"
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
/*
####################################################
# circuits
####################################################

# oci

resource "azurerm_express_route_circuit" "er_oci" {
  resource_group_name   = azurerm_resource_group.rg.name
  name                  = "${local.prefix}-er-oci"
  location              = local.region1
  service_provider_name = "Megaport"
  peering_location      = "Amsterdam"
  bandwidth_in_mbps     = 50
  sku {
    tier   = "Premium"
    family = "MeteredData"
  }
}

resource "azurerm_express_route_circuit_authorization" "er_oci" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.prefix}-er-oci"
  express_route_circuit_name = azurerm_express_route_circuit.er_oci.name
}

# avs

resource "azurerm_express_route_circuit" "er_avs" {
  resource_group_name   = azurerm_resource_group.rg.name
  name                  = "${local.prefix}-er-avs"
  location              = local.region1
  service_provider_name = "Megaport"
  peering_location      = "Amsterdam"
  bandwidth_in_mbps     = 50
  sku {
    tier   = "Premium"
    family = "MeteredData"
  }
}

resource "azurerm_express_route_circuit_authorization" "er_avs" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.prefix}-er-avs"
  express_route_circuit_name = azurerm_express_route_circuit.er_avs.name
}

# native

resource "azurerm_express_route_circuit" "er_native" {
  resource_group_name   = azurerm_resource_group.rg.name
  name                  = "${local.prefix}-er-native"
  location              = local.branch2_location
  service_provider_name = "Megaport"
  peering_location      = "Amsterdam"
  bandwidth_in_mbps     = 50
  sku {
    tier   = "Standard"
    family = "MeteredData"
  }
}

resource "azurerm_express_route_circuit_authorization" "er_native" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.prefix}-er-oci"
  express_route_circuit_name = azurerm_express_route_circuit.er_native.name
}

####################################################
# megaport
####################################################

resource "megaport_port" "port" {
  port_name   = "${local.megaport_prefix}-port"
  port_speed  = 1000
  location_id = data.megaport_location.location.id
}

resource "megaport_azure_connection" "azure_vcx_oci" {
  vxc_name   = "${local.megaport_prefix}-azure-vcx-oci"
  rate_limit = 50

  a_end {
    port_id        = megaport_port.port.id
    requested_vlan = local.megaport_vlan_er_oci
  }

  csp_settings {
    service_key = azurerm_express_route_circuit.er_oci.service_key
  }
}

resource "megaport_azure_connection" "azure_vcx_avs" {
  vxc_name   = "${local.megaport_prefix}-azure-vcx-avs"
  rate_limit = 50

  a_end {
    port_id        = megaport_port.port.id
    requested_vlan = local.megaport_vlan_er_avs
  }

  csp_settings {
    service_key = azurerm_express_route_circuit.er_avs.service_key
  }
}

resource "megaport_azure_connection" "azure_vcx_native" {
  vxc_name   = "${local.megaport_prefix}-azure-vcx-native"
  rate_limit = 50

  a_end {
    port_id        = megaport_port.port.id
    requested_vlan = local.megaport_vlan_er_native
  }

  csp_settings {
    service_key = azurerm_express_route_circuit.er_native.service_key
  }
}

####################################################
# gateway
####################################################

# oci
/*
resource "azurerm_virtual_network_gateway_connection" "azure_vcx_oci_branch3" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.prefix}-azure-vcx-oci-branch3"
  location                   = local.branch3_location
  type                       = "ExpressRoute"
  virtual_network_gateway_id = module.branch3.ergw.id
  authorization_key          = azurerm_express_route_circuit_authorization.er_oci.authorization_key
  express_route_circuit_id   = azurerm_express_route_circuit.er_oci.id
  depends_on = [
    megaport_azure_connection.azure_vcx_oci
  ]
}

# avs

resource "azurerm_virtual_network_gateway_connection" "azure_vcx_avs_hub2" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.prefix}-azure-vcx-avs-hub2"
  location                   = local.hub2_location
  type                       = "ExpressRoute"
  virtual_network_gateway_id = module.hub2.ergw.id
  authorization_key          = azurerm_express_route_circuit_authorization.er_avs.authorization_key
  express_route_circuit_id   = azurerm_express_route_circuit.er_avs.id
  depends_on = [
    megaport_azure_connection.azure_vcx_avs
  ]
}

# native

resource "azurerm_virtual_network_gateway_connection" "azure_vcx_native_hub1" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.branch2_prefix}-azure-vcx-native-hub1"
  location                   = local.hub1_location
  type                       = "ExpressRoute"
  virtual_network_gateway_id = module.hub1.ergw.id
  authorization_key          = azurerm_express_route_circuit_authorization.er_native.authorization_key
  express_route_circuit_id   = azurerm_express_route_circuit.er_native.id
  depends_on = [
    megaport_azure_connection.azure_vcx_native
  ]
} */



####################################################
# spoke1
####################################################

# vnet peering
#----------------------------

# spoke1-to-hub1

resource "azurerm_virtual_network_peering" "spoke1_to_hub1_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-spoke1-to-hub1-peering"
  virtual_network_name         = module.spoke1.vnet.name
  remote_virtual_network_id    = module.hub1.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = local.hub1_features.config_s2s_vpngw.enable ? true : false
  depends_on = [
    module.spoke1,
    module.hub1,
  ]
}

# hub1-to-spoke1

resource "azurerm_virtual_network_peering" "hub1_to_spoke1_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub1-to-spoke1-peering"
  virtual_network_name         = module.hub1.vnet.name
  remote_virtual_network_id    = module.spoke1.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  depends_on = [
    module.spoke1,
    module.hub1,
  ]
}

# udr
#----------------------------

# main

module "spoke1_udr_main" {
  count          = local.hub1_features.config_firewall.enable ? 1 : 0
  source         = "../../modules/route-table"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.spoke1_prefix}main"
  location       = local.spoke1_location
  subnet_ids     = [module.spoke1.subnets["MainSubnet"].id, ]
  routes = [for r in local.spoke1_udr_main_routes : {
    name                   = r.name
    address_prefix         = r.address_prefix
    next_hop_type          = length(try(r.next_hop_ip, "")) > 0 ? "VirtualAppliance" : "Internet"
    next_hop_in_ip_address = length(try(r.next_hop_ip, "")) > 0 ? r.next_hop_ip : null
  } if local.hub1_features.config_firewall.enable]

  bgp_route_propagation_enabled = local.hub1_features.config_firewall.enable ? false : true

  depends_on = [
    time_sleep.hub1,
  ]
}

####################################################
# spoke2
####################################################

# vnet peering
#----------------------------

# spoke2-to-hub1

resource "azurerm_virtual_network_peering" "spoke2_to_hub1_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-spoke2-to-hub1-peering"
  virtual_network_name         = module.spoke2.vnet.name
  remote_virtual_network_id    = module.hub1.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = local.hub1_features.config_s2s_vpngw.enable ? true : false
  depends_on = [
    module.spoke2,
    module.hub1,
    azurerm_virtual_network_peering.spoke1_to_hub1_peering,
    azurerm_virtual_network_peering.hub1_to_spoke1_peering,
  ]
}

# hub1-to-spoke2

resource "azurerm_virtual_network_peering" "hub1_to_spoke2_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub1-to-spoke2-peering"
  virtual_network_name         = module.hub1.vnet.name
  remote_virtual_network_id    = module.spoke2.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  depends_on = [
    module.spoke2,
    module.hub1,
    azurerm_virtual_network_peering.spoke1_to_hub1_peering,
    azurerm_virtual_network_peering.hub1_to_spoke1_peering,
  ]
}

# udr
#----------------------------

# main

module "spoke2_udr_main" {
  count          = local.hub1_features.config_firewall.enable ? 1 : 0
  source         = "../../modules/route-table"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.spoke2_prefix}main"
  location       = local.spoke2_location
  subnet_ids     = [module.spoke2.subnets["MainSubnet"].id, ]
  routes = [for r in local.spoke2_udr_main_routes : {
    name                   = r.name
    address_prefix         = r.address_prefix
    next_hop_type          = length(try(r.next_hop_ip, "")) > 0 ? "VirtualAppliance" : "Internet"
    next_hop_in_ip_address = length(try(r.next_hop_ip, "")) > 0 ? r.next_hop_ip : null
  } if local.hub1_features.config_firewall.enable]

  bgp_route_propagation_enabled = local.hub1_features.config_firewall.enable ? false : true

  depends_on = [
    time_sleep.hub1,
  ]
}

####################################################
# hub1
####################################################

# udr
#----------------------------

# gateway

module "hub1_gateway_udr" {
  count          = local.hub1_features.config_firewall.enable ? 1 : 0
  source         = "../../modules/route-table"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.hub1_prefix}gateway"
  location       = local.hub1_location
  subnet_ids     = [module.hub1.subnets["GatewaySubnet"].id, ]
  routes = [for r in local.hub1_gateway_udr_destinations : {
    name                   = r.name
    address_prefix         = r.address_prefix
    next_hop_type          = length(try(r.next_hop_ip, "")) > 0 ? "VirtualAppliance" : "Internet"
    next_hop_in_ip_address = length(try(r.next_hop_ip, "")) > 0 ? r.next_hop_ip : null
  } if local.hub1_features.config_firewall.enable]

  depends_on = [
    time_sleep.hub1,
  ]
}

# main

module "hub1_udr_main" {
  count          = local.hub1_features.config_firewall.enable ? 1 : 0
  source         = "../../modules/route-table"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.hub1_prefix}main"
  location       = local.hub1_location
  subnet_ids     = [module.hub1.subnets["MainSubnet"].id, ]
  routes = [for r in local.hub1_udr_main_routes : {
    name                   = r.name
    address_prefix         = r.address_prefix
    next_hop_type          = length(try(r.next_hop_ip, "")) > 0 ? "VirtualAppliance" : "Internet"
    next_hop_in_ip_address = length(try(r.next_hop_ip, "")) > 0 ? r.next_hop_ip : null
  } if local.hub1_features.config_firewall.enable]

  bgp_route_propagation_enabled = local.hub1_features.config_firewall.enable ? false : true

  depends_on = [
    time_sleep.hub1,
  ]
}

####################################################
# vpn-site connection
####################################################

# lng
#----------------------------

# branch1

resource "azurerm_local_network_gateway" "hub1_branch1_lng" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub1_prefix}branch1-lng"
  location            = local.hub1_location
  gateway_address     = azurerm_public_ip.branch1_nva_pip.ip_address
  address_space       = ["${local.branch1_nva_loopback0}/32", ]
  bgp_settings {
    asn                 = local.branch1_nva_asn
    bgp_peering_address = local.branch1_nva_loopback0
  }
}

# lng connection
#----------------------------

# branch1

resource "azurerm_virtual_network_gateway_connection" "hub1_branch1_lng" {
  count                          = local.hub1_features.config_s2s_vpngw.enable ? 1 : 0
  resource_group_name            = azurerm_resource_group.rg.name
  name                           = "${local.hub1_prefix}branch1-lng-conn"
  location                       = local.hub1_location
  type                           = "IPsec"
  enable_bgp                     = true
  virtual_network_gateway_id     = module.hub1.s2s_vpngw.id
  local_network_gateway_id       = azurerm_local_network_gateway.hub1_branch1_lng.id
  local_azure_ip_address_enabled = false
  shared_key                     = local.psk
  egress_nat_rule_ids            = []
  ingress_nat_rule_ids           = []
}

####################################################
# output files
####################################################

locals {
  hub1_files = {}
}

resource "local_file" "hub1_files" {
  for_each = local.hub1_files
  filename = each.key
  content  = each.value
}



####################################################
# spoke4
####################################################

# vnet peering
#----------------------------

# spoke4-to-hub2

resource "azurerm_virtual_network_peering" "spoke4_to_hub2_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-spoke4-to-hub2-peering"
  virtual_network_name         = module.spoke4.vnet.name
  remote_virtual_network_id    = module.hub2.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = true
  depends_on = [
    module.hub2.vpngw
  ]
}

# hub2-to-spoke4

resource "azurerm_virtual_network_peering" "hub2_to_spoke4_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub2-to-spoke4-peering"
  virtual_network_name         = module.hub2.vnet.name
  remote_virtual_network_id    = module.spoke4.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  depends_on = [
    module.hub2.vpngw
  ]
}

# udr
#----------------------------

# main

module "spoke4_udr_main" {
  source                        = "../../modules/udr"
  resource_group                = azurerm_resource_group.rg.name
  prefix                        = "${local.spoke4_prefix}main"
  location                      = local.spoke4_location
  subnet_id                     = module.spoke4.subnets["MainSubnet"].id
  next_hop_type                 = "VirtualAppliance"
  next_hop_in_ip_address        = local.hub2_nva_ilb_addr
  disable_bgp_route_propagation = true

  destinations = merge(
    local.default_udr_destinations,
    { "hub2" = local.hub2_address_space[0] }
  )
  depends_on = [module.hub2, ]
}

####################################################
# spoke5
####################################################

# vnet peering
#----------------------------

# spoke5-to-hub2

resource "azurerm_virtual_network_peering" "spoke5_to_hub2_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-spoke5-to-hub2-peering"
  virtual_network_name         = module.spoke5.vnet.name
  remote_virtual_network_id    = module.hub2.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = true
  depends_on = [
    module.hub2.vpngw
  ]
}

# hub2-to-spoke5

resource "azurerm_virtual_network_peering" "hub2_to_spoke5_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub2-to-spoke5-peering"
  virtual_network_name         = module.hub2.vnet.name
  remote_virtual_network_id    = module.spoke5.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  depends_on = [
    module.hub2.vpngw
  ]
}

# udr
#----------------------------

# main

module "spoke5_udr_main" {
  source                        = "../../modules/udr"
  resource_group                = azurerm_resource_group.rg.name
  prefix                        = "${local.spoke5_prefix}main"
  location                      = local.spoke5_location
  subnet_id                     = module.spoke5.subnets["MainSubnet"].id
  next_hop_type                 = "VirtualAppliance"
  next_hop_in_ip_address        = local.hub2_nva_ilb_addr
  disable_bgp_route_propagation = true

  destinations = merge(
    local.default_udr_destinations,
    { "hub2" = local.hub2_address_space[0] }
  )
  depends_on = [
    module.hub2,
  ]
}

####################################################
# hub2
####################################################

# udr
#----------------------------

# gateway

module "hub2_udr_gateway" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub2_prefix}gateway"
  location               = local.hub2_location
  subnet_id              = module.hub2.subnets["GatewaySubnet"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub2_nva_ilb_addr
  destinations           = local.hub2_gateway_udr_destinations
  depends_on             = [module.hub2, ]
}

# main

module "hub2_udr_main" {
  source                        = "../../modules/udr"
  resource_group                = azurerm_resource_group.rg.name
  prefix                        = "${local.hub2_prefix}main"
  location                      = local.hub2_location
  subnet_id                     = module.hub2.subnets["MainSubnet"].id
  next_hop_type                 = "VirtualAppliance"
  next_hop_in_ip_address        = local.hub2_nva_ilb_addr
  disable_bgp_route_propagation = true

  destinations = merge(
    local.default_udr_destinations,
    {
      "spoke4" = local.spoke4_address_space[0]
      "spoke5" = local.spoke5_address_space[0]
    }
  )
  depends_on = [
    module.hub2,
  ]
}

####################################################
# vpn-site connection
####################################################

# lng
#----------------------------

# branch3

resource "azurerm_local_network_gateway" "hub2_branch3_lng" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub2_prefix}branch3-lng"
  location            = local.hub2_location
  gateway_address     = azurerm_public_ip.branch3_nva_pip.ip_address
  address_space       = ["${local.branch3_nva_loopback0}/32", ]
  bgp_settings {
    asn                 = local.branch3_nva_asn
    bgp_peering_address = local.branch3_nva_loopback0
  }
}

# lng connection
#----------------------------

# branch3

resource "azurerm_virtual_network_gateway_connection" "hub2_branch3_lng" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub2_prefix}branch3-lng-conn"
  location                   = local.hub2_location
  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = module.hub2.vpngw.id
  local_network_gateway_id   = azurerm_local_network_gateway.hub2_branch3_lng.id
  shared_key                 = local.psk
  egress_nat_rule_ids        = []
  ingress_nat_rule_ids       = []
}

####################################################
# output files
####################################################

locals {
  hub2_files = {
    "output/hub2-linux-nva.sh" = local.hub2_linux_nva_init
  }
}

resource "local_file" "hub2_files" {
  for_each = local.hub2_files
  filename = each.key
  content  = each.value
}


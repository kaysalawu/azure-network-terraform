locals {
  hub2_bgp_asn       = module.hub2.vpngw.bgp_settings[0].asn
  hub2_vpngw_bgp_ip0 = module.hub2.vpngw.bgp_settings[0].peering_addresses[0].default_addresses[0]
  hub2_vpngw_bgp_ip1 = module.hub2.vpngw.bgp_settings[0].peering_addresses[1].default_addresses[0]
  hub2_firewall_ip   = module.hub2.firewall.ip_configuration[0].private_ip_address
}

####################################################
# spoke4
####################################################

# udr
#----------------------------

module "spoke4_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.spoke4_prefix}main"
  location               = local.spoke4_location
  subnet_id              = module.spoke4.subnets["${local.spoke4_prefix}main"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub2_firewall_ip
  destinations           = local.main_udr_destinations
  depends_on             = [module.hub2]
}

####################################################
# spoke5
####################################################

# udr
#----------------------------

module "spoke5_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.spoke5_prefix}main"
  location               = local.spoke5_location
  subnet_id              = module.spoke5.subnets["${local.spoke5_prefix}main"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub2_firewall_ip
  destinations           = local.main_udr_destinations
  depends_on             = [module.hub2]
}

####################################################
# hub2
####################################################

# udr

module "hub2_udr_gateway" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub2_prefix}gateway"
  location               = local.hub2_location
  subnet_id              = module.hub2.subnets["GatewaySubnet"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub2_firewall_ip
  destinations           = local.hub2_gateway_udr_destinations
  depends_on             = [module.hub2, ]
}

module "hub2_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub2_prefix}main"
  location               = local.hub2_location
  subnet_id              = module.hub2.subnets["${local.hub2_prefix}main"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub2_firewall_ip
  destinations           = local.main_udr_destinations
  depends_on             = [module.hub2, ]
}

####################################################
# vpn-site connection
####################################################

# lng
#----------------------------

# branch1

resource "azurerm_local_network_gateway" "hub2_branch1_lng" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub2_prefix}branch1-lng"
  location            = local.hub2_location
  gateway_address     = azurerm_public_ip.branch1_nva_pip.ip_address
  address_space       = ["${local.branch1_nva_loopback0}/32", ]
  bgp_settings {
    asn                 = local.branch1_nva_asn
    bgp_peering_address = local.branch1_nva_loopback0
  }
}

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

# branch1

resource "azurerm_virtual_network_gateway_connection" "hub2_branch1_lng" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub2_prefix}branch1-lng-conn"
  location                   = local.hub2_location
  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = module.hub2.vpngw.id
  local_network_gateway_id   = azurerm_local_network_gateway.hub2_branch1_lng.id
  shared_key                 = local.psk
  egress_nat_rule_ids        = []
  ingress_nat_rule_ids       = []
}

####################################################
# output files
####################################################

locals {
  hub2_files = {}
}

resource "local_file" "hub2_files" {
  for_each = local.hub2_files
  filename = each.key
  content  = each.value
}


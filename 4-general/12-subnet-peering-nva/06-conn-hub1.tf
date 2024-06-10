
####################################################
# hub1
####################################################

# udr
#----------------------------

# gateway

module "hub1_gateway_udr" {
  source         = "../../modules/route-table"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.hub1_prefix}gateway"
  location       = local.hub1_location
  subnet_id      = module.hub1.subnets["GatewaySubnet"].id
  routes = [for r in local.hub1_gateway_udr_destinations : {
    name                   = r.name
    address_prefix         = r.address_prefix
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = r.next_hop_ip
  }]

  depends_on = [
    time_sleep.hub1,
  ]
}

# public

module "hub1_public_udr" {
  source         = "../../modules/route-table"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.hub1_prefix}public"
  location       = local.hub1_location
  subnet_id      = module.hub1.subnets["PublicSubnet"].id
  routes = [for r in local.hub1_public_udr_destinations : {
    name                   = r.name
    address_prefix         = r.address_prefix
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = r.next_hop_ip
  }]
  disable_bgp_route_propagation = true

  depends_on = [
    time_sleep.hub1,
  ]
}

# production

module "hub1_prod_udr" {
  source         = "../../modules/route-table"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.hub1_prefix}prod"
  location       = local.hub1_location
  subnet_id      = module.hub1.subnets["ProdSubnet"].id
  routes = [for r in local.hub1_prod_destinations : {
    name                   = r.name
    address_prefix         = r.address_prefix
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = r.next_hop_ip
  }]
  disable_bgp_route_propagation = true

  depends_on = [
    time_sleep.hub1,
  ]
}

# non-production

module "hub1_nonprod_udr" {
  source         = "../../modules/route-table"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.hub1_prefix}nonprod"
  location       = local.hub1_location
  subnet_id      = module.hub1.subnets["NonProdSubnet"].id
  routes = [for r in local.hub1_nonprod_destinations : {
    name                   = r.name
    address_prefix         = r.address_prefix
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = r.next_hop_ip
  }]
  disable_bgp_route_propagation = true

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


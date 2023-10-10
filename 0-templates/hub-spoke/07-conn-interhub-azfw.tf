
####################################################
# static routes
####################################################

# hub1 firewall
#----------------------------

module "hub1_udr_firewall" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub1_prefix}azfw"
  location               = local.hub1_location
  subnet_id              = module.hub1.subnets["AzureFirewallSubnet"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub2_firewall_ip
  destinations = concat(
    local.udr_azure_destinations_region2,
  )
  depends_on = [module.hub1, ]
}

# hub2 firewall
#----------------------------

module "hub2_udr_firewall" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub2_prefix}azfw"
  location               = local.hub2_location
  subnet_id              = module.hub2.subnets["AzureFirewallSubnet"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub1_firewall_ip
  destinations = concat(
    local.udr_azure_destinations_region1,
  )
  depends_on = [module.hub2, ]
}


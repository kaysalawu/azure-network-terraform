
####################################################
# static routes
####################################################

# hub1 nva
#----------------------------

module "hub1_udr_nva" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub1_prefix}nva"
  location               = local.hub1_location
  subnet_id              = module.hub1.subnets["${local.hub1_prefix}nva"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub2_nva_ilb_addr
  destinations = concat(
    local.udr_azure_destinations_region2,
  )
  depends_on = [module.hub1, ]
}

# hub2 nva
#----------------------------

module "hub2_udr_nva" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub2_prefix}nva"
  location               = local.hub2_location
  subnet_id              = module.hub2.subnets["${local.hub2_prefix}nva"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub1_nva_ilb_addr
  destinations = concat(
    local.udr_azure_destinations_region1,
  )
  depends_on = [module.hub2, ]
}

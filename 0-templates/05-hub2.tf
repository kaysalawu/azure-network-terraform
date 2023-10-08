
####################################################
# base
####################################################

module "hub2" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.hub2_prefix, "-")
  env             = "prod"
  location        = local.hub2_location
  storage_account = module.common.storage_accounts["region2"]
  tags = {
    "nodeType" = "hub"
  }

  private_dns_zone_name   = azurerm_private_dns_zone.global.name
  private_dns_zone_prefix = local.hub2_dns_zone

  nsg_subnet_map = {
    "${local.hub2_prefix}main" = module.common.nsg_main["region2"].id
    "${local.hub2_prefix}nva"  = module.common.nsg_nva["region2"].id
    "${local.hub2_prefix}ilb"  = module.common.nsg_default["region2"].id
  }

  vnet_config = [
    {
      address_space = local.hub2_address_space
      subnets       = local.hub2_subnets

      private_dns_inbound_subnet_name  = "${local.hub2_prefix}dns-in"
      private_dns_outbound_subnet_name = "${local.hub2_prefix}dns-out"

      enable_private_dns_resolver = local.hub2_features.enable_private_dns_resolver
      enable_ars                  = local.hub2_features.enable_ars
      enable_vpn_gateway          = local.hub2_features.enable_vpn_gateway
      enable_er_gateway           = local.hub2_features.enable_er_gateway

      vpn_gateway_sku = "VpnGw2AZ"
      vpn_gateway_asn = local.hub2_vpngw_asn

      enable_firewall    = local.hub2_features.enable_firewall
      firewall_sku       = local.hub2_features.firewall_sku
      firewall_policy_id = local.hub2_features.firewall_policy_id
    }
  ]

  vm_config = [
    {
      name         = "vm"
      dns_host     = local.hub2_vm_dns_host
      subnet       = "${local.hub2_prefix}main"
      private_ip   = local.hub2_vm_addr
      custom_data  = base64encode(local.vm_startup)
      source_image = "ubuntu"
    }
  ]
}

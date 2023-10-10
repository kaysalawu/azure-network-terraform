
####################################################
# base
####################################################

module "hub1" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.hub1_prefix, "-")
  env             = "prod"
  location        = local.hub1_location
  storage_account = module.common.storage_accounts["region1"]
  tags = {
    "nodeType" = "hub"
  }

  create_private_dns_zone                = true
  private_dns_zone_name                  = "hub1.${local.cloud_domain}"
  private_dns_zone_linked_external_vnets = {}
  #private_dns_zone_prefix = local.spoke1_dns_zone

  nsg_subnet_map = {
    "${local.hub1_prefix}main" = module.common.nsg_main["region1"].id
    "${local.hub1_prefix}nva"  = module.common.nsg_nva["region1"].id
    "${local.hub1_prefix}ilb"  = module.common.nsg_default["region1"].id
  }

  vnet_config = [
    {
      address_space = local.hub1_address_space
      subnets       = local.hub1_subnets

      private_dns_inbound_subnet_name  = "${local.hub1_prefix}dns-in"
      private_dns_outbound_subnet_name = "${local.hub1_prefix}dns-out"

      enable_private_dns_resolver = local.hub1_features.enable_private_dns_resolver
      enable_ars                  = local.hub1_features.enable_ars
      enable_vpn_gateway          = local.hub1_features.enable_vpn_gateway
      enable_er_gateway           = local.hub1_features.enable_er_gateway

      vpn_gateway_sku = "VpnGw2AZ"
      vpn_gateway_asn = local.hub1_vpngw_asn

      enable_firewall    = local.hub1_features.enable_firewall
      firewall_sku       = local.hub1_features.firewall_sku
      firewall_policy_id = local.hub1_features.firewall_policy_id
    }
  ]

  vm_config = [
    {
      name         = "vm"
      dns_host     = local.hub1_vm_dns_host
      subnet       = "${local.hub1_prefix}main"
      private_ip   = local.hub1_vm_addr
      custom_data  = base64encode(local.vm_startup)
      source_image = "ubuntu"
    }
  ]
}

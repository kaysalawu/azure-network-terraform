
# This template creates PrivateLink Service in spoke6 access via private endpoint in hub1.

####################################################
# private link
####################################################

locals {
  private_dns_zone_privatelink_vnet_links_hub2 = {
    "pl-blob" = azurerm_private_dns_zone.privatelink_blob.name
    "pl-apps" = azurerm_private_dns_zone.privatelink_appservice.name
  }
}

# links
#----------------------------

resource "azurerm_private_dns_zone_virtual_network_link" "hub2_privatelink_vnet_links" {
  for_each              = local.private_dns_zone_privatelink_vnet_links_hub2
  resource_group_name   = azurerm_resource_group.rg.name
  name                  = "${local.hub2_prefix}${each.key}-vnet-link"
  private_dns_zone_name = each.value
  virtual_network_id    = module.hub2.vnet.id
  registration_enabled  = false
  timeouts {
    create = "60m"
  }
}

####################################################
# app service
####################################################

module "spoke6_apps" {
  source            = "../../modules/app-service"
  resource_group    = azurerm_resource_group.rg.name
  location          = local.spoke6_location
  prefix            = lower(local.spoke6_prefix)
  name              = random_id.random.hex
  docker_image_name = "ksalawu/web:latest"
  subnet_id         = module.spoke6.subnets["AppServiceSubnet"].id
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.hub2_privatelink_vnet_links,
  ]
}

# private endpoint

resource "azurerm_private_endpoint" "hub2_spoke6_apps_pep" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub2_prefix}spoke6-apps-pep"
  location            = local.hub2_location
  subnet_id           = module.hub2.subnets["PrivateEndpointSubnet"].id

  private_service_connection {
    name                           = "${local.hub2_prefix}spoke6-apps-svc-conn"
    private_connection_resource_id = module.spoke6_apps.app_service_id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  private_dns_zone_group {
    name                 = "${local.hub2_prefix}spoke6-apps-zg"
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_appservice.id]
  }
  depends_on = [
    azurerm_private_endpoint.hub2_spoke6_pls_pep,
  ]
}

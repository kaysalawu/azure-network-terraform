# Single Cluster Single Region

locals {
  spoke1_aks_cluster_name = "${local.spoke1_prefix}aks"
}

resource "azurerm_container_registry" "spoke1_cr" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = lower("${local.prefix}spoke1cr")
  location            = local.spoke1_location
  sku                 = "Premium"
  tags                = local.spoke1_tags
}

####################################################
# identity
####################################################

resource "azurerm_user_assigned_identity" "spoke1_aks" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.spoke1_location
  name                = "uami-aks"
  tags                = local.spoke1_tags
}

# container registry

resource "azurerm_role_assignment" "spoke1_cr" {
  principal_id                     = azurerm_user_assigned_identity.spoke1_aks.principal_id
  scope                            = azurerm_container_registry.spoke1_cr.id
  role_definition_name             = "AcrPull"
  skip_service_principal_aad_check = true
}

# dns zone

data "azurerm_dns_zone" "spoke1" {
  resource_group_name = "DNS_RG"
  name                = "salawu.net"
}

resource "azurerm_role_assignment" "spoke1_dns" {
  scope                            = data.azurerm_dns_zone.spoke1.id
  role_definition_name             = "DNS Zone Contributor"
  principal_id                     = azurerm_user_assigned_identity.spoke1_aks.principal_id
  skip_service_principal_aad_check = true
}

####################################################
# cluster
####################################################

module "spoke1_aks" {
  source  = "Azure/aks/azurerm"
  version = "9.1.0"

  resource_group_name       = azurerm_resource_group.rg.name
  prefix                    = trimsuffix(local.spoke1_prefix, "-")
  location                  = local.spoke1_location
  kubernetes_version        = "1.30"
  automatic_channel_upgrade = "patch"
  agents_availability_zones = ["1", "2", ]
  agents_size               = "Standard_D4s_v3"

  # workload_identity_enabled = true
  # oidc_issuer_enabled = true

  identity_type = "UserAssigned"
  identity_ids = [
    azurerm_user_assigned_identity.spoke1_aks.id,
  ]

  os_disk_size_gb = 60
  sku_tier        = "Standard"
  rbac_aad        = false
  vnet_subnet_id  = module.spoke1.subnets["AksSubnet"].id

  network_plugin      = "azure"
  network_policy      = "cilium"
  network_plugin_mode = "overlay"
  ebpf_data_plane     = "cilium"

  attached_acr_id_map = {
    spoke1 = azurerm_container_registry.spoke1_cr.id
  }
}


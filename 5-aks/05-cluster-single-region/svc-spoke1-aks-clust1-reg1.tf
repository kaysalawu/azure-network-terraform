# Single Cluster Single Region

locals {
  spoke1_aks_cluster_name = "${local.spoke1_prefix}aks"
}

resource "random_string" "spoke1_acr_suffix" {
  length  = 8
  numeric = true
  special = false
  upper   = false
}

resource "azurerm_container_registry" "spoke1_cr" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.prefix}spoke1cr${random_string.spoke1_acr_suffix.result}"
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

# resource "azurerm_role_assignment" "spoke1_cr" {
#   resource_group                   = azurerm_resource_group.rg.name
#   principal_id                     = azurerm_kubernetes_cluster.spoke1_aks.kubelet_identity[0].object_id
#   scope                            = azurerm_container_registry.spoke1_cr.id
#   role_definition_name             = "AcrPull"
#   skip_service_principal_aad_check = true
# }

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
  agents_availability_zones = ["1", "2"]

  os_disk_size_gb = 60
  sku_tier        = "Standard"
  rbac_aad        = false
  vnet_subnet_id  = module.spoke1.subnets["AksSubnet"].id
  # pod_subnet_id   = module.spoke1.subnets["AksPodSubnet"].id

  network_plugin      = "azure"
  network_policy      = "cilium"
  network_plugin_mode = "overlay"
  ebpf_data_plane     = "cilium"

  attached_acr_id_map = {
    spoke1 = azurerm_container_registry.spoke1_cr.id
  }
}

# resource "azurerm_kubernetes_cluster" "spoke1_aks" {
#   resource_group_name = azurerm_resource_group.rg.name
#   name                = local.spoke1_aks_cluster_name
#   location            = local.spoke1_location
#   dns_prefix          = "spoke1"
#   kubernetes_version  = "1.30"
#   tags                = local.spoke1_tags

#   private_cluster_enabled = false
#   # private_dns_zone_id     = module.common.private_dns_zones[local.region1_dns_zone].id
#   sku_tier = "Standard"

#   default_node_pool {
#     name                 = "default"
#     orchestrator_version = "1.30"
#     vm_size              = "Standard_D2_v2"
#     node_count           = 1
#     max_pods             = 110
#     os_sku               = "Ubuntu"
#     vnet_subnet_id       = module.spoke1.subnets["AksSubnet"].id
#     zones                = ["1", ]
#   }

#   identity {
#     type = "UserAssigned"
#     identity_ids = [
#       azurerm_user_assigned_identity.spoke1_aks.id,
#     ]
#   }

#   lifecycle {
#     ignore_changes = [
#       kubernetes_version
#     ]
#   }
# }

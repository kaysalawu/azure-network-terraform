
####################################################
# private link service
####################################################

# internal load balancer

module "spoke6_lb" {
  source              = "../../modules/azure-load-balancer"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.spoke6_location
  prefix              = trimsuffix(local.spoke6_prefix, "-")
  name                = "pls"
  type                = "private"
  lb_sku              = "Standard"

  log_analytics_workspace_name = module.common.log_analytics_workspaces["region2"].name

  frontend_ip_configuration = [
    {
      name                          = "pls"
      zones                         = ["1", "2", "3"]
      subnet_id                     = module.spoke6.subnets["LoadBalancerSubnet"].id
      private_ip_address            = local.spoke6_ilb_addr
      private_ip_address_allocation = "Static"
    }
  ]

  probes = [
    { name = "http", protocol = "Tcp", port = "80", request_path = "" },
  ]

  backend_pools = [
    {
      name = "pls"
      interfaces = [
        {
          ip_configuration_name = module.spoke6_vm.interface_names["${local.spoke6_prefix}vm-main-nic"]
          network_interface_id  = module.spoke6_vm.interface_ids["${local.spoke6_prefix}vm-main-nic"]
        },
      ]
    },
  ]

  lb_rules = [
    {
      name                           = "pls-80"
      protocol                       = "Tcp"
      frontend_port                  = "80"
      backend_port                   = "80"
      frontend_ip_configuration_name = "pls"
      backend_address_pool_name      = ["pls", ]
      probe_name                     = "http"
    },
  ]
}

# service

resource "azurerm_private_link_service" "spoke6" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.spoke6_prefix}pls"
  location            = local.spoke6_location
  tags                = local.spoke6_tags

  nat_ip_configuration {
    name      = "pls-nat-ip-config"
    primary   = true
    subnet_id = module.spoke6.subnets["PrivateLinkServiceSubnet"].id
  }

  load_balancer_frontend_ip_configuration_ids = [
    module.spoke6_lb.frontend_ip_configurations["pls"].id,
  ]

  lifecycle {
    ignore_changes = [
      nat_ip_configuration
    ]
  }
}

# endpoint

resource "azurerm_private_endpoint" "hub2_spoke6_pls_pep" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub2_prefix}spoke6-pls-pep"
  location            = local.hub2_location
  subnet_id           = module.hub2.subnets["PrivateEndpointSubnet"].id

  private_service_connection {
    name                           = "${local.hub2_prefix}spoke6-pls-svc-conn"
    private_connection_resource_id = azurerm_private_link_service.spoke6.id
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "pep-ip-config"
    private_ip_address = local.hub2_spoke6_pls_pep_ip
  }
}

resource "azurerm_private_dns_a_record" "hub2_spoke6_pls_pep" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = local.hub2_spoke6_pep_host
  zone_name           = module.common.private_dns_zones[local.region2_dns_zone].name
  ttl                 = 300
  records = [
    azurerm_private_endpoint.hub2_spoke6_pls_pep.private_service_connection[0].private_ip_address,
  ]
}

####################################################
# stoarge account
####################################################

# storage account

resource "azurerm_storage_account" "spoke6" {
  resource_group_name      = azurerm_resource_group.rg.name
  name                     = local.spoke6_storage_account_name
  location                 = local.spoke6_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.spoke6_tags
}

# container

resource "azurerm_storage_container" "spoke6" {
  name                  = "spoke6"
  storage_account_name  = azurerm_storage_account.spoke6.name
  container_access_type = "blob"
}

# blob

resource "azurerm_storage_blob" "spoke6" {
  name                   = "spoke6.txt"
  storage_account_name   = azurerm_storage_account.spoke6.name
  storage_container_name = azurerm_storage_container.spoke6.name
  type                   = "Block"
  source_content         = "Hello, World!"
}

# role assignment (system-assigned identity)

locals {
  spoke6_storage_account_role_assignment = [
    { role = "Reader", principal_id = module.branch3_vm.vm.identity[0].principal_id },
  ]
}

resource "azurerm_role_assignment" "spoke6" {
  count                = length(local.spoke6_storage_account_role_assignment)
  scope                = azurerm_storage_account.spoke6.id
  role_definition_name = local.spoke6_storage_account_role_assignment[count.index].role
  principal_id         = local.spoke6_storage_account_role_assignment[count.index].principal_id
}

# private endpoint

resource "azurerm_private_endpoint" "hub2_spoke6_blob_pep" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub2_prefix}spoke6-blob-pep"
  location            = local.hub2_location
  subnet_id           = module.hub2.subnets["PrivateEndpointSubnet"].id

  private_service_connection {
    name                           = "${local.hub2_prefix}spoke6-blob-conn"
    private_connection_resource_id = azurerm_storage_account.spoke6.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  ip_configuration {
    name               = "pep-ip-config"
    private_ip_address = local.hub2_spoke6_blob_pep_ip
    subresource_name   = "blob"
    member_name        = "blob"
  }

  private_dns_zone_group {
    name = "${local.hub2_prefix}spoke6-blob-zg"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.privatelink_blob.id
    ]
  }
}

####################################################
# app service
####################################################

# module "spoke6_apps" {
#   source            = "../../modules/app-service"
#   resource_group    = azurerm_resource_group.rg.name
#   location          = local.spoke6_location
#   prefix            = lower(local.spoke6_prefix)
#   name              = random_id.random.hex
#   docker_image_name = "ksalawu/web:latest"
#   subnet_id         = module.spoke6.subnets["AppServiceSubnet"].id
#   depends_on = [
#     azurerm_private_dns_zone_virtual_network_link.hub2_privatelink_vnet_links,
#   ]
# }

# private endpoint

# resource "azurerm_private_endpoint" "hub2_spoke6_apps_pep" {
#   resource_group_name = azurerm_resource_group.rg.name
#   name                = "${local.hub2_prefix}spoke6-apps-pep"
#   location            = local.hub2_location
#   subnet_id           = module.hub2.subnets["PrivateEndpointSubnet"].id

#   private_service_connection {
#     name                           = "${local.hub2_prefix}spoke6-apps-svc-conn"
#     private_connection_resource_id = module.spoke6_apps.app_service_id
#     is_manual_connection           = false
#     subresource_names              = ["sites"]
#   }

#   private_dns_zone_group {
#     name                 = "${local.hub2_prefix}spoke6-apps-zg"
#     private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_appservice.id]
#   }
# }



####################################################
# private link service
####################################################

# internal load balancer

module "spoke3_lb" {
  source              = "../../modules/azure-load-balancer"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.spoke3_location
  prefix              = trimsuffix(local.spoke3_prefix, "-")
  name                = "pls"
  type                = "private"
  lb_sku              = "Standard"

  log_analytics_workspace_name = module.common.log_analytics_workspaces["region1"].name

  frontend_ip_configuration = [
    {
      name                          = "pls"
      zones                         = ["1", "2", "3"]
      subnet_id                     = module.spoke3.subnets["LoadBalancerSubnet"].id
      private_ip_address            = local.spoke3_ilb_addr
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
          ip_configuration_name = module.spoke3_vm.interface_names["${local.spoke3_prefix}vm-main-nic"]
          network_interface_id  = module.spoke3_vm.interface_ids["${local.spoke3_prefix}vm-main-nic"]
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
  depends_on = [
    module.spoke3,
  ]
}

# service

resource "azurerm_private_link_service" "spoke3" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.spoke3_prefix}pls"
  location            = local.spoke3_location
  tags                = local.spoke3_tags

  nat_ip_configuration {
    name      = "pls-nat-ip-config"
    primary   = true
    subnet_id = module.spoke3.subnets["PrivateLinkServiceSubnet"].id
  }

  load_balancer_frontend_ip_configuration_ids = [
    module.spoke3_lb.frontend_ip_configurations["pls"].id,
  ]

  lifecycle {
    ignore_changes = [
      nat_ip_configuration
    ]
  }
  depends_on = [
    module.spoke3,
  ]
}

# endpoint

resource "azurerm_private_endpoint" "hub1_spoke3_pls_pep" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub1_prefix}spoke3-pls-pep"
  location            = local.hub1_location
  subnet_id           = module.hub1.subnets["PrivateEndpointSubnet"].id

  private_service_connection {
    name                           = "${local.hub1_prefix}spoke3-pls-svc-conn"
    private_connection_resource_id = azurerm_private_link_service.spoke3.id
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "pep-ip-config"
    private_ip_address = local.hub1_spoke3_pls_pep_ip
  }
  depends_on = [
    module.spoke3,
    module.hub1,
  ]
}

resource "azurerm_private_dns_a_record" "hub1_spoke3_pls_pep" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = local.hub1_spoke3_pep_host
  zone_name           = module.common.private_dns_zones[local.region1_dns_zone].name
  ttl                 = 300
  records = [
    azurerm_private_endpoint.hub1_spoke3_pls_pep.private_service_connection[0].private_ip_address,
  ]
}

####################################################
# stoarge account
####################################################

# storage account

resource "azurerm_storage_account" "spoke3" {
  resource_group_name      = azurerm_resource_group.rg.name
  name                     = local.spoke3_storage_account_name
  location                 = local.spoke3_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.spoke3_tags
}

# container

resource "azurerm_storage_container" "spoke3" {
  name                  = "spoke3"
  storage_account_name  = azurerm_storage_account.spoke3.name
  container_access_type = "blob"
}

# blob

resource "azurerm_storage_blob" "spoke3" {
  name                   = "spoke3.txt"
  storage_account_name   = azurerm_storage_account.spoke3.name
  storage_container_name = azurerm_storage_container.spoke3.name
  type                   = "Block"
  source_content         = "Hello, World!"
}

# role assignment (system-assigned identity)

locals {
  spoke3_storage_account_role_assignment = [
    { role = "Reader", principal_id = module.branch1_vm.vm.identity[0].principal_id },
    { role = "Reader", principal_id = module.branch2_vm.vm.identity[0].principal_id },
  ]
}

resource "azurerm_role_assignment" "spoke3" {
  count                = length(local.spoke3_storage_account_role_assignment)
  scope                = azurerm_storage_account.spoke3.id
  role_definition_name = local.spoke3_storage_account_role_assignment[count.index].role
  principal_id         = local.spoke3_storage_account_role_assignment[count.index].principal_id
}

# private endpoint

resource "azurerm_private_endpoint" "hub1_spoke3_blob_pep" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub1_prefix}spoke3-blob-pep"
  location            = local.hub1_location
  subnet_id           = module.hub1.subnets["PrivateEndpointSubnet"].id

  private_service_connection {
    name                           = "${local.hub1_prefix}spoke3-blob-conn"
    private_connection_resource_id = azurerm_storage_account.spoke3.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  ip_configuration {
    name               = "pep-ip-config"
    private_ip_address = local.hub1_spoke3_blob_pep_ip
    subresource_name   = "blob"
    member_name        = "blob"
  }

  private_dns_zone_group {
    name = "${local.hub1_prefix}spoke3-blob-zg"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.privatelink_blob.id
    ]
  }
  depends_on = [
    module.spoke3,
    module.hub1,
  ]
}

####################################################
# app service
####################################################

# module "spoke3_apps" {
#   source            = "../../modules/app-service"
#   resource_group    = azurerm_resource_group.rg.name
#   location          = local.spoke3_location
#   prefix            = lower(local.spoke3_prefix)
#   name              = random_id.random.hex
#   docker_image_name = "ksalawu/web:latest"
#   subnet_id         = module.spoke3.subnets["AppServiceSubnet"].id
#   depends_on = [
#     azurerm_private_dns_zone_virtual_network_link.hub1_privatelink_vnet_links,
#   ]
# }

# private endpoint

# resource "azurerm_private_endpoint" "hub1_spoke3_apps_pep" {
#   resource_group_name = azurerm_resource_group.rg.name
#   name                = "${local.hub1_prefix}spoke3-apps-pep"
#   location            = local.hub1_location
#   subnet_id           = module.hub1.subnets["PrivateEndpointSubnet"].id

#   private_service_connection {
#     name                           = "${local.hub1_prefix}spoke3-apps-svc-conn"
#     private_connection_resource_id = module.spoke3_apps.app_service_id
#     is_manual_connection           = false
#     subresource_names              = ["sites"]
#   }

#   private_dns_zone_group {
#     name                 = "${local.hub1_prefix}spoke3-apps-zg"
#     private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_appservice.id]
#   }
#   depends_on = [
#     module.spoke3,
#   ]
# }


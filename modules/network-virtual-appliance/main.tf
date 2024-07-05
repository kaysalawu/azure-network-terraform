
locals {
  prefix = var.prefix == "" ? "${var.name}" : format("%s-%s", var.prefix, var.name)
  frontend_ip_configuration_trust = concat(
    [{
      name                          = "nva"
      zones                         = ["1", "2", "3"]
      subnet_id                     = var.subnet_id_trust
      private_ip_address            = var.ilb_trust_ip
      private_ip_address_allocation = "Static"
    }],
    var.enable_ipv6 ? [{
      name                          = "nva-ipv6"
      zones                         = ["1", "2", "3"]
      subnet_id                     = var.subnet_id_trust
      private_ip_address_version    = "IPv6"
      private_ip_address            = var.ilb_trust_ipv6
      private_ip_address_allocation = "Static"
    }] : []
  )

  backend_pools_trust = concat(
    [{
      name = "nva"
      interfaces = [for nva in module.nva : {
        ip_configuration_name = nva.interfaces["${local.prefix}-trust-nic"].ip_configuration[0].name
        network_interface_id  = nva.interfaces["${local.prefix}-trust-nic"].id
      }]
    }],
    var.enable_ipv6 ? [{ #TODO: fix. requires dual terraform apply. create local backendpool resource for ipv6.
      name = "nva-ipv6"
      addresses = [{
        name               = "nva-ipv6"
        virtual_network_id = var.virtual_network_id
        ip_address         = module.nva[0].private_ipv6_address
      }]
    }] : []
  )

  lb_rules_trust = concat(
    [{
      name                           = "nva-ha"
      protocol                       = "All"
      frontend_port                  = "0"
      backend_port                   = "0"
      frontend_ip_configuration_name = "nva"
      backend_address_pool_name      = ["nva", ]
      probe_name                     = var.health_probes[0].name
    }],
    var.enable_ipv6 ? [{ #TODO: fix. requires dual terraform apply. create local backendpool resource for ipv6.
      name                           = "nva-ha-ipv6"
      protocol                       = "All"
      frontend_port                  = "0"
      backend_port                   = "0"
      frontend_ip_configuration_name = "nva-ipv6"
      backend_address_pool_name      = ["nva-ipv6", ]
      probe_name                     = var.health_probes[0].name
    }] : []
  )
}

####################################################
# ip addresses
####################################################

resource "azurerm_public_ip" "untrust" {
  count               = var.scenario_option == "Active-Active" ? 2 : var.scenario_option == "TwoNics" ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.prefix}-pip-untrust-${count.index}"
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
  zones               = [1, 2, 3]
  timeouts {
    create = "60m"
  }
  tags = var.tags
}

####################################################
# appliance
####################################################

module "nva" {
  count                 = var.scenario_option == "Active-Active" ? 2 : var.scenario_option == "TwoNics" ? 1 : 0
  source                = "../../modules/virtual-machine-linux"
  resource_group        = var.resource_group
  name                  = "${local.prefix}-${count.index}"
  computer_name         = "${local.prefix}-${count.index}"
  location              = var.location
  storage_account       = var.storage_account
  user_assigned_ids     = var.user_assigned_ids
  ip_forwarding_enabled = true

  source_image_publisher = var.source_image_publisher
  source_image_offer     = var.source_image_offer
  source_image_sku       = var.source_image_sku
  source_image_version   = var.source_image_version
  enable_plan            = var.enable_plan

  use_vm_extension      = var.use_vm_extension
  vm_extension_settings = var.vm_extension_settings
  custom_data           = var.custom_data

  enable_ipv6 = var.enable_ipv6
  interfaces = [
    {
      name                 = "${local.prefix}-untrust-nic"
      subnet_id            = var.subnet_id_untrust
      public_ip_address_id = azurerm_public_ip.untrust[count.index].id
    },
    {
      name      = "${local.prefix}-trust-nic"
      subnet_id = var.subnet_id_trust
    },
  ]
}

####################################################
# internal lb untrust
####################################################

module "ilb_untrust" {
  source              = "../../modules/azure-load-balancer"
  resource_group_name = var.resource_group
  location            = var.location
  prefix              = local.prefix
  name                = "untrust"
  type                = "private"
  lb_sku              = "Standard"

  log_analytics_workspace_name = var.log_analytics_workspace_name

  frontend_ip_configuration = [
    {
      name                          = "nva"
      zones                         = ["1", "2", "3"]
      subnet_id                     = var.subnet_id_untrust
      private_ip_address            = var.ilb_untrust_ip
      private_ip_address_allocation = "Static"
    }
  ]

  probes = var.health_probes

  backend_pools = [
    {
      name = "nva"
      interfaces = [for nva in module.nva : {
        ip_configuration_name = nva.interfaces["${local.prefix}-untrust-nic"].ip_configuration[0].name
        network_interface_id  = nva.interfaces["${local.prefix}-untrust-nic"].id
      }]
    }
  ]

  lb_rules = [
    {
      name                           = "nva-ha"
      protocol                       = "All"
      frontend_port                  = "0"
      backend_port                   = "0"
      frontend_ip_configuration_name = "nva"
      backend_address_pool_name      = ["nva", ]
      probe_name                     = var.health_probes[0].name
    },
  ]
  depends_on = [
    module.nva,
  ]
}

####################################################
# internal lb trust
####################################################

module "ilb_trust" {
  source              = "../../modules/azure-load-balancer"
  resource_group_name = var.resource_group
  location            = var.location
  prefix              = local.prefix
  name                = "trust"
  type                = "private"
  lb_sku              = "Standard"
  enable_dual_stack   = var.enable_ipv6

  log_analytics_workspace_name = var.log_analytics_workspace_name

  frontend_ip_configuration = local.frontend_ip_configuration_trust
  backend_pools             = local.backend_pools_trust
  lb_rules                  = local.lb_rules_trust
  probes                    = var.health_probes

  depends_on = [
    module.nva,
  ]
}

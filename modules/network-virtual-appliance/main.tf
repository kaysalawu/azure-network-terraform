
locals {
  name = var.prefix == "" ? "${var.name}" : format("%s-%s", var.prefix, var.name)
}

####################################################
# public ip
####################################################

# ip addresses

resource "azurerm_public_ip" "untrust" {
  count               = var.scenario_option == "Active-Active" ? 2 : var.scenario_option == "TwoNics" ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.name}-pip-untrust-${count.index}"
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
  zones               = [1, 2, 3]
  timeouts {
    create = "60m"
  }
  tags = var.tags
}

module "nva" {
  count                = var.scenario_option == "Active-Active" ? 2 : var.scenario_option == "TwoNics" ? 1 : 0
  source               = "../../modules/virtual-machine-linux"
  resource_group       = var.resource_group
  name                 = "${local.name}-${count.index}"
  computer_name        = "${local.name}-${count.index}"
  location             = var.location
  storage_account      = var.storage_account
  identity_ids         = var.identity_ids
  enable_ip_forwarding = true

  interfaces = [
    {
      name                 = "${local.name}-untrust-nic"
      subnet_id            = var.subnet_id_untrust
      public_ip_address_id = length(azurerm_public_ip.untrust) > 0 ? azurerm_public_ip.untrust[count.index].id : null
    },
    {
      name      = "${local.name}-trust-nic"
      subnet_id = var.subnet_id_trust
    },
  ]

  source_image_publisher = var.source_image_publisher
  source_image_offer     = var.source_image_offer
  source_image_sku       = var.source_image_sku
  source_image_version   = var.source_image_version

  enable_plan = var.enable_plan

  use_vm_extension      = var.use_vm_extension
  vm_extension_settings = var.vm_extension_settings
  custom_data           = var.custom_data
}

# internal lb

module "ilb_untrust" {
  source              = "../../modules/azure-load-balancer"
  resource_group_name = var.resource_group
  location            = var.location
  prefix              = ""
  name                = local.name
  type                = "private"
  lb_sku              = "Standard"

  frontend_ip_configuration = [
    {
      name                          = "nva"
      zones                         = ["1", "2", "3"]
      subnet_id                     = var.subnet_id_untrust
      private_ip_address            = var.ilb_untrust_ip
      private_ip_address_allocation = "Static"
    }
  ]

  probes = [
    { name = "ssh", protocol = "Tcp", port = "22", request_path = "" },
  ]

  backend_pools = [
    {
      name = "nva"
      interfaces = [for nva in module.nva : {
        ip_configuration_name = nva.interfaces["${local.name}-untrust-nic"].ip_configuration[0].name
        network_interface_id  = nva.interfaces["${local.name}-untrust-nic"].id
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
      probe_name                     = "ssh"
    },
  ]
}

# # internal lb

# module "ilb_nva_linux" {
#   count               = var.config_nva.enable && var.config_nva.type == "linux" ? 1 : 0
#   source              = "../../modules/azure-load-balancer"
#   resource_group_name = var.resource_group
#   location            = var.location
#   prefix              = trimsuffix(local.prefix, "-")
#   name                = "nva"
#   type                = "private"
#   lb_sku              = "Standard"

#   frontend_ip_configuration = [
#     {
#       name                          = "nva"
#       zones                         = ["1", "2", "3"]
#       subnet_id                     = azurerm_subnet.this["LoadBalancerSubnet"].id
#       private_ip_address            = var.config_nva.internal_lb_addr
#       private_ip_address_allocation = "Static"
#     }
#   ]

#   probes = [
#     { name = "ssh", protocol = "Tcp", port = "22", request_path = "" },
#   ]

#   backend_pools = [
#     {
#       name = "nva"
#       addresses = [
#         {
#           name               = module.nva_linux[0].vm.name
#           virtual_network_id = azurerm_virtual_network.this.id
#           ip_address         = module.nva_linux[0].interfaces["${local.prefix}nva-untrust-nic"].ip_configuration[0].private_ip_address
#         },
#       ]
#     }
#   ]

#   lb_rules = [
#     {
#       name                           = "nva-ha"
#       protocol                       = "All"
#       frontend_port                  = "0"
#       backend_port                   = "0"
#       frontend_ip_configuration_name = "nva"
#       backend_address_pool_name      = ["nva", ]
#       probe_name                     = "ssh"
#     },
#   ]

#   depends_on = [
#     azurerm_subnet.this,
#     azurerm_subnet_network_security_group_association.this,
#     module.nva_linux,
#   ]
# }

# opnsense
#----------------------------

# locals {
#   settings_opnsense = templatefile("${path.module}/templates/settings.tpl", local.params_opnsense)
#   params_opnsense = {
#     ShellScriptName               = var.shell_script_name
#     OpnScriptURI                  = var.opn_script_uri
#     OpnVersion                    = var.opn_version
#     WALinuxVersion                = var.walinux_version
#     OpnType                       = var.opn_type
#     TrustedSubnetAddressPrefix    = var.trusted_subnet_address_prefix
#     WindowsVmSubnetAddressPrefix  = var.deploy_windows_mgmt ? var.mgmt_subnet_address_prefix : "1.1.1.1/32"
#     publicIPAddress               = length(azurerm_public_ip.opnsense) > 0 ? azurerm_public_ip.opnsense[0].ip_address : ""
#     opnSenseSecondarytrustedNicIP = var.scenario_option == "Active-Active" ? "SOME" : ""
#   }
# }

# resource "local_file" "params_opnsense" {
#   count = (var.config_nva.enable && var.config_nva.type == "opnsense" ?
#     var.config_nva.scenario_option == "Active-Active" ? 2 :
#     var.config_nva.scenario_option == "TwoNics" ? 1 :
#     0 : 0
#   )
#   filename = "settings.json"
#   content  = local.settings_opnsense
# }



# # appliances

# module "opnsense" {
#   count = (var.config_nva.enable && var.config_nva.type == "opnsense" ?
#     var.config_nva.scenario_option == "Active-Active" ? 2 :
#     var.config_nva.scenario_option == "TwoNics" ? 1 :
#     0 : 0
#   )
#   source          = "../../modules/virtual-machine-linux"
#   resource_group  = var.resource_group
#   name            = "${local.prefix}opns-${count.index}"
#   location        = var.location
#   storage_account = var.storage_account
#   identity_ids    = var.user_assigned_ids

#   source_image_publisher = "thefreebsdfoundation"
#   source_image_offer     = "freebsd-13_1"
#   source_image_sku       = "13_1-release"
#   source_image_version   = "latest"
#   enable_plan            = true

#   use_vm_extension      = true
#   vm_extension_settings = local.settings_opnsense


#   interfaces = [
#     {
#       name                 = "${local.prefix}opns-untrust-nic"
#       subnet_id            = azurerm_subnet.this["UntrustSubnet"].id
#       public_ip_address_id = azurerm_public_ip.opnsense[count.index].id
#     },
#     {
#       name      = "${local.prefix}opns-trust-nic"
#       subnet_id = azurerm_subnet.this["TrustSubnet"].id
#     },
#   ]

#   depends_on = [
#     azurerm_subnet.this,
#     azurerm_subnet_network_security_group_association.this,
#   ]
# }



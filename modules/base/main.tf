
locals {
  prefix = var.prefix == "" ? "" : format("%s-", var.prefix)
  nat_gateway_subnet_ids = {
    for k, v in var.config_vnet.subnets : k => azurerm_subnet.this[k].id
    if contains(var.config_vnet.nat_gateway_subnet_names, k)
  }
}

####################################################
# vnet
####################################################

resource "azurerm_virtual_network" "this" {
  resource_group_name = var.resource_group
  name                = "${local.prefix}vnet"
  address_space       = var.config_vnet.address_space
  location            = var.location
  dns_servers         = var.config_vnet.dns_servers
  tags                = var.tags
}

####################################################
# subnets
####################################################s

resource "azurerm_subnet" "this" {
  for_each             = var.config_vnet.subnets
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.this.name
  name                 = each.key
  address_prefixes     = each.value.address_prefixes

  dynamic "delegation" {
    for_each = [for d in var.delegation : d if contains(try(each.value.delegate, []), d.name)]
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation[0].name
        actions = delegation.value.service_delegation[0].actions
      }
    }
  }

  private_endpoint_network_policies_enabled     = try(each.value.address_prefixes.enable_private_endpoint_policies[0], false)
  private_link_service_network_policies_enabled = try(each.value.address_prefixes.enable_private_link_policies[0], false)
}

####################################################
# nsg
####################################################

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each                  = var.nsg_subnet_map
  subnet_id                 = [for k, v in azurerm_subnet.this : v.id if k == each.key][0]
  network_security_group_id = each.value
  timeouts {
    create = "60m"
  }
}

####################################################
# nsg flow logs
####################################################

resource "azurerm_network_watcher_flow_log" "this" {
  count                = length(var.flow_log_nsg_ids)
  resource_group_name  = var.network_watcher_resource_group
  network_watcher_name = var.network_watcher_name
  name                 = "${local.prefix}flowlog-${count.index}"

  network_security_group_id = var.flow_log_nsg_ids[count.index]
  storage_account_id        = var.storage_account.id
  enabled                   = true

  retention_policy {
    enabled = true
    days    = 7
  }

  traffic_analytics {
    enabled               = var.enable_diagnostics != null ? true : false
    workspace_id          = data.azurerm_log_analytics_workspace.this[0].workspace_id
    workspace_region      = data.azurerm_log_analytics_workspace.this[0].location
    workspace_resource_id = data.azurerm_log_analytics_workspace.this[0].id
    interval_in_minutes   = 10
  }
}

####################################################
# dns
####################################################

# dns zones linked to vnet

resource "azurerm_private_dns_zone_virtual_network_link" "dns" {
  for_each              = { for v in var.dns_zones_linked_to_vnet : v.name => v }
  resource_group_name   = var.resource_group
  name                  = "${azurerm_virtual_network.this.name}--link"
  private_dns_zone_name = each.key
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = each.value.registration_enabled
  depends_on = [
    azurerm_virtual_network.this,
  ]
  timeouts {
    create = "60m"
  }
}

####################################################
# dns resolver
####################################################

module "dns_resolver" {
  count              = var.config_vnet.enable_private_dns_resolver ? 1 : 0
  source             = "../../modules/private-dns-resolver"
  resource_group     = var.resource_group
  prefix             = local.prefix
  env                = var.env
  location           = var.location
  virtual_network_id = azurerm_virtual_network.this.id
  tags               = var.tags

  private_dns_inbound_subnet_id  = azurerm_subnet.this["DnsResolverInboundSubnet"].id
  private_dns_outbound_subnet_id = azurerm_subnet.this["DnsResolverOutboundSubnet"].id
  ruleset_dns_forwarding_rules   = var.config_vnet.ruleset_dns_forwarding_rules
  vnets_linked_to_ruleset        = var.vnets_linked_to_ruleset

  log_analytics_workspace_name = var.enable_diagnostics ? var.log_analytics_workspace_name : null

  depends_on = [
    azurerm_subnet.this,
    azurerm_subnet_network_security_group_association.this,
  ]
}

####################################################
# nat
####################################################

resource "azurerm_public_ip" "nat" {
  count               = length(var.config_vnet.nat_gateway_subnet_names) > 0 ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.prefix}natgw"
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  timeouts {
    create = "60m"
  }
  depends_on = [
    azurerm_subnet.this,
    azurerm_subnet_network_security_group_association.this,
  ]
  tags = var.tags
}

resource "azurerm_nat_gateway" "nat" {
  count               = length(var.config_vnet.nat_gateway_subnet_names) > 0 ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.prefix}natgw"
  location            = var.location
  sku_name            = "Standard"
  timeouts {
    create = "60m"
  }
  depends_on = [
    azurerm_subnet.this,
    azurerm_subnet_network_security_group_association.this,
  ]
  tags = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "nat" {
  count                = length(var.config_vnet.nat_gateway_subnet_names) > 0 ? 1 : 0
  nat_gateway_id       = azurerm_nat_gateway.nat[0].id
  public_ip_address_id = azurerm_public_ip.nat[0].id
  timeouts {
    create = "60m"
  }
}

resource "azurerm_subnet_nat_gateway_association" "nat" {
  for_each       = { for s in var.config_vnet.nat_gateway_subnet_names : s => local.nat_gateway_subnet_ids[s] }
  subnet_id      = each.value
  nat_gateway_id = azurerm_nat_gateway.nat[0].id
}

####################################################
# s2s vpngw
####################################################

module "s2s_vpngw" {
  count          = var.config_s2s_vpngw.enable ? 1 : 0
  source         = "../../modules/vnet-gateway-s2s"
  resource_group = var.resource_group
  prefix         = local.prefix
  env            = var.env
  location       = var.location
  subnet_id      = azurerm_subnet.this["GatewaySubnet"].id
  tags           = var.tags

  sku           = var.config_s2s_vpngw.sku
  active_active = var.config_s2s_vpngw.active_active
  bgp_asn       = var.config_s2s_vpngw.bgp_settings.asn

  private_ip_address_enabled  = var.config_s2s_vpngw.private_ip_address_enabled
  remote_vnet_traffic_enabled = var.config_s2s_vpngw.remote_vnet_traffic_enabled
  virtual_wan_traffic_enabled = var.config_s2s_vpngw.remote_vnet_traffic_enabled

  log_analytics_workspace_name = var.enable_diagnostics ? var.log_analytics_workspace_name : null

  ip_configuration = [for c in var.config_s2s_vpngw.ip_configuration : {
    name                          = c.name
    subnet_id                     = azurerm_subnet.this["GatewaySubnet"].id
    public_ip_address_name        = c.public_ip_address_name
    private_ip_address_allocation = c.private_ip_address_allocation
    apipa_addresses               = c.apipa_addresses
  }]

  depends_on = [
    azurerm_subnet.this,
    azurerm_subnet_network_security_group_association.this,
  ]
}

####################################################
# p2s vpngw
####################################################

module "p2s_vpngw" {
  count          = var.config_p2s_vpngw.enable ? 1 : 0
  source         = "../../modules/vnet-gateway-p2s"
  resource_group = var.resource_group
  prefix         = local.prefix
  env            = var.env
  location       = var.location
  sku            = var.config_p2s_vpngw.sku
  active_active  = false
  subnet_id      = azurerm_subnet.this["GatewaySubnet"].id
  tags           = var.tags

  custom_route_address_prefixes = try(var.config_p2s_vpngw.custom_route_address_prefixes, [])

  vpn_client_configuration = {
    address_space = try(var.config_p2s_vpngw.vpn_client_configuration.address_space, ["172.16.0.0/24"])
    clients       = try(var.config_p2s_vpngw.vpn_client_configuration.clients, [])
  }

  ip_configuration = [for c in var.config_s2s_vpngw.ip_configuration : {
    name                          = c.name
    subnet_id                     = azurerm_subnet.this["GatewaySubnet"].id
    public_ip_address_name        = c.public_ip_address_name
    private_ip_address_allocation = c.private_ip_address_allocation
  }]
  log_analytics_workspace_name = var.enable_diagnostics ? var.log_analytics_workspace_name : null

  depends_on = [
    azurerm_subnet.this,
    azurerm_subnet_network_security_group_association.this,
  ]
}

####################################################
# ergw
####################################################

module "ergw" {
  count          = var.config_ergw.enable ? 1 : 0
  source         = "../../modules/vnet-gateway-express-route"
  resource_group = var.resource_group
  prefix         = local.prefix
  env            = var.env
  location       = var.location
  subnet_id      = azurerm_subnet.this["GatewaySubnet"].id
  tags           = var.tags

  sku           = var.config_vnet.express_route_gateway_sku
  active_active = var.config_ergw.active_active

  log_analytics_workspace_name = var.enable_diagnostics ? var.log_analytics_workspace_name : null

  depends_on = [
    azurerm_subnet.this,
    azurerm_subnet_network_security_group_association.this,
  ]
}

####################################################
# route server
####################################################

resource "azurerm_public_ip" "ars_pip" {
  count               = var.config_vnet.enable_ars ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.prefix}ars-pip"
  location            = var.location
  sku                 = var.config_vnet.express_route_gateway_sku
  allocation_method   = "Static"
  tags                = var.tags
  timeouts {
    create = "60m"
  }
  depends_on = [
    azurerm_subnet.this,
    azurerm_subnet_network_security_group_association.this,
  ]
}

resource "azurerm_route_server" "ars" {
  count                            = var.config_vnet.enable_ars ? 1 : 0
  resource_group_name              = var.resource_group
  name                             = "${local.prefix}ars"
  location                         = var.location
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.ars_pip[0].id
  subnet_id                        = azurerm_subnet.this["RouteServerSubnet"].id
  branch_to_branch_traffic_enabled = true
  tags                             = var.tags

  lifecycle {
    ignore_changes = [
      subnet_id
    ]
  }
  timeouts {
    create = "60m"
  }
  depends_on = [
    module.s2s_vpngw,
    module.p2s_vpngw,
    module.ergw,
  ]
}

####################################################
# azure firewall
####################################################

module "azfw" {
  count          = var.config_firewall.enable ? 1 : 0
  source         = "../../modules/azure-firewall"
  resource_group = var.resource_group
  prefix         = local.prefix
  env            = var.env
  location       = var.location
  subnet_id      = azurerm_subnet.this["AzureFirewallSubnet"].id
  mgt_subnet_id  = azurerm_subnet.this["AzureFirewallManagementSubnet"].id
  sku_name       = "AZFW_VNet"
  tags           = var.tags

  firewall_policy_id           = var.config_firewall.firewall_policy_id
  log_analytics_workspace_name = var.enable_diagnostics ? var.log_analytics_workspace_name : null

  depends_on = [
    azurerm_subnet.this,
    azurerm_subnet_network_security_group_association.this,
    azurerm_route_server.ars,
    module.s2s_vpngw,
    module.p2s_vpngw,
    module.ergw,
  ]
}

####################################################
# nva
####################################################

# linux
#----------------------------

# appliance

module "nva_linux" {
  count           = var.config_nva.enable && var.config_nva.type == "linux" ? 1 : 0
  source          = "../../modules/virtual-machine-linux"
  resource_group  = var.resource_group
  name            = "${local.prefix}nva"
  location        = var.location
  storage_account = var.storage_account
  #source_image    = "ubuntu-20"
  custom_data = var.config_nva.custom_data

  #log_analytics_workspace_name = var.enable_diagnostics ? var.log_analytics_workspace_name : null

  enable_ip_forwarding = true
  interfaces = [
    {
      name             = "${local.prefix}nva-untrust-nic"
      subnet_id        = azurerm_subnet.this["UntrustSubnet"].id
      create_public_ip = true
    },
    {
      name      = "${local.prefix}nva-trust-nic"
      subnet_id = azurerm_subnet.this["TrustSubnet"].id
    },
  ]

  depends_on = [
    azurerm_subnet.this,
    azurerm_subnet_network_security_group_association.this,
  ]
}


# internal lb

module "ilb_nva_linux" {
  count               = var.config_nva.enable && var.config_nva.type == "linux" ? 1 : 0
  source              = "../../modules/azure-load-balancer"
  resource_group_name = var.resource_group
  location            = var.location
  prefix              = trimsuffix(local.prefix, "-")
  name                = "nva"
  type                = "private"
  lb_sku              = "Standard"

  frontend_ip_configuration = [
    {
      name                          = "nva"
      zones                         = ["1", "2", "3"]
      subnet_id                     = azurerm_subnet.this["LoadBalancerSubnet"].id
      private_ip_address            = var.config_nva.internal_lb_addr
      private_ip_address_allocation = "Static"
    }
  ]

  probes = [
    { name = "ssh", protocol = "Tcp", port = "22", request_path = "" },
  ]

  backend_pools = [
    {
      name = "nva"
      addresses = [
        {
          name               = module.nva_linux[0].vm.name
          virtual_network_id = azurerm_virtual_network.this.id
          ip_address         = module.nva_linux[0].interfaces["${local.prefix}nva-untrust-nic"].ip_configuration[0].private_ip_address
        },
      ]
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

  depends_on = [
    azurerm_subnet.this,
    azurerm_subnet_network_security_group_association.this,
    module.nva_linux,
  ]
}

# opnsense
#----------------------------

locals {
  settings_opnsense = templatefile("${path.module}/templates/settings.tpl", local.params_opnsense)
  params_opnsense = {
    ShellScriptName               = var.shell_script_name
    OpnScriptURI                  = var.opn_script_uri
    OpnVersion                    = var.opn_version
    WALinuxVersion                = var.walinux_version
    OpnType                       = var.opn_type
    TrustedSubnetAddressPrefix    = var.trusted_subnet_address_prefix
    WindowsVmSubnetAddressPrefix  = var.deploy_windows_mgmt ? var.mgmt_subnet_address_prefix : "1.1.1.1/32"
    publicIPAddress               = length(azurerm_public_ip.opnsense) > 0 ? azurerm_public_ip.opnsense[0].ip_address : ""
    opnSenseSecondarytrustedNicIP = var.scenario_option == "Active-Active" ? "SOME" : ""
  }
}

resource "local_file" "params_opnsense" {
  count = (var.config_nva.enable && var.config_nva.type == "opnsense" ?
    var.config_nva.scenario_option == "Active-Active" ? 2 :
    var.config_nva.scenario_option == "TwoNics" ? 1 :
    0 : 0
  )
  filename = "settings.json"
  content  = local.settings_opnsense
}

# ip addresses

resource "azurerm_public_ip" "opnsense" {
  count = (var.config_nva.enable && var.config_nva.type == "opnsense" ?
    var.config_nva.scenario_option == "Active-Active" ? 2 :
    var.config_nva.scenario_option == "TwoNics" ? 1 :
    0 : 0
  )
  resource_group_name = var.resource_group
  name                = "${local.prefix}opns-${count.index}"
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
  zones               = [1, 2, 3]
  timeouts {
    create = "60m"
  }
  tags = var.tags
}

# appliances

module "opnsense" {
  count = (var.config_nva.enable && var.config_nva.type == "opnsense" ?
    var.config_nva.scenario_option == "Active-Active" ? 2 :
    var.config_nva.scenario_option == "TwoNics" ? 1 :
    0 : 0
  )
  source          = "../../modules/virtual-machine-linux"
  resource_group  = var.resource_group
  name            = "${local.prefix}opns-${count.index}"
  location        = var.location
  storage_account = var.storage_account
  identity_ids    = var.user_assigned_ids

  source_image_publisher = "thefreebsdfoundation"
  source_image_offer     = "freebsd-13_1"
  source_image_sku       = "13_1-release"
  source_image_version   = "latest"
  enable_plan            = true

  use_vm_extension      = true
  vm_extension_settings = local.settings_opnsense


  interfaces = [
    {
      name                 = "${local.prefix}opns-untrust-nic"
      subnet_id            = azurerm_subnet.this["UntrustSubnet"].id
      public_ip_address_id = azurerm_public_ip.opnsense[count.index].id
    },
    {
      name      = "${local.prefix}opns-trust-nic"
      subnet_id = azurerm_subnet.this["TrustSubnet"].id
    },
  ]

  depends_on = [
    azurerm_subnet.this,
    azurerm_subnet_network_security_group_association.this,
  ]
}


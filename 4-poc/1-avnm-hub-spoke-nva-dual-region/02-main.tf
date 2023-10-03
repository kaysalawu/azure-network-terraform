####################################################
# Lab
####################################################

locals {
  prefix       = "Poc1"
  my_public_ip = chomp(data.http.my_public_ip.response_body)
}

####################################################
# Data
####################################################

data "azurerm_subscription" "current" {
}

####################################################
# providers
####################################################

provider "azurerm" {
  skip_provider_registration = true
  features {}
}

terraform {
  required_providers {
    megaport = {
      source  = "megaport/megaport"
      version = "0.1.9"
    }
  }
}

####################################################
# network features
####################################################

locals {
  regions = {
    region1 = local.region1
    region2 = local.region2
  }

  default_udr_destinations = {
    "default" = "0.0.0.0/0"
  }

  hub1_nva_udr_destinations = {
    "spoke4" = local.spoke4_address_space[0]
    "spoke5" = local.spoke5_address_space[0]
    "hub2"   = local.hub2_address_space[0]
  }

  hub2_nva_udr_destinations = {
    "spoke1" = local.spoke1_address_space[0]
    "spoke2" = local.spoke2_address_space[0]
    "hub1"   = local.hub1_address_space[0]
  }

  hub1_gateway_udr_destinations = {
    "spoke1" = local.spoke1_address_space[0]
    "spoke2" = local.spoke2_address_space[0]
    "hub1"   = local.hub1_address_space[0]
  }

  hub2_gateway_udr_destinations = {
    "spoke4" = local.spoke4_address_space[0]
    "spoke5" = local.spoke5_address_space[0]
    "hub2"   = local.hub2_address_space[0]
  }

  firewall_sku = "Basic"

  hub1_features = {
    enable_private_dns_resolver = true
    enable_ars                  = false
    enable_vpn_gateway          = true
    enable_er_gateway           = false

    enable_firewall    = false
    firewall_sku       = local.firewall_sku
    firewall_policy_id = azurerm_firewall_policy.firewall_policy["region1"].id
  }

  hub2_features = {
    enable_private_dns_resolver = true
    enable_ars                  = false
    enable_vpn_gateway          = true
    enable_er_gateway           = false

    enable_firewall    = false
    firewall_sku       = local.firewall_sku
    firewall_policy_id = azurerm_firewall_policy.firewall_policy["region2"].id
  }
}

# resource group

resource "azurerm_resource_group" "rg" {
  name     = "${local.prefix}RG"
  location = local.default_region
}

# my public ip

data "http" "my_public_ip" {
  url = "http://ipv4.icanhazip.com"
}

####################################################
# common resources
####################################################

module "common" {
  source         = "../../modules/common"
  resource_group = azurerm_resource_group.rg.name
  env            = "common"
  prefix         = local.prefix
  firewall_sku   = local.firewall_sku
  regions        = local.regions
  tags           = {}
}

resource "azurerm_private_dns_zone" "global" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = local.cloud_domain
  timeouts {
    create = "60m"
  }
}

# vm startup scripts
#----------------------------

locals {
  hub1_nva_asn   = "65000"
  hub1_vpngw_asn = "65515"
  hub1_ergw_asn  = "65515"
  hub1_ars_asn   = "65515"

  hub2_nva_asn   = "65000"
  hub2_vpngw_asn = "65515"
  hub2_ergw_asn  = "65515"
  hub2_ars_asn   = "65515"

  vm_script_targets_region1 = [
    { name = "branch1", dns = local.branch1_vm_fqdn, ip = local.branch1_vm_addr },
    { name = "hub1   ", dns = local.hub1_vm_fqdn, ip = local.hub1_vm_addr },
    { name = "hub1-pe", dns = local.hub1_pep_fqdn, ping = false },
    { name = "spoke1 ", dns = local.spoke1_vm_fqdn, ip = local.spoke1_vm_addr },
    { name = "spoke2 ", dns = local.spoke2_vm_fqdn, ip = local.spoke2_vm_addr },
    { name = "spoke3 ", dns = local.spoke3_vm_fqdn, ip = local.spoke3_vm_addr, ping = false },
  ]
  vm_script_targets_region2 = [
    { name = "branch3", dns = local.branch3_vm_fqdn, ip = local.branch3_vm_addr },
    { name = "hub2   ", dns = local.hub2_vm_fqdn, ip = local.hub2_vm_addr },
    { name = "hub2-pe", dns = local.hub2_pep_fqdn, ping = false },
    { name = "spoke4 ", dns = local.spoke4_vm_fqdn, ip = local.spoke4_vm_addr },
    { name = "spoke5 ", dns = local.spoke5_vm_fqdn, ip = local.spoke5_vm_addr },
    { name = "spoke6 ", dns = local.spoke6_vm_fqdn, ip = local.spoke6_vm_addr, ping = false },
  ]
  vm_script_targets_misc = [
    { name = "internet", dns = "icanhazip.com", ip = "icanhazip.com" },
  ]
  vm_script_targets = concat(
    local.vm_script_targets_region1,
    local.vm_script_targets_region2,
    local.vm_script_targets_misc,
  )
  vm_startup = templatefile("../../scripts/server.sh", {
    TARGETS = local.vm_script_targets
  })

  unbound_vars = {
    ONPREM_LOCAL_RECORDS = local.onprem_local_records
    REDIRECTED_HOSTS     = local.onprem_redirected_hosts
    FORWARD_ZONES        = local.onprem_forward_zones
    TARGETS              = local.vm_script_targets_region1
  }
  branch_unbound_conf         = templatefile("../../scripts/unbound/unbound.conf", local.unbound_vars)
  branch_unbound_startup      = templatefile("../../scripts/unbound/unbound.sh", local.unbound_vars)
  branch_dnsmasq_startup      = templatefile("../../scripts/dnsmasq/dnsmasq.sh", local.unbound_vars)
  branch_dnsmasq_cloud_config = templatefile("../../scripts/dnsmasq/cloud-config", local.unbound_vars)
  branch_unbound_cloud_config = templatefile("../../scripts/unbound/cloud-config", local.unbound_vars)
  branch_unbound_vars = {
    ONPREM_LOCAL_RECORDS = local.onprem_local_records
    REDIRECTED_HOSTS     = local.onprem_redirected_hosts
    FORWARD_ZONES        = local.onprem_forward_zones
    TARGETS              = local.vm_script_targets_region1
  }
  onprem_local_records = [
    { name = (local.branch1_vm_fqdn), record = local.branch1_vm_addr },
    { name = (local.branch2_vm_fqdn), record = local.branch2_vm_addr },
    { name = (local.branch3_vm_fqdn), record = local.branch3_vm_addr },
  ]
  onprem_forward_zones = [
    { zone = "${local.cloud_domain}.", targets = [local.hub1_dns_in_addr, local.hub2_dns_in_addr], },
    { zone = ".", targets = [local.azuredns, ] },
  ]
  onprem_redirected_hosts = []
}

module "unbound" {
  source   = "../../modules/cloud-config-gen"
  packages = ["tcpdump", "dnsutils", "net-tools", "unbound"]
  files = {
    "/var/log/unbound"          = { owner = "root", permissions = "0755", content = "" }
    "/etc/unbound/unbound.conf" = { owner = "root", permissions = "0640", content = local.branch_unbound_conf }
  }
  run_commands = [
    "systemctl restart unbound",
    "systemctl enable unbound",
  ]
}

module "dnsmasq" {
  source   = "../../modules/cloud-config-gen"
  packages = ["dnsmasq"]
  files    = {}
  run_commands = [
    "systemctl restart dnsmasq",
    "systemctl enable dnsmasq",
  ]
}

####################################################
# nsg
####################################################

# rules

####################################################
# addresses
####################################################

resource "azurerm_public_ip" "branch1_nva_pip" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.branch1_prefix}nva-pip"
  location            = local.branch1_location
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "branch3_nva_pip" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.branch3_prefix}nva-pip"
  location            = local.branch3_location
  sku                 = "Standard"
  allocation_method   = "Static"
}

####################################################
# firewall policy
####################################################

# policy

resource "azurerm_firewall_policy" "firewall_policy" {
  for_each                 = local.regions
  resource_group_name      = azurerm_resource_group.rg.name
  name                     = "${local.prefix}-fw-policy-${each.key}"
  location                 = each.value
  threat_intelligence_mode = "Alert"
  sku                      = local.firewall_sku

  private_ip_ranges = concat(
    local.private_prefixes,
    [
      #"${local.spoke3_vm_public_ip}/32",
      #"${local.spoke6_vm_public_ip}/32",
    ]
  )

  #dns {
  #  proxy_enabled = true
  #}
}

# collection

module "fw_policy_rule_collection_group" {
  for_each           = local.regions
  source             = "../../modules/fw-policy"
  prefix             = local.prefix
  firewall_policy_id = azurerm_firewall_policy.firewall_policy[each.key].id

  network_rule_collection = [
    {
      name     = "network-rc"
      priority = 100
      action   = "Allow"
      rule = [
        {
          name                  = "network-rc-any-to-any"
          source_addresses      = ["*"]
          destination_addresses = ["*"]
          protocols             = ["Any"]
          destination_ports     = ["*"]
        }
      ]
    }
  ]
  application_rule_collection = []
  nat_rule_collection         = []
}

####################################################
# network manager
####################################################

resource "azurerm_network_manager" "netman" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = "${local.prefix}-netman"
  scope_accesses      = ["Connectivity", "SecurityAdmin"]
  description         = "global"
  scope {
    subscription_ids = [data.azurerm_subscription.current.id]
  }
}

####################################################
# output files
####################################################

locals {
  ouput_values = templatefile("./scripts/values.sh", {
    HUB1_VNET_NAME    = module.hub1.vnet.name
    HUB2_VNET_NAME    = module.hub2.vnet.name
    SPOKE1_VNET_NAME  = module.spoke1.vnet.name
    SPOKE2_VNET_NAME  = module.spoke2.vnet.name
    SPOKE3_VNET_NAME  = module.spoke3.vnet.name
    SPOKE4_VNET_NAME  = module.spoke4.vnet.name
    SPOKE5_VNET_NAME  = module.spoke5.vnet.name
    SPOKE6_VNET_NAME  = module.spoke6.vnet.name
    BRANCH1_VNET_NAME = module.branch1.vnet.name
    BRANCH3_VNET_NAME = module.branch3.vnet.name

    HUB1_VNET_RANGES    = join(", ", module.hub1.vnet.address_space)
    HUB2_VNET_RANGES    = join(", ", module.hub2.vnet.address_space)
    SPOKE1_VNET_RANGES  = join(", ", module.spoke1.vnet.address_space)
    SPOKE2_VNET_RANGES  = join(", ", module.spoke2.vnet.address_space)
    SPOKE3_VNET_RANGES  = join(", ", module.spoke3.vnet.address_space)
    SPOKE4_VNET_RANGES  = join(", ", module.spoke4.vnet.address_space)
    SPOKE5_VNET_RANGES  = join(", ", module.spoke5.vnet.address_space)
    SPOKE6_VNET_RANGES  = join(", ", module.spoke6.vnet.address_space)
    BRANCH1_VNET_RANGES = join(", ", module.branch1.vnet.address_space)
    BRANCH3_VNET_RANGES = join(", ", module.branch3.vnet.address_space)

    HUB1_VM_NAME    = module.hub1.vm["vm"].name
    HUB2_VM_NAME    = module.hub2.vm["vm"].name
    SPOKE1_VM_NAME  = module.spoke1.vm["vm"].name
    SPOKE2_VM_NAME  = module.spoke2.vm["vm"].name
    SPOKE3_VM_NAME  = module.spoke3.vm["vm"].name
    SPOKE4_VM_NAME  = module.spoke4.vm["vm"].name
    SPOKE5_VM_NAME  = module.spoke5.vm["vm"].name
    SPOKE6_VM_NAME  = module.spoke6.vm["vm"].name
    BRANCH1_VM_NAME = module.branch1.vm["vm"].name
    BRANCH3_VM_NAME = module.branch3.vm["vm"].name

    HUB1_VM_IP    = module.hub1.vm["vm"].private_ip_address
    HUB2_VM_IP    = module.hub2.vm["vm"].private_ip_address
    SPOKE1_VM_IP  = module.spoke1.vm["vm"].private_ip_address
    SPOKE2_VM_IP  = module.spoke2.vm["vm"].private_ip_address
    SPOKE3_VM_IP  = module.spoke3.vm["vm"].private_ip_address
    SPOKE4_VM_IP  = module.spoke4.vm["vm"].private_ip_address
    SPOKE5_VM_IP  = module.spoke5.vm["vm"].private_ip_address
    SPOKE6_VM_IP  = module.spoke6.vm["vm"].private_ip_address
    BRANCH1_VM_IP = module.branch1.vm["vm"].private_ip_address
    BRANCH3_VM_IP = module.branch3.vm["vm"].private_ip_address

    HUB1_SUBNETS    = { for k, v in module.hub1.subnets : k => v.address_prefixes[0] }
    HUB2_SUBNETS    = { for k, v in module.hub2.subnets : k => v.address_prefixes[0] }
    SPOKE1_SUBNETS  = { for k, v in module.spoke1.subnets : k => v.address_prefixes[0] }
    SPOKE2_SUBNETS  = { for k, v in module.spoke2.subnets : k => v.address_prefixes[0] }
    SPOKE3_SUBNETS  = { for k, v in module.spoke3.subnets : k => v.address_prefixes[0] }
    SPOKE4_SUBNETS  = { for k, v in module.spoke4.subnets : k => v.address_prefixes[0] }
    SPOKE5_SUBNETS  = { for k, v in module.spoke5.subnets : k => v.address_prefixes[0] }
    SPOKE6_SUBNETS  = { for k, v in module.spoke6.subnets : k => v.address_prefixes[0] }
    BRANCH1_SUBNETS = { for k, v in module.branch1.subnets : k => v.address_prefixes[0] }
    BRANCH3_SUBNETS = { for k, v in module.branch3.subnets : k => v.address_prefixes[0] }
  })

  main_files = {
    "output/unbound.conf" = module.unbound.cloud_config
    "output/dnsmasq.sh"   = local.branch_dnsmasq_startup
    "output/values.sh"    = local.ouput_values
  }
}

resource "local_file" "main_files" {
  for_each = local.main_files
  filename = each.key
  content  = each.value
}

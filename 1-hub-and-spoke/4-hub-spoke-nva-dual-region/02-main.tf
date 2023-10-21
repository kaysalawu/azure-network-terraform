####################################################
# Lab
####################################################

locals {
  prefix = "Hs14"
  #my_public_ip = chomp(data.http.my_public_ip.response_body)
}

####################################################
# Data
####################################################

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
      version = "0.3.0"
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
  hub1_appliance_udr_destinations = {
    "spoke4" = local.spoke4_address_space[0]
    "spoke5" = local.spoke5_address_space[0]
    "hub2"   = local.hub2_address_space[0]
  }
  hub2_appliance_udr_destinations = {
    "spoke1" = local.spoke1_address_space[0]
    "spoke2" = local.spoke2_address_space[0]
    "hub1"   = local.hub1_address_space[0]
  }
  hub1_gateway_udr_destinations = {
    "spoke1" = local.spoke1_address_space[0]
    "spoke2" = local.spoke2_address_space[0]
    "spoke4" = local.spoke4_address_space[0]
    "spoke5" = local.spoke5_address_space[0]
    "hub1"   = local.hub1_address_space[0]
    "hub2"   = local.hub2_address_space[0]
  }
  hub2_gateway_udr_destinations = {
    "spoke1" = local.spoke1_address_space[0]
    "spoke2" = local.spoke2_address_space[0]
    "spoke4" = local.spoke4_address_space[0]
    "spoke5" = local.spoke5_address_space[0]
    "hub1"   = local.hub1_address_space[0]
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

/* data "http" "my_public_ip" {
  url = "http://ipv4.icanhazip.com"
} */

####################################################
# common resources
####################################################

module "common" {
  source           = "../../modules/common"
  resource_group   = azurerm_resource_group.rg.name
  env              = "common"
  prefix           = local.prefix
  firewall_sku     = local.firewall_sku
  regions          = local.regions
  private_prefixes = local.private_prefixes
  tags             = {}
}

# private dns zones

resource "azurerm_private_dns_zone" "global" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = local.cloud_domain
  timeouts {
    create = "60m"
  }
}

resource "azurerm_private_dns_zone" "privatelink_blob" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "privatelink.blob.core.windows.net"
  timeouts {
    create = "60m"
  }
}

resource "azurerm_private_dns_zone" "privatelink_appservice" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "privatelink.azurewebsites.net"
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
    { name = "hub1-spoke3-pep", dns = local.hub1_spoke3_pep_fqdn, ping = false },
    { name = "spoke1 ", dns = local.spoke1_vm_fqdn, ip = local.spoke1_vm_addr },
    { name = "spoke2 ", dns = local.spoke2_vm_fqdn, ip = local.spoke2_vm_addr },
    { name = "spoke3 ", dns = local.spoke3_vm_fqdn, ip = local.spoke3_vm_addr, ping = false },
  ]
  vm_script_targets_region2 = [
    { name = "branch3", dns = local.branch3_vm_fqdn, ip = local.branch3_vm_addr },
    { name = "hub2   ", dns = local.hub2_vm_fqdn, ip = local.hub2_vm_addr },
    { name = "hub2-spoke6-pep", dns = local.hub2_spoke6_pep_fqdn, ping = false },
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
    ACCESS_CONTROL_PREFIXES = concat(
      local.private_prefixes,
      [
        "127.0.0.0/8",
        "35.199.192.0/19",
      ]
    )
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
# output files
####################################################

locals {
  main_files = {
    "output/branch-unbound.sh" = local.branch_unbound_startup
    "output/server.sh"         = local.vm_startup
  }
}

resource "local_file" "main_files" {
  for_each = local.main_files
  filename = each.key
  content  = each.value
}

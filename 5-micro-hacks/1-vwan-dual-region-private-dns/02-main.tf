####################################################
# Lab
####################################################

locals {
  prefix             = "Vwan_Dns"
  enable_diagnostics = false
  shared1_apps_fqdn  = lower("spoke3-${random_id.random.hex}.azurewebsites.net")
  shared2_apps_fqdn  = lower("spoke6-${random_id.random.hex}.azurewebsites.net")
  spoke1_vm_fqdn     = lower("vm.${local.spoke1_dns_zone}")
  spoke2_vm_fqdn     = lower("vm.${local.spoke2_dns_zone}")
  spoke3_vm_fqdn     = lower("vm.${local.spoke3_dns_zone}")
  spoke4_vm_fqdn     = lower("vm.${local.spoke4_dns_zone}")

  shared1_tags = { "lab" = "mH51_Vwan_Dns", "nodeType" = "hub" }
  shared2_tags = { "lab" = "mH51_Vwan_Dns", "nodeType" = "hub" }
  branch1_tags = { "lab" = "mH51_Vwan_Dns", "nodeType" = "branch" }
  branch2_tags = { "lab" = "mH51_Vwan_Dns", "nodeType" = "branch" }
  spoke1_tags  = { "lab" = "mH51_Vwan_Dns", "nodeType" = "spoke" }
  spoke2_tags  = { "lab" = "mH51_Vwan_Dns", "nodeType" = "spoke" }
  spoke3_tags  = { "lab" = "mH51_Vwan_Dns", "nodeType" = "spoke" }
  spoke4_tags  = { "lab" = "mH51_Vwan_Dns", "nodeType" = "spoke" }
}

resource "random_id" "random" {
  byte_length = 2
}

####################################################
# providers
####################################################

provider "azurerm" {
  skip_provider_registration = true
  features {}
}

provider "azapi" {}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.78.0"
    }
    azapi = {
      source = "azure/azapi"
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

  firewall_sku = "Basic"

  shared1_features = {
    config_vnet = {
      address_space               = local.shared1_address_space
      subnets                     = local.shared1_subnets
      enable_private_dns_resolver = false
      enable_ars                  = false

      ruleset_dns_forwarding_rules = {
        # "onprem" = {
        #   domain = local.onprem_domain
        #   target_dns_servers = [
        #     { ip_address = local.branch1_dns_addr, port = 53 },
        #     { ip_address = local.branch2_dns_addr, port = 53 },
        #   ]
        # }
        # "eu" = {
        #   domain = "eu.${local.cloud_domain}"
        #   target_dns_servers = [
        #     { ip_address = local.shared1_dns_in_addr, port = 53 },
        #   ]
        # }
        # "us" = {
        #   domain = "us.${local.cloud_domain}"
        #   target_dns_servers = [
        #     { ip_address = local.shared2_dns_in_addr, port = 53 },
        #   ]
        # }
        # "azurewebsites" = {
        #   domain = "privatelink.azurewebsites.net"
        #   target_dns_servers = [
        #     { ip_address = local.shared1_dns_in_addr, port = 53 },
        #   ]
        # }
      }
    }
  }

  shared2_features = {
    config_vnet = {
      address_space               = local.shared2_address_space
      subnets                     = local.shared2_subnets
      enable_private_dns_resolver = false
      enable_ars                  = false

      ruleset_dns_forwarding_rules = {
        # "onprem" = {
        #   domain = local.onprem_domain
        #   target_dns_servers = [
        #     { ip_address = local.branch2_dns_addr, port = 53 },
        #     { ip_address = local.branch1_dns_addr, port = 53 },
        #   ]
        # }
        # "eu" = {
        #   domain = "eu.${local.cloud_domain}"
        #   target_dns_servers = [
        #     { ip_address = local.shared1_dns_in_addr, port = 53 },
        #   ]
        # }
        # "us" = {
        #   domain = "us.${local.cloud_domain}"
        #   target_dns_servers = [
        #     { ip_address = local.shared2_dns_in_addr, port = 53 },
        #   ]
        # }
        # "azurewebsites" = {
        #   domain = "privatelink.azurewebsites.net"
        #   target_dns_servers = [
        #     { ip_address = local.shared2_dns_in_addr, port = 53 },
        #   ]
        # }
      }
    }
  }

  vhub1_features = {
    s2s_vpn_gateway = {
      enable             = true
      sku                = "VpnGw1AZ"
      enable_diagnostics = local.enable_diagnostics
      bgp_settings = {
        asn                                       = local.vhub1_bgp_asn
        peer_weight                               = 0
        instance_0_bgp_peering_address_custom_ips = [local.vhub1_vpngw_bgp_apipa_0]
        instance_1_bgp_peering_address_custom_ips = [local.vhub1_vpngw_bgp_apipa_1]
      }
    }
  }

  vhub2_features = {
    s2s_vpn_gateway = {
      enable             = true
      sku                = "VpnGw1AZ"
      enable_diagnostics = local.enable_diagnostics
      bgp_settings = {
        asn                                       = local.vhub2_bgp_asn
        peer_weight                               = 0
        instance_0_bgp_peering_address_custom_ips = [local.vhub2_vpngw_bgp_apipa_0]
        instance_1_bgp_peering_address_custom_ips = [local.vhub2_vpngw_bgp_apipa_1]
      }
    }
  }
}

####################################################
# common resources
####################################################

# resource group

resource "azurerm_resource_group" "rg" {
  name     = "${local.prefix}RG"
  location = local.default_region
}

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

# resource "azurerm_private_dns_zone" "global" {
#   resource_group_name = azurerm_resource_group.rg.name
#   name                = local.cloud_domain
#   timeouts {
#     create = "60m"
#   }
# }

# resource "azurerm_private_dns_zone" "privatelink_blob" {
#   resource_group_name = azurerm_resource_group.rg.name
#   name                = "privatelink.blob.core.windows.net"
#   timeouts {
#     create = "60m"
#   }
# }

# resource "azurerm_private_dns_zone" "privatelink_appservice" {
#   resource_group_name = azurerm_resource_group.rg.name
#   name                = "privatelink.azurewebsites.net"
#   timeouts {
#     create = "60m"
#   }
# }

# vm startup scripts
#----------------------------

locals {
  shared1_nva_asn   = "65010"
  shared1_vpngw_asn = "65011"
  shared1_ergw_asn  = "65012"
  shared1_ars_asn   = "65515"

  shared2_nva_asn   = "65020"
  shared2_vpngw_asn = "65021"
  shared2_ergw_asn  = "65022"
  shared2_ars_asn   = "65515"

  vm_script_targets_region1 = [
    { name = "branch1", dns = local.branch1_vm_fqdn, ip = local.branch1_vm_addr, probe = true },
    { name = "shared1-spoke3-pep", dns = local.shared1_spoke3_pep_fqdn, ping = false, probe = true },
    { name = "spoke1 ", dns = local.spoke1_vm_fqdn, ip = local.spoke1_vm_addr, probe = true },
    { name = "spoke2 ", dns = local.spoke2_vm_fqdn, ip = local.spoke2_vm_addr, probe = true },
  ]
  vm_script_targets_region2 = [
    { name = "branch2", dns = local.branch2_vm_fqdn, ip = local.branch2_vm_addr, probe = true },
    { name = "shared2-spoke6-pep", dns = local.shared2_spoke6_pep_fqdn, ping = false, probe = true },
    { name = "spoke3 ", dns = local.spoke3_vm_fqdn, ip = local.spoke3_vm_addr, probe = true },
    { name = "spoke4 ", dns = local.spoke4_vm_fqdn, ip = local.spoke4_vm_addr, probe = true },
  ]
  vm_script_targets_misc = [
    { name = "internet", dns = "icanhazip.com", ip = "icanhazip.com" },
    { name = "shared1-apps", dns = local.shared1_apps_fqdn, ping = false, probe = true },
    { name = "shared2-apps", dns = local.shared2_apps_fqdn, ping = false, probe = true },
  ]
  vm_script_targets = concat(
    local.vm_script_targets_region1,
    local.vm_script_targets_region2,
    local.vm_script_targets_misc,
  )
  vm_startup = templatefile("../../scripts/server.sh", {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []
    ENABLE_TRAFFIC_GEN        = false
  })

  branch_dns_vars = {
    ONPREM_LOCAL_RECORDS = local.onprem_local_records
    REDIRECTED_HOSTS     = local.onprem_redirected_hosts
    FORWARD_ZONES        = local.onprem_forward_zones
    TARGETS              = local.vm_script_targets
    ACCESS_CONTROL_PREFIXES = concat(
      local.private_prefixes,
      [
        "127.0.0.0/8",
        "35.199.192.0/19",
      ]
    )
  }
  branch_unbound_startup = templatefile("../../scripts/unbound/unbound.sh", local.branch_dns_vars)
  branch_dnsmasq_startup = templatefile("../../scripts/dnsmasq/dnsmasq.sh", local.branch_dns_vars)
  branch_dns_init_dir    = "/var/lib/labs"
  branch_dnsmasq_init = {
    "${local.branch_dns_init_dir}/app/Dockerfile"     = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/dnsmasq/app/Dockerfile", {}) }
    "${local.branch_dns_init_dir}/docker-compose.yml" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/dnsmasq/docker-compose.yml", {}) }
    "/etc/dnsmasq.d/local_records.conf"               = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/dnsmasq/app/conf/local_records.conf", local.branch_dns_vars) }
    "/etc/dnsmasq.d/forwarding.conf"                  = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/dnsmasq/app/conf/forwarding.conf", local.branch_dns_vars) }
    "/etc/dnsmasq.d/default.conf"                     = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/dnsmasq/app/conf/default.conf", local.branch_dns_vars) }
  }
  branch_unbound_init = {
    "${local.branch_dns_init_dir}/app/Dockerfile"     = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/app/Dockerfile", {}) }
    "${local.branch_dns_init_dir}/docker-compose.yml" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/docker-compose.yml", {}) }
    "/etc/unbound/unbound.conf"                       = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/app/conf/unbound.conf", local.branch_dns_vars) }
    "/etc/unbound/unbound.log"                        = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/app/conf/unbound.log", local.branch_dns_vars) }
  }
  onprem_local_records = [
    { name = (local.branch1_vm_fqdn), record = local.branch1_vm_addr },
    { name = (local.branch2_vm_fqdn), record = local.branch2_vm_addr },
  ]
  onprem_forward_zones = [
    #{ zone = "${local.cloud_domain}.", targets = [local.shared1_dns_in_addr, local.shared2_dns_in_addr], },
    #{ zone = "${local.cloud_domain}.", targets = [local.shared1_dns_in_addr, local.shared2_dns_in_addr], },
    #{ zone = "privatelink.blob.core.windows.net.", targets = [local.shared1_dns_in_addr, local.shared2_dns_in_addr], },
    #{ zone = "privatelink.azurewebsites.net.", targets = [local.shared1_dns_in_addr, local.shared2_dns_in_addr], },
    #{ zone = "privatelink.database.windows.net.", targets = [local.shared1_dns_in_addr, local.shared2_dns_in_addr], },
    #{ zone = "privatelink.table.cosmos.azure.com.", targets = [local.shared1_dns_in_addr, local.shared2_dns_in_addr], },
    #{ zone = "privatelink.queue.core.windows.net.", targets = [local.shared1_dns_in_addr, local.shared2_dns_in_addr], },
    #{ zone = "privatelink.file.core.windows.net.", targets = [local.shared1_dns_in_addr, local.shared2_dns_in_addr], },
    { zone = ".", targets = [local.azuredns, ] },
  ]
  onprem_redirected_hosts = []
}

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

resource "azurerm_public_ip" "branch2_nva_pip" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.branch2_prefix}nva-pip"
  location            = local.branch2_location
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
      local.internet_proxy,
    ]
  )

  #dns {
  #  proxy_enabled = true
  #}
}

# collection

module "fw_policy_rule_collection_group" {
  for_each           = local.regions
  source             = "../../modules/firewall-policy"
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

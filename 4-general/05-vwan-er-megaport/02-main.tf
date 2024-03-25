####################################################
# Lab
####################################################

locals {
  prefix                      = "G05"
  lab_name                    = "VwanEr"
  enable_diagnostics          = false
  enable_onprem_wan_link      = false
  spoke2_storage_account_name = lower(replace("${local.spoke3_prefix}sa${random_id.random.hex}", "-", ""))
  spoke2_blob_url             = "https://${local.spoke2_storage_account_name}.blob.core.windows.net/spoke3/spoke3.txt"
  spoke2_apps_fqdn            = lower("${local.spoke3_prefix}${random_id.random.hex}.azurewebsites.net")

  hub1_tags    = { "lab" = local.prefix, "nodeType" = "hub" }
  branch2_tags = { "lab" = local.prefix, "nodeType" = "branch" }
  spoke1_tags  = { "lab" = local.prefix, "nodeType" = "spoke" }
  spoke2_tags  = { "lab" = local.prefix, "nodeType" = "float" }
  spoke3_tags  = { "lab" = local.prefix, "nodeType" = "spoke" }
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
    megaport = {
      source  = "megaport/megaport"
      version = "0.4.0"
    }
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
    "region1" = { name = local.region1, dns_zone = local.region1_dns_zone }
    "region2" = { name = local.region2, dns_zone = local.region2_dns_zone }
    "region3" = { name = local.region3, dns_zone = local.region3_dns_zone }
  }
  default_udr_destinations = [
    { name = "default", address_prefix = ["0.0.0.0/0"] }
  ]

  firewall_sku = "Basic"

  hub1_features = {
    config_vnet = {
      address_space               = local.hub1_address_space
      subnets                     = local.hub1_subnets
      enable_private_dns_resolver = true
      enable_ars                  = false

      ruleset_dns_forwarding_rules = {
        "onprem" = {
          domain = local.onprem_domain
          target_dns_servers = [
            { ip_address = local.branch2_dns_addr, port = 53 },
          ]
        }
        "${local.region1_code}" = {
          domain = local.region1_dns_zone
          target_dns_servers = [
            { ip_address = local.hub1_dns_in_addr, port = 53 },
          ]
        }
        "${local.region2_code}" = {
          domain = local.region2_dns_zone
          target_dns_servers = [
            { ip_address = local.hub1_dns_in_addr, port = 53 },
          ]
        }
        "${local.region3_code}" = {
          domain = local.region3_dns_zone
          target_dns_servers = [
            { ip_address = local.hub1_dns_in_addr, port = 53 },
          ]
        }
        "azurewebsites" = {
          domain = "privatelink.azurewebsites.net"
          target_dns_servers = [
            { ip_address = local.hub1_dns_in_addr, port = 53 },
          ]
        }
        "blob" = {
          domain = "privatelink.blob.core.windows.net"
          target_dns_servers = [
            { ip_address = local.hub1_dns_in_addr, port = 53 },
          ]
        }
      }
    }

    config_s2s_vpngw = { enable = false }
    config_p2s_vpngw = { enable = false }

    config_ergw = {
      enable = false
      sku    = "ErGw1AZ"
    }

    config_firewall = { enable = false }

    config_nva = {
      enable          = true
      type            = "linux"
      scenario_option = "TwoNics"
      opn_type        = "TwoNics"
      custom_data     = base64encode(local.hub1_linux_nva_init)
      ilb_untrust_ip  = local.hub1_nva_ilb_untrust_addr
      ilb_trust_ip    = local.hub1_nva_ilb_trust_addr
    }
  }

  vhub1_features = {
    express_route_gateway = {
      enable = true
      sku    = "ErGw1AZ"
    }

    s2s_vpn_gateway = {
      enable = true
      sku    = "VpnGw1AZ"
      bgp_settings = {
        asn                                       = local.vhub1_bgp_asn
        peer_weight                               = 0
        instance_0_bgp_peering_address_custom_ips = [local.vhub1_vpngw_bgp_apipa_0]
        instance_1_bgp_peering_address_custom_ips = [local.vhub1_vpngw_bgp_apipa_1]
      }
    }

    p2s_vpn_gateway = { enable = false }

    config_security = {
      create_firewall       = true
      enable_routing_intent = true
      firewall_sku          = local.firewall_sku
      firewall_policy_id    = azurerm_firewall_policy.firewall_policy["region1"].id
      routing_policies = {
        internet            = true
        private_traffic     = true
        additional_prefixes = { "private_traffic" = [local.internet_proxy, ] }
      }
    }
  }

  vhub2_features = {
    express_route_gateway = { enable = false }
    s2s_vpn_gateway       = { enable = false }
    p2s_vpn_gateway       = { enable = false }

    config_security = {
      create_firewall       = true
      enable_routing_intent = true
      firewall_sku          = local.firewall_sku
      firewall_policy_id    = azurerm_firewall_policy.firewall_policy["region2"].id
      routing_policies = {
        internet            = true
        private_traffic     = true
        additional_prefixes = { "private_traffic" = ["8.8.8.8/32"] }
      }
    }
  }

  vhub3_features = {
    express_route_gateway = {
      enable = true
      sku    = "ErGw1AZ"
    }
    s2s_vpn_gateway = {}
    p2s_vpn_gateway = {}

    config_security = {
      create_firewall       = true
      enable_routing_intent = true
      firewall_sku          = local.firewall_sku
      firewall_policy_id    = azurerm_firewall_policy.firewall_policy["region1"].id
      routing_policies = {
        internet            = true
        private_traffic     = true
        additional_prefixes = { "private_traffic" = [local.internet_proxy, ] }
      }
    }
  }
}

####################################################
# common resources
####################################################

# resource group

resource "azurerm_resource_group" "rg" {
  name     = "${local.prefix}_${local.lab_name}_RG"
  location = local.default_region
  tags = {
    prefix   = local.prefix
    lab_name = local.lab_name
  }
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
  hub1_nva_asn   = "65010"
  hub1_vpngw_asn = "65011"
  hub1_ergw_asn  = "65012"
  hub1_ars_asn   = "65515"

  hub2_nva_asn   = "65020"
  hub2_vpngw_asn = "65021"
  hub2_ergw_asn  = "65022"
  hub2_ars_asn   = "65515"

  vm_script_targets_region1 = [
    { name = "spoke1 ", dns = lower(local.spoke1_vm_fqdn), ip = local.spoke1_vm_addr, probe = true },
  ]
  vm_script_targets_region2 = [
    { name = "branch2", dns = lower(local.branch2_vm_fqdn), ip = local.branch2_vm_addr, probe = true },
    { name = "hub1   ", dns = lower(local.hub1_vm_fqdn), ip = local.hub1_vm_addr, probe = false },
    { name = "hub1-spoke3-pep", dns = lower(local.hub1_spoke3_pep_fqdn), ping = false, probe = true },
    { name = "spoke2 ", dns = lower(local.spoke2_vm_fqdn), ip = local.spoke2_vm_addr, probe = true },
  ]
  vm_script_targets_region3 = [
    { name = "spoke3 ", dns = lower(local.spoke3_vm_fqdn), ip = local.spoke3_vm_addr, probe = true },
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
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []
    ENABLE_TRAFFIC_GEN        = false
  })
  onprem_local_records = [
    { name = lower(local.branch2_vm_fqdn), record = local.branch2_vm_addr },
  ]
  onprem_redirected_hosts = []
  branch_dns_init_dir     = "/var/lib/azure"
}

####################################################
# addresses
####################################################

# branch2

resource "azurerm_public_ip" "branch2_nva_pip" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.branch2_prefix}nva-pip"
  location            = local.branch2_location
  sku                 = "Standard"
  allocation_method   = "Static"
  tags                = local.branch2_tags
}

####################################################
# firewall policy
####################################################

# policy

resource "azurerm_firewall_policy" "firewall_policy" {
  for_each                 = local.regions
  resource_group_name      = azurerm_resource_group.rg.name
  name                     = "${local.prefix}-fw-policy-${each.key}"
  location                 = each.value.name
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
# nva
####################################################

# hub1

locals {
  hub1_nva_route_map_onprem      = "ONPREM"
  hub1_nva_route_map_azure       = "AZURE"
  hub1_nva_route_map_block_azure = "BLOCK_HUB_GW_SUBNET"
  hub1_nva_vars = {
    LOCAL_ASN = local.hub1_nva_asn
    LOOPBACK0 = local.hub1_nva_loopback0
    LOOPBACKS = []

    PREFIX_LISTS = [
      # "ip prefix-list ${local.hub1_nva_route_map_block_azure} deny ${local.hub1_subnets["GatewaySubnet"].address_prefixes[0]}",
      # "ip prefix-list ${local.hub1_nva_route_map_block_azure} permit 0.0.0.0/0 le 32",
    ]

    ROUTE_MAPS = [
      # "match ip address prefix-list all",
      # "set ip next-hop ${local.hub1_nva_ilb_trust_addr}"
    ]
    STATIC_ROUTES = [
      { prefix = "0.0.0.0/0", next_hop = local.hub1_default_gw_nva },
      { prefix = "${module.vhub2.router_bgp_ip0}/32", next_hop = local.hub1_default_gw_nva },
      { prefix = "${module.vhub2.router_bgp_ip1}/32", next_hop = local.hub1_default_gw_nva },
    ]
    TUNNELS = []
    BGP_SESSIONS = [
      {
        peer_asn        = module.vhub2.bgp_asn
        peer_ip         = module.vhub2.router_bgp_ip0
        ebgp_multihop   = true
        source_loopback = true
        route_maps      = []
      },
      {
        peer_asn        = module.vhub2.bgp_asn
        peer_ip         = module.vhub2.router_bgp_ip1
        ebgp_multihop   = true
        source_loopback = true
        route_maps      = []
      },
    ]
    BGP_ADVERTISED_PREFIXES = [
      local.hub1_subnets["MainSubnet"].address_prefixes[0],
    ]
  }
  hub1_linux_nva_init = templatefile("../../scripts/linux-nva.sh", merge(local.hub1_nva_vars, {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []
    ENABLE_TRAFFIC_GEN        = false
    IPTABLES_RULES            = []
    FRR_CONF                  = templatefile("../../scripts/frr/frr.conf", merge(local.hub1_nva_vars, {}))
    STRONGSWAN_VTI_SCRIPT     = ""
    STRONGSWAN_IPSEC_SECRETS  = ""
    STRONGSWAN_IPSEC_CONF     = ""
  }))
}

####################################################
# output files
####################################################

locals {
  main_files = {
    "output/server.sh"         = local.vm_startup
    "output/hub1-linux-nva.sh" = local.hub1_linux_nva_init
  }
}

resource "local_file" "main_files" {
  for_each = local.main_files
  filename = each.key
  content  = each.value
}

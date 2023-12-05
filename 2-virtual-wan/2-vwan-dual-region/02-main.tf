####################################################
# Lab
####################################################

locals {
  prefix           = "Vwan22"
  spoke3_apps_fqdn = lower("${local.spoke3_prefix}${random_id.random.hex}-app.azurewebsites.net")
  spoke6_apps_fqdn = lower("${local.spoke6_prefix}${random_id.random.hex}-app.azurewebsites.net")
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
  #required_version = ">= 1.4.6"
  required_providers {
    megaport = {
      source  = "megaport/megaport"
      version = "0.1.9"
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
    region1 = local.region1
    region2 = local.region2
  }
  default_udr_destinations = {
    "default" = "0.0.0.0/0"
  }

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
            { ip_address = local.branch1_dns_addr, port = 53 },
            { ip_address = local.branch3_dns_addr, port = 53 },
          ]
        }
        "eu" = {
          domain = "we.${local.cloud_domain}"
          target_dns_servers = [
            { ip_address = local.hub1_dns_in_addr, port = 53 },
          ]
        }
        "ne" = {
          domain = "ne.${local.cloud_domain}"
          target_dns_servers = [
            { ip_address = local.hub2_dns_in_addr, port = 53 },
          ]
        }
        "azurewebsites" = {
          domain = "privatelink.azurewebsites.net"
          target_dns_servers = [
            { ip_address = local.hub1_dns_in_addr, port = 53 },
          ]
        }
      }
    }

    config_vpngw = {
      enable = true
      sku    = "VpnGw1AZ"
      bgp_settings = {
        asn = local.hub1_vpngw_asn
      }
    }

    config_ergw = {
      enable = false
      sku    = "ErGw1AZ"
    }

    config_firewall = {
      enable             = false
      firewall_sku       = local.firewall_sku
      firewall_policy_id = azurerm_firewall_policy.firewall_policy["region1"].id
    }

    config_nva = {
      enable           = true
      type             = "linux"
      internal_lb_addr = local.hub1_nva_ilb_addr
      custom_data      = base64encode(local.hub1_linux_nva_init)
    }
  }

  hub2_features = {
    config_vnet = {
      address_space               = local.hub2_address_space
      subnets                     = local.hub2_subnets
      enable_private_dns_resolver = true
      enable_ars                  = false

      ruleset_dns_forwarding_rules = {
        "onprem" = {
          domain = local.onprem_domain
          target_dns_servers = [
            { ip_address = local.branch3_dns_addr, port = 53 },
            { ip_address = local.branch1_dns_addr, port = 53 },
          ]
        }
        "eu" = {
          domain = "we.${local.cloud_domain}"
          target_dns_servers = [
            { ip_address = local.hub1_dns_in_addr, port = 53 },
          ]
        }
        "ne" = {
          domain = "ne.${local.cloud_domain}"
          target_dns_servers = [
            { ip_address = local.hub2_dns_in_addr, port = 53 },
          ]
        }
      }
    }

    config_vpngw = {
      enable = true
      sku    = "VpnGw1AZ"
      bgp_settings = {
        asn = local.hub2_vpngw_asn
      }
    }

    config_ergw = {
      enable = false
      sku    = "ErGw1AZ"
    }

    config_firewall = {
      enable             = false
      firewall_sku       = local.firewall_sku
      firewall_policy_id = azurerm_firewall_policy.firewall_policy["region2"].id
    }

    config_nva = {
      enable           = true
      type             = "linux"
      internal_lb_addr = local.hub2_nva_ilb_addr
      custom_data      = base64encode(local.hub2_linux_nva_init)
    }
  }

  vhub1_features = {
    enable_er_gateway      = false
    enable_s2s_vpn_gateway = true
    enable_p2s_vpn_gateway = false

    security = {
      create_firewall       = false
      enable_routing_intent = false
      firewall_sku          = local.firewall_sku
      firewall_policy_id    = azurerm_firewall_policy.firewall_policy["region1"].id
      routing_policies      = {}
    }
  }

  vhub2_features = {
    enable_er_gateway      = false
    enable_s2s_vpn_gateway = true
    enable_p2s_vpn_gateway = false

    security = {
      create_firewall       = false
      enable_routing_intent = false
      firewall_sku          = local.firewall_sku
      firewall_policy_id    = azurerm_firewall_policy.firewall_policy["region2"].id
      routing_policies      = {}
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
    { name = "branch1", dns = local.branch1_vm_fqdn, ip = local.branch1_vm_addr, probe = true },
    { name = "hub1   ", dns = local.hub1_vm_fqdn, ip = local.hub1_vm_addr, probe = false },
    { name = "hub1-spoke3-pep", dns = local.hub1_spoke3_pep_fqdn, ping = false, probe = true },
    { name = "spoke1 ", dns = local.spoke1_vm_fqdn, ip = local.spoke1_vm_addr, probe = true },
    { name = "spoke2 ", dns = local.spoke2_vm_fqdn, ip = local.spoke2_vm_addr, probe = true },
    { name = "spoke3 ", dns = local.spoke3_vm_fqdn, ip = local.spoke3_vm_addr, ping = false },
  ]
  vm_script_targets_region2 = [
    { name = "branch3", dns = local.branch3_vm_fqdn, ip = local.branch3_vm_addr, probe = true },
    { name = "hub2   ", dns = local.hub2_vm_fqdn, ip = local.hub2_vm_addr, probe = false },
    { name = "hub2-spoke6-pep", dns = local.hub2_spoke6_pep_fqdn, ping = false, probe = true },
    { name = "spoke4 ", dns = local.spoke4_vm_fqdn, ip = local.spoke4_vm_addr, probe = true },
    { name = "spoke5 ", dns = local.spoke5_vm_fqdn, ip = local.spoke5_vm_addr, probe = true },
    { name = "spoke6 ", dns = local.spoke6_vm_fqdn, ip = local.spoke6_vm_addr, ping = false },
  ]
  vm_script_targets_misc = [
    { name = "internet", dns = "icanhazip.com", ip = "icanhazip.com" },
    { name = "hub1-spoke3-apps", dns = local.spoke3_apps_fqdn, ping = false, probe = true },
    { name = "hub2-spoke6-apps", dns = local.spoke6_apps_fqdn, ping = false, probe = true },
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
    { zone = "${local.cloud_domain}.", targets = [local.hub1_dns_in_addr, local.hub2_dns_in_addr], },
    { zone = "privatelink.blob.core.windows.net.", targets = [local.hub1_dns_in_addr, local.hub2_dns_in_addr], },
    { zone = "privatelink.azurewebsites.net.", targets = [local.hub1_dns_in_addr, local.hub2_dns_in_addr], },
    { zone = "privatelink.database.windows.net.", targets = [local.hub1_dns_in_addr, local.hub2_dns_in_addr], },
    { zone = "privatelink.table.cosmos.azure.com.", targets = [local.hub1_dns_in_addr, local.hub2_dns_in_addr], },
    { zone = "privatelink.queue.core.windows.net.", targets = [local.hub1_dns_in_addr, local.hub2_dns_in_addr], },
    { zone = "privatelink.file.core.windows.net.", targets = [local.hub1_dns_in_addr, local.hub2_dns_in_addr], },
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
# nva
####################################################

# hub1

locals {
  hub1_router_route_map_name_nh = "NEXT-HOP"
  hub1_nva_vars = {
    LOCAL_ASN = local.hub1_nva_asn
    LOOPBACK0 = local.hub1_nva_loopback0
    LOOPBACKS = {
      Loopback1 = local.hub1_nva_ilb_addr
    }
    CRYPTO_ADDR = local.hub1_nva_trust_addr
    VPN_PSK     = local.psk
  }
  hub1_linux_nva_init = templatefile("../../scripts/linux-nva.sh", merge(local.hub1_nva_vars, {
    TARGETS        = local.vm_script_targets
    IPTABLES_RULES = []
    ROUTE_MAPS = [
      {
        name   = local.hub1_router_route_map_name_nh
        action = "permit"
        rule   = 100
        commands = [
          "match ip address prefix-list all",
          "set ip next-hop ${local.hub1_nva_ilb_addr}"
        ]
      }
    ]
    TUNNELS = []
    QUAGGA_ZEBRA_CONF = templatefile("../../scripts/quagga/zebra.conf", merge(
      local.hub1_nva_vars,
      {
        INTERFACE = "eth0"
        STATIC_ROUTES = [
          { prefix = "0.0.0.0/0", next_hop = local.hub1_default_gw_nva },
          { prefix = "${module.vhub1.router_bgp_ip0}/32", next_hop = local.hub1_default_gw_nva },
          { prefix = "${module.vhub1.router_bgp_ip1}/32", next_hop = local.hub1_default_gw_nva },
          { prefix = local.spoke2_address_space[0], next_hop = local.hub1_default_gw_nva },
        ]
      }
    ))
    QUAGGA_BGPD_CONF = templatefile("../../scripts/quagga/bgpd.conf", merge(
      local.hub1_nva_vars,
      {
        BGP_SESSIONS = [
          {
            peer_asn      = local.vhub1_bgp_asn
            peer_ip       = module.vhub1.router_bgp_ip0
            ebgp_multihop = true
            route_maps = [
              # {
              #   name      = local.hub1_router_route_map_name_nh
              #   direction = "out"
              # }
            ]
          },
          {
            peer_asn      = local.vhub1_bgp_asn
            peer_ip       = module.vhub1.router_bgp_ip1
            ebgp_multihop = true
            route_maps = [
              # {
              #   name      = local.hub1_router_route_map_name_nh
              #   direction = "out"
              # }
            ]
          },
        ]
        BGP_ADVERTISED_PREFIXES = [
          local.hub1_subnets["MainSubnet"].address_prefixes[0],
          local.spoke2_address_space[0],
          #"${local.spoke6_vm_public_ip}/32"
        ]
      }
    ))
    }
  ))
}

# hub2

locals {
  hub2_router_route_map_name_nh = "NEXT-HOP"
  hub2_nva_vars = {
    LOCAL_ASN = local.hub2_nva_asn
    LOOPBACK0 = local.hub2_nva_loopback0
    LOOPBACKS = {
      Loopback1 = local.hub2_nva_ilb_addr
    }
    CRYPTO_ADDR = local.hub2_nva_trust_addr
    VPN_PSK     = local.psk
  }
  hub2_linux_nva_init = templatefile("../../scripts/linux-nva.sh", merge(local.hub2_nva_vars, {
    TARGETS        = local.vm_script_targets
    IPTABLES_RULES = []
    ROUTE_MAPS = [
      {
        name   = local.hub2_router_route_map_name_nh
        action = "permit"
        rule   = 100
        commands = [
          "match ip address prefix-list all",
          "set ip next-hop ${local.hub2_nva_ilb_addr}"
        ]
      }
    ]
    TUNNELS = []
    QUAGGA_ZEBRA_CONF = templatefile("../../scripts/quagga/zebra.conf", merge(
      local.hub2_nva_vars,
      {
        INTERFACE = "eth0"
        STATIC_ROUTES = [
          { prefix = "0.0.0.0/0", next_hop = local.hub2_default_gw_nva },
          { prefix = "${module.vhub2.router_bgp_ip0}/32", next_hop = local.hub2_default_gw_nva },
          { prefix = "${module.vhub2.router_bgp_ip1}/32", next_hop = local.hub2_default_gw_nva },
          { prefix = local.spoke5_address_space[0], next_hop = local.hub2_default_gw_nva },
        ]
      }
    ))
    QUAGGA_BGPD_CONF = templatefile("../../scripts/quagga/bgpd.conf", merge(
      local.hub2_nva_vars,
      {
        BGP_SESSIONS = [
          {
            peer_asn      = local.vhub2_bgp_asn
            peer_ip       = module.vhub2.router_bgp_ip0
            ebgp_multihop = true
            route_maps = [
              # {
              #   name      = local.hub2_router_route_map_name_nh
              #   direction = "out"
              # }
            ]
          },
          {
            peer_asn      = local.vhub2_bgp_asn
            peer_ip       = module.vhub2.router_bgp_ip1
            ebgp_multihop = true
            route_maps = [
              # {
              #   name      = local.hub2_router_route_map_name_nh
              #   direction = "out"
              # }
            ]
          },
        ]
        BGP_ADVERTISED_PREFIXES = [
          local.hub2_subnets["MainSubnet"].address_prefixes[0],
          local.spoke5_address_space[0],
          #"${local.spoke6_vm_public_ip}/32"
        ]
      }
    ))
    }
  ))
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

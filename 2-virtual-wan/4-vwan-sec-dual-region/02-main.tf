####################################################
# Lab
####################################################

locals {
  prefix                      = "Vwan24"
  enable_diagnostics          = false
  spoke3_storage_account_name = lower(replace("${local.spoke3_prefix}sa${random_id.random.hex}", "-", ""))
  spoke6_storage_account_name = lower(replace("${local.spoke6_prefix}sa${random_id.random.hex}", "-", ""))
  spoke3_blob_url             = "https://${local.spoke3_storage_account_name}.blob.core.windows.net/spoke3/spoke3.txt"
  spoke6_blob_url             = "https://${local.spoke6_storage_account_name}.blob.core.windows.net/spoke6/spoke6.txt"
  spoke3_apps_fqdn            = lower("${local.spoke3_prefix}${random_id.random.hex}.azurewebsites.net")
  spoke6_apps_fqdn            = lower("${local.spoke6_prefix}${random_id.random.hex}.azurewebsites.net")

  hub1_tags    = { "lab" = local.prefix, "nodeType" = "hub" }
  hub2_tags    = { "lab" = local.prefix, "nodeType" = "hub" }
  branch1_tags = { "lab" = local.prefix, "nodeType" = "branch" }
  branch2_tags = { "lab" = local.prefix, "nodeType" = "branch" }
  branch3_tags = { "lab" = local.prefix, "nodeType" = "branch" }
  spoke1_tags  = { "lab" = local.prefix, "nodeType" = "spoke" }
  spoke2_tags  = { "lab" = local.prefix, "nodeType" = "spoke" }
  spoke3_tags  = { "lab" = local.prefix, "nodeType" = "float" }
  spoke4_tags  = { "lab" = local.prefix, "nodeType" = "spoke" }
  spoke5_tags  = { "lab" = local.prefix, "nodeType" = "spoke" }
  spoke6_tags  = { "lab" = local.prefix, "nodeType" = "float" }
}

resource "random_id" "random" {
  byte_length = 2
}

data "azurerm_subscription" "current" {}

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
# user assigned identity
####################################################

resource "azurerm_user_assigned_identity" "machine" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.default_region
  name                = "${local.prefix}-user"
}

resource "azurerm_role_assignment" "machine" {
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.machine.principal_id
  scope                = data.azurerm_subscription.current.id
}

####################################################
# network features
####################################################

locals {
  regions = {
    "region1" = { name = local.region1, dns_zone = local.region1_dns_zone }
    "region2" = { name = local.region2, dns_zone = local.region2_dns_zone }
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
            { ip_address = local.branch1_dns_addr, port = 53 },
            { ip_address = local.branch3_dns_addr, port = 53 },
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

    config_s2s_vpngw = {
      enable = false
      sku    = "VpnGw1AZ"
      ip_configuration = [
        #{ name = "ipconf0", public_ip_address_name = azurerm_public_ip.hub1_s2s_vpngw_pip0.name, apipa_addresses = ["169.254.21.1"] },
        #{ name = "ipconf1", public_ip_address_name = azurerm_public_ip.hub1_s2s_vpngw_pip1.name, apipa_addresses = ["169.254.21.5"] }
      ]
      bgp_settings = {
        asn = local.hub1_vpngw_asn
      }
    }

    config_p2s_vpngw = {
      enable = false
      sku    = "VpnGw1AZ"
      ip_configuration = [
        #{ name = "ipconf", public_ip_address_name = azurerm_public_ip.hub1_p2s_vpngw_pip.name }
      ]
      vpn_client_configuration = {
        address_space = ["192.168.0.0/24"]
        clients = [
          # { name = "client1" },
          # { name = "client2" },
        ]
      }
      custom_route_address_prefixes = ["8.8.8.8/32"]
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
      internal_lb_addr = local.hub1_nva_ilb_untrust_addr
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
        "${local.region1_code}" = {
          domain = local.region1_dns_zone
          target_dns_servers = [
            { ip_address = local.hub2_dns_in_addr, port = 53 },
          ]
        }
        "${local.region2_code}" = {
          domain = local.region2_dns_zone
          target_dns_servers = [
            { ip_address = local.hub2_dns_in_addr, port = 53 },
          ]
        }
        "azurewebsites" = {
          domain = "privatelink.azurewebsites.net"
          target_dns_servers = [
            { ip_address = local.hub2_dns_in_addr, port = 53 },
          ]
        }
        "blob.core.windows.net" = {
          domain = "privatelink.blob.core.windows.net"
          target_dns_servers = [
            { ip_address = local.hub2_dns_in_addr, port = 53 },
          ]
        }
      }
    }

    config_s2s_vpngw = {
      enable = false
      sku    = "VpnGw1AZ"
      ip_configuration = [
        #{ name = "ipconf0", public_ip_address_name = azurerm_public_ip.hub2_s2s_vpngw_pip0.name, apipa_addresses = ["169.254.21.1"] },
        #{ name = "ipconf1", public_ip_address_name = azurerm_public_ip.hub2_s2s_vpngw_pip1.name, apipa_addresses = ["169.254.21.5"] }
      ]
      bgp_settings = {
        asn = local.hub2_vpngw_asn
      }
    }

    config_p2s_vpngw = {
      enable = false
      sku    = "VpnGw1AZ"
      ip_configuration = [
        #{ name = "ipconf", public_ip_address_name = azurerm_public_ip.hub2_p2s_vpngw_pip.name },
      ]
      vpn_client_configuration = {
        address_space = ["192.168.1.0/24"]
        clients = [
          # { name = "client3" },
          # { name = "client4" },
        ]
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
    express_route_gateway = {
      enable = false
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

    p2s_vpn_gateway = {
      enable = false
      sku    = "VpnGw1AZ"
    }

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
    express_route_gateway = {
      enable = false
      sku    = "ErGw1AZ"
    }

    s2s_vpn_gateway = {
      enable = true
      sku    = "VpnGw1AZ"
      bgp_settings = {
        asn                                       = local.vhub2_bgp_asn
        peer_weight                               = 0
        instance_0_bgp_peering_address_custom_ips = [local.vhub2_vpngw_bgp_apipa_0]
        instance_1_bgp_peering_address_custom_ips = [local.vhub2_vpngw_bgp_apipa_1]
      }
    }

    p2s_vpn_gateway = {
      enable = false
      sku    = "VpnGw1AZ"
    }

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
    { name = "branch1", dns = lower(local.branch1_vm_fqdn), ip = local.branch1_vm_addr, probe = true },
    { name = "hub1   ", dns = lower(local.hub1_vm_fqdn), ip = local.hub1_vm_addr, probe = false },
    { name = "hub1-spoke3-pep", dns = lower(local.hub1_spoke3_pep_fqdn), ping = false, probe = true },
    { name = "spoke1 ", dns = lower(local.spoke1_vm_fqdn), ip = local.spoke1_vm_addr, probe = true },
    { name = "spoke2 ", dns = lower(local.spoke2_vm_fqdn), ip = local.spoke2_vm_addr, probe = true },
  ]
  vm_script_targets_region2 = [
    { name = "branch3", dns = lower(local.branch3_vm_fqdn), ip = local.branch3_vm_addr, probe = true },
    { name = "hub2   ", dns = lower(local.hub2_vm_fqdn), ip = local.hub2_vm_addr, probe = false },
    { name = "hub2-spoke6-pep", dns = lower(local.hub2_spoke6_pep_fqdn), ping = false, probe = true },
    { name = "spoke4 ", dns = lower(local.spoke4_vm_fqdn), ip = local.spoke4_vm_addr, probe = true },
    { name = "spoke5 ", dns = lower(local.spoke5_vm_fqdn), ip = local.spoke5_vm_addr, probe = true },
  ]
  vm_script_targets_misc = [
    { name = "internet", dns = "icanhazip.com", ip = "icanhazip.com" },
    { name = "hub1-spoke3-blob", dns = local.spoke3_blob_url, ping = false, probe = true },
    { name = "hub2-spoke6-blob", dns = local.spoke6_blob_url, ping = false, probe = true },
  ]
  vm_script_targets = concat(
    local.vm_script_targets_region1,
    local.vm_script_targets_region2,
    local.vm_script_targets_misc,
  )
  vm_startup = templatefile("../../scripts/server.sh", {
    USER_ASSIGNED_ID          = azurerm_user_assigned_identity.machine.id
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []
    ENABLE_TRAFFIC_GEN        = false
  })
  tools = templatefile("../../scripts/tools.sh", {
    USER_ASSIGNED_ID          = azurerm_user_assigned_identity.machine.id
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []
    ENABLE_TRAFFIC_GEN        = false
  })
  onprem_local_records = [
    { name = lower(local.branch1_vm_fqdn), record = local.branch1_vm_addr },
    { name = lower(local.branch2_vm_fqdn), record = local.branch2_vm_addr },
    { name = lower(local.branch3_vm_fqdn), record = local.branch3_vm_addr },
  ]
  onprem_redirected_hosts = []
  branch_dns_init_dir     = "/var/lib/labs"
}

####################################################
# nsg
####################################################

# rules

####################################################
# addresses
####################################################

# branch1

resource "azurerm_public_ip" "branch1_nva_pip" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.branch1_prefix}nva-pip"
  location            = local.branch1_location
  sku                 = "Standard"
  allocation_method   = "Static"
  tags                = local.branch1_tags
}

# branch3

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
  hub1_router_route_map_name_nh = "NEXT-HOP"
  hub1_nva_vars = {
    LOCAL_ASN = local.hub1_nva_asn
    LOOPBACK0 = local.hub1_nva_loopback0
    LOOPBACKS = {
      Loopback1 = local.hub1_nva_ilb_untrust_addr
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
          # "match ip address prefix-list all",
          # "set ip next-hop ${local.hub1_nva_ilb_untrust_addr}"
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
          # "match ip address prefix-list all",
          # "set ip next-hop ${local.hub2_nva_ilb_addr}"
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
    "output/branch1Dns.sh" = local.branch1_unbound_startup
    "output/server.sh"     = local.vm_startup
  }
}

resource "local_file" "main_files" {
  for_each = local.main_files
  filename = each.key
  content  = each.value
}

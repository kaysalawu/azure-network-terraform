####################################################
# Lab
####################################################

locals {
  prefix                      = "Hs14"
  lab_name                    = "HubSpoke_Nva_2Region"
  enable_diagnostics          = false
  enable_onprem_wan_link      = true
  enable_ipv6                 = true
  spoke3_storage_account_name = lower(replace("${local.spoke3_prefix}sa${random_id.random.hex}", "-", ""))
  spoke6_storage_account_name = lower(replace("${local.spoke6_prefix}sa${random_id.random.hex}", "-", ""))
  spoke3_blob_url             = "https://${local.spoke3_storage_account_name}.blob.core.windows.net/spoke3/spoke3.txt"
  spoke6_blob_url             = "https://${local.spoke6_storage_account_name}.blob.core.windows.net/spoke6/spoke6.txt"
  spoke3_apps_fqdn            = lower("${local.spoke3_prefix}${random_id.random.hex}.azurewebsites.net")
  spoke6_apps_fqdn            = lower("${local.spoke6_prefix}${random_id.random.hex}.azurewebsites.net")

  hub1_tags    = { "lab" = local.prefix, "env" = "prod", "nodeType" = "hub" }
  hub2_tags    = { "lab" = local.prefix, "env" = "prod", "nodeType" = "hub" }
  branch1_tags = { "lab" = local.prefix, "env" = "prod", "nodeType" = "branch" }
  branch2_tags = { "lab" = local.prefix, "env" = "prod", "nodeType" = "branch" }
  branch3_tags = { "lab" = local.prefix, "env" = "prod", "nodeType" = "branch" }
  spoke1_tags  = { "lab" = local.prefix, "env" = "prod", "nodeType" = "spoke" }
  spoke2_tags  = { "lab" = local.prefix, "env" = "prod", "nodeType" = "spoke" }
  spoke3_tags  = { "lab" = local.prefix, "env" = "prod", "nodeType" = "float" }
  spoke4_tags  = { "lab" = local.prefix, "env" = "prod", "nodeType" = "spoke" }
  spoke5_tags  = { "lab" = local.prefix, "env" = "prod", "nodeType" = "spoke" }
  spoke6_tags  = { "lab" = local.prefix, "env" = "prod", "nodeType" = "float" }
}

resource "random_id" "random" {
  byte_length = 2
}

####################################################
# providers
####################################################

provider "azurerm" {
  skip_provider_registration = true
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
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
  }
  default_udr_destinations = [
    { name = "default", address_prefix = ["0.0.0.0/0"], next_hop_ip = local.hub1_nva_ilb_trust_addr },
    { name = "defaultv6", address_prefix = ["::/0"], next_hop_ip = local.hub1_nva_ilb_trust_addr_v6 }
  ]

  spoke1_udr_main_routes = concat(local.default_udr_destinations, [
    { name = "hub1", address_prefix = [local.hub1_address_space.0, ], next_hop_ip = local.hub1_nva_ilb_trust_addr },
    { name = "hub1v6", address_prefix = [local.hub1_address_space.2, ], next_hop_ip = local.hub1_nva_ilb_trust_addr_v6 },
  ])
  spoke2_udr_main_routes = concat(local.default_udr_destinations, [
    { name = "hub1", address_prefix = [local.hub1_address_space.0, ], next_hop_ip = local.hub1_nva_ilb_trust_addr },
    { name = "hub1v6", address_prefix = [local.hub1_address_space.2, ], next_hop_ip = local.hub1_nva_ilb_trust_addr_v6 },
  ])
  hub1_udr_main_routes = concat(local.default_udr_destinations, [
    { name = "spoke1", address_prefix = [local.spoke1_address_space.0, ], next_hop_ip = local.hub1_nva_ilb_trust_addr },
    { name = "spoke2", address_prefix = [local.spoke2_address_space.0, ], next_hop_ip = local.hub1_nva_ilb_trust_addr },
    { name = "spoke1v6", address_prefix = [local.spoke1_address_space.1, ], next_hop_ip = local.hub1_nva_ilb_trust_addr_v6 },
    { name = "spoke2v6", address_prefix = [local.spoke2_address_space.1, ], next_hop_ip = local.hub1_nva_ilb_trust_addr_v6 },
  ])
  hub1_gateway_udr_destinations = [
    { name = "spoke1", address_prefix = [local.spoke1_address_space.0, ], next_hop_ip = local.hub1_nva_ilb_trust_addr },
    { name = "spoke2", address_prefix = [local.spoke2_address_space.0, ], next_hop_ip = local.hub1_nva_ilb_trust_addr },
    { name = "hub1", address_prefix = [local.hub1_address_space.0, ], next_hop_ip = local.hub1_nva_ilb_trust_addr },
    { name = "spoke1v6", address_prefix = [local.spoke1_address_space.1, ], next_hop_ip = local.hub1_nva_ilb_trust_addr_v6 },
    { name = "spoke2v6", address_prefix = [local.spoke2_address_space.1, ], next_hop_ip = local.hub1_nva_ilb_trust_addr_v6 },
    { name = "hub1v6", address_prefix = [local.hub1_address_space.2, ], next_hop_ip = local.hub1_nva_ilb_trust_addr_v6 },
  ]
  hub1_appliance_udr_destinations = [
    { name = "spoke4", address_prefix = [local.spoke4_address_space.0, ], next_hop_ip = local.hub2_nva_ilb_trust_addr },
    { name = "spoke5", address_prefix = [local.spoke5_address_space.0, ], next_hop_ip = local.hub2_nva_ilb_trust_addr },
    { name = "hub2", address_prefix = [local.hub2_address_space.0, ], next_hop_ip = local.hub2_nva_ilb_trust_addr },
  ]

  spoke4_udr_main_routes = concat(local.default_udr_destinations, [
    { name = "hub2", address_prefix = [local.hub2_address_space.0, ], next_hop_ip = local.hub2_nva_ilb_trust_addr },
    { name = "hub2v6", address_prefix = [local.hub2_address_space.2], next_hop_ip = local.hub2_nva_ilb_trust_addr_v6 },
  ])
  spoke5_udr_main_routes = concat(local.default_udr_destinations, [
    { name = "hub2", address_prefix = [local.hub2_address_space.0, ], next_hop_ip = local.hub2_nva_ilb_trust_addr },
    { name = "hub2v6", address_prefix = [local.hub2_address_space.2, ], next_hop_ip = local.hub2_nva_ilb_trust_addr_v6 },
  ])
  hub2_udr_main_routes = concat(local.default_udr_destinations, [
    { name = "spoke4", address_prefix = [local.spoke4_address_space.0, ], next_hop_ip = local.hub2_nva_ilb_trust_addr },
    { name = "spoke5", address_prefix = [local.spoke5_address_space.0, ], next_hop_ip = local.hub2_nva_ilb_trust_addr },
    { name = "spoke4v6", address_prefix = [local.spoke4_address_space.1, ], next_hop_ip = local.hub2_nva_ilb_trust_addr_v6 },
    { name = "spoke5v6", address_prefix = [local.spoke5_address_space.1, ], next_hop_ip = local.hub2_nva_ilb_trust_addr_v6 },
  ])
  hub2_gateway_udr_destinations = [
    { name = "spoke4", address_prefix = [local.spoke4_address_space.0, ], next_hop_ip = local.hub2_nva_ilb_trust_addr },
    { name = "spoke5", address_prefix = [local.spoke5_address_space.0, ], next_hop_ip = local.hub2_nva_ilb_trust_addr },
    { name = "hub2", address_prefix = [local.hub2_address_space.0, ], next_hop_ip = local.hub2_nva_ilb_trust_addr },
    { name = "spoke4v6", address_prefix = [local.spoke4_address_space.1, ], next_hop_ip = local.hub2_nva_ilb_trust_addr_v6 },
    { name = "spoke5v6", address_prefix = [local.spoke5_address_space.1, ], next_hop_ip = local.hub2_nva_ilb_trust_addr_v6 },
    { name = "hub2v6", address_prefix = [local.hub2_address_space.2, ], next_hop_ip = local.hub2_nva_ilb_trust_addr_v6 },

  ]
  hub2_appliance_udr_destinations = [
    { name = "spoke1", address_prefix = [local.spoke1_address_space.0, ], next_hop_ip = local.hub1_nva_ilb_trust_addr },
    { name = "spoke2", address_prefix = [local.spoke2_address_space.0, ], next_hop_ip = local.hub1_nva_ilb_trust_addr },
    { name = "hub1", address_prefix = [local.hub1_address_space.0, ], next_hop_ip = local.hub1_nva_ilb_trust_addr },
  ]

  firewall_sku = "Basic"

  hub1_features = {
    config_vnet = {
      address_space               = local.hub1_address_space
      subnets                     = local.hub1_subnets
      enable_private_dns_resolver = true
      enable_ars                  = false
      nat_gateway_subnet_names = [
        "MainSubnet",
        "TrustSubnet",
        "TestSubnet",
      ]

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
      enable = true
      sku    = "VpnGw1AZ"
      ip_configuration = [
        { name = "ipconf0", public_ip_address_name = azurerm_public_ip.hub1_s2s_vpngw_pip0.name, apipa_addresses = ["169.254.21.1"] },
        { name = "ipconf1", public_ip_address_name = azurerm_public_ip.hub1_s2s_vpngw_pip1.name, apipa_addresses = ["169.254.21.5"] }
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
      enable          = true
      type            = "opnsense"
      scenario_option = "TwoNics"
      opn_type        = "TwoNics"
      custom_data     = base64encode(local.hub1_linux_nva_init)
      ilb_untrust_ip  = local.hub1_nva_ilb_untrust_addr
      ilb_trust_ip    = local.hub1_nva_ilb_trust_addr
      enable_ipv6     = local.enable_ipv6
    }
  }

  hub2_features = {
    config_vnet = {
      address_space               = local.hub2_address_space
      subnets                     = local.hub2_subnets
      enable_private_dns_resolver = true
      enable_ars                  = false
      nat_gateway_subnet_names = [
        "MainSubnet",
        "TrustSubnet",
        "TestSubnet",
      ]

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
      enable = true
      sku    = "VpnGw1AZ"
      ip_configuration = [
        { name = "ipconf0", public_ip_address_name = azurerm_public_ip.hub2_s2s_vpngw_pip0.name, apipa_addresses = ["169.254.21.1"] },
        { name = "ipconf1", public_ip_address_name = azurerm_public_ip.hub2_s2s_vpngw_pip1.name, apipa_addresses = ["169.254.21.5"] }
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
      custom_route_address_prefixes = ["8.8.8.8/32"]
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
      enable          = true
      type            = "opnsense"
      scenario_option = "TwoNics"
      opn_type        = "TwoNics"
      custom_data     = base64encode(local.hub2_linux_nva_init)
      ilb_untrust_ip  = local.hub2_nva_ilb_untrust_addr
      ilb_trust_ip    = local.hub2_nva_ilb_trust_addr
      enable_ipv6     = local.enable_ipv6
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
  hub1_nva_asn   = "65000"
  hub1_vpngw_asn = "65515"
  hub1_ergw_asn  = "65515"
  hub1_ars_asn   = "65515"

  hub2_nva_asn   = "65000"
  hub2_vpngw_asn = "65515"
  hub2_ergw_asn  = "65515"
  hub2_ars_asn   = "65515"

  init_dir = "/var/lib/azure"
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
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []
    ENABLE_TRAFFIC_GEN        = false
  })
  vm_init_vars = {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []
  }
  vm_init_files = {
    "${local.init_dir}/fastapi/docker-compose-app1-80.yml"   = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/docker-compose-app1-80.yml", {}) }
    "${local.init_dir}/fastapi/docker-compose-app2-8080.yml" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/docker-compose-app2-8080.yml", {}) }
    "${local.init_dir}/fastapi/app/app/Dockerfile"           = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/app/app/Dockerfile", {}) }
    "${local.init_dir}/fastapi/app/app/_app.py"              = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/app/app/_app.py", {}) }
    "${local.init_dir}/fastapi/app/app/main.py"              = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/app/app/main.py", {}) }
    "${local.init_dir}/fastapi/app/app/requirements.txt"     = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/app/app/requirements.txt", {}) }
    "${local.init_dir}/init/start.sh"                        = { owner = "root", permissions = "0744", content = templatefile("../../scripts/startup.sh", local.vm_init_vars) }
  }
  onprem_local_records = [
    { name = lower(local.branch1_vm_fqdn), record = local.branch1_vm_addr },
    { name = lower(local.branch2_vm_fqdn), record = local.branch2_vm_addr },
    { name = lower(local.branch3_vm_fqdn), record = local.branch3_vm_addr },
  ]
  onprem_redirected_hosts = []
}

module "vm_cloud_init" {
  source = "../../modules/cloud-config-gen"
  files  = local.vm_init_files
  packages = [
    "docker.io", "docker-compose", "npm",
  ]
  run_commands = [
    "systemctl enable docker",
    "systemctl start docker",
    "bash ${local.init_dir}/init/start.sh",
    "docker-compose -f ${local.init_dir}/fastapi/docker-compose-app1-80.yml up -d",
    "docker-compose -f ${local.init_dir}/fastapi/docker-compose-app2-8080.yml up -d",
  ]
}

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
  count               = length(local.regions) > 1 ? 1 : 0
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.branch3_prefix}nva-pip"
  location            = local.branch3_location
  sku                 = "Standard"
  allocation_method   = "Static"
}

# hub1

resource "azurerm_public_ip" "hub1_s2s_vpngw_pip0" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub1_prefix}s2s-vpngw-pip0"
  location            = local.hub1_location
  sku                 = "Standard"
  allocation_method   = "Static"
  zones               = [1, 2, 3]
  tags                = local.hub1_tags
}

resource "azurerm_public_ip" "hub1_s2s_vpngw_pip1" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub1_prefix}s2s-vpngw-pip1"
  location            = local.hub1_location
  sku                 = "Standard"
  allocation_method   = "Static"
  zones               = [1, 2, 3]
  tags                = local.hub1_tags
}

# hub2

resource "azurerm_public_ip" "hub2_s2s_vpngw_pip0" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub2_prefix}s2s-vpngw-pip0"
  location            = local.hub2_location
  sku                 = "Standard"
  allocation_method   = "Static"
  zones               = [1, 2, 3]
  tags                = local.hub2_tags
}

resource "azurerm_public_ip" "hub2_s2s_vpngw_pip1" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub2_prefix}s2s-vpngw-pip1"
  location            = local.hub2_location
  sku                 = "Standard"
  allocation_method   = "Static"
  zones               = [1, 2, 3]
  tags                = local.hub2_tags
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

    PREFIX_LISTS                 = []
    ROUTE_MAPS                   = []
    STATIC_ROUTES                = []
    TUNNELS                      = []
    BGP_SESSIONS_IPV4            = []
    BGP_ADVERTISED_PREFIXES_IPV4 = []
  }
  hub1_linux_nva_init = templatefile("../../scripts/linux-nva.sh", merge(local.hub1_nva_vars, {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []
    ENABLE_TRAFFIC_GEN        = false
    IPTABLES_RULES            = []
    FRR_CONF                  = ""
    STRONGSWAN_VTI_SCRIPT     = ""
    STRONGSWAN_IPSEC_SECRETS  = ""
    STRONGSWAN_IPSEC_CONF     = ""
    STRONGSWAN_AUTO_RESTART   = ""
  }))
}

# hub2

locals {
  hub2_nva_route_map_onprem      = "ONPREM"
  hub2_nva_route_map_azure       = "AZURE"
  hub2_nva_route_map_block_azure = "BLOCK_HUB_GW_SUBNET"
  hub2_nva_vars = {
    LOCAL_ASN = local.hub2_nva_asn
    LOOPBACK0 = local.hub2_nva_loopback0
    LOOPBACKS = []

    PREFIX_LISTS                 = []
    ROUTE_MAPS                   = []
    STATIC_ROUTES                = []
    TUNNELS                      = []
    BGP_SESSIONS_IPV4            = []
    BGP_ADVERTISED_PREFIXES_IPV4 = []
  }
  hub2_linux_nva_init = templatefile("../../scripts/linux-nva.sh", merge(local.hub2_nva_vars, {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []
    ENABLE_TRAFFIC_GEN        = false
    IPTABLES_RULES            = []
    FRR_CONF                  = ""
    STRONGSWAN_VTI_SCRIPT     = ""
    STRONGSWAN_IPSEC_SECRETS  = ""
    STRONGSWAN_IPSEC_CONF     = ""
    STRONGSWAN_AUTO_RESTART   = ""
  }))
}

####################################################
# output files
####################################################

locals {
  main_files = {
    "output/server.sh"         = local.vm_startup
    "output/hub1-linux-nva.sh" = local.hub1_linux_nva_init
    "output/hub2-linux-nva.sh" = local.hub2_linux_nva_init
  }
}

resource "local_file" "main_files" {
  for_each = local.main_files
  filename = each.key
  content  = each.value
}

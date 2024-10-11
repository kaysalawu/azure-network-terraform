####################################################
# Lab
####################################################

locals {
  prefix                      = "Ne32"
  lab_name                    = "HubSpoke_Azfw_2Region"
  enable_onprem_wan_link      = true
  enable_diagnostics          = false
  enable_ipv6                 = false
  enable_vnet_flow_logs       = false
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

data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

####################################################
# providers
####################################################

provider "azurerm" {
  # resource_provider_registrations = "none"
  subscription_id = var.subscription_id
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
  region1_default_udr_destinations = [
    { name = "default-region1", address_prefix = ["0.0.0.0/0"], next_hop_ip = module.hub1.firewall_private_ip },
  ]
  spoke1_udr_main_routes = concat(local.region1_default_udr_destinations, [
    { name = "hub1", address_prefix = [local.hub1_address_space.0, ], next_hop_ip = module.hub1.firewall_private_ip },
  ])
  spoke2_udr_main_routes = concat(local.region1_default_udr_destinations, [
    { name = "hub1", address_prefix = [local.hub1_address_space.0, ], next_hop_ip = module.hub1.firewall_private_ip },
  ])
  hub1_udr_main_routes = concat(local.region1_default_udr_destinations, [
    { name = "spoke1", address_prefix = [local.spoke1_address_space.0, ], next_hop_ip = module.hub1.firewall_private_ip },
    { name = "spoke2", address_prefix = [local.spoke2_address_space.0, ], next_hop_ip = module.hub1.firewall_private_ip },
  ])
  hub1_gateway_udr_destinations = [
    { name = "spoke1", address_prefix = [local.spoke1_address_space.0, ], next_hop_ip = module.hub1.firewall_private_ip },
    { name = "spoke2", address_prefix = [local.spoke2_address_space.0, ], next_hop_ip = module.hub1.firewall_private_ip },
    { name = "hub1", address_prefix = [local.hub1_address_space.0, ], next_hop_ip = module.hub1.firewall_private_ip },
  ]
  hub1_appliance_udr_destinations = [
    { name = "spoke4", address_prefix = [local.spoke4_address_space.0, ], next_hop_ip = module.hub2.firewall_private_ip },
    { name = "spoke5", address_prefix = [local.spoke5_address_space.0, ], next_hop_ip = module.hub2.firewall_private_ip },
    { name = "hub2", address_prefix = [local.hub2_address_space.0, ], next_hop_ip = module.hub2.firewall_private_ip },
  ]

  region2_default_udr_destinations = [
    { name = "default-region2", address_prefix = ["0.0.0.0/0"], next_hop_ip = module.hub2.firewall_private_ip },
  ]
  spoke4_udr_main_routes = concat(local.region2_default_udr_destinations, [
    { name = "hub2", address_prefix = [local.hub2_address_space.0, ], next_hop_ip = module.hub2.firewall_private_ip },
  ])
  spoke5_udr_main_routes = concat(local.region2_default_udr_destinations, [
    { name = "hub2", address_prefix = [local.hub2_address_space.0, ], next_hop_ip = module.hub2.firewall_private_ip },
  ])
  hub2_udr_main_routes = concat(local.region2_default_udr_destinations, [
    { name = "spoke4", address_prefix = [local.spoke4_address_space.0, ], next_hop_ip = module.hub2.firewall_private_ip },
    { name = "spoke5", address_prefix = [local.spoke5_address_space.0, ], next_hop_ip = module.hub2.firewall_private_ip },
  ])
  hub2_gateway_udr_destinations = [
    { name = "spoke4", address_prefix = [local.spoke4_address_space.0, ], next_hop_ip = module.hub2.firewall_private_ip },
    { name = "spoke5", address_prefix = [local.spoke5_address_space.0, ], next_hop_ip = module.hub2.firewall_private_ip },
    { name = "hub2", address_prefix = [local.hub2_address_space.0, ], next_hop_ip = module.hub2.firewall_private_ip },
  ]
  hub2_appliance_udr_destinations = [
    { name = "spoke1", address_prefix = [local.spoke1_address_space.0, ], next_hop_ip = module.hub1.firewall_private_ip },
    { name = "spoke2", address_prefix = [local.spoke2_address_space.0, ], next_hop_ip = module.hub1.firewall_private_ip },
    { name = "hub1", address_prefix = [local.hub1_address_space.0, ], next_hop_ip = module.hub1.firewall_private_ip },
  ]

  firewall_sku = "Basic"

  hub1_features = {
    config_vnet = {
      bgp_community               = local.hub1_bgp_community
      address_space               = local.hub1_address_space
      subnets                     = local.hub1_subnets
      enable_private_dns_resolver = true
      enable_ars                  = false
      enable_vnet_flow_logs       = local.enable_vnet_flow_logs
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
        "azurewebsites.net" = {
          domain = "privatelink.azurewebsites.net"
          target_dns_servers = [
            { ip_address = local.hub1_dns_in_addr, port = 53 },
          ]
        }
        "blob.core.windows.net" = {
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
      enable             = true
      firewall_sku       = local.firewall_sku
      firewall_policy_id = azurerm_firewall_policy.firewall_policy["region1"].id
    }

    config_nva = {
      enable           = false
      enable_ipv6      = null
      type             = null
      scenario_option  = null
      opn_type         = null
      custom_data      = null
      ilb_untrust_ip   = null
      ilb_trust_ip     = null
      ilb_untrust_ipv6 = null
      ilb_trust_ipv6   = null
    }
  }

  hub2_features = {
    config_vnet = {
      bgp_community               = local.hub2_bgp_community
      address_space               = local.hub2_address_space
      subnets                     = local.hub2_subnets
      enable_private_dns_resolver = true
      enable_ars                  = false
      enable_vnet_flow_logs       = local.enable_vnet_flow_logs
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
        "azurewebsites.net" = {
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
      enable             = true
      firewall_sku       = local.firewall_sku
      firewall_policy_id = azurerm_firewall_policy.firewall_policy["region2"].id
    }

    config_nva = {
      enable           = false
      enable_ipv6      = null
      type             = null
      scenario_option  = null
      opn_type         = null
      custom_data      = null
      ilb_untrust_ip   = null
      ilb_trust_ip     = null
      ilb_untrust_ipv6 = null
      ilb_trust_ipv6   = null
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
  source              = "../../modules/common"
  resource_group      = azurerm_resource_group.rg.name
  env                 = "common"
  prefix              = local.prefix
  firewall_sku        = local.firewall_sku
  regions             = local.regions
  private_prefixes    = local.private_prefixes
  private_prefixes_v6 = local.private_prefixes_v6
  tags                = {}
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
    { name = "branch1", dns = lower(local.branch1_vm_fqdn), ipv4 = local.branch1_vm_addr, ipv6 = local.branch1_vm_addr_v6, probe = true },
    { name = "hub1   ", dns = lower(local.hub1_vm_fqdn), ipv4 = local.hub1_vm_addr, ipv6 = local.hub1_vm_addr_v6, probe = true },
    { name = "hub1-spoke3-pep", dns = lower(local.hub1_spoke3_pep_fqdn), ping = false, probe = true },
    { name = "spoke1 ", dns = lower(local.spoke1_vm_fqdn), ipv4 = local.spoke1_vm_addr, ipv6 = local.spoke1_vm_addr_v6, probe = true },
    { name = "spoke2 ", dns = lower(local.spoke2_vm_fqdn), ipv4 = local.spoke2_vm_addr, ipv6 = local.spoke2_vm_addr_v6, probe = true },
  ]
  vm_script_targets_region2 = [
    { name = "branch3", dns = lower(local.branch3_vm_fqdn), ipv4 = local.branch3_vm_addr, ipv6 = local.branch3_vm_addr_v6, probe = true },
    { name = "hub2   ", dns = lower(local.hub2_vm_fqdn), ipv4 = local.hub2_vm_addr, ipv6 = local.hub2_vm_addr_v6, probe = true },
    { name = "hub2-spoke6-pep", dns = lower(local.hub2_spoke6_pep_fqdn), ping = false, probe = true },
    { name = "spoke4 ", dns = lower(local.spoke4_vm_fqdn), ipv4 = local.spoke4_vm_addr, ipv6 = local.spoke4_vm_addr_v6, probe = true },
    { name = "spoke5 ", dns = lower(local.spoke5_vm_fqdn), ipv4 = local.spoke5_vm_addr, ipv6 = local.spoke5_vm_addr_v6, probe = true },
  ]
  vm_script_targets_misc = [
    { name = "internet", dns = "icanhazip.com", ipv4 = "icanhazip.com", ipv6 = "icanhazip.com" },
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
  probe_init_vars = {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = local.vm_script_targets
    TARGETS_HEAVY_TRAFFIC_GEN = [for target in local.vm_script_targets : target.dns if try(target.probe, false)]
  }
  vm_init_vars = {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []
  }
  proxy_init_vars = {
    ONPREM_LOCAL_RECORDS = []
    REDIRECTED_HOSTS     = []
    FORWARD_ZONES        = []
    TARGETS              = local.vm_script_targets
    ACCESS_CONTROL_PREFIXES = concat(
      local.private_prefixes,
      ["127.0.0.0/8", "35.199.192.0/19", "fd00::/8", ]
    )
  }
  vm_init_files = {
    "${local.init_dir}/fastapi/docker-compose-app1-80.yml"   = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/docker-compose-app1-80.yml", {}) }
    "${local.init_dir}/fastapi/docker-compose-app2-8080.yml" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/docker-compose-app2-8080.yml", {}) }
    "${local.init_dir}/fastapi/app/app/Dockerfile"           = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/app/app/Dockerfile", {}) }
    "${local.init_dir}/fastapi/app/app/_app.py"              = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/app/app/_app.py", {}) }
    "${local.init_dir}/fastapi/app/app/main.py"              = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/app/app/main.py", {}) }
    "${local.init_dir}/fastapi/app/app/requirements.txt"     = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/app/app/requirements.txt", {}) }
  }
  vm_startup_init_files = {
    "${local.init_dir}/init/startup.sh" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/startup.sh", local.vm_init_vars) }
  }
  probe_startup_init_files = {
    "${local.init_dir}/init/startup.sh" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/startup.sh", local.probe_init_vars) }
  }
  proxy_startup_files = {
    "${local.init_dir}/unbound/Dockerfile"         = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/Dockerfile", {}) }
    "${local.init_dir}/unbound/docker-compose.yml" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/docker-compose.yml", {}) }
    "${local.init_dir}/unbound/setup-unbound.sh"   = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/setup-unbound.sh", local.proxy_init_vars) }
    "/etc/unbound/unbound.conf"                    = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/unbound.conf", local.proxy_init_vars) }

    "${local.init_dir}/squid/docker-compose.yml" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/squid/docker-compose.yml", local.proxy_init_vars) }
    "${local.init_dir}/squid/setup-squid.sh"     = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/squid/setup-squid.sh", local.proxy_init_vars) }
    "/etc/squid/blocked_sites"                   = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/squid/blocked_sites", local.proxy_init_vars) }
    "/etc/squid/squid.conf"                      = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/squid/squid.conf", local.proxy_init_vars) }
  }
  service_crawler_files = {
    "${local.init_dir}/crawler/app/crawler.sh"       = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/crawler/app/crawler.sh", {}) }
    "${local.init_dir}/crawler/app/service_tags.py"  = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/crawler/app/service_tags.py", {}) }
    "${local.init_dir}/crawler/app/requirements.txt" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/crawler/app/requirements.txt", {}) }
  }
  onprem_local_records = [
    { name = lower(local.branch1_vm_fqdn), rdata = local.branch1_vm_addr, ttl = "300", type = "A" },
    { name = lower(local.branch2_vm_fqdn), rdata = local.branch2_vm_addr, ttl = "300", type = "A" },
    { name = lower(local.branch3_vm_fqdn), rdata = local.branch3_vm_addr, ttl = "300", type = "A" },
    { name = lower(local.branch1_vm_fqdn), rdata = local.branch1_vm_addr_v6, ttl = "300", type = "AAAA" },
    { name = lower(local.branch2_vm_fqdn), rdata = local.branch2_vm_addr_v6, ttl = "300", type = "AAAA" },
    { name = lower(local.branch3_vm_fqdn), rdata = local.branch3_vm_addr_v6, ttl = "300", type = "AAAA" },
  ]
  onprem_redirected_hosts = []
}

module "vm_cloud_init" {
  source = "../../modules/cloud-config-gen"
  files = merge(
    local.vm_init_files,
    local.vm_startup_init_files
  )
  packages = [
    "docker.io", "docker-compose", #npm,
  ]
  run_commands = [
    "bash ${local.init_dir}/init/startup.sh",
    "docker-compose -f ${local.init_dir}/fastapi/docker-compose-app1-80.yml up -d",
    "docker-compose -f ${local.init_dir}/fastapi/docker-compose-app2-8080.yml up -d",
  ]
}

module "probe_vm_cloud_init" {
  source = "../../modules/cloud-config-gen"
  files = merge(
    local.vm_init_files,
    local.probe_startup_init_files,
  )
  packages = [
    "docker.io", "docker-compose",
  ]
  run_commands = [
    "bash ${local.init_dir}/init/startup.sh",
    "docker-compose -f ${local.init_dir}/fastapi/docker-compose-app1-80.yml up -d",
    "docker-compose -f ${local.init_dir}/fastapi/docker-compose-app2-8080.yml up -d",
  ]
}

module "proxy_vm_cloud_init" {
  source   = "../../modules/cloud-config-gen"
  files    = local.proxy_startup_files
  packages = ["docker.io", "docker-compose", ]
  run_commands = [
    "sysctl -w net.ipv4.ip_forward=1",
    "sysctl -w net.ipv4.conf.eth0.disable_xfrm=1",
    "sysctl -w net.ipv4.conf.eth0.disable_policy=1",
    "echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf",
    "sysctl -w net.ipv6.conf.all.forwarding=1",
    "echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.conf",
    "sysctl -p",
    "echo iptables-persistent iptables-persistent/autosave_v4 boolean false | debconf-set-selections",
    "echo iptables-persistent iptables-persistent/autosave_v6 boolean false | debconf-set-selections",
    "apt-get -y install iptables-persistent",
    "iptables -P FORWARD ACCEPT",
    "iptables -P INPUT ACCEPT",
    "iptables -P OUTPUT ACCEPT",
    "iptables -t nat -A POSTROUTING -d 10.0.0.0/8 -j ACCEPT",
    "iptables -t nat -A POSTROUTING -d 172.16.0.0/12 -j ACCEPT",
    "iptables -t nat -A POSTROUTING -d 192.168.0.0/16 -j ACCEPT",
    "iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE",
    ". ${local.init_dir}/init/startup.sh",
    ". ${local.init_dir}/unbound/setup-unbound.sh",
    ". ${local.init_dir}/squid/setup-squid.sh",
    "docker-compose -f ${local.init_dir}/unbound/docker-compose.yml up -d",
    "docker-compose -f ${local.init_dir}/squid/docker-compose.yml up -d",
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
  nat_rule_collection = [
    # {
    #   name     = "nat-rc"
    #   priority = 200
    #   action   = "Dnat"
    #   rule = [
    #     {
    #       name                = "nat-rc-any-to-spoke1vm"
    #       source_addresses    = ["*"]
    #       destination_address = "52.169.147.205"
    #       protocols           = ["TCP"]
    #       destination_ports   = ["22"]
    #       translated_address  = "10.1.0.5"
    #       translated_port     = 22
    #     }
    #   ]
    # }
  ]
}

####################################################
# output files
####################################################

locals {
  main_files = {
    "output/server.sh"              = local.vm_startup
    "output/startup.sh"             = templatefile("../../scripts/startup.sh", local.vm_init_vars)
    "output/startup-probe.sh"       = templatefile("../../scripts/startup.sh", local.probe_init_vars)
    "output/probe-cloud-config.yml" = module.probe_vm_cloud_init.cloud_config
    "output/vm-cloud-config.yml"    = module.vm_cloud_init.cloud_config
  }
}

resource "local_file" "main_files" {
  for_each = local.main_files
  filename = each.key
  content  = each.value
}

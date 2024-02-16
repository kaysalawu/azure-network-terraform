####################################################
# Lab
####################################################

locals {
  prefix             = "G02"
  enable_diagnostics = false

  hub1_tags   = { "lab" = "Hs13", "nodeType" = "hub" }
  spoke1_tags = { "lab" = "Hs13", "nodeType" = "spoke" }

  server_cert_name_app1 = "cert"
  server_common_name    = "healthz.az.corp"
  server_host_app1      = "app1.we.az.corp"
  server_host_app2      = "app2.we.az.corp"
  server_host_wildcard  = "*.az.corp"
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
    region1 = local.region1
  }
  default_udr_destinations = [
    { name = "default", address_prefix = ["0.0.0.0/0"] }
  ]
  hub1_appliance_udr_destinations = [
    { name = "spoke4", address_prefix = local.spoke4_address_space },
    { name = "spoke5", address_prefix = local.spoke5_address_space },
    { name = "hub2", address_prefix = local.hub2_address_space },
  ]
  hub1_gateway_udr_destinations = [
    { name = "spoke1", address_prefix = local.spoke1_address_space },
    { name = "spoke2", address_prefix = local.spoke2_address_space },
    { name = "hub1", address_prefix = local.hub1_address_space },
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
          ]
        }
        "${local.region1_code}" = {
          domain = "${local.region1_code}.${local.cloud_domain}"
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
      }
    }

    config_s2s_vpngw = {
      enable = false
      sku    = "VpnGw1AZ"
      bgp_settings = {
        asn = local.hub1_vpngw_asn
      }
    }

    config_p2s_vpngw = {
      enable = false
      sku    = "VpnGw1AZ"
      ip_configuration = [
        # { name = "ip-config", public_ip_address_name = azurerm_public_ip.hub1_p2s_vpngw_pip.name },
      ]
      vpn_client_configuration = {
        address_space = []
        clients = [
          # { name = "client1" },
          # { name = "client2" },
          # { name = "client3" },
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
  hub1_nva_asn   = "65000"
  hub1_vpngw_asn = "65515"
  hub1_ergw_asn  = "65515"
  hub1_ars_asn   = "65515"

  vm_script_targets_region1 = [
    { name = "branch1", dns = local.branch1_vm_fqdn, ip = local.branch1_vm_addr },
    { name = "hub1   ", dns = local.hub1_vm_fqdn, ip = local.hub1_vm_addr },
    { name = "spoke1 ", dns = local.spoke1_vm_fqdn, ip = local.spoke1_vm_addr },
  ]
  vm_script_targets_misc = [
    { name = "internet", dns = "icanhazip.com", ip = "icanhazip.com" },
  ]
  vm_script_targets = concat(
    local.vm_script_targets_region1,
    local.vm_script_targets_misc,
  )
  vm_startup = templatefile("../../scripts/server.sh", {
    USER_ASSIGNED_ID          = azurerm_user_assigned_identity.machine.id
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []
    ENABLE_TRAFFIC_GEN        = false
  })
  init_dir               = "/var/lib/azure"
  init_local_path        = "../../scripts/docker/fastapi"
  init_port_app1         = "8080" # nginx tls
  init_port_app1_target  = "9000"
  init_port_app2_target  = "8081"
  init_name_app1         = "app1"
  init_name_app2         = "app2"
  init_niginx_cert_path  = "/etc/ssl/app/cert.pem"
  init_niginx_key_path   = "/etc/ssl/app/key.pem"
  init_nginx_config_path = "/etc/nginx/nginx.conf"
  init_vars = {
    INIT_DIR = local.init_dir
    NGINX = {
      enable_tls  = true
      port        = local.init_port_app1
      cert_path   = local.init_niginx_cert_path
      key_path    = local.init_niginx_key_path
      config_path = local.init_nginx_config_path
      proxy_pass  = "http://localhost:${local.init_port_app1_target}"
    }
    APPS = [
      { name = local.init_name_app1, port = local.init_port_app1_target },
      { name = local.init_name_app2, port = local.init_port_app2_target },
    ]
  }
  init_vars_app1 = merge(local.init_vars, {
    APP_NAME = local.init_name_app1
    APP_PORT = local.init_port_app1_target
  })
  init_vars_app2 = merge(local.init_vars, {
    APP_NAME = local.init_name_app2
    APP_PORT = local.init_port_app2_target
  })
  vm_startup_fastapi_init = {
    "${local.init_dir}/docker-compose.yml" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/docker/fastapi/docker-compose.yml", local.init_vars) }
    "${local.init_dir}/start.sh"           = { owner = "root", permissions = "0744", content = templatefile("../../scripts/docker/fastapi/start.sh", local.init_vars) }
    "${local.init_dir}/stop.sh"            = { owner = "root", permissions = "0744", content = templatefile("../../scripts/docker/fastapi/stop.sh", local.init_vars) }
    "${local.init_dir}/service.sh"         = { owner = "root", permissions = "0744", content = templatefile("../../scripts/docker/fastapi/service.sh", local.init_vars) }
    "/etc/ssl/app/cert.pem"                = { owner = "root", permissions = "0400", content = join("\n", [module.server_cert.cert_pem, tls_self_signed_cert.root_ca.cert_pem]) }
    "/etc/ssl/app/key.pem"                 = { owner = "root", permissions = "0400", content = module.server_cert.private_key_pem }

    "${local.init_dir}/nginx/Dockerfile" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/docker/fastapi/nginx/Dockerfile", local.init_vars) }
    "/etc/nginx/nginx.conf"              = { owner = "root", permissions = "0744", content = templatefile("../../scripts/docker/fastapi/nginx/nginx.conf", local.init_vars) }

    "${local.init_dir}/${local.init_name_app1}/Dockerfile"       = { owner = "root", permissions = "0744", content = templatefile("${local.init_local_path}/Dockerfile", local.init_vars_app1) }
    "${local.init_dir}/${local.init_name_app1}/.dockerignore"    = { owner = "root", permissions = "0744", content = templatefile("${local.init_local_path}/.dockerignore", local.init_vars_app1) }
    "${local.init_dir}/${local.init_name_app1}/main.py"          = { owner = "root", permissions = "0744", content = templatefile("${local.init_local_path}/main.py", local.init_vars_app1) }
    "${local.init_dir}/${local.init_name_app1}/_app.py"          = { owner = "root", permissions = "0744", content = templatefile("${local.init_local_path}/_app.py", local.init_vars_app1) }
    "${local.init_dir}/${local.init_name_app1}/requirements.txt" = { owner = "root", permissions = "0744", content = templatefile("${local.init_local_path}/requirements.txt", local.init_vars) }

    "${local.init_dir}/${local.init_name_app2}/Dockerfile"       = { owner = "root", permissions = "0744", content = templatefile("${local.init_local_path}/Dockerfile", local.init_vars_app2) }
    "${local.init_dir}/${local.init_name_app2}/.dockerignore"    = { owner = "root", permissions = "0744", content = templatefile("${local.init_local_path}/.dockerignore", local.init_vars_app2) }
    "${local.init_dir}/${local.init_name_app2}/main.py"          = { owner = "root", permissions = "0744", content = templatefile("${local.init_local_path}/main.py", local.init_vars_app2) }
    "${local.init_dir}/${local.init_name_app2}/_app.py"          = { owner = "root", permissions = "0744", content = templatefile("${local.init_local_path}/_app.py", local.init_vars_app2) }
    "${local.init_dir}/${local.init_name_app2}/requirements.txt" = { owner = "root", permissions = "0744", content = templatefile("${local.init_local_path}/requirements.txt", local.init_vars_app2) }
  }

  onprem_dns_vars = {
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
  branch_dns_init_dir    = "/var/lib/labs"
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
    { zone = "${local.cloud_domain}.", targets = [local.hub1_dns_in_addr, ], },
    { zone = "${local.cloud_domain}.", targets = [local.hub1_dns_in_addr, ], },
    { zone = "privatelink.blob.core.windows.net.", targets = [local.hub1_dns_in_addr, ], },
    { zone = "privatelink.azurewebsites.net.", targets = [local.hub1_dns_in_addr, ], },
    { zone = "privatelink.database.windows.net.", targets = [local.hub1_dns_in_addr, ], },
    { zone = "privatelink.table.cosmos.azure.com.", targets = [local.hub1_dns_in_addr, ], },
    { zone = "privatelink.queue.core.windows.net.", targets = [local.hub1_dns_in_addr, ], },
    { zone = "privatelink.file.core.windows.net.", targets = [local.hub1_dns_in_addr, ], },
    { zone = ".", targets = [local.azuredns, ] },
  ]
  onprem_redirected_hosts = []
}

module "branch_unbound_init" {
  source   = "../../modules/cloud-config-gen"
  packages = ["docker.io", "docker-compose", "dnsutils", "net-tools", ]
  files    = local.branch_unbound_init
  run_commands = [
    "systemctl stop systemd-resolved",
    "systemctl disable systemd-resolved",
    "echo \"nameserver 8.8.8.8\" > /etc/resolv.conf",
    "systemctl restart unbound",
    "systemctl enable unbound",
  ]
}

module "web_http_backend_init" {
  source = "../../modules/cloud-config-gen"
  packages = [
    "docker.io", "docker-compose",
    "tcpdump", "dnsutils", "net-tools", "nmap", "apache2-utils",
  ]
  files = local.vm_startup_fastapi_init
  run_commands = [
    ". ${local.init_dir}/service.sh",
  ]
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
    TARGETS           = local.vm_script_targets
    IPTABLES_RULES    = []
    ROUTE_MAPS        = []
    TUNNELS           = []
    QUAGGA_ZEBRA_CONF = ""
    QUAGGA_BGPD_CONF  = ""
    }
  ))
}

####################################################
# client cert
####################################################

module "server_cert" {
  source   = "../../modules/cert-self-signed"
  name     = local.server_cert_name_app1
  rsa_bits = 2048
  subject = {
    common_name         = local.server_host_wildcard
    organization        = "app1 demo"
    organizational_unit = "app1 network team"
    street_address      = "99 mpls chicken road, network avenue"
    locality            = "London"
    province            = "England"
    country             = "UK"
  }
  dns_names = [
    local.server_host_wildcard,
  ]
  ca_private_key_pem = tls_private_key.root_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.root_ca.cert_pem
}

####################################################
# output files
####################################################

locals {
  main_files = {
    "output/branch-unbound.sh" = local.branch_unbound_startup
    "output/server.sh"         = local.vm_startup
    "output/cloud-init"        = module.web_http_backend_init.cloud_config
  }
}

resource "local_file" "main_files" {
  for_each = local.main_files
  filename = each.key
  content  = each.value
}

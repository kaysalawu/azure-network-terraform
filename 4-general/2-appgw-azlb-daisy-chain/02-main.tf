####################################################
# Lab
####################################################

locals {
  prefix                = "G02"
  region1               = "westeurope"
  region2               = "northeurope"
  spoke3_apps_fqdn      = lower("${local.spoke3_prefix}${random_id.random.hex}.azurewebsites.net")
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
# network features
####################################################

locals {
  regions = {
    region1 = local.region1
  }
  default_udr_destinations = {
    "default" = "0.0.0.0/0"
  }
  hub1_appliance_udr_destinations = {
    "spoke4" = local.spoke4_address_space[0]
    "spoke5" = local.spoke5_address_space[0]
    "hub2"   = local.hub2_address_space[0]
  }
  hub1_gateway_udr_destinations = {
    "spoke1" = local.spoke1_address_space[0]
    "spoke2" = local.spoke2_address_space[0]
    "hub1"   = local.hub1_address_space[0]
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
          ]
        }
        "we" = {
          domain = "we.${local.cloud_domain}"
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
      enable             = false
      sku                = "VpnGw1AZ"
      enable_diagnostics = local.enable_diagnostics
      bgp_settings = {
        asn = local.hub1_vpngw_asn
      }
    }

    config_ergw = {
      enable             = false
      sku                = "ErGw1AZ"
      enable_diagnostics = local.enable_diagnostics
    }

    config_firewall = {
      enable             = false
      firewall_sku       = local.firewall_sku
      firewall_policy_id = azurerm_firewall_policy.firewall_policy["region1"].id
      enable_diagnostics = local.enable_diagnostics
    }

    config_nva = {
      enable             = true
      type               = "linux"
      internal_lb_addr   = local.hub1_nva_ilb_addr
      custom_data        = base64encode(local.hub1_linux_nva_init)
      enable_diagnostics = local.enable_diagnostics
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
  branch_unbound_conf         = templatefile("../../scripts/unbound/unbound.conf", local.onprem_dns_vars)
  branch_unbound_startup      = templatefile("../../scripts/unbound/unbound.sh", local.onprem_dns_vars)
  branch_dnsmasq_startup      = templatefile("../../scripts/dnsmasq/dnsmasq.sh", local.onprem_dns_vars)
  branch_dnsmasq_cloud_config = templatefile("../../scripts/dnsmasq/cloud-config", local.onprem_dns_vars)
  branch_unbound_cloud_config = templatefile("../../scripts/unbound/cloud-config", local.onprem_dns_vars)
  branch_onprem_dns_vars = {
    ONPREM_LOCAL_RECORDS = local.onprem_local_records
    REDIRECTED_HOSTS     = local.onprem_redirected_hosts
    FORWARD_ZONES        = local.onprem_forward_zones
    TARGETS              = local.vm_script_targets
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
# root ca
####################################################

# private key

resource "tls_private_key" "root_ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# root ca cert

resource "tls_self_signed_cert" "root_ca" {
  private_key_pem = tls_private_key.root_ca.private_key_pem
  subject {
    common_name         = local.server_host_wildcard
    organization        = "demo"
    organizational_unit = "cloud network team"
    street_address      = ["mpls chicken road"]
    locality            = "London"
    province            = "England"
    country             = "UK"
  }
  is_ca_certificate     = true
  validity_period_hours = 8760
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
  ]
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

# resource "local_file" "docker_files" {
#   for_each = local.vm_startup_fastapi_init
#   filename = "output/docker/${each.key}"
#   content  = each.value.content
# }

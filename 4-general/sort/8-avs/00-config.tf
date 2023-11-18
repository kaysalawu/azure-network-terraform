
# Common

#----------------------------

locals {
  region1  = "westeurope"
  region2  = "northeurope"
  username = "azureuser"
  password = "Password123"
  vmsize   = "Standard_DS1_v2"
  psk      = "changeme"

  bgp_apipa_range1 = "169.254.21.0/30"
  bgp_apipa_range2 = "169.254.21.4/30"
  bgp_apipa_range3 = "169.254.21.8/30"
  bgp_apipa_range4 = "169.254.21.12/30"
  bgp_apipa_range5 = "169.254.21.16/30"
  bgp_apipa_range6 = "169.254.21.20/30"
  bgp_apipa_range7 = "169.254.21.24/30"
  bgp_apipa_range8 = "169.254.21.28/30"

  gr_range1 = "10.99.0.0/29"
  gr_range2 = "10.99.0.8/29"
  gr_range3 = "10.99.0.16/29"
  gr_range4 = "10.99.0.24/29"

  default_region      = "westeurope"
  subnets_without_nsg = ["GatewaySubnet"]

  nva_aggregate = "10.1.0.0/23"

  onprem_domain    = "corp"
  cloud_domain     = "az.corp"
  azuredns         = "168.63.129.16"
  rfc1918_prefixes = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]

  firewall_sku = "Standard"

  udr_destinations_region1 = [
    local.core1_address_space[0],
    local.core2_address_space[0],
    local.hub_address_space[0],
    local.avs_subnets["${local.avs_prefix}main"].address_prefixes[0],
  ]
}

# hub
#----------------------------

locals {
  hub_prefix        = local.prefix == "" ? "hub-" : join("-", [local.prefix, "hub-"])
  hub_location      = local.region1
  hub_address_space = ["10.11.0.0/16"]
  hub_nat_ranges = {
    "avs" = {
      "egress-static"  = "10.11.90.0/24"
      "egress-dynamic" = "10.11.91.0/24"
      "ingress-static" = "10.11.80.0/24"
    }
  }
  hub_dns_zone = "hub.${local.cloud_domain}"
  hub_tags     = { env = "hub" }
  hub_subnets = {
    ("${local.hub_prefix}main")       = { address_prefixes = ["10.11.0.0/24"] }
    ("${local.hub_prefix}nva")        = { address_prefixes = ["10.11.1.0/24"] }
    ("${local.hub_prefix}ilb")        = { address_prefixes = ["10.11.2.0/24"] }
    ("${local.hub_prefix}pls")        = { address_prefixes = ["10.11.3.0/24"] }
    ("${local.hub_prefix}pep")        = { address_prefixes = ["10.11.4.0/24"] }
    ("${local.hub_prefix}dns-in")     = { address_prefixes = ["10.11.5.0/24"], delegate = ["dns"] }
    ("${local.hub_prefix}dns-out")    = { address_prefixes = ["10.11.6.0/24"], delegate = ["dns"] }
    ("GatewaySubnet")                 = { address_prefixes = ["10.11.7.0/24"] }
    ("RouteServerSubnet")             = { address_prefixes = ["10.11.8.0/24"] }
    ("AzureFirewallSubnet")           = { address_prefixes = ["10.11.9.0/24"] }
    ("AzureFirewallManagementSubnet") = { address_prefixes = ["10.11.10.0/24"] }
  }
  hub_default_gw_main   = cidrhost(local.hub_subnets["${local.hub_prefix}main"].address_prefixes[0], 1)
  hub_default_gw_nva    = cidrhost(local.hub_subnets["${local.hub_prefix}nva"].address_prefixes[0], 1)
  hub_vm_addr           = cidrhost(local.hub_subnets["${local.hub_prefix}main"].address_prefixes[0], 5)
  hub_nva_addr          = cidrhost(local.hub_subnets["${local.hub_prefix}nva"].address_prefixes[0], 9)
  hub_nva_ilb_addr      = cidrhost(local.hub_subnets["${local.hub_prefix}ilb"].address_prefixes[0], 99)
  hub_dns_in_addr       = cidrhost(local.hub_subnets["${local.hub_prefix}dns-in"].address_prefixes[0], 4)
  hub_dns_out_addr      = cidrhost(local.hub_subnets["${local.hub_prefix}dns-out"].address_prefixes[0], 4)
  hub_vpngw_bgp_ip      = cidrhost(local.hub_subnets["GatewaySubnet"].address_prefixes[0], 254)
  hub_nva_loopback0     = "10.11.11.11"
  hub_nva_tun_range0    = "10.11.50.0/30"
  hub_nva_tun_range1    = "10.11.51.4/30"
  hub_vpngw_bgp_apipa_0 = cidrhost(local.bgp_apipa_range1, 1)
  hub_vpngw_bgp_apipa_1 = cidrhost(local.bgp_apipa_range2, 1)
  hub_vm_dns_host       = "vm"
  hub_ilb_dns_host      = "ilb"
  hub_pep_dns_host      = "pep"
  hub_vm_dns            = "${local.hub_vm_dns_host}.${local.hub_dns_zone}"
  hub_pep_dns           = "${local.hub_pep_dns_host}.${local.hub_dns_zone}"
}

# avs
#----------------------------

locals {
  avs_prefix        = local.prefix == "" ? "avs-" : join("-", [local.prefix, "avs-"])
  avs_location      = local.region1
  avs_address_space = ["10.10.0.0/16", /*"10.1.0.0/16"*/]
  avs_nva_asn       = "65001"
  avs_dns_zone      = "avs.${local.onprem_domain}"
  avs_tags          = { env = "avs" }
  avs_subnets = {
    #("${local.avs_prefix}main2") = { address_prefixes = ["10.1.0.0/24"] }
    ("${local.avs_prefix}main") = { address_prefixes = ["10.10.0.0/24"] }
    ("${local.avs_prefix}ext")  = { address_prefixes = ["10.10.1.0/24"] }
    ("${local.avs_prefix}int")  = { address_prefixes = ["10.10.2.0/24"] }
    ("GatewaySubnet")           = { address_prefixes = ["10.10.3.0/24"] }
  }
  avs_ext_default_gw = cidrhost(local.avs_subnets["${local.avs_prefix}ext"].address_prefixes[0], 1)
  avs_int_default_gw = cidrhost(local.avs_subnets["${local.avs_prefix}int"].address_prefixes[0], 1)
  avs_nva_ext_addr   = cidrhost(local.avs_subnets["${local.avs_prefix}ext"].address_prefixes[0], 9)
  avs_nva_int_addr   = cidrhost(local.avs_subnets["${local.avs_prefix}int"].address_prefixes[0], 9)
  avs_vm_addr        = cidrhost(local.avs_subnets["${local.avs_prefix}main"].address_prefixes[0], 5)
  avs_dns_addr       = cidrhost(local.avs_subnets["${local.avs_prefix}main"].address_prefixes[0], 6)
  #avs_vm2_addr       = cidrhost(local.avs_subnets["${local.avs_prefix}main2"].address_prefixes[0], 5)
  avs_nva_loopback0  = "192.168.10.10"
  avs_nva_tun_range0 = "10.10.10.0/30"
  avs_nva_tun_range1 = "10.10.10.4/30"
  avs_nva_tun_range2 = "10.10.10.8/30"
  avs_nva_tun_range3 = "10.10.10.12/30"
  avs_bgp_apipa_0    = cidrhost(local.bgp_apipa_range3, 2)
  avs_bgp_apipa_1    = cidrhost(local.bgp_apipa_range4, 2)
  avs_vm_dns_host    = "vm.avs"
  #avs_vm2_dns_host   = "vm2.avs"
  avs_vm_dns = "${local.avs_vm_dns_host}.${local.onprem_domain}"
  #avs_vm2_dns        = "${local.avs_vm2_dns_host}.${local.onprem_domain}"
}

# onprem
#----------------------------

locals {
  onprem_prefix        = local.prefix == "" ? "onprem-" : join("-", [local.prefix, "onprem-"])
  onprem_location      = local.region1
  onprem_address_space = ["10.20.0.0/16"]
  onprem_nva_asn       = "65002"
  onprem_dns_zone      = "onprem.${local.onprem_domain}"
  onprem_tags          = { env = "onprem" }
  onprem_subnets = {
    ("${local.onprem_prefix}main") = { address_prefixes = ["10.20.0.0/24"] }
    ("${local.onprem_prefix}ext")  = { address_prefixes = ["10.20.1.0/24"] }
    ("${local.onprem_prefix}int")  = { address_prefixes = ["10.20.2.0/24"] }
    ("GatewaySubnet")              = { address_prefixes = ["10.20.3.0/24"] }
  }
  onprem_ext_default_gw = cidrhost(local.onprem_subnets["${local.onprem_prefix}ext"].address_prefixes[0], 1)
  onprem_int_default_gw = cidrhost(local.onprem_subnets["${local.onprem_prefix}int"].address_prefixes[0], 1)
  onprem_nva_ext_addr   = cidrhost(local.onprem_subnets["${local.onprem_prefix}ext"].address_prefixes[0], 9)
  onprem_nva_int_addr   = cidrhost(local.onprem_subnets["${local.onprem_prefix}int"].address_prefixes[0], 9)
  onprem_vm_addr        = cidrhost(local.onprem_subnets["${local.onprem_prefix}main"].address_prefixes[0], 5)
  onprem_dns_addr       = cidrhost(local.onprem_subnets["${local.onprem_prefix}main"].address_prefixes[0], 6)
  onprem_nva_loopback0  = "192.168.20.20"
  onprem_nva_tun_range0 = "10.20.20.0/30"
  onprem_nva_tun_range1 = "10.20.20.4/30"
  onprem_nva_tun_range2 = "10.20.20.8/30"
  onprem_nva_tun_range3 = "10.20.20.12/30"
  onprem_vm_dns_host    = "backup.onprem"
  onprem_vm_dns         = "${local.onprem_vm_dns_host}.${local.onprem_domain}"
}

# core1
#----------------------------

locals {
  core1_prefix        = local.prefix == "" ? "core1-" : join("-", [local.prefix, "core1-"])
  core1_location      = local.region1
  core1_address_space = ["10.1.0.0/16"]
  core1_dns_zone      = "core1.${local.cloud_domain}"
  core1_tags          = { env = "core1" }
  core1_subnets = {
    ("${local.core1_prefix}main")  = { address_prefixes = ["10.1.0.0/24"] }
    ("${local.core1_prefix}appgw") = { address_prefixes = ["10.1.1.0/24"] }
    ("${local.core1_prefix}ilb")   = { address_prefixes = ["10.1.2.0/24"] }
    ("${local.core1_prefix}pls")   = { address_prefixes = ["10.1.3.0/24"] }
    ("${local.core1_prefix}pep")   = { address_prefixes = ["10.1.4.0/24"] }
    ("GatewaySubnet")              = { address_prefixes = ["10.1.5.0/24"] }
  }
  core1_vm_addr      = cidrhost(local.core1_subnets["${local.core1_prefix}main"].address_prefixes[0], 5)
  core1_ilb_addr     = cidrhost(local.core1_subnets["${local.core1_prefix}ilb"].address_prefixes[0], 99)
  core1_pl_nat_addr  = cidrhost(local.core1_subnets["${local.core1_prefix}main"].address_prefixes[0], 50)
  core1_appgw_addr   = cidrhost(local.core1_subnets["${local.core1_prefix}appgw"].address_prefixes[0], 99)
  core1_vm_dns_host  = "bak-srv"
  core1_ilb_dns_host = "ilb"
  core1_vm_dns       = "${local.core1_vm_dns_host}.${local.core1_dns_zone}"
}

# core2
#----------------------------

locals {
  core2_prefix        = local.prefix == "" ? "core2-" : join("-", [local.prefix, "core2-"])
  core2_location      = local.region1
  core2_address_space = ["10.2.0.0/16"]
  core2_dns_zone      = "core2.${local.cloud_domain}"
  core2_tags          = { env = "core2" }
  core2_subnets = {
    ("${local.core2_prefix}main")  = { address_prefixes = ["10.2.0.0/24"] }
    ("${local.core2_prefix}appgw") = { address_prefixes = ["10.2.1.0/24"] }
    ("${local.core2_prefix}ilb")   = { address_prefixes = ["10.2.2.0/24"] }
    ("${local.core2_prefix}pls")   = { address_prefixes = ["10.2.3.0/24"] }
    ("${local.core2_prefix}pep")   = { address_prefixes = ["10.2.4.0/24"] }
  }
  core2_vm_addr      = cidrhost(local.core2_subnets["${local.core2_prefix}main"].address_prefixes[0], 5)
  core2_ilb_addr     = cidrhost(local.core2_subnets["${local.core2_prefix}ilb"].address_prefixes[0], 99)
  core2_pl_nat_addr  = cidrhost(local.core2_subnets["${local.core2_prefix}main"].address_prefixes[0], 50)
  core2_appgw_addr   = cidrhost(local.core2_subnets["${local.core2_prefix}appgw"].address_prefixes[0], 99)
  core2_vm_dns_host  = "bak-srv"
  core2_ilb_dns_host = "ilb"
  core2_vm_dns       = "${local.core2_vm_dns_host}.${local.core2_dns_zone}"
}

# yellow
#----------------------------

locals {
  yellow_prefix        = local.prefix == "" ? "yellow-" : join("-", [local.prefix, "yellow-"])
  yellow_location      = local.region1
  yellow_address_space = ["10.3.0.0/16"]
  yellow_dns_zone      = "yellow.${local.cloud_domain}"
  yellow_tags          = { env = "yellow" }
  yellow_subnets = {
    ("${local.yellow_prefix}main")  = { address_prefixes = ["10.3.0.0/24"] }
    ("${local.yellow_prefix}appgw") = { address_prefixes = ["10.3.1.0/24"] }
    ("${local.yellow_prefix}ilb")   = { address_prefixes = ["10.3.2.0/24"] }
    ("${local.yellow_prefix}pls")   = { address_prefixes = ["10.3.3.0/24"] }
    ("${local.yellow_prefix}pep")   = { address_prefixes = ["10.3.4.0/24"] }
  }
  yellow_vm_addr      = cidrhost(local.yellow_subnets["${local.yellow_prefix}main"].address_prefixes[0], 5)
  yellow_ilb_addr     = cidrhost(local.yellow_subnets["${local.yellow_prefix}ilb"].address_prefixes[0], 99)
  yellow_pl_nat_addr  = cidrhost(local.yellow_subnets["${local.yellow_prefix}pls"].address_prefixes[0], 50)
  yellow_appgw_addr   = cidrhost(local.yellow_subnets["${local.yellow_prefix}appgw"].address_prefixes[0], 99)
  yellow_vm_dns_host  = "vm"
  yellow_ilb_dns_host = "ilb"
  yellow_vm_dns       = "${local.yellow_vm_dns_host}.${local.yellow_dns_zone}"
}

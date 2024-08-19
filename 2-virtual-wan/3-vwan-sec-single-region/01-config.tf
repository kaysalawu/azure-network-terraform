
# Common

#----------------------------
locals {
  username = "azureuser"
  password = "Password123"
  vmsize   = "Standard_DS1_v2"
  psk      = "changeme"

  region1          = "northeurope"
  region2          = "eastus"
  region1_code     = "eu"
  region2_code     = "us"
  region1_dns_zone = "${local.region1_code}.${local.cloud_domain}"
  region2_dns_zone = "${local.region2_code}.${local.cloud_domain}"

  bgp_apipa_range1 = "169.254.21.0/30"
  bgp_apipa_range2 = "169.254.21.4/30"
  bgp_apipa_range3 = "169.254.21.8/30"
  bgp_apipa_range4 = "169.254.21.12/30"
  bgp_apipa_range5 = "169.254.21.16/30"
  bgp_apipa_range6 = "169.254.21.20/30"
  bgp_apipa_range7 = "169.254.21.24/30"
  bgp_apipa_range8 = "169.254.21.28/30"

  csp_range1 = "172.16.0.0/30"
  csp_range2 = "172.16.0.4/30"
  csp_range3 = "172.16.0.8/30"
  csp_range4 = "172.16.0.12/30"
  csp_range5 = "172.16.0.16/30"
  csp_range6 = "172.16.0.20/30"
  csp_range7 = "172.16.0.24/30"
  csp_range8 = "172.16.0.28/30"

  csp_range1_v6 = "2001:db8:1::/126"
  csp_range2_v6 = "2001:db8:1:1::/126"
  csp_range3_v6 = "2001:db8:1:2::/126"
  csp_range4_v6 = "2001:db8:1:3::/126"
  csp_range5_v6 = "2001:db8:1:4::/126"
  csp_range6_v6 = "2001:db8:1:5::/126"
  csp_range7_v6 = "2001:db8:1:6::/126"
  csp_range8_v6 = "2001:db8:1:7::/126"

  vti_range0 = "10.10.10.0/30"
  vti_range1 = "10.10.10.4/30"
  vti_range2 = "10.10.10.8/30"
  vti_range3 = "10.10.10.12/30"
  vti_range4 = "10.10.10.16/30"
  vti_range5 = "10.10.10.20/30"
  vti_range6 = "10.10.10.24/30"
  vti_range7 = "10.10.10.28/30"

  default_region = "westeurope"

  onprem_domain  = "corp"
  cloud_domain   = "az.corp"
  azuredns       = "168.63.129.16"
  internet_proxy = "8.8.8.8/32" # test only
  private_prefixes = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16",
    "100.64.0.0/10",
  ]
  private_prefixes_v6 = [
    "fd00::/8",
  ]

  service_tags = [
    "AzureActiveDirectory",
    "AzureBackup",
    "AzureKeyVault",
    # "AzureLoadBalancer",
    "AzureMonitor",
    "AzureResourceManager",
    "EventHub",
    "Storage",
  ]

  azure_asn          = 12076
  azure_internal_asn = 65515
  megaport_asn       = 64512
}

# vhub1
#----------------------------

locals {
  vhub1_prefix            = local.prefix == "" ? "vhub1-" : join("-", [local.prefix, "vhub1-"])
  vhub1_location          = local.region1
  vhub1_bgp_asn           = "65515"
  vhub1_address_prefix    = "192.168.11.0/24"
  vhub1_vpngw_bgp_apipa_0 = cidrhost(local.bgp_apipa_range1, 1)
  vhub1_vpngw_bgp_apipa_1 = cidrhost(local.bgp_apipa_range2, 1)
}

# vhub2
#----------------------------

locals {
  vhub2_prefix            = local.prefix == "" ? "vhub2-" : join("-", [local.prefix, "vhub2-"])
  vhub2_location          = local.region2
  vhub2_bgp_asn           = "65515"
  vhub2_address_prefix    = "192.168.22.0/24"
  vhub2_vpngw_bgp_apipa_0 = cidrhost(local.bgp_apipa_range3, 1)
  vhub2_vpngw_bgp_apipa_1 = cidrhost(local.bgp_apipa_range4, 1)
}

# hub1
#----------------------------

locals {
  hub1_prefix        = local.prefix == "" ? "hub1-" : join("-", [local.prefix, "hub1-"])
  hub1_location      = local.region1
  hub1_address_space = ["10.11.0.0/16", "fd00:db8:11::/56", ]
  hub1_bgp_community = "12076:20011"
  hub1_nat_ranges = {
    "branch1" = {
      "egress-static"  = "10.11.90.0/24"
      "egress-dynamic" = "10.11.91.0/24"
      "ingress-static" = "10.11.80.0/24"
    }
  }
  hub1_dns_zone = local.region1_dns_zone
  hub1_subnets = {
    ("MainSubnet")                    = { address_prefixes = ["10.11.0.0/24", ], address_prefixes_v6 = ["fd00:db8:11::/64", ], }
    ("UntrustSubnet")                 = { address_prefixes = ["10.11.1.0/24", ], address_prefixes_v6 = ["fd00:db8:11:1::/64", ], }
    ("TrustSubnet")                   = { address_prefixes = ["10.11.2.0/24", ], address_prefixes_v6 = ["fd00:db8:11:2::/64", ], }
    ("ManagementSubnet")              = { address_prefixes = ["10.11.3.0/24", ], address_prefixes_v6 = ["fd00:db8:11:3::/64", ], }
    ("AppGatewaySubnet")              = { address_prefixes = ["10.11.4.0/24", ], address_prefixes_v6 = ["fd00:db8:11:4::/64", ], }
    ("LoadBalancerSubnet")            = { address_prefixes = ["10.11.5.0/24", ], address_prefixes_v6 = ["fd00:db8:11:5::/64", ], }
    ("PrivateLinkServiceSubnet")      = { address_prefixes = ["10.11.6.0/24", ], }
    ("PrivateEndpointSubnet")         = { address_prefixes = ["10.11.7.0/24", ], private_endpoint_network_policies = ["Enabled", "RouteTableEnabled", ] }
    ("DnsResolverInboundSubnet")      = { address_prefixes = ["10.11.8.0/24", ], delegate = ["Microsoft.Network/dnsResolvers"] }
    ("DnsResolverOutboundSubnet")     = { address_prefixes = ["10.11.9.0/24", ], delegate = ["Microsoft.Network/dnsResolvers"] }
    ("RouteServerSubnet")             = { address_prefixes = ["10.11.10.0/24", ], address_prefixes_v6 = ["fd00:db8:11:10::/64", ], }
    ("AzureFirewallSubnet")           = { address_prefixes = ["10.11.11.0/24", ], address_prefixes_v6 = ["fd00:db8:11:11::/64", ], }
    ("AzureFirewallManagementSubnet") = { address_prefixes = ["10.11.12.0/24", ], address_prefixes_v6 = ["fd00:db8:11:12::/64", ], }
    ("AppServiceSubnet")              = { address_prefixes = ["10.11.13.0/24", ], address_prefixes_v6 = ["fd00:db8:11:13::/64", ], delegate = ["Microsoft.Web/serverFarms"] }
    ("GatewaySubnet")                 = { address_prefixes = ["10.11.16.0/24", ], address_prefixes_v6 = ["fd00:db8:11:16::/64", ], }
    ("TestSubnet")                    = { address_prefixes = ["10.11.17.0/24", ], address_prefixes_v6 = ["fd00:db8:11:17::/64", ], }
  }
  hub1_default_gw_main      = cidrhost(local.hub1_subnets["MainSubnet"].address_prefixes[0], 1)
  hub1_default_gw_nva       = cidrhost(local.hub1_subnets["TrustSubnet"].address_prefixes[0], 1)
  hub1_vm_addr              = cidrhost(local.hub1_subnets["MainSubnet"].address_prefixes[0], 5)
  hub1_nva_trust_addr       = cidrhost(local.hub1_subnets["TrustSubnet"].address_prefixes[0], 4)
  hub1_nva_untrust_addr     = cidrhost(local.hub1_subnets["UntrustSubnet"].address_prefixes[0], 4)
  hub1_nva_ilb_trust_addr   = cidrhost(local.hub1_subnets["TrustSubnet"].address_prefixes[0], 99)
  hub1_nva_ilb_untrust_addr = cidrhost(local.hub1_subnets["UntrustSubnet"].address_prefixes[0], 99)

  hub1_vm_addr_v6              = cidrhost(local.hub1_subnets["MainSubnet"].address_prefixes_v6[0], 5)
  hub1_nva_trust_addr_v6       = cidrhost(local.hub1_subnets["TrustSubnet"].address_prefixes_v6[0], 4)
  hub1_nva_untrust_addr_v6     = cidrhost(local.hub1_subnets["UntrustSubnet"].address_prefixes_v6[0], 4)
  hub1_nva_ilb_trust_addr_v6   = cidrhost(local.hub1_subnets["TrustSubnet"].address_prefixes_v6[0], 153)
  hub1_nva_ilb_untrust_addr_v6 = cidrhost(local.hub1_subnets["UntrustSubnet"].address_prefixes_v6[0], 153)

  hub1_appgw_addr         = cidrhost(local.hub1_subnets["AppGatewaySubnet"].address_prefixes[0], 99)
  hub1_dns_in_addr        = cidrhost(local.hub1_subnets["DnsResolverInboundSubnet"].address_prefixes[0], 4)
  hub1_vpngw_bgp_ip       = cidrhost(local.hub1_subnets["GatewaySubnet"].address_prefixes[0], 254)
  hub1_spoke3_pls_pep_ip  = cidrhost(local.hub1_subnets["PrivateEndpointSubnet"].address_prefixes[0], 88)
  hub1_spoke3_blob_pep_ip = cidrhost(local.hub1_subnets["PrivateEndpointSubnet"].address_prefixes[0], 99)
  hub1_nva_loopback0      = "10.11.11.11"
  hub1_nva_tun_range0     = "10.11.50.0/30"
  hub1_nva_tun_range1     = "10.11.51.4/30"
  hub1_vpngw_bgp_apipa_0  = cidrhost(local.bgp_apipa_range1, 1)
  hub1_vpngw_bgp_apipa_1  = cidrhost(local.bgp_apipa_range2, 1)
  hub1_vm_hostname        = "hub1Vm"
  hub1_ilb_hostname       = "hub1-ilb"
  hub1_spoke3_pep_host    = "spoke3pls"
  hub1_vm_fqdn            = "${local.hub1_vm_hostname}.${local.hub1_dns_zone}"
  hub1_spoke3_pep_fqdn    = "${local.hub1_spoke3_pep_host}.${local.hub1_dns_zone}"
}

# hub2
#----------------------------

locals {
  hub2_prefix        = local.prefix == "" ? "hub2-" : join("-", [local.prefix, "hub2-"])
  hub2_location      = local.region2
  hub2_address_space = ["10.22.0.0/16", "fd00:db8:22::/56", ]
  hub2_bgp_community = "12076:20022"
  hub2_dns_zone      = local.region2_dns_zone
  hub2_subnets = {
    ("MainSubnet")                    = { address_prefixes = ["10.22.0.0/24", ], address_prefixes_v6 = ["fd00:db8:22::/64", ], }
    ("UntrustSubnet")                 = { address_prefixes = ["10.22.1.0/24", ], address_prefixes_v6 = ["fd00:db8:22:1::/64", ], }
    ("TrustSubnet")                   = { address_prefixes = ["10.22.2.0/24", ], address_prefixes_v6 = ["fd00:db8:22:2::/64", ], }
    ("ManagementSubnet")              = { address_prefixes = ["10.22.3.0/24", ], address_prefixes_v6 = ["fd00:db8:22:3::/64", ], }
    ("AppGatewaySubnet")              = { address_prefixes = ["10.22.4.0/24", ], address_prefixes_v6 = ["fd00:db8:22:4::/64", ], }
    ("LoadBalancerSubnet")            = { address_prefixes = ["10.22.5.0/24", ], address_prefixes_v6 = ["fd00:db8:22:5::/64", ], }
    ("PrivateLinkServiceSubnet")      = { address_prefixes = ["10.22.6.0/24", ], }
    ("PrivateEndpointSubnet")         = { address_prefixes = ["10.22.7.0/24", ], private_endpoint_network_policies = ["RouteTableEnabled", ] }
    ("DnsResolverInboundSubnet")      = { address_prefixes = ["10.22.8.0/24", ], delegate = ["Microsoft.Network/dnsResolvers"] }
    ("DnsResolverOutboundSubnet")     = { address_prefixes = ["10.22.9.0/24", ], delegate = ["Microsoft.Network/dnsResolvers"] }
    ("RouteServerSubnet")             = { address_prefixes = ["10.22.10.0/24", ], address_prefixes_v6 = ["fd00:db8:22:10::/64", ], }
    ("AzureFirewallSubnet")           = { address_prefixes = ["10.22.11.0/24", ], address_prefixes_v6 = ["fd00:db8:22:11::/64", ], }
    ("AzureFirewallManagementSubnet") = { address_prefixes = ["10.22.12.0/24", ], address_prefixes_v6 = ["fd00:db8:22:12::/64", ], }
    ("AppServiceSubnet")              = { address_prefixes = ["10.22.13.0/24", ], address_prefixes_v6 = ["fd00:db8:22:13::/64", ], delegate = ["Microsoft.Web/serverFarms"] }
    ("GatewaySubnet")                 = { address_prefixes = ["10.22.16.0/24", ], address_prefixes_v6 = ["fd00:db8:22:16::/64", ], }
    ("TestSubnet")                    = { address_prefixes = ["10.22.17.0/24", ], address_prefixes_v6 = ["fd00:db8:22:17::/64", ], }
  }
  hub2_default_gw_main      = cidrhost(local.hub2_subnets["MainSubnet"].address_prefixes[0], 1)
  hub2_default_gw_nva       = cidrhost(local.hub2_subnets["TrustSubnet"].address_prefixes[0], 1)
  hub2_vm_addr              = cidrhost(local.hub2_subnets["MainSubnet"].address_prefixes[0], 5)
  hub2_nva_trust_addr       = cidrhost(local.hub2_subnets["TrustSubnet"].address_prefixes[0], 4)
  hub2_nva_untrust_addr     = cidrhost(local.hub2_subnets["UntrustSubnet"].address_prefixes[0], 4)
  hub2_nva_ilb_trust_addr   = cidrhost(local.hub2_subnets["TrustSubnet"].address_prefixes[0], 99)
  hub2_nva_ilb_untrust_addr = cidrhost(local.hub2_subnets["UntrustSubnet"].address_prefixes[0], 99)

  hub2_vm_addr_v6              = cidrhost(local.hub2_subnets["MainSubnet"].address_prefixes_v6[0], 5)
  hub2_nva_trust_addr_v6       = cidrhost(local.hub2_subnets["TrustSubnet"].address_prefixes_v6[0], 4)
  hub2_nva_untrust_addr_v6     = cidrhost(local.hub2_subnets["UntrustSubnet"].address_prefixes_v6[0], 4)
  hub2_nva_ilb_trust_addr_v6   = cidrhost(local.hub2_subnets["TrustSubnet"].address_prefixes_v6[0], 153)
  hub2_nva_ilb_untrust_addr_v6 = cidrhost(local.hub2_subnets["UntrustSubnet"].address_prefixes_v6[0], 153)

  hub2_appgw_addr         = cidrhost(local.hub2_subnets["AppGatewaySubnet"].address_prefixes[0], 99)
  hub2_dns_in_addr        = cidrhost(local.hub2_subnets["DnsResolverInboundSubnet"].address_prefixes[0], 4)
  hub2_vpngw_bgp_ip       = cidrhost(local.hub2_subnets["GatewaySubnet"].address_prefixes[0], 254)
  hub2_spoke6_pls_pep_ip  = cidrhost(local.hub2_subnets["PrivateEndpointSubnet"].address_prefixes[0], 88)
  hub2_spoke6_blob_pep_ip = cidrhost(local.hub2_subnets["PrivateEndpointSubnet"].address_prefixes[0], 99)
  hub2_nva_loopback0      = "10.22.22.22"
  hub2_nva_tun_range0     = "10.22.50.0/30"
  hub2_nva_tun_range1     = "10.22.51.4/30"
  hub2_vpngw_bgp_apipa_0  = cidrhost(local.bgp_apipa_range5, 1)
  hub2_vm_hostname        = "hub2Vm"
  hub2_ilb_hostname       = "hub2-ilb"
  hub2_spoke6_pep_host    = "spoke6pls"
  hub2_vm_fqdn            = "${local.hub2_vm_hostname}.${local.hub2_dns_zone}"
  hub2_spoke6_pep_fqdn    = "${local.hub2_spoke6_pep_host}.${local.hub2_dns_zone}"
}

# branch1
#----------------------------

locals {
  branch1_prefix        = local.prefix == "" ? "branch1-" : join("-", [local.prefix, "branch1-"])
  branch1_location      = local.region1
  branch1_address_space = ["10.10.0.0/16", "fd00:db8:10::/56", ]
  branch1_bgp_community = "12076:20010"
  branch1_nva_asn       = "65001"
  branch1_dns_zone      = local.onprem_domain
  branch1_subnets = {
    ("MainSubnet")        = { address_prefixes = ["10.10.0.0/24", ], address_prefixes_v6 = ["fd00:db8:10::/64"], }
    ("UntrustSubnet")     = { address_prefixes = ["10.10.1.0/24", ], address_prefixes_v6 = ["fd00:db8:10:1::/64"], }
    ("TrustSubnet")       = { address_prefixes = ["10.10.2.0/24", ], address_prefixes_v6 = ["fd00:db8:10:2::/64"], }
    ("ManagementSubnet")  = { address_prefixes = ["10.10.3.0/24", ], address_prefixes_v6 = ["fd00:db8:10:3::/64"], }
    ("DnsServerSubnet")   = { address_prefixes = ["10.10.4.0/24", ], address_prefixes_v6 = ["fd00:db8:10:4::/64"], }
    ("GatewaySubnet")     = { address_prefixes = ["10.10.16.0/24", ], address_prefixes_v6 = ["fd00:db8:10:16::/64"], }
    ("RouteServerSubnet") = { address_prefixes = ["10.10.18.0/24"], }
    ("TestSubnet")        = { address_prefixes = ["10.10.17.0/24", ], address_prefixes_v6 = ["fd00:db8:10:17::/64"], }
  }
  branch1_untrust_default_gw = cidrhost(local.branch1_subnets["UntrustSubnet"].address_prefixes[0], 1)
  branch1_trust_default_gw   = cidrhost(local.branch1_subnets["TrustSubnet"].address_prefixes[0], 1)
  branch1_nva_untrust_addr   = cidrhost(local.branch1_subnets["UntrustSubnet"].address_prefixes[0], 9)
  branch1_nva_trust_addr     = cidrhost(local.branch1_subnets["TrustSubnet"].address_prefixes[0], 9)
  branch1_vm_addr            = cidrhost(local.branch1_subnets["MainSubnet"].address_prefixes[0], 5)
  branch1_dns_addr           = cidrhost(local.branch1_subnets["MainSubnet"].address_prefixes[0], 6)

  branch1_nva_untrust_addr_v6 = cidrhost(local.branch1_subnets["UntrustSubnet"].address_prefixes_v6[0], 9)
  branch1_nva_trust_addr_v6   = cidrhost(local.branch1_subnets["TrustSubnet"].address_prefixes_v6[0], 9)
  branch1_vm_addr_v6          = cidrhost(local.branch1_subnets["MainSubnet"].address_prefixes_v6[0], 5)
  branch1_dns_addr_v6         = cidrhost(local.branch1_subnets["MainSubnet"].address_prefixes_v6[0], 6)

  branch1_nva_loopback0 = "192.168.10.10"
  branch1_bgp_apipa_0   = cidrhost(local.bgp_apipa_range3, 2)
  branch1_bgp_apipa_1   = cidrhost(local.bgp_apipa_range4, 2)
  branch1_vm_hostname   = "branch1Vm"
  branch1_nva_hostname  = "branch1Nva"
  branch1_dns_hostname  = "branch1Dns"
  branch1_vm_fqdn       = "${local.branch1_vm_hostname}.${local.onprem_domain}"
}

# branch2
#----------------------------

locals {
  branch2_prefix        = local.prefix == "" ? "branch2-" : join("-", [local.prefix, "branch2-"])
  branch2_location      = local.region1
  branch2_address_space = ["10.20.0.0/16", "fd00:db8:20::/56", ]
  branch2_bgp_community = "12076:20020"
  branch2_nva_asn       = "65002"
  branch2_dns_zone      = local.onprem_domain
  branch2_subnets = {
    ("MainSubnet")        = { address_prefixes = ["10.20.0.0/24", ], address_prefixes_v6 = ["fd00:db8:20::/64"], }
    ("UntrustSubnet")     = { address_prefixes = ["10.20.1.0/24", ], address_prefixes_v6 = ["fd00:db8:20:1::/64"], }
    ("TrustSubnet")       = { address_prefixes = ["10.20.2.0/24", ], address_prefixes_v6 = ["fd00:db8:20:2::/64"], }
    ("ManagementSubnet")  = { address_prefixes = ["10.20.3.0/24", ], address_prefixes_v6 = ["fd00:db8:20:3::/64"], }
    ("DnsServerSubnet")   = { address_prefixes = ["10.20.4.0/24", ], address_prefixes_v6 = ["fd00:db8:20:4::/64"], }
    ("GatewaySubnet")     = { address_prefixes = ["10.20.16.0/24", ], address_prefixes_v6 = ["fd00:db8:20:16::/64"], }
    ("RouteServerSubnet") = { address_prefixes = ["10.20.17.0/24", ], }
    ("TestSubnet")        = { address_prefixes = ["10.20.18.0/24", ], address_prefixes_v6 = ["fd00:db8:20:18::/64"], }
  }
  branch2_untrust_default_gw = cidrhost(local.branch2_subnets["UntrustSubnet"].address_prefixes[0], 1)
  branch2_trust_default_gw   = cidrhost(local.branch2_subnets["TrustSubnet"].address_prefixes[0], 1)
  branch2_nva_untrust_addr   = cidrhost(local.branch2_subnets["UntrustSubnet"].address_prefixes[0], 9)
  branch2_nva_trust_addr     = cidrhost(local.branch2_subnets["TrustSubnet"].address_prefixes[0], 9)
  branch2_vm_addr            = cidrhost(local.branch2_subnets["MainSubnet"].address_prefixes[0], 5)
  branch2_dns_addr           = cidrhost(local.branch2_subnets["MainSubnet"].address_prefixes[0], 6)

  branch2_nva_untrust_addr_v6 = cidrhost(local.branch2_subnets["UntrustSubnet"].address_prefixes_v6[0], 9)
  branch2_nva_trust_addr_v6   = cidrhost(local.branch2_subnets["TrustSubnet"].address_prefixes_v6[0], 9)
  branch2_vm_addr_v6          = cidrhost(local.branch2_subnets["MainSubnet"].address_prefixes_v6[0], 5)
  branch2_dns_addr_v6         = cidrhost(local.branch2_subnets["MainSubnet"].address_prefixes_v6[0], 6)

  branch2_nva_loopback0  = "192.168.20.20"
  branch2_nva_tun_range0 = "10.20.20.0/30"
  branch2_nva_tun_range1 = "10.20.20.4/30"
  branch2_nva_tun_range2 = "10.20.20.8/30"
  branch2_nva_tun_range3 = "10.20.20.12/30"
  branch2_vm_hostname    = "branch2Vm"
  branch2_nva_hostname   = "branch2Nva"
  branch2_dns_hostname   = "branch2Dns"
  branch2_vm_fqdn        = "${local.branch2_vm_hostname}.${local.onprem_domain}"
}

# branch3
#----------------------------

locals {
  branch3_prefix        = local.prefix == "" ? "branch3-" : join("-", [local.prefix, "branch3-"])
  branch3_location      = local.region2
  branch3_address_space = ["10.30.0.0/16", "fd00:db8:30::/56", ]
  branch3_bgp_community = "12076:20030"
  branch3_nva_asn       = "65003"
  branch3_dns_zone      = local.onprem_domain
  branch3_subnets = {
    ("MainSubnet")        = { address_prefixes = ["10.30.0.0/24", ], address_prefixes_v6 = ["fd00:db8:30::/64"], }
    ("UntrustSubnet")     = { address_prefixes = ["10.30.1.0/24", ], address_prefixes_v6 = ["fd00:db8:30:1::/64"], }
    ("TrustSubnet")       = { address_prefixes = ["10.30.2.0/24", ], address_prefixes_v6 = ["fd00:db8:30:2::/64"], }
    ("ManagementSubnet")  = { address_prefixes = ["10.30.3.0/24", ], address_prefixes_v6 = ["fd00:db8:30:3::/64"], }
    ("DnsServerSubnet")   = { address_prefixes = ["10.30.4.0/24", ], address_prefixes_v6 = ["fd00:db8:30:4::/64"], }
    ("GatewaySubnet")     = { address_prefixes = ["10.30.16.0/24", ], address_prefixes_v6 = ["fd00:db8:30:16::/64"], }
    ("RouteServerSubnet") = { address_prefixes = ["10.30.17.0/24"], }
    ("TestSubnet")        = { address_prefixes = ["10.30.18.0/24", ], address_prefixes_v6 = ["fd00:db8:30:18::/64"], }
  }
  branch3_untrust_default_gw = cidrhost(local.branch3_subnets["UntrustSubnet"].address_prefixes[0], 1)
  branch3_trust_default_gw   = cidrhost(local.branch3_subnets["TrustSubnet"].address_prefixes[0], 1)
  branch3_nva_untrust_addr   = cidrhost(local.branch3_subnets["UntrustSubnet"].address_prefixes[0], 9)
  branch3_nva_trust_addr     = cidrhost(local.branch3_subnets["TrustSubnet"].address_prefixes[0], 9)
  branch3_vm_addr            = cidrhost(local.branch3_subnets["MainSubnet"].address_prefixes[0], 5)
  branch3_dns_addr           = cidrhost(local.branch3_subnets["MainSubnet"].address_prefixes[0], 6)

  branch3_nva_untrust_addr_v6 = cidrhost(local.branch3_subnets["UntrustSubnet"].address_prefixes_v6[0], 9)
  branch3_nva_trust_addr_v6   = cidrhost(local.branch3_subnets["TrustSubnet"].address_prefixes_v6[0], 9)
  branch3_vm_addr_v6          = cidrhost(local.branch3_subnets["MainSubnet"].address_prefixes_v6[0], 5)
  branch3_dns_addr_v6         = cidrhost(local.branch3_subnets["MainSubnet"].address_prefixes_v6[0], 6)

  branch3_nva_loopback0 = "192.168.30.30"
  branch3_bgp_apipa_0   = cidrhost(local.bgp_apipa_range7, 2)
  branch3_bgp_apipa_1   = cidrhost(local.bgp_apipa_range8, 2)
  branch3_vm_hostname   = "branch3Vm"
  branch3_nva_hostname  = "branch3Nva"
  branch3_dns_hostname  = "branch3Dns"
  branch3_vm_fqdn       = "${local.branch3_vm_hostname}.${local.onprem_domain}"
}

# spoke1
#----------------------------

locals {
  spoke1_prefix        = local.prefix == "" ? "spoke1-" : join("-", [local.prefix, "spoke1-"])
  spoke1_location      = local.region1
  spoke1_address_space = ["10.1.0.0/16", "fd00:db8:1::/56", ]
  spoke1_bgp_community = "12076:20001"
  spoke1_dns_zone      = local.region1_dns_zone
  spoke1_subnets = {
    ("MainSubnet")               = { address_prefixes = ["10.1.0.0/24", ], address_prefixes_v6 = ["fd00:db8:1::/64", ] }
    ("UntrustSubnet")            = { address_prefixes = ["10.1.1.0/24", ], address_prefixes_v6 = ["fd00:db8:1:1::/64", ], }
    ("TrustSubnet")              = { address_prefixes = ["10.1.2.0/24", ], address_prefixes_v6 = ["fd00:db8:1:2::/64", ], }
    ("ManagementSubnet")         = { address_prefixes = ["10.1.3.0/24", ], address_prefixes_v6 = ["fd00:db8:1:3::/64", ], }
    ("AppGatewaySubnet")         = { address_prefixes = ["10.1.4.0/24", ], address_prefixes_v6 = ["fd00:db8:1:4::/64", ], }
    ("LoadBalancerSubnet")       = { address_prefixes = ["10.1.5.0/24", ], address_prefixes_v6 = ["fd00:db8:1:5::/64", ], }
    ("PrivateLinkServiceSubnet") = { address_prefixes = ["10.1.6.0/24", ], }
    ("PrivateEndpointSubnet")    = { address_prefixes = ["10.1.7.0/24", ], private_endpoint_network_policies = ["Enabled"] }
    ("AppServiceSubnet")         = { address_prefixes = ["10.1.8.0/24", ], address_prefixes_v6 = ["fd00:db8:1:8::/64", ], delegate = ["Microsoft.Web/serverFarms"] }
    ("GatewaySubnet")            = { address_prefixes = ["10.1.9.0/24", ], address_prefixes_v6 = ["fd00:db8:1:9::/64", ], }
    ("TestSubnet")               = { address_prefixes = ["10.1.10.0/24"], }
  }
  spoke1_vm_addr    = cidrhost(local.spoke1_subnets["MainSubnet"].address_prefixes[0], 5)
  spoke1_ilb_addr   = cidrhost(local.spoke1_subnets["LoadBalancerSubnet"].address_prefixes[0], 99)
  spoke1_appgw_addr = cidrhost(local.spoke1_subnets["AppGatewaySubnet"].address_prefixes[0], 99)

  spoke1_vm_addr_v6    = cidrhost(local.spoke1_subnets["MainSubnet"].address_prefixes_v6[0], 5)
  spoke1_ilb_addr_v6   = cidrhost(local.spoke1_subnets["LoadBalancerSubnet"].address_prefixes_v6[0], 153)
  spoke1_appgw_addr_v6 = cidrhost(local.spoke1_subnets["AppGatewaySubnet"].address_prefixes_v6[0], 153)

  spoke1_pl_nat_addr  = cidrhost(local.spoke1_subnets["MainSubnet"].address_prefixes[0], 50)
  spoke1_vm_hostname  = "spoke1Vm"
  spoke1_ilb_hostname = "spoke1-ilb"
  spoke1_vm_fqdn      = "${local.spoke1_vm_hostname}.${local.spoke1_dns_zone}"
}

# spoke2
#----------------------------

locals {
  spoke2_prefix        = local.prefix == "" ? "spoke2-" : join("-", [local.prefix, "spoke2-"])
  spoke2_location      = local.region1
  spoke2_address_space = ["10.2.0.0/16", "fd00:db8:2::/56", ]
  spoke2_bgp_community = "12076:20002"
  spoke2_dns_zone      = local.region1_dns_zone
  spoke2_subnets = {
    ("MainSubnet")               = { address_prefixes = ["10.2.0.0/24", ], address_prefixes_v6 = ["fd00:db8:2::/64"] }
    ("UntrustSubnet")            = { address_prefixes = ["10.2.1.0/24", ], address_prefixes_v6 = ["fd00:db8:2:1::/64"], }
    ("TrustSubnet")              = { address_prefixes = ["10.2.2.0/24", ], address_prefixes_v6 = ["fd00:db8:2:2::/64"], }
    ("ManagementSubnet")         = { address_prefixes = ["10.2.3.0/24", ], address_prefixes_v6 = ["fd00:db8:2:3::/64"], }
    ("AppGatewaySubnet")         = { address_prefixes = ["10.2.4.0/24", ], address_prefixes_v6 = ["fd00:db8:2:4::/64"], }
    ("LoadBalancerSubnet")       = { address_prefixes = ["10.2.5.0/24", ], address_prefixes_v6 = ["fd00:db8:2:5::/64"], }
    ("PrivateLinkServiceSubnet") = { address_prefixes = ["10.2.6.0/24", ], }
    ("PrivateEndpointSubnet")    = { address_prefixes = ["10.2.7.0/24", ], private_endpoint_network_policies = ["Enabled"] }
    ("AppServiceSubnet")         = { address_prefixes = ["10.2.8.0/24", ], address_prefixes_v6 = ["fd00:db8:2:8::/64"], delegate = ["Microsoft.Web/serverFarms"] }
    ("GatewaySubnet")            = { address_prefixes = ["10.2.9.0/24", ], address_prefixes_v6 = ["fd00:db8:2:9::/64"], }
    ("TestSubnet")               = { address_prefixes = ["10.2.10.0/24"], }
  }
  spoke2_vm_addr    = cidrhost(local.spoke2_subnets["MainSubnet"].address_prefixes[0], 5)
  spoke2_ilb_addr   = cidrhost(local.spoke2_subnets["LoadBalancerSubnet"].address_prefixes[0], 99)
  spoke2_appgw_addr = cidrhost(local.spoke2_subnets["AppGatewaySubnet"].address_prefixes[0], 99)

  spoke2_vm_addr_v6    = cidrhost(local.spoke2_subnets["MainSubnet"].address_prefixes_v6[0], 5)
  spoke2_ilb_addr_v6   = cidrhost(local.spoke2_subnets["LoadBalancerSubnet"].address_prefixes_v6[0], 153)
  spoke2_appgw_addr_v6 = cidrhost(local.spoke2_subnets["AppGatewaySubnet"].address_prefixes_v6[0], 153)

  spoke2_pl_nat_addr  = cidrhost(local.spoke2_subnets["MainSubnet"].address_prefixes[0], 50)
  spoke2_vm_hostname  = "spoke2Vm"
  spoke2_ilb_hostname = "spoke2-ilb"
  spoke2_vm_fqdn      = "${local.spoke2_vm_hostname}.${local.spoke2_dns_zone}"
}

# spoke3
#----------------------------

locals {
  spoke3_prefix        = local.prefix == "" ? "spoke3-" : join("-", [local.prefix, "spoke3-"])
  spoke3_location      = local.region1
  spoke3_address_space = ["10.3.0.0/16", "fd00:db8:3::/56", ]
  spoke3_bgp_community = "12076:20003"
  spoke3_dns_zone      = local.region1_dns_zone
  spoke3_subnets = {
    ("MainSubnet")               = { address_prefixes = ["10.3.0.0/24", ], address_prefixes_v6 = ["fd00:db8:3::/64"], }
    ("UntrustSubnet")            = { address_prefixes = ["10.3.1.0/24", ], address_prefixes_v6 = ["fd00:db8:3:1::/64"], }
    ("TrustSubnet")              = { address_prefixes = ["10.3.2.0/24", ], address_prefixes_v6 = ["fd00:db8:3:2::/64"], }
    ("ManagementSubnet")         = { address_prefixes = ["10.3.3.0/24", ], address_prefixes_v6 = ["fd00:db8:3:3::/64"], }
    ("AppGatewaySubnet")         = { address_prefixes = ["10.3.4.0/24", ], address_prefixes_v6 = ["fd00:db8:3:4::/64"], }
    ("LoadBalancerSubnet")       = { address_prefixes = ["10.3.5.0/24", ], address_prefixes_v6 = ["fd00:db8:3:5::/64"], }
    ("PrivateLinkServiceSubnet") = { address_prefixes = ["10.3.6.0/24", ], }
    ("PrivateEndpointSubnet")    = { address_prefixes = ["10.3.7.0/24", ], private_endpoint_network_policies = ["Enabled"] }
    ("AppServiceSubnet")         = { address_prefixes = ["10.3.8.0/24", ], address_prefixes_v6 = ["fd00:db8:3:8::/64"], delegate = ["Microsoft.Web/serverFarms"] }
    ("GatewaySubnet")            = { address_prefixes = ["10.3.9.0/24", ], address_prefixes_v6 = ["fd00:db8:3:9::/64"], }
    ("TestSubnet")               = { address_prefixes = ["10.3.10.0/24", ], address_prefixes_v6 = ["fd00:db8:3:10::/64"], use_azapi = [true], default_outbound_access = [false] }
  }
  spoke3_vm_addr    = cidrhost(local.spoke3_subnets["MainSubnet"].address_prefixes[0], 5)
  spoke3_ilb_addr   = cidrhost(local.spoke3_subnets["LoadBalancerSubnet"].address_prefixes[0], 99)
  spoke3_appgw_addr = cidrhost(local.spoke3_subnets["AppGatewaySubnet"].address_prefixes[0], 99)

  spoke3_vm_addr_v6    = cidrhost(local.spoke3_subnets["MainSubnet"].address_prefixes_v6[0], 5)
  spoke3_ilb_addr_v6   = cidrhost(local.spoke3_subnets["LoadBalancerSubnet"].address_prefixes_v6[0], 153)
  spoke3_appgw_addr_v6 = cidrhost(local.spoke3_subnets["AppGatewaySubnet"].address_prefixes_v6[0], 153)

  spoke3_pl_nat_addr  = cidrhost(local.spoke3_subnets["MainSubnet"].address_prefixes[0], 50)
  spoke3_vm_hostname  = "spoke3Vm"
  spoke3_ilb_hostname = "spoke3-ilb"
  spoke3_vm_fqdn      = "${local.spoke3_vm_hostname}.${local.spoke3_dns_zone}"
}

# spoke4
#----------------------------

locals {
  spoke4_prefix        = local.prefix == "" ? "spoke4-" : join("-", [local.prefix, "spoke4-"])
  spoke4_location      = local.region2
  spoke4_address_space = ["10.4.0.0/16", "fd00:db8:4::/56", ]
  spoke4_bgp_community = "12076:20004"
  spoke4_dns_zone      = local.region2_dns_zone
  spoke4_subnets = {
    ("MainSubnet")               = { address_prefixes = ["10.4.0.0/24", ], address_prefixes_v6 = ["fd00:db8:4::/64"], }
    ("UntrustSubnet")            = { address_prefixes = ["10.4.1.0/24", ], address_prefixes_v6 = ["fd00:db8:4:1::/64"], }
    ("TrustSubnet")              = { address_prefixes = ["10.4.2.0/24", ], address_prefixes_v6 = ["fd00:db8:4:2::/64"], }
    ("ManagementSubnet")         = { address_prefixes = ["10.4.3.0/24", ], address_prefixes_v6 = ["fd00:db8:4:3::/64"], }
    ("AppGatewaySubnet")         = { address_prefixes = ["10.4.4.0/24", ], address_prefixes_v6 = ["fd00:db8:4:4::/64"], }
    ("LoadBalancerSubnet")       = { address_prefixes = ["10.4.5.0/24", ], address_prefixes_v6 = ["fd00:db8:4:5::/64"], }
    ("PrivateLinkServiceSubnet") = { address_prefixes = ["10.4.6.0/24", ], }
    ("PrivateEndpointSubnet")    = { address_prefixes = ["10.4.7.0/24", ], private_endpoint_network_policies = ["Enabled"] }
    ("AppServiceSubnet")         = { address_prefixes = ["10.4.8.0/24", ], address_prefixes_v6 = ["fd00:db8:4:8::/64"], delegate = ["Microsoft.Web/serverFarms"] }
    ("GatewaySubnet")            = { address_prefixes = ["10.4.9.0/24", ], address_prefixes_v6 = ["fd00:db8:4:9::/64"], }
    ("TestSubnet")               = { address_prefixes = ["10.4.10.0/24"], }
  }
  spoke4_vm_addr    = cidrhost(local.spoke4_subnets["MainSubnet"].address_prefixes[0], 5)
  spoke4_ilb_addr   = cidrhost(local.spoke4_subnets["LoadBalancerSubnet"].address_prefixes[0], 99)
  spoke4_appgw_addr = cidrhost(local.spoke4_subnets["AppGatewaySubnet"].address_prefixes[0], 99)

  spoke4_vm_addr_v6    = cidrhost(local.spoke4_subnets["MainSubnet"].address_prefixes_v6[0], 5)
  spoke4_ilb_addr_v6   = cidrhost(local.spoke4_subnets["LoadBalancerSubnet"].address_prefixes_v6[0], 153)
  spoke4_appgw_addr_v6 = cidrhost(local.spoke4_subnets["AppGatewaySubnet"].address_prefixes_v6[0], 153)

  spoke4_pl_nat_addr  = cidrhost(local.spoke4_subnets["MainSubnet"].address_prefixes[0], 50)
  spoke4_vm_hostname  = "spoke4Vm"
  spoke4_ilb_hostname = "spoke4-ilb"
  spoke4_vm_fqdn      = "${local.spoke4_vm_hostname}.${local.spoke4_dns_zone}"
}

# spoke5
#----------------------------

locals {
  spoke5_prefix        = local.prefix == "" ? "spoke5-" : join("-", [local.prefix, "spoke5-"])
  spoke5_location      = local.region2
  spoke5_address_space = ["10.5.0.0/16", "fd00:db8:5::/56", ]
  spoke5_bgp_community = "12076:20005"
  spoke5_dns_zone      = local.region2_dns_zone
  spoke5_subnets = {
    ("MainSubnet")               = { address_prefixes = ["10.5.0.0/24", ], address_prefixes_v6 = ["fd00:db8:5::/64"], }
    ("UntrustSubnet")            = { address_prefixes = ["10.5.1.0/24", ], address_prefixes_v6 = ["fd00:db8:5:1::/64"], }
    ("TrustSubnet")              = { address_prefixes = ["10.5.2.0/24", ], address_prefixes_v6 = ["fd00:db8:5:2::/64"], }
    ("ManagementSubnet")         = { address_prefixes = ["10.5.3.0/24", ], address_prefixes_v6 = ["fd00:db8:5:3::/64"], }
    ("AppGatewaySubnet")         = { address_prefixes = ["10.5.4.0/24", ], address_prefixes_v6 = ["fd00:db8:5:4::/64"], }
    ("LoadBalancerSubnet")       = { address_prefixes = ["10.5.5.0/24", ], address_prefixes_v6 = ["fd00:db8:5:5::/64"], }
    ("PrivateLinkServiceSubnet") = { address_prefixes = ["10.5.6.0/24", ], }
    ("PrivateEndpointSubnet")    = { address_prefixes = ["10.5.7.0/24", ], private_endpoint_network_policies = ["Enabled"] }
    ("AppServiceSubnet")         = { address_prefixes = ["10.5.8.0/24", ], address_prefixes_v6 = ["fd00:db8:5:8::/64"], delegate = ["Microsoft.Web/serverFarms"] }
    ("GatewaySubnet")            = { address_prefixes = ["10.5.9.0/24", ], address_prefixes_v6 = ["fd00:db8:5:9::/64"], }
    ("TestSubnet")               = { address_prefixes = ["10.5.10.0/24"], }
  }
  spoke5_vm_addr    = cidrhost(local.spoke5_subnets["MainSubnet"].address_prefixes[0], 5)
  spoke5_ilb_addr   = cidrhost(local.spoke5_subnets["LoadBalancerSubnet"].address_prefixes[0], 99)
  spoke5_appgw_addr = cidrhost(local.spoke5_subnets["AppGatewaySubnet"].address_prefixes[0], 99)

  spoke5_vm_addr_v6    = cidrhost(local.spoke5_subnets["MainSubnet"].address_prefixes_v6[0], 5)
  spoke5_ilb_addr_v6   = cidrhost(local.spoke5_subnets["LoadBalancerSubnet"].address_prefixes_v6[0], 153)
  spoke5_appgw_addr_v6 = cidrhost(local.spoke5_subnets["AppGatewaySubnet"].address_prefixes_v6[0], 153)

  spoke5_pl_nat_addr  = cidrhost(local.spoke5_subnets["MainSubnet"].address_prefixes[0], 50)
  spoke5_vm_hostname  = "spoke5Vm"
  spoke5_ilb_hostname = "spoke5-ilb"
  spoke5_vm_fqdn      = "${local.spoke5_vm_hostname}.${local.spoke5_dns_zone}"
}

# spoke6
#----------------------------

locals {
  spoke6_prefix        = local.prefix == "" ? "spoke6-" : join("-", [local.prefix, "spoke6-"])
  spoke6_location      = local.region2
  spoke6_address_space = ["10.6.0.0/16", "fd00:db8:6::/56", ]
  spoke6_bgp_community = "12076:20006"
  spoke6_dns_zone      = local.region2_dns_zone
  spoke6_subnets = {
    ("MainSubnet")               = { address_prefixes = ["10.6.0.0/24", ], address_prefixes_v6 = ["fd00:db8:6::/64"], }
    ("UntrustSubnet")            = { address_prefixes = ["10.6.1.0/24", ], address_prefixes_v6 = ["fd00:db8:6:1::/64"], }
    ("TrustSubnet")              = { address_prefixes = ["10.6.2.0/24", ], address_prefixes_v6 = ["fd00:db8:6:2::/64"], }
    ("ManagementSubnet")         = { address_prefixes = ["10.6.3.0/24", ], address_prefixes_v6 = ["fd00:db8:6:3::/64"], }
    ("AppGatewaySubnet")         = { address_prefixes = ["10.6.4.0/24", ], address_prefixes_v6 = ["fd00:db8:6:4::/64"], }
    ("LoadBalancerSubnet")       = { address_prefixes = ["10.6.5.0/24", ], address_prefixes_v6 = ["fd00:db8:6:5::/64"], }
    ("PrivateLinkServiceSubnet") = { address_prefixes = ["10.6.6.0/24", ], }
    ("PrivateEndpointSubnet")    = { address_prefixes = ["10.6.7.0/24", ], private_endpoint_network_policies = ["Enabled"] }
    ("AppServiceSubnet")         = { address_prefixes = ["10.6.8.0/24", ], address_prefixes_v6 = ["fd00:db8:6:8::/64"], delegate = ["Microsoft.Web/serverFarms"] }
    ("GatewaySubnet")            = { address_prefixes = ["10.6.9.0/24", ], address_prefixes_v6 = ["fd00:db8:6:9::/64"], }
    ("TestSubnet")               = { address_prefixes = ["10.6.10.0/24", ], address_prefixes_v6 = ["fd00:db8:6:10::/64"], use_azapi = [true], default_outbound_access = [false] }
  }
  spoke6_vm_addr    = cidrhost(local.spoke6_subnets["MainSubnet"].address_prefixes[0], 5)
  spoke6_ilb_addr   = cidrhost(local.spoke6_subnets["LoadBalancerSubnet"].address_prefixes[0], 99)
  spoke6_appgw_addr = cidrhost(local.spoke6_subnets["AppGatewaySubnet"].address_prefixes[0], 99)

  spoke6_vm_addr_v6    = cidrhost(local.spoke6_subnets["MainSubnet"].address_prefixes_v6[0], 5)
  spoke6_ilb_addr_v6   = cidrhost(local.spoke6_subnets["LoadBalancerSubnet"].address_prefixes_v6[0], 153)
  spoke6_appgw_addr_v6 = cidrhost(local.spoke6_subnets["AppGatewaySubnet"].address_prefixes_v6[0], 153)

  spoke6_pl_nat_addr  = cidrhost(local.spoke6_subnets["MainSubnet"].address_prefixes[0], 50)
  spoke6_vm_hostname  = "spoke6Vm"
  spoke6_ilb_hostname = "spoke6-ilb"
  spoke6_vm_fqdn      = "${local.spoke6_vm_hostname}.${local.spoke6_dns_zone}"
}


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

  vti_range0 = "10.10.10.0/30"
  vti_range1 = "10.10.10.4/30"
  vti_range2 = "10.10.10.8/30"
  vti_range3 = "10.10.10.12/30"

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
  private_prefixes_map = { for i, prefix in local.private_prefixes : i => prefix }
}

# hub1
#----------------------------

locals {
  hub1_prefix        = local.prefix == "" ? "hub1-" : join("-", [local.prefix, "hub1-"])
  hub1_location      = local.region1
  hub1_address_space = ["10.11.0.0/20", "10.11.16.0/20"]
  hub1_nat_ranges = {
    "branch1" = {
      "egress-static"  = "10.11.90.0/24"
      "egress-dynamic" = "10.11.91.0/24"
      "ingress-static" = "10.11.80.0/24"
    }
  }
  hub1_dns_zone = local.region1_dns_zone
  hub1_subnets = {
    ("MainSubnet")                    = { address_prefixes = ["10.11.0.0/24", ] }
    ("UntrustSubnet")                 = { address_prefixes = ["10.11.1.0/24", ] }
    ("TrustSubnet")                   = { address_prefixes = ["10.11.2.0/24", ] }
    ("ManagementSubnet")              = { address_prefixes = ["10.11.3.0/24", ] }
    ("AppGatewaySubnet")              = { address_prefixes = ["10.11.4.0/24", ] }
    ("LoadBalancerSubnet")            = { address_prefixes = ["10.11.5.0/24", ] }
    ("PrivateLinkServiceSubnet")      = { address_prefixes = ["10.11.6.0/24", ], private_link_service_network_policies_enabled = [true] }
    ("PrivateEndpointSubnet")         = { address_prefixes = ["10.11.7.0/24", ], private_endpoint_network_policies = ["Enabled", ] }
    ("DnsResolverInboundSubnet")      = { address_prefixes = ["10.11.8.0/24"], delegate = ["Microsoft.Network/dnsResolvers", ] }
    ("DnsResolverOutboundSubnet")     = { address_prefixes = ["10.11.9.0/24"], delegate = ["Microsoft.Network/dnsResolvers", ] }
    ("RouteServerSubnet")             = { address_prefixes = ["10.11.10.0/24", ] }
    ("AzureFirewallSubnet")           = { address_prefixes = ["10.11.11.0/24", ] }
    ("AzureFirewallManagementSubnet") = { address_prefixes = ["10.11.12.0/24", ] }
    ("AppServiceSubnet")              = { address_prefixes = ["10.11.13.0/24"], delegate = ["Microsoft.Web/serverFarms", ] }
    ("GatewaySubnet")                 = { address_prefixes = ["10.11.16.0/24", ] }
  }
  hub1_default_gw_main = cidrhost(local.hub1_subnets["MainSubnet"].address_prefixes[0], 1)
  hub1_default_gw_nva  = cidrhost(local.hub1_subnets["TrustSubnet"].address_prefixes[0], 1)
  hub1_good_addr       = cidrhost(local.hub1_subnets["MainSubnet"].address_prefixes[0], 4)
  hub1_bad_addr        = cidrhost(local.hub1_subnets["MainSubnet"].address_prefixes[0], 5)
  hub1_appgw_addr      = cidrhost(local.hub1_subnets["AppGatewaySubnet"].address_prefixes[0], 99)
}

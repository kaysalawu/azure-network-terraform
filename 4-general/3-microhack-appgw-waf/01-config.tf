
# Common

#----------------------------
locals {
  username = "azureuser"
  password = "Password123"
  psk      = "changeme"

  default_region = "eastus"
  onprem_domain  = "corp"
  cloud_domain   = "az.corp"
  azuredns       = "168.63.129.16"
  private_prefixes = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16",
    "100.64.0.0/10",
  ]
  private_prefixes_map = { for i, v in local.private_prefixes : i => v }
}

# hub1
#----------------------------

locals {
  hub1_prefix        = local.prefix == "" ? "hub1-" : join("-", [local.prefix, "hub1-"])
  hub1_location      = local.region1
  hub1_address_space = ["10.11.0.0/16", ]
  hub1_dns_zone      = "hub1.we.${local.cloud_domain}"
  hub1_tags          = { "nodeType" = "hub" }
  hub1_subnets = {
    ("MainSubnet")                    = { address_prefixes = ["10.11.0.0/24"] }
    ("TrustSubnet")                   = { address_prefixes = ["10.11.1.0/24"] }
    ("UntrustSubnet")                 = { address_prefixes = ["10.11.2.0/24"] }
    ("ManagementSubnet")              = { address_prefixes = ["10.11.3.0/24"] }
    ("AppGatewaySubnet")              = { address_prefixes = ["10.11.4.0/24"] }
    ("LoadBalancerSubnet")            = { address_prefixes = ["10.11.5.0/24"] }
    ("PrivateLinkServiceSubnet")      = { address_prefixes = ["10.11.6.0/24"], enable_private_link_policies = [true] }
    ("PrivateEndpointSubnet")         = { address_prefixes = ["10.11.7.0/24"], enable_private_endpoint_policies = [true] }
    ("DnsResolverInboundSubnet")      = { address_prefixes = ["10.11.8.0/24"], delegate = ["Microsoft.Network/dnsResolvers"] }
    ("DnsResolverOutboundSubnet")     = { address_prefixes = ["10.11.9.0/24"], delegate = ["Microsoft.Network/dnsResolvers"] }
    ("GatewaySubnet")                 = { address_prefixes = ["10.11.10.0/24"] }
    ("RouteServerSubnet")             = { address_prefixes = ["10.11.11.0/24"] }
    ("AzureFirewallSubnet")           = { address_prefixes = ["10.11.12.0/24"] }
    ("AzureFirewallManagementSubnet") = { address_prefixes = ["10.11.13.0/24"] }
    ("AppServiceSubnet")              = { address_prefixes = ["10.11.14.0/24"], delegate = ["Microsoft.Web/serverFarms"] }
  }
  hub1_appgw_addr = cidrhost(local.hub1_subnets["AppGatewaySubnet"].address_prefixes[0], 99)
}

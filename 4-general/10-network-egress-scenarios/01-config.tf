
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

  service_endpoints = local.enable_service_endpoints ? [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    # "Microsoft.Sql",
    # "Microsoft.ServiceBus",
    # "Microsoft.EventHub",
    # "Microsoft.AzureActiveDirectory",
    # "Microsoft.Web",
    # "Microsoft.CognitiveServices",
    # "Microsoft.ContainerRegistry",
  ] : []
}

# hub
#----------------------------

locals {
  hub_prefix        = local.prefix == "" ? "hub-" : join("-", [local.prefix, "hub-"])
  hub_location      = local.region1
  hub_address_space = ["10.0.0.0/21"]
  hub_dns_zone      = local.region1_dns_zone
  hub_subnets = {
    ("GatewaySubnet")    = { address_prefixes = ["10.0.0.0/24"], default_outbound_access = [true] }
    ("AppGatewaySubnet") = { address_prefixes = ["10.0.1.0/24"], service_endpoints = local.service_endpoints, default_outbound_access = [true] }
    ("PublicSubnet")     = { address_prefixes = ["10.0.2.0/24"], service_endpoints = local.service_endpoints, default_outbound_access = [true] }
    ("ProductionSubnet") = { address_prefixes = ["10.0.3.0/24"], service_endpoints = local.service_endpoints, default_outbound_access = [false], use_azapi = [true] }
  }
  hub_proxy_addr       = cidrhost(local.hub_subnets["PublicSubnet"].address_prefixes[0], 4)
  hub_server1_addr     = cidrhost(local.hub_subnets["ProductionSubnet"].address_prefixes[0], 4)
  hub_server2_addr     = cidrhost(local.hub_subnets["ProductionSubnet"].address_prefixes[0], 5)
  hub_proxy_hostname   = "Proxy"
  hub_server1_hostname = "Server1"
  hub_server2_hostname = "Server2"
  hub_proxy_fqdn       = "${local.hub_proxy_hostname}.${local.hub_dns_zone}"
  hub_server1_fqdn     = "${local.hub_server1_hostname}.${local.hub_dns_zone}"
  hub_server2_fqdn     = "${local.hub_server2_hostname}.${local.hub_dns_zone}"
}

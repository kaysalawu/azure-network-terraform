
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
    "Microsoft.Sql",
    "Microsoft.KeyVault",
    "Microsoft.ServiceBus",
    "Microsoft.EventHub",
    "Microsoft.AzureActiveDirectory",
    "Microsoft.Web",
    "Microsoft.CognitiveServices",
    "Microsoft.ContainerRegistry",
  ] : []
}

# ecs
#----------------------------

locals {
  ecs_prefix        = local.prefix == "" ? "ecs-" : join("-", [local.prefix, "ecs-"])
  ecs_location      = local.region1
  ecs_address_space = ["10.0.0.0/21"]
  ecs_dns_zone      = "corp.sap.com"
  ecs_subnets = {
    ("GatewaySubnet")    = { address_prefixes = ["10.0.0.0/24"] }
    ("AppGatewaySubnet") = { address_prefixes = ["10.0.1.0/24"], service_endpoints = local.service_endpoints }
    ("PublicSubnet")     = { address_prefixes = ["10.0.2.0/24"], service_endpoints = local.service_endpoints }
    ("ProductionSubnet") = { address_prefixes = ["10.0.3.0/24"], service_endpoints = local.service_endpoints }
    ("UntrustSubnet")    = { address_prefixes = ["10.0.4.0/24"] }
  }
  # untrust (management)
  ecs_default_gw_untrust    = cidrhost(local.ecs_subnets["UntrustSubnet"].address_prefixes[0], 1)
  ecs_webd1_untrust_addr    = cidrhost(local.ecs_subnets["UntrustSubnet"].address_prefixes[0], 4)
  ecs_webd2_untrust_addr    = cidrhost(local.ecs_subnets["UntrustSubnet"].address_prefixes[0], 5)
  ecs_webd_ilb_untrust_addr = cidrhost(local.ecs_subnets["UntrustSubnet"].address_prefixes[0], 99)

  # production
  ecs_default_gw_prod  = cidrhost(local.ecs_subnets["ProductionSubnet"].address_prefixes[0], 1)
  ecs_webd1_addr       = cidrhost(local.ecs_subnets["ProductionSubnet"].address_prefixes[0], 4)
  ecs_webd2_addr       = cidrhost(local.ecs_subnets["ProductionSubnet"].address_prefixes[0], 5)
  ecs_appsrv1_addr     = cidrhost(local.ecs_subnets["ProductionSubnet"].address_prefixes[0], 6)
  ecs_appsrv2_addr     = cidrhost(local.ecs_subnets["ProductionSubnet"].address_prefixes[0], 7)
  ecs_cgs_addr         = cidrhost(local.ecs_subnets["ProductionSubnet"].address_prefixes[0], 8)
  ecs_webd_ilb_addr    = cidrhost(local.ecs_subnets["ProductionSubnet"].address_prefixes[0], 99)
  ecs_webd1_hostname   = "Webd1"
  ecs_webd2_hostname   = "Webd2"
  ecs_appsrv1_hostname = "AppSrv1"
  ecs_appsrv2_hostname = "AppSrv2"
  ecs_cgs_hostname     = "EcsCgs"
  ecs_ilb_hostname     = "ilb"
  ecs_test_hostname    = "Test"
  ecs_webd1_fqdn       = "${local.ecs_webd1_hostname}.${local.ecs_dns_zone}"
  ecs_webd2_fqdn       = "${local.ecs_webd2_hostname}.${local.ecs_dns_zone}"
  ecs_appsrv1_fqdn     = "${local.ecs_appsrv1_hostname}.${local.ecs_dns_zone}"
  ecs_appsrv2_fqdn     = "${local.ecs_appsrv2_hostname}.${local.ecs_dns_zone}"
  ecs_cgs_fqdn         = "${local.ecs_cgs_hostname}.${local.ecs_dns_zone}"
  ecs_webd_ilb_fqdn    = "${local.ecs_ilb_hostname}.${local.ecs_dns_zone}"
  ecs_test_fqdn        = "${local.ecs_test_hostname}.${local.ecs_dns_zone}"
}

# onprem
#----------------------------

locals {
  onprem_prefix        = local.prefix == "" ? "onprem-" : join("-", [local.prefix, "onprem-"])
  onprem_location      = local.region1
  onprem_address_space = ["10.10.0.0/20", "10.10.16.0/20", ]
  onprem_nva_asn       = "65001"
  onprem_dns_zone      = local.onprem_domain
  onprem_subnets = {
    ("MainSubnet")       = { address_prefixes = ["10.10.0.0/24"] }
    ("UntrustSubnet")    = { address_prefixes = ["10.10.1.0/24"] }
    ("TrustSubnet")      = { address_prefixes = ["10.10.2.0/24"] }
    ("ManagementSubnet") = { address_prefixes = ["10.10.3.0/24"] }
    ("DnsServerSubnet")  = { address_prefixes = ["10.10.4.0/24"] }
    ("GatewaySubnet")    = { address_prefixes = ["10.10.16.0/24"] }
  }
  onprem_untrust_default_gw = cidrhost(local.onprem_subnets["UntrustSubnet"].address_prefixes[0], 1)
  onprem_trust_default_gw   = cidrhost(local.onprem_subnets["TrustSubnet"].address_prefixes[0], 1)
  onprem_nva_untrust_addr   = cidrhost(local.onprem_subnets["UntrustSubnet"].address_prefixes[0], 9)
  onprem_nva_trust_addr     = cidrhost(local.onprem_subnets["TrustSubnet"].address_prefixes[0], 9)
  onprem_vm_addr            = cidrhost(local.onprem_subnets["MainSubnet"].address_prefixes[0], 5)
  onprem_dns_addr           = cidrhost(local.onprem_subnets["MainSubnet"].address_prefixes[0], 6)
  onprem_nva_loopback0      = "192.168.10.10"
  onprem_bgp_apipa_0        = cidrhost(local.bgp_apipa_range3, 2)
  onprem_bgp_apipa_1        = cidrhost(local.bgp_apipa_range4, 2)
  onprem_vm_hostname        = "onpremVm"
  onprem_nva_hostname       = "onpremNva"
  onprem_dns_hostname       = "onpremDns"
  onprem_vm_fqdn            = "${local.onprem_vm_hostname}.${local.onprem_domain}"
}

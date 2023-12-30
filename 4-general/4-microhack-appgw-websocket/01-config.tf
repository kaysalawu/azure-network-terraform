
# Common

#----------------------------
locals {
  username       = "azureuser"
  password       = "Password123"
  psk            = "changeme"
  default_region = "eastus"
  private_prefixes = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16",
    "100.64.0.0/10",
  ]
}

# hub1
#----------------------------

locals {
  hub1_prefix        = local.prefix == "" ? "hub1-" : join("-", [local.prefix, "hub1-"])
  hub1_location      = local.region1
  hub1_address_space = ["10.11.0.0/16", ]
  hub1_tags          = { "nodeType" = "hub" }
  hub1_subnets = {
    ("MainSubnet")         = { address_prefixes = ["10.11.0.0/24"] }
    ("AppGatewaySubnet")   = { address_prefixes = ["10.11.4.0/24"] }
    ("LoadBalancerSubnet") = { address_prefixes = ["10.11.5.0/24"] }
  }
  hub1_appgw_addr = cidrhost(local.hub1_subnets["AppGatewaySubnet"].address_prefixes[0], 99)
}

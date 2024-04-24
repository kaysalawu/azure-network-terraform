
####################################################
# region1
####################################################

# mesh1

module "mesh1" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = "${local.prefix}-mesh1"
  location        = local.region1
  storage_account = module.common.storage_accounts["region1"]
  tags            = { "lab" = local.prefix, "env" = "prod", "nodeType" = "float" }

  nsg_subnet_map = {
    "MainSubnet"      = module.common.nsg_main["region1"].id
    "UntrustSubnet"   = module.common.nsg_nva["region1"].id
    "TrustSubnet"     = module.common.nsg_main["region1"].id
    "DnsServerSubnet" = module.common.nsg_main["region1"].id
    "TestSubnet"      = module.common.nsg_main["region1"].id
  }

  config_vnet = {
    address_space = ["10.51.0.0/20", ]
    subnets = {
      ("MainSubnet")      = { address_prefixes = ["10.51.0.0/24", ] }
      ("UntrustSubnet")   = { address_prefixes = ["10.51.1.0/24", ] }
      ("TrustSubnet")     = { address_prefixes = ["10.51.2.0/24", ] }
      ("DnsServerSubnet") = { address_prefixes = ["10.51.3.0/24", ] }
      ("TestSubnet")      = { address_prefixes = ["10.51.4.0/24", ] }
    }
    nat_gateway_subnet_names = [
      "MainSubnet",
      "TrustSubnet",
      "DnsServerSubnet",
      "TestSubnet",
    ]
  }

  depends_on = [
    module.common,
  ]
}

# mesh shared region1

module "mesh_shared1" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = "${local.prefix}-mesh-shared1"
  location        = local.region1
  storage_account = module.common.storage_accounts["region1"]
  tags            = { "lab" = local.prefix, "env" = "prod", "nodeType" = "float" }

  nsg_subnet_map = {
    "MainSubnet"      = module.common.nsg_main["region1"].id
    "UntrustSubnet"   = module.common.nsg_nva["region1"].id
    "TrustSubnet"     = module.common.nsg_main["region1"].id
    "DnsServerSubnet" = module.common.nsg_main["region1"].id
    "TestSubnet"      = module.common.nsg_main["region1"].id
  }

  config_vnet = {
    address_space = ["10.53.0.0/20", ]
    subnets = {
      ("MainSubnet")      = { address_prefixes = ["10.53.0.0/24", ] }
      ("UntrustSubnet")   = { address_prefixes = ["10.53.1.0/24", ] }
      ("TrustSubnet")     = { address_prefixes = ["10.53.2.0/24", ] }
      ("DnsServerSubnet") = { address_prefixes = ["10.53.3.0/24", ] }
      ("TestSubnet")      = { address_prefixes = ["10.53.4.0/24", ] }
    }
    nat_gateway_subnet_names = [
      "MainSubnet",
      "TrustSubnet",
      "DnsServerSubnet",
      "TestSubnet",
    ]
  }

  depends_on = [
    module.common,
  ]
}

####################################################
# region2
####################################################

# mesh2

module "mesh2" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = "${local.prefix}-mesh2"
  location        = local.region2
  storage_account = module.common.storage_accounts["region2"]
  tags            = { "lab" = local.prefix, "env" = "prod", "nodeType" = "float" }

  nsg_subnet_map = {
    "MainSubnet"      = module.common.nsg_main["region2"].id
    "UntrustSubnet"   = module.common.nsg_nva["region2"].id
    "TrustSubnet"     = module.common.nsg_main["region2"].id
    "DnsServerSubnet" = module.common.nsg_main["region2"].id
    "TestSubnet"      = module.common.nsg_main["region2"].id
  }

  config_vnet = {
    address_space = ["10.52.0.0/20", ]
    subnets = {
      ("MainSubnet")      = { address_prefixes = ["10.52.0.0/24", ] }
      ("UntrustSubnet")   = { address_prefixes = ["10.52.1.0/24", ] }
      ("TrustSubnet")     = { address_prefixes = ["10.52.2.0/24", ] }
      ("DnsServerSubnet") = { address_prefixes = ["10.52.3.0/24", ] }
      ("TestSubnet")      = { address_prefixes = ["10.52.4.0/24", ] }
    }
    nat_gateway_subnet_names = [
      "MainSubnet",
      "TrustSubnet",
      "DnsServerSubnet",
      "TestSubnet",
    ]
  }

  depends_on = [
    module.common,
  ]
}

# mesh shared region2

module "mesh_shared2" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = "${local.prefix}-mesh-shared2"
  location        = local.region2
  storage_account = module.common.storage_accounts["region2"]
  tags            = { "lab" = local.prefix, "env" = "prod", "nodeType" = "float" }

  nsg_subnet_map = {
    "MainSubnet"      = module.common.nsg_main["region2"].id
    "UntrustSubnet"   = module.common.nsg_nva["region2"].id
    "TrustSubnet"     = module.common.nsg_main["region2"].id
    "DnsServerSubnet" = module.common.nsg_main["region2"].id
    "TestSubnet"      = module.common.nsg_main["region2"].id
  }

  config_vnet = {
    address_space = ["10.54.0.0/20", ]
    subnets = {
      ("MainSubnet")      = { address_prefixes = ["10.54.0.0/24", ] }
      ("UntrustSubnet")   = { address_prefixes = ["10.54.1.0/24", ] }
      ("TrustSubnet")     = { address_prefixes = ["10.54.2.0/24", ] }
      ("DnsServerSubnet") = { address_prefixes = ["10.54.3.0/24", ] }
      ("TestSubnet")      = { address_prefixes = ["10.54.4.0/24", ] }
    }
    nat_gateway_subnet_names = [
      "MainSubnet",
      "TrustSubnet",
      "DnsServerSubnet",
      "TestSubnet",
    ]
  }

  depends_on = [
    module.common,
  ]
}


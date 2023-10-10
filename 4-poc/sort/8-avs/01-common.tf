
####################################################
# providers
####################################################

terraform {
  required_providers {
    megaport = {
      source  = "megaport/megaport"
      version = "0.1.9"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = true
  features {}
}

# default resource group

resource "azurerm_resource_group" "rg" {
  name     = "${local.prefix}RG"
  location = local.default_region
}

####################################################
# log analytics workspace
####################################################

resource "azurerm_log_analytics_workspace" "analytics_ws_region1" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.prefix}-${local.region1}-analytics-ws"
  location            = local.region1
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

locals {
  firewall_categories_metric = ["AllMetrics"]
  firewall_categories_log = [
    "AzureFirewallApplicationRule",
    "AzureFirewallNetworkRule",
    "AzureFirewallDnsProxy"
  ]
}

####################################################
# nsg
####################################################

# region1
#----------------------------

# vm

resource "azurerm_network_security_group" "nsg_region1_main" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.prefix}-nsg-${local.region1}-main"
  location            = local.region1
}

resource "azurerm_network_security_rule" "nsg_region1_main_inbound_allow_all" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_region1_main.name
  name                        = "inbound-allow-all"
  direction                   = "Inbound"
  access                      = "Allow"
  priority                    = 100
  source_address_prefixes     = local.rfc1918_prefixes
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "*"
  protocol                    = "*"
  description                 = "Inbound Allow RFC1918"
}

resource "azurerm_network_security_rule" "nsg_region1_main_inbound_allow_web_external" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_region1_main.name
  name                        = "inbound-allow-web-external"
  direction                   = "Inbound"
  access                      = "Allow"
  priority                    = 110
  source_address_prefix       = "0.0.0.0/0"
  source_port_range           = "*"
  destination_address_prefix  = "VirtualNetwork"
  destination_port_ranges     = ["80", "8080", "443"]
  protocol                    = "Tcp"
  description                 = "Allow inbound web traffic"
}

resource "azurerm_network_security_rule" "nsg_region1_main_outbound_allow_rfc1918" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_region1_main.name
  name                        = "outbound-allow-rfc1918"
  direction                   = "Outbound"
  access                      = "Allow"
  priority                    = 100
  source_address_prefixes     = local.rfc1918_prefixes
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "*"
  protocol                    = "*"
  description                 = "Outbound Allow RFC1918"
}

# nva

resource "azurerm_network_security_group" "nsg_region1_nva" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.prefix}-nsg-${local.region1}-nva"
  location            = local.region1
}

resource "azurerm_network_security_rule" "nsg_region1_nva_inbound_allow_rfc1918" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_region1_nva.name
  name                        = "inbound-allow-rfc1918"
  direction                   = "Inbound"
  access                      = "Allow"
  priority                    = 100
  source_address_prefixes     = local.rfc1918_prefixes
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "*"
  protocol                    = "*"
  description                 = "Inbound Allow RFC1918"
}

resource "azurerm_network_security_rule" "nsg_region1_nva_outbound_allow_rfc1918" {
  resource_group_name          = azurerm_resource_group.rg.name
  network_security_group_name  = azurerm_network_security_group.nsg_region1_nva.name
  name                         = "outbound-allow-rfc1918"
  direction                    = "Outbound"
  access                       = "Allow"
  priority                     = 100
  source_address_prefix        = "*"
  source_port_range            = "*"
  destination_address_prefixes = local.rfc1918_prefixes
  destination_port_range       = "*"
  protocol                     = "*"
  description                  = "Outbound Allow RFC1918"
}

resource "azurerm_network_security_rule" "nsg_region1_nva_inbound_allow_ipsec" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_region1_nva.name
  name                        = "inbound-allow-ipsec"
  direction                   = "Inbound"
  access                      = "Allow"
  priority                    = 110
  source_address_prefix       = "*"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_ranges     = ["500", "4500"]
  protocol                    = "Udp"
  description                 = "Inbound Allow UDP 500, 4500"
}

resource "azurerm_network_security_rule" "nsg_region1_nva_outbound_allow_ipsec" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_region1_nva.name
  name                        = "outbound-allow-ipsec"
  direction                   = "Outbound"
  access                      = "Allow"
  priority                    = 110
  source_address_prefix       = "*"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_ranges     = ["500", "4500"]
  protocol                    = "Udp"
  description                 = "Outbound Allow UDP 500, 4500"
}

# appgw

resource "azurerm_network_security_group" "nsg_region1_appgw" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.prefix}-nsg-${local.region1}-appgw"
  location            = local.region1
}

resource "azurerm_network_security_rule" "nsg_region1_appgw_inbound_allow_appgw_v2sku" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_region1_appgw.name
  name                        = "inbound-allow-appgw-v2sku"
  direction                   = "Inbound"
  access                      = "Allow"
  priority                    = 100
  source_address_prefix       = "GatewayManager"
  source_port_range           = "*"
  destination_address_prefix  = "*"
  destination_port_range      = "65200-65535"
  protocol                    = "*"
  description                 = "Allow Inbound Azure infrastructure communication"
}

resource "azurerm_network_security_rule" "nsg_region1_appgw_inbound_allow_web_external" {
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg_region1_appgw.name
  name                        = "inbound-allow-web-external"
  direction                   = "Inbound"
  access                      = "Allow"
  priority                    = 110
  source_address_prefix       = "0.0.0.0/0"
  source_port_range           = "*"
  destination_address_prefix  = "VirtualNetwork"
  destination_port_ranges     = ["80", "8080", "443"]
  protocol                    = "Tcp"
  description                 = "Allow inbound web traffic"
}

# default

resource "azurerm_network_security_group" "nsg_region1_default" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.prefix}-nsg-${local.region1}-default"
  location            = local.region1
}

####################################################
# storage accounts (boot diagnostics)
####################################################

resource "random_id" "storage_accounts" {
  byte_length = 3
}

# region 1

resource "azurerm_storage_account" "region1" {
  resource_group_name      = azurerm_resource_group.rg.name
  name                     = lower("${local.prefix}r1${random_id.storage_accounts.hex}")
  location                 = local.region1
  account_replication_type = "LRS"
  account_tier             = "Standard"
}

####################################################
# firewall policy
####################################################

# region1

resource "azurerm_firewall_policy" "firewall_policy_region1" {
  resource_group_name      = azurerm_resource_group.rg.name
  name                     = "${local.prefix}-fw-policy-region1"
  location                 = local.region1
  threat_intelligence_mode = "Alert"
  sku                      = local.firewall_sku

  /*dns {
    proxy_enabled = true
  }*/
}

module "fw_policy_rule_collection_group_region1" {
  source             = "../../modules/fw-policy"
  prefix             = local.prefix
  firewall_policy_id = azurerm_firewall_policy.firewall_policy_region1.id

  network_rule_collection = [
    {
      name     = "network-rc"
      priority = 100
      action   = "Deny"
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
# dns
####################################################

module "onprem_dns_cloud_init" {
  source          = "../../modules/cloud-config-gen"
  container_image = null
  files = { "/var/tmp/unbound.sh" = {
    owner       = "root"
    permissions = "0744"
    content = templatefile("../../scripts/unbound.sh", local.onprem_unbound_vars) }
  }
  run_commands = [
    #". /var/tmp/unbound.sh",
  ]
}

####################################################
# output files
####################################################

locals {
  onprem_files = {
    "output/onprem-vm.sh"  = local.vm_startup
    "output/onprem-dns.sh" = local.onprem_unbound_config
  }
  spoke_files = {
    "output/spoke-vm.sh" = local.vm_startup
  }
}

resource "local_file" "onprem_files" {
  for_each = merge(
    local.onprem_files,
    local.spoke_files
  )
  filename = each.key
  content  = each.value
}

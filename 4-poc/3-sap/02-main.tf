locals {
  vnet_ranges = [for i in range(0, 50) : "10.0.${i}.0/24"]
}

####################################################
# providers
####################################################

provider "azurerm" {
  skip_provider_registration = true
  features {}
}

terraform {
  required_providers {
    megaport = {
      source  = "megaport/megaport"
      version = "0.1.9"
    }
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "loopRG"
  location = "westeurope"
}

resource "azurerm_virtual_network" "loop_vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = "loop-vnet"
  address_space       = local.vnet_ranges
}

# create subnet matching the vnet ranges

resource "azurerm_subnet" "loop_subnet" {
  count                = length(local.vnet_ranges)
  name                 = "subnet-${count.index}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.loop_vnet.name
  address_prefixes     = [local.vnet_ranges[count.index]]
}

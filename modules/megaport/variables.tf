
variable "prefix" {
  description = "prefix"
  type        = string
  default     = "megaport"
}

variable "tags" {
  description = "tags for all hub resources"
  type        = map(any)
  default     = {}
}

variable "azure_location" {
  description = "azure region"
}

variable "megaport_location" {
  description = "megaport location"
}

variable "resource_group" {
  description = "Name of the resource group"
  type        = string
}

variable "mcr" {
  description = "megaport cloud router"
  type = list(object({
    name          = string
    port_speed    = number
    requested_asn = number
  }))
  default = []
}

variable "circuits" {
  description = "megaport circuits"
  type = list(object({
    name                       = string
    location                   = string
    peering_location           = string
    peering_type               = optional(string, "AzurePrivatePeering")
    advertised_public_prefixes = optional(list(string))
    service_provider_name      = optional(string, "Megaport")
    bandwidth_in_mbps          = optional(number, 50)
    requested_vlan             = optional(number, 0)
    mcr_name                   = string
    sku_tier                   = optional(string, "Standard")
    sku_family                 = optional(string, "MeteredData")
    enable_mcr_auto_peering    = optional(bool, false) # auto-assign circuit addresses
    enable_mcr_peering         = optional(bool, false) # creates layer2 circuit only, layer3 peering will be created on azure side *

    ipv4_config = object({
      primary_peer_address_prefix   = optional(string, null)
      secondary_peer_address_prefix = optional(string, null)
    })
    ipv6_config = optional(object({
      enabled                       = optional(bool, false)
      create_azure_private_peering  = optional(bool, false) # * creates azure private peering, used when enable_mcr_peering = false and enable_mcr_auto_peering = false
      primary_peer_address_prefix   = optional(string, null)
      secondary_peer_address_prefix = optional(string, null)
    }), {})
  }))
  default = []
}

variable "gateway_connections" {
  description = "express route connection to gateway"
  type = list(object({
    express_route_circuit_name   = string
    virtual_network_gateway_name = optional(string, null)
    express_route_gateway_name   = optional(string, null)
  }))
  default = []
}

variable "log_analytics_workspace_name" {
  description = "log analytics workspace name"
  type        = string
  default     = null
}


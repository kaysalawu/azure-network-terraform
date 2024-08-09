
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

    primary_peer_address_prefix_ipv4   = optional(string, null)
    secondary_peer_address_prefix_ipv4 = optional(string, null)
    primary_peer_address_prefix_ipv6   = optional(string, null)
    secondary_peer_address_prefix_ipv6 = optional(string, null)

    # mcr_config_block creates layer2 and layer3 config on megaport and azure sides
    mcr_config = object({
      enable_auto_peering    = optional(bool, false) # auto-assign circuit addresses
      create_private_peering = optional(bool, false) # use provided addresses
    })

    # azure_config_block is only used when all mcr_config attributes are false
    # creates layer2 and layer3 config on azure and megaport sides
    azure_config = object({
      create_ipv4_peering = optional(bool, false)
      create_ipv6_peering = optional(bool, false)
    })
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


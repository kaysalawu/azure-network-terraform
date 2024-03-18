

variable "prefix" {
  description = "prefix"
  type        = string
  default     = "megaport"
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
    connection_target          = string
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

    primary_peer_address_prefix   = string
    secondary_peer_address_prefix = string
    virtual_network_gateway_id    = optional(string, null)
    express_route_gateway_id      = optional(string, null)
    auto_create_private_peering   = optional(bool, true)
    auto_create_microsoft_peering = optional(bool, true)
  }))
  default = []
}

variable "log_analytics_workspace_name" {
  description = "log analytics workspace name"
  type        = string
  default     = null
}

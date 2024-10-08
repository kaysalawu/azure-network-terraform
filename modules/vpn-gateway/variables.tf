
variable "resource_group" {
  description = "resource group name"
  type        = any
}

variable "prefix" {
  description = "prefix to append before all resources"
  type        = string
}

variable "env" {
  description = "environment name"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "vnet region location"
  type        = string
}

variable "tags" {
  description = "tags for all hub resources"
  type        = map(any)
  default     = {}
}

variable "virtual_hub_id" {
  description = "virtual hub id"
  type        = string
}

variable "bgp_route_translation_for_nat_enabled" {
  description = "enable bgp route translation for nat"
  type        = bool
  default     = false
}

variable "routing_preference" {
  description = "routing preference = Internet | Microsoft Network"
  type        = string
  default     = "Microsoft Network"
}

variable "scale_unit" {
  description = "scale unit"
  type        = number
  default     = 1
}

variable "sku" {
  description = "sku"
  type        = string
  default     = "VpnGw1AZ"
}

variable "bgp_settings" {
  type = object({
    asn                                       = optional(string, "65515")
    peer_weight                               = optional(number, 0)
    instance_0_bgp_peering_address_custom_ips = optional(list(string), [])
    instance_1_bgp_peering_address_custom_ips = optional(list(string), [])
  })
  default = {}
}

variable "log_categories" {
  type = list(any)
  default = [
    "GatewayDiagnosticLog",
    "TunnelDiagnosticLog",
    "RouteDiagnosticLog",
    "IKEDiagnosticLog"
  ]
}

variable "log_analytics_workspace_name" {
  description = "log analytics workspace name"
  type        = string
  default     = null
}

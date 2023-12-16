
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
    {
      "category"      = "GatewayDiagnosticLog",
      "categoryGroup" = null,
      "enabled"       = true,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    },
    {
      "category"      = "TunnelDiagnosticLog",
      "categoryGroup" = null,
      "enabled"       = true,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    },
    {
      "category"      = "RouteDiagnosticLog",
      "categoryGroup" = null,
      "enabled"       = true,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    },
    {
      "category"      = "IKEDiagnosticLog",
      "categoryGroup" = null,
      "enabled"       = true,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    }
  ]
}

variable "metric_categories" {
  type = list(any)
  default = [
    {
      "enabled" = false,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      },
      "category" = "AllMetrics"
    }
  ]
}

variable "create_dashboard" {
  description = "create dashboard"
  type        = bool
  default     = true
}

variable "enable_diagnostics" {
  description = "enable diagnostics"
  type        = bool
  default     = false
}

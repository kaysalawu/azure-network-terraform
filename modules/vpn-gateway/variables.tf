
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

variable "bgp_settings_asn" {
  description = "asn of bgp speaker"
  type        = number
  default     = "65515"
}

variable "bgp_settings_peer_weight" {
  description = "bgp peer weight"
  type        = number
  default     = 0
}

variable "bgp_settings_instance_0_bgp_peering_address_custom_ips" {
  description = "custom bgp peering address for instance 0"
  type        = list(string)
  default     = []
}

variable "bgp_settings_instance_1_bgp_peering_address_custom_ips" {
  description = "custom bgp peering address for instance 1"
  type        = list(string)
  default     = []
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

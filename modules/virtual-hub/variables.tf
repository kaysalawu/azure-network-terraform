
variable "prefix" {
  description = "Prefix for all resources"
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(any)
  default     = {}
}

variable "resource_group" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Location for all resources"
  type        = string
}

variable "virtual_wan_id" {
  description = "ID of the virtual WAN"
  type        = string
}

variable "address_prefix" {
  description = "Address prefix for the virtual hub"
  type        = string
}

variable "bgp_config" {
  type = list(object({
    asn                   = optional(string, "65001")
    peer_weight           = optional(number, 0)
    instance_0_custom_ips = optional(list(string))
    instance_1_custom_ips = optional(list(string))
  }))
  default = []
}

variable "security_config" {
  type = list(object({
    create_firewall    = optional(bool, false)
    firewall_sku       = optional(string, "Basic")
    firewall_policy_id = optional(string, null)
  }))
  default = []
}

variable "enable_s2s_vpn_gateway" {
  description = "Enable S2S VPN"
  type        = bool
  default     = false
}

variable "enable_p2s_vpn_gateway" {
  description = "Enable P2S VPN"
  type        = bool
  default     = false
}

variable "enable_er_gateway" {
  description = "Enable ExpressRoute gateway"
  type        = bool
  default     = false
}

variable "hub_routing_preference" {
  description = "Hub routing preference: ExpressRoute | ASPath | VpnGateway"
  type        = string
  default     = "ASPath"
}

variable "sku" {
  description = "SKU of the virtual hub: Basic | Standard"
  type        = string
  default     = "Standard"
}

variable "enable_routing_intent" {
  description = "Enable routing intent"
  type        = bool
  default     = false
}

variable "routing_policies" {
  type = map(object({
    name         = string
    destinations = list(string)
  }))
}

variable "metric_categories_firewall" {
  type = list(any)
  default = [
    {
      "enabled" = false,
      "retentionPolicy" = {
        "days" : 0,
        "enabled" = false
      },
      "category" = "AllMetrics"
    }
  ]
}

variable "log_categories_firewall" {
  type = list(any)
  default = [
    {
      "category"      = "AzureFirewallNetworkRule",
      "categoryGroup" = null,
      "enabled"       = false,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    },
    {
      "category"      = "AZFWNetworkRule",
      "categoryGroup" = null,
      "enabled"       = true,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    },
    {
      "category"      = "AZFWApplicationRule",
      "categoryGroup" = null,
      "enabled"       = true,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    },
    {
      "category"      = "AZFWNatRule",
      "categoryGroup" = null,
      "enabled"       = true,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    },
    {
      "category"      = "AZFWThreatIntel",
      "categoryGroup" = null,
      "enabled"       = false,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    },
    {
      "category"      = "AZFWIdpsSignature",
      "categoryGroup" = null,
      "enabled"       = false,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    },
    {
      "category"      = "AZFWDnsQuery",
      "categoryGroup" = null,
      "enabled"       = false,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    },
    {
      "category"      = "AZFWFqdnResolveFailure",
      "categoryGroup" = null,
      "enabled"       = false,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    },
    {
      "category"      = "AZFWFatFlow",
      "categoryGroup" = null,
      "enabled"       = false,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    },
    {
      "category"      = "AZFWFlowTrace",
      "categoryGroup" = null,
      "enabled"       = false,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    },
    {
      "category"      = "AZFWApplicationRuleAggregation",
      "categoryGroup" = null,
      "enabled"       = false,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    },
    {
      "category"      = "AZFWNetworkRuleAggregation",
      "categoryGroup" = null,
      "enabled"       = false,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    },
    {
      "category"      = "AZFWNatRuleAggregation",
      "categoryGroup" = null,
      "enabled"       = false,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    }
  ]
}

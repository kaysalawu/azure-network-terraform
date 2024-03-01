
variable "prefix" {
  description = "Prefix for all resources"
  type        = string
}

variable "env" {
  description = "environment name"
  type        = string
  default     = "dev"
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

variable "config_security" {
  type = object({
    create_firewall       = optional(bool, false)
    enable_routing_intent = optional(bool, false)
    firewall_sku          = optional(string, "Basic")
    firewall_policy_id    = optional(string, null)
    routing_policies = optional(object({
      internet            = optional(bool, false)
      private_traffic     = optional(bool, false)
      additional_prefixes = optional(map(any), {})
    }))
  })
  default = {}
}

variable "express_route_gateway" {
  type = object({
    enable = optional(bool, false)
    sku    = optional(string, "ErGw1AZ")
  })
  default = {}
}

variable "s2s_vpn_gateway" {
  type = object({
    enable = optional(bool, false)
    sku    = optional(string, "VpnGw1AZ")
    bgp_settings = optional(object({
      asn                                       = optional(string, "65515")
      peer_weight                               = optional(number, 0)
      instance_0_bgp_peering_address_custom_ips = optional(list(string), [])
      instance_1_bgp_peering_address_custom_ips = optional(list(string), [])
    }))
  })
  default = {
    enable       = false
    sku          = "VpnGw1AZ"
    bgp_settings = {}
  }
}

variable "p2s_vpn_gateway" {
  type = object({
    enable        = optional(bool, false)
    sku           = optional(string, "VpnGw1AZ")
    active_active = optional(bool, false)

    custom_route_address_prefixes = optional(list(string), [])

    vpn_client_configuration = optional(object({
      address_space = list(string)
      clients = list(object({
        name = string
      }))
    }))
  })

  default = {
    enable = false
    sku    = "VpnGw1AZ"
    ip_configuration = [
      { name = "ip-config", public_ip_address_name = null },
    ]
  }
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
  type = object({
    internet            = optional(bool, false)
    private_traffic     = optional(bool, false)
    additional_prefixes = optional(map(any), {})
  })
  default = {
    internet            = false
    private_traffic     = false
    additional_prefixes = {}
  }
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

variable "enable_diagnostics" {
  description = "enable diagnostics"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_name" {
  description = "log analytics workspace name"
  type        = string
  default     = null
}


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

variable "storage_account" {
  description = "storage account object"
  type        = any
  default     = null
}

variable "subnet_id" {
  description = "subnet id"
  type        = string
  default     = null
}

variable "mgt_subnet_id" {
  description = "management subnet id"
  type        = string
  default     = null
}

variable "sku_tier" {
  description = "firewall sku"
  type        = string
  default     = "Basic"
}

variable "sku_name" {
  description = "firewall sku name"
  type        = string
  default     = "AZFW_VNet"
}

variable "firewall_policy_id" {
  description = "firewall policy id"
  type        = string
  default     = null
}

variable "metric_categories_firewall" {
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

variable "log_categories_firewall" {
  type = list(any)
  default = [
    {
      "category"      = "AzureFirewallNetworkRule",
      "categoryGroup" = null,
      "enabled"       = true,
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

variable "virtual_hub_id" {
  description = "virtual hub id"
  type        = string
  default     = null
}

variable "virtual_hub_public_ip_count" {
  description = "virtual hub public ip count"
  type        = number
  default     = 1
}

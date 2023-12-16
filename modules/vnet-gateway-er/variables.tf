
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

variable "subnet_id" {
  description = "subnet id for vnet gateway"
  type        = string
}

variable "sku" {
  description = "sku for vnet gateway"
  type        = string
  default     = "ErGw1AZ"
}

variable "bgp_asn" {
  description = "bgp asn for vnet gateway"
  type        = string
  default     = 65515
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
      "enabled"       = false,
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
      "enabled"       = false,
      "retentionPolicy" = {
        "days"    = 0,
        "enabled" = false
      }
    },
    {
      "category"      = "P2SDiagnosticLog",
      "categoryGroup" = null,
      "enabled"       = false,
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


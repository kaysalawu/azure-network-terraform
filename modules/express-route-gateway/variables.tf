
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

variable "scale_units" {
  description = "scale units"
  type        = number
  default     = 1
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

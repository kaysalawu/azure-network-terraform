
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

variable "scale_unit" {
  description = "scale unit for vnet gateway"
  type        = string
  default     = "1"
}

variable "sku" {
  description = "sku for vnet gateway"
  type        = string
  default     = "VpnGw1AZ"
}

# variable "log_categories" {
#   type = list(any)
#   default = [
#     "GatewayDiagnosticLog",
#     "TunnelDiagnosticLog",
#     "RouteDiagnosticLog",
#     "IKEDiagnosticLog",
#     "P2SDiagnosticLog"
#   ]
# }

variable "vpn_client_configuration" {
  description = "vpn client configuration for vnet gateway"
  type = object({
    address_space = list(string)
    clients = list(object({
      name = string
    }))
  })
  default = {
    address_space = ["172.16.0.0/24"]
    clients       = []
  }
}

variable "cert_password" {
  description = "The password to use for the self-signed certificate."
  type        = string
  default     = "Password123"
}

variable "custom_route_address_prefixes" {
  description = "custom route address prefixes for vnet gateway"
  type        = list(string)
  default     = []
}

variable "log_analytics_workspace_name" {
  description = "log analytics workspace name"
  type        = string
  default     = null
}



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
  default     = "VpnGw1AZ"
}

variable "bgp_asn" {
  description = "bgp asn for vnet gateway"
  type        = string
  default     = 65515
}

variable "ip_configuration" {
  description = "ip configurations for vnet gateway"
  type = list(object({
    name                          = string
    subnet_id                     = string
    public_ip_address_name        = optional(string, null)
    private_ip_address_allocation = optional(string, "Dynamic")
    apipa_addresses               = optional(list(string), null)
  }))
  default = []
}

variable "ip_config0_apipa_addresses" {
  description = "ip config0 apipa addresses for vnet gateway"
  type        = list(string)
  default     = ["169.254.21.1"]
}

variable "ip_config1_apipa_addresses" {
  description = "ip config1 apipa addresses for vnet gateway"
  type        = list(string)
  default     = ["169.254.21.5"]
}

variable "log_categories" {
  type = list(any)
  default = [
    "GatewayDiagnosticLog",
    "TunnelDiagnosticLog",
    "RouteDiagnosticLog",
    "IKEDiagnosticLog",
    "P2SDiagnosticLog"
  ]
}

variable "enable_bgp" {
  description = "enable bgp"
  type        = bool
  default     = true
}

variable "private_ip_address_enabled" {
  description = "private ip address enabled"
  type        = bool
  default     = true
}

variable "remote_vnet_traffic_enabled" {
  description = "remote vnet traffic enabled"
  type        = bool
  default     = true
}

variable "virtual_wan_traffic_enabled" {
  description = "virtual wan traffic enabled"
  type        = bool
  default     = true
}

variable "active_active" {
  description = "active active"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_name" {
  description = "log analytics workspace name"
  type        = string
  default     = null
}

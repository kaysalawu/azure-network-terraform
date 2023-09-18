
variable "prefix" {
  description = "Prefix for all resources"
  type        = string
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

variable "storage_account_id" {
  description = "ID of the storage account"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "ID of the log analytics workspace"
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
    enable_firewall    = optional(bool, false)
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

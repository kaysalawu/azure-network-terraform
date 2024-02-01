
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

variable "virtual_network_id" {
  description = "virtual network id"
  type        = string
}

variable "dns_zone_linked_rulesets" {
  description = "private dns rulesets"
  type        = map(any)
  default     = {}
}

variable "private_dns_ruleset_linked_external_vnets" {
  description = "private dns rulesets"
  type        = map(any)
  default     = {}
}

variable "enable_private_dns_resolver" {
  description = "enable private dns resolver"
  type        = bool
  default     = false
}

variable "private_dns_inbound_subnet_id" {
  description = "private dns inbound subnet id"
  type        = string
}

variable "private_dns_outbound_subnet_id" {
  description = "private dns outbound subnet id"
  type        = string
}

variable "ruleset_dns_forwarding_rules" {
  description = "private dns ruleset forwarding rules"
  type        = map(any)
  default     = {}
}

variable "create_dashboard" {
  description = "create dashboard"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_name" {
  description = "log analytics workspace name"
  type        = string
  default     = null
}

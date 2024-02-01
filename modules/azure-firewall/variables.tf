
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

variable "log_categories_firewall" {
  type = list(any)
  default = [
    "AzureFirewallNetworkRule",
    "AZFWNetworkRule",
    "AZFWApplicationRule",
    "AZFWNatRule",
    "AZFWThreatIntel",
    "AZFWIdpsSignature",
    "AZFWDnsQuery",
    "AZFWFqdnResolveFailure",
    "AZFWFatFlow",
    "AZFWFlowTrace",
    "AZFWApplicationRuleAggregation",
    "AZFWNetworkRuleAggregation",
    "AZFWNatRuleAggregation"
  ]
}

variable "create_dashboard" {
  description = "create dashboard"
  type        = bool
  default     = true
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

variable "log_analytics_workspace_name" {
  description = "log analytics workspace name"
  type        = string
  default     = null
}

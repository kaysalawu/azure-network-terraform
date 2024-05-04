
variable "resource_group_name" {
  description = "resource group name"
  type        = any
}

variable "prefix" {
  description = "prefix to append before all resources"
  type        = string
}

variable "location" {
  description = "location for network manager and other resources"
  type        = string
}

variable "tags" {
  description = "tags for all hub resources"
  type        = map(any)
  default     = {}
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

# variable "description" {
#   description = "global"
#   type        = string
# }

# variable "scope_accesses" {
#   description = "scope accesses"
#   type        = list(string)
#   default = [
#     "Connectivity",
#     "SecurityAdmin"
#   ]
# }

# variable "scope_subscription_ids" {
#   description = "scope subscription ids"
#   type        = list(string)
#   default     = []
# }

# variable "scope_management_group_ids" {
#   description = "scope management group ids"
#   type        = list(string)
#   default     = []
# }

# variable "network_watcher_resource_group" {
#   description = "network watcher resource group"
#   type        = string
#   default     = null
# }

# variable "network_watcher_name" {
#   description = "network watcher name"
#   type        = string
#   default     = null
# }

# variable "flow_log_nsg_ids" {
#   description = "flow log nsg id"
#   type        = list(string)
#   default     = []
# }


variable "prefix" {
  description = "The prefix to use for all resources"
  type        = string
}

variable "resource_group" {
  description = "The name of the resource group to deploy to"
  type        = string
}

variable "regions" {
  description = "A map of regions to deploy resources to"
  type        = map(any)
}

variable "firewall_sku" {
  description = "The SKU of the firewall to deploy"
  type        = string
  default     = "Standard"
}

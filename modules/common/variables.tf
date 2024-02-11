
variable "prefix" {
  description = "The prefix to use for all resources"
  type        = string
}

variable "env" {
  description = "environment name"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(any)
  default     = {}
}

variable "resource_group" {
  description = "The name of the resource group to deploy to"
  type        = string
}

variable "regions" {
  description = "A map of regions to deploy resources to"
  type = map(object({
    name     = string
    dns_zone = string
  }))
}


variable "firewall_sku" {
  description = "The SKU of the firewall to deploy"
  type        = string
  default     = "Standard"
}

variable "private_prefixes" {
  description = "A list of private prefixes to allow access to"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "100.64.0.0/10"]
}

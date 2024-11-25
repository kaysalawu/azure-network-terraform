
variable "subscription_id" {
  description = "The Azure subscription ID"
}

variable "dns_resource_group" {
  description = "The resource group where the DNS zone is located"
  default     = "DNS_RG"
}

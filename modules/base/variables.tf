
variable "resource_group" {
  description = "resource group name"
  type        = any
}

variable "prefix" {
  description = "prefix to append before all resources"
  type        = string
}

variable "location" {
  description = "vnet region location"
  type        = string
}

variable "tags" {
  description = "tags for all hub resources"
  type        = map(any)
  default     = null
}

variable "storage_account" {
  description = "storage account object"
  type        = any
  default     = null
}

variable "admin_username" {
  description = "private dns zone name"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "private dns zone name"
  type        = string
  default     = "Password123"
}

variable "ssh_public_key" {
  description = "sh public key data"
  type        = string
  default     = null
}

variable "private_dns_zone" {
  description = "private dns zone"
  type        = string
  default     = null
}

variable "dns_zone_linked_vnets" {
  description = "private dns zone"
  type        = map(any)
  default     = {}
}

variable "nsg_subnets" {
  description = "subnets to associate to nsg"
  type        = map(any)
  default     = {}
}

variable "dns_zone_linked_rulesets" {
  description = "private dns rulesets"
  type        = map(any)
  default     = {}
}

variable "vnet_config" {
  type = list(object({
    address_space               = list(string)
    subnets                     = map(any)
    subnets_nat_gateway         = optional(list(string), [])
    nsg_id                      = optional(string)
    dns_servers                 = optional(list(string))
    enable_private_dns_resolver = optional(bool, false)
    enable_ars                  = optional(bool, false)
    enable_vpngw                = optional(bool, false)
    enable_ergw                 = optional(bool, false)
    vpngw_config = optional(list(object({
      asn                        = string
      ip_config0_apipa_addresses = optional(list(string), ["169.254.21.1"])
      ip_config1_apipa_addresses = optional(list(string), ["169.254.21.5"])
    })))
  }))
  default = []
}

variable "vm_config" {
  type = list(object({
    name                 = string
    dns_host             = optional(string)
    zone                 = optional(string, null)
    size                 = optional(string, "Standard_B1s")
    private_ip           = optional(string, null)
    public_ip            = optional(string, null)
    custom_data          = optional(string, null)
    enable_ip_forwarding = optional(bool, false)
    use_vm_extension     = optional(bool, false)
  }))
  default = []
}

variable "dns_config" {
  type = list(object({
    name                 = string
    dns_host             = optional(string)
    zone                 = optional(string, null)
    size                 = optional(string, "Standard_B1s")
    private_ip           = optional(string, null)
    public_ip            = optional(string, null)
    custom_data          = optional(string, null)
    enable_ip_forwarding = optional(bool, false)
    use_vm_extension     = optional(bool, false)
  }))
  default = []
}

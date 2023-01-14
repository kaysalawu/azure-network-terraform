
variable "resource_group" {
  description = "resource group name"
  type        = any
}

variable "name" {
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

variable "zone" {
  description = "availability zone for supported regions"
  type        = string
  default     = null
}

variable "subnet_ext" {
  description = "NVA's external subnet"
  type        = any
}

variable "subnet_int" {
  description = "NVA's internal subnet"
  type        = any
}

variable "private_ip_ext" {
  description = "optional static private external ip of vm"
  type        = any
  default     = null
}

variable "private_ip_int" {
  description = "optional static private external ip of vm"
  type        = any
  default     = null
}

variable "enable_public_ip" {
  description = "enable public ip interface"
  type        = bool
  default     = false
}

variable "public_ip" {
  description = "optional static public ip of vm"
  type        = any
  default     = null
}

variable "vm_size" {
  description = "size of vm"
  type        = string
  default     = "Standard_B2s"
}

variable "ssh_public_key" {
  description = "sh public key data"
  type        = string
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
  default     = "azureuser"
}

variable "enable_ip_forwarding" {
  description = "enable ip forwarding"
  type        = bool
  default     = false
}

variable "custom_data" {
  description = "base64 string containing virtual machine custom data"
  type        = string
  default     = null
}

variable "dns_servers" {
  description = "DNS servers"
  type        = list(any)
  default     = null
}

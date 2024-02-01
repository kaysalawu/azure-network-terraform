
variable "resource_group" {
  description = "resource group name"
  type        = any
}

variable "prefix" {
  description = "prefix to append before all resources"
  type        = string
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
  default     = {}
}

variable "storage_account" {
  description = "storage account object"
  type        = any
  default     = null
}

variable "admin_username" {
  description = "test username. please change for production"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "test password. please change for production"
  type        = string
  default     = "Password123"
}

variable "public_ip_address_id" {
  description = "(optional) static public ip address id"
  type        = any
  default     = null
}

variable "private_ip_untrust" {
  description = "private ip address for untrust interface"
  type        = string
  default     = null
}

variable "private_ip_trust" {
  description = "private ip address for trust interface"
  type        = string
  default     = null
}

variable "dns_servers" {
  description = "DNS servers"
  type        = list(any)
  default     = null
}

variable "enable_ip_forwarding" {
  description = "enable ip forwarding"
  type        = bool
  default     = false
}

variable "untrust_subnet_id" {
  description = "subnet id for untrust interface"
  type        = string
}

variable "trust_subnet_id" {
  description = "subnet id for trust interface"
  type        = string
}

variable "vm_size" {
  description = "size of vm"
  type        = string
  default     = "Standard_B2s"
}

variable "custom_data" {
  description = "base64 string containing virtual machine custom data"
  type        = string
  default     = null
}

variable "zone" {
  description = "availability zone for supported regions"
  type        = string
  default     = null
}

variable "image_publisher" {
  description = "image object"
  type        = any
  default     = "thefreebsdfoundation"
}

variable "image_offer" {
  description = "image object"
  type        = any
  default     = "freebsd-13_1"
}

variable "image_sku" {
  description = "image object"
  type        = any
  default     = "13_1-release"
}

variable "image_version" {
  description = "image object"
  type        = any
  default     = "latest"
}

# parameters
#--------------------------------------------------

variable "opn_script_uri" {
  description = "URI for Custom OPN Script and Config"
  type        = string
  default     = "https://raw.githubusercontent.com/dmauser/opnazure/master/scripts/"
}

variable "shell_script_name" {
  description = "Shell Script to be executed"
  type        = string
  default     = "configureopnsense.sh"
}

variable "opn_version" {
  description = "OPN Version"
  type        = string
  default     = "23.7"
}

variable "walinux_version" {
  description = "WALinuxAgent Version"
  type        = string
  default     = "2.9.1.1"
}

variable "scenario_option" {
  description = "scenario_option = Active-Active, TwnoNics"
  type        = string
  default     = "TwnoNics"
}

variable "opn_type" {
  description = "opn type = Primary, Secondary, TwnoNics"
  type        = string
  default     = "TwnoNics"
}

variable "deploy_windows_mgmt" {
  description = "deploy windows management vm in a management subnet"
  type        = bool
  default     = false
}

variable "mgmt_subnet_address_prefix" {
  description = "management subnet address prefix"
  type        = string
  default     = ""
}

variable "trusted_subnet_address_prefix" {
  description = "trusted subnet address prefix"
  type        = string
  default     = ""
}

variable "log_analytics_workspace_name" {
  description = "log analytics workspace name"
  type        = string
  default     = null
}

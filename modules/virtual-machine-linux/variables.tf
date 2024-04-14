
variable "resource_group" {
  description = "resource group name"
  type        = any
}

variable "prefix" {
  description = "prefix to append before all resources"
  type        = string
  default     = ""
}

variable "name" {
  description = "virtual machine resource name"
  type        = string
}

variable "computer_name" {
  description = "computer name"
  type        = string
  default     = ""
}

variable "location" {
  description = "vnet region location"
  type        = string
}

variable "user_assigned_ids" {
  description = "list of identity ids"
  type        = list(any)
  default     = []
}

variable "assigned_roles" {
  description = "list of assigned roles"
  type = list(object({
    role  = string
    scope = string
  }))
  default = []

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

variable "interfaces" {
  type = list(object({
    name                   = string
    subnet_id              = string
    private_ip_address     = optional(string, null)
    private_ipv6_address   = optional(string, null)
    create_public_ip       = optional(bool, false)
    public_ip_address_id   = optional(string, null)
    public_ipv6_address_id = optional(string, null)
  }))
}

variable "private_ip_untrust" {
  description = "optional static private untrust ip of vm"
  type        = any
  default     = null
}

variable "private_ip_trust" {
  description = "optional static private trust ip of vm"
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
  description = "admin username"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "admin password"
  type        = string
  default     = "Password123"
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

variable "source_image_publisher" {
  description = "source image reference publisher"
  type        = string
  default     = "Canonical"
}

variable "source_image_offer" {
  description = "source image reference offer"
  type        = string
  default     = "0001-com-ubuntu-server-focal"
}

variable "source_image_sku" {
  description = "source image reference sku"
  type        = string
  default     = "20_04-lts"
}

variable "source_image_version" {
  description = "source image reference version"
  type        = string
  default     = "latest"
}

variable "enable_plan" {
  description = "enable plan"
  type        = bool
  default     = false
}

variable "source_image_reference_library" {
  description = "source image reference"
  type        = map(any)
  default = {
    "cisco-csr-1000v" = {
      publisher = "cisco"
      offer     = "cisco-csr-1000v"
      sku       = "17_3_4a-byol"
      version   = "latest"
    }
    "cisco-c8000v" = {
      publisher = "cisco"
      offer     = "cisco-c8000v"
      sku       = "17_11_01a-byol"
      version   = "latest"
    }
    "ubuntu-18" = {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "18.04-LTS"
      version   = "latest"
    }
    "ubuntu-20" = {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-focal"
      sku       = "20_04-lts"
      version   = "latest"
    }
    "ubuntu-22" = {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts"
      version   = "latest"
    }
    "debian-10" = {
      publisher = "Debian"
      offer     = "debian-10"
      sku       = "10"
      version   = "0.20201013.422"
    }
    "freebsd-13" = {
      publisher = "thefreebsdfoundation"
      offer     = "freebsd-13_1"
      sku       = "13_1-release"
      version   = "latest"
    }
  }
}

variable "images_with_plan" {
  description = "images with plan"
  type        = list(string)
  default = [
    "cisco-csr-1000v",
    "cisco-c8000v",
    "freebsd-13"
  ]
}

variable "log_analytics_workspace_name" {
  description = "log analytics workspace name"
  type        = string
  default     = null
}

variable "use_vm_extension" {
  description = "use virtual machine extension"
  type        = bool
  default     = false
}

variable "vm_extension_publisher" {
  description = "vm extension publisher"
  type        = string
  default     = "Microsoft.OSTCExtensions"
}

variable "vm_extension_type" {
  description = "vm extension type"
  type        = string
  default     = "CustomScriptForLinux"
}

variable "vm_extension_type_handler_version" {
  description = "vm extension type"
  type        = string
  default     = "1.5"
}

variable "vm_extension_settings" {
  description = "vm extension settings"
  type        = string
  default     = ""
}

variable "vm_extension_auto_upgrade_minor_version" {
  description = "vm extension settings"
  type        = bool
  default     = true
}

variable "enable_ipv6" {
  description = "enable dual stack networking"
  type        = bool
  default     = false
}

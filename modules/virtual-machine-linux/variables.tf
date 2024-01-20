
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
  description = "prefix to append before all resources"
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

variable "identity_ids" {
  description = "list of identity ids"
  type        = list(any)
  default     = null
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
    name               = string
    subnet_id          = string
    private_ip_address = optional(string, null)
    create_public_ip   = optional(bool, false)
    public_ip_id       = optional(string, null)
  }))
}

# variable "subnet_untrust" {
#   description = "NVA's untrust subnet"
#   type        = any
# }

# variable "subnet_trust" {
#   description = "NVA's trust subnet"
#   type        = any
# }

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

variable "source_image" {
  description = "source image"
  type        = string
  default     = "ubuntu-20"
}

variable "source_image_reference" {
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
  }
}


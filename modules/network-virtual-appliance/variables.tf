
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

variable "location" {
  description = "vnet region location"
  type        = string
}

variable "nva_type" {
  description = "type of network virtual appliance - opnsense, linux"
  type        = string
  default     = "opnsense"
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

variable "scenario_option" {
  description = "scenario_option = Active-Active, TwoNics"
  type        = string
  default     = "TwoNics"
}

variable "storage_account" {
  description = "storage account object"
  type        = any
  default     = null
}

variable "subnet_id_untrust" {
  description = "subnet id for untrust interface"
  type        = string
}

variable "subnet_id_trust" {
  description = "subnet id for trust interface"
  type        = string
}

variable "ilb_untrust_ip" {
  description = "internal load balancer untrust address"
  type        = string
  default     = null
}

variable "ilb_trust_ip" {
  description = "internal load balancer trust address"
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

variable "vm_extension_auto_upgrade_minor_version" {
  description = "vm extension settings"
  type        = bool
  default     = true
}

variable "vm_extension_settings" {
  description = "vm extension settings"
  type        = string
  default     = ""
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

variable "custom_data" {
  description = "base64 string containing virtual machine custom data"
  type        = string
  default     = null
}

variable "health_probes" {
  description = "probe name"
  type = list(object({
    name         = string
    port         = number
    protocol     = string
    request_path = optional(string, "")
  }))
  default = [
    {
      name         = "ssh"
      port         = 22
      protocol     = "Tcp"
      request_path = ""
    }
  ]
}

# variable "virtual_network_id" {
#   description = "virtual network id"
#   type        = string
# }

# variable "private_ip_untrust" {
#   description = "optional static private untrust ip of vm"
#   type        = any
#   default     = null
# }

# variable "private_ip_trust" {
#   description = "optional static private trust ip of vm"
#   type        = any
#   default     = null
# }

# variable "enable_public_ip" {
#   description = "enable public ip interface"
#   type        = bool
#   default     = false
# }

# variable "public_ip" {
#   description = "optional static public ip of vm"
#   type        = any
#   default     = null
# }

# variable "vm_size" {
#   description = "size of vm"
#   type        = string
#   default     = "Standard_B2s"
# }

# variable "ssh_public_key" {
#   description = "sh public key data"
#   type        = string
#   default     = null
# }

# variable "admin_username" {
#   description = "admin username"
#   type        = string
#   default     = "azureuser"
# }

# variable "admin_password" {
#   description = "admin password"
#   type        = string
#   default     = "Password123"
# }

# variable "enable_ip_forwarding" {
#   description = "enable ip forwarding"
#   type        = bool
#   default     = false
# }

# variable "dns_servers" {
#   description = "DNS servers"
#   type        = list(any)
#   default     = null
# }




# variable "images_with_plan" {
#   description = "images with plan"
#   type        = list(string)
#   default = [
#     "cisco-csr-1000v",
#     "cisco-c8000v",
#     "freebsd-13"
#   ]
# }

# variable "log_analytics_workspace_name" {
#   description = "log analytics workspace name"
#   type        = string
#   default     = null
# }




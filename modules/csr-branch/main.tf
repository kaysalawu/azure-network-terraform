
locals {
  name = var.name == "" ? "" : join("-", [var.name, ""])
}

# interface

resource "azurerm_network_interface" "untrust" {
  resource_group_name  = var.resource_group
  name                 = "${local.name}nic-untrust"
  location             = var.location
  dns_servers          = var.dns_servers
  tags                 = var.tags
  enable_ip_forwarding = var.enable_ip_forwarding
  ip_configuration {
    name                          = "${local.name}nic"
    subnet_id                     = var.subnet_untrust
    private_ip_address_allocation = var.private_ip_untrust == null ? "Dynamic" : "Static"
    private_ip_address            = var.private_ip_untrust == null ? null : var.private_ip_untrust
    public_ip_address_id          = var.enable_public_ip ? var.public_ip : null
  }
}

resource "azurerm_network_interface" "trust" {
  resource_group_name  = var.resource_group
  name                 = "${local.name}nic-trust"
  location             = var.location
  dns_servers          = var.dns_servers
  tags                 = var.tags
  enable_ip_forwarding = var.enable_ip_forwarding
  ip_configuration {
    name                          = "${local.name}nic"
    subnet_id                     = var.subnet_trust
    private_ip_address_allocation = var.private_ip_trust == null ? "Dynamic" : "Static"
    private_ip_address            = var.private_ip_trust == null ? null : var.private_ip_trust
  }
}

# vm

resource "azurerm_linux_virtual_machine" "this" {
  resource_group_name = var.resource_group
  name                = var.name
  location            = var.location
  zone                = var.zone
  size                = var.vm_size
  tags                = var.tags
  custom_data         = var.custom_data
  network_interface_ids = [
    azurerm_network_interface.untrust.id,
    azurerm_network_interface.trust.id
  ]
  os_disk {
    name                 = "${local.name}vm-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = var.source_image_reference[var.source_image].publisher
    offer     = var.source_image_reference[var.source_image].offer
    sku       = var.source_image_reference[var.source_image].sku
    version   = var.source_image_reference[var.source_image].version
  }
  plan {
    publisher = var.source_image_reference[var.source_image].publisher
    product   = var.source_image_reference[var.source_image].offer
    name      = var.source_image_reference[var.source_image].sku
  }
  computer_name  = replace("${local.name}vm", "_", "")
  admin_username = var.admin_username
  admin_password = var.admin_password
  boot_diagnostics {
    storage_account_uri = null
  }
  disable_password_authentication = false

  lifecycle {
    ignore_changes = [
      identity,
      secure_boot_enabled,
      tags,
    ]
  }
}


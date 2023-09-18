
# interface

resource "azurerm_network_interface" "ext" {
  resource_group_name  = var.resource_group
  name                 = "${local.name}nic-ext"
  location             = var.location
  dns_servers          = var.dns_servers
  tags                 = var.tags
  enable_ip_forwarding = var.enable_ip_forwarding
  ip_configuration {
    name                          = "${local.name}nic"
    subnet_id                     = var.subnet_ext
    private_ip_address_allocation = var.private_ip_ext == null ? "Dynamic" : "Static"
    private_ip_address            = var.private_ip_ext == null ? null : var.private_ip_ext
    public_ip_address_id          = var.enable_public_ip ? var.public_ip : null
  }
}

resource "azurerm_network_interface" "int" {
  resource_group_name  = var.resource_group
  name                 = "${local.name}nic-int"
  location             = var.location
  dns_servers          = var.dns_servers
  tags                 = var.tags
  enable_ip_forwarding = var.enable_ip_forwarding
  ip_configuration {
    name                          = "${local.name}nic"
    subnet_id                     = var.subnet_int
    private_ip_address_allocation = var.private_ip_int == null ? "Dynamic" : "Static"
    private_ip_address            = var.private_ip_int == null ? null : var.private_ip_int
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
    azurerm_network_interface.ext.id,
    azurerm_network_interface.int.id
  ]
  os_disk {
    name                 = "${local.name}vm-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "cisco"
    offer     = "cisco-csr-1000v"
    sku       = "17_3_4a-byol"
    version   = "latest"
  }
  plan {
    publisher = "cisco"
    product   = "cisco-csr-1000v" # offer
    name      = "17_3_4a-byol"    # sku
  }
  computer_name  = "${local.name}vm"
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


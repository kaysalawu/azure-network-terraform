
locals {
  prefix = var.prefix == "" ? "${var.name}" : join("-", [var.prefix, var.name, ""])
}

# public ip

resource "azurerm_public_ip" "this" {
  count               = var.enable_public_ip == true ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.prefix}pip"
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
  tags                = var.tags
}

# interface

resource "azurerm_network_interface" "this" {
  resource_group_name  = var.resource_group
  name                 = "${local.prefix}nic"
  location             = var.location
  dns_servers          = var.dns_servers
  tags                 = var.tags
  enable_ip_forwarding = var.enable_ip_forwarding
  ip_configuration {
    name                          = "${local.prefix}nic-ip-config"
    subnet_id                     = var.subnet
    private_ip_address_allocation = var.private_ip == null ? "Dynamic" : "Static"
    private_ip_address            = var.private_ip == null ? null : var.private_ip
    public_ip_address_id          = var.enable_public_ip ? azurerm_public_ip.this.0.id : null
  }
  timeouts {
    create = "60m"
  }
}

# delay

resource "time_sleep" "this" {
  depends_on = [
    azurerm_network_interface.this
  ]
  create_duration = var.delay_creation
}

# vm

resource "azurerm_linux_virtual_machine" "this" {
  resource_group_name = var.resource_group
  name                = trimsuffix(local.prefix, "-")
  location            = var.location
  zone                = var.zone
  size                = var.vm_size
  tags                = var.tags
  custom_data         = var.use_vm_extension ? null : var.custom_data
  network_interface_ids = [
    azurerm_network_interface.this.id
  ]
  os_disk {
    name                 = "${local.prefix}os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = var.source_image_reference[var.source_image].publisher
    offer     = var.source_image_reference[var.source_image].offer
    sku       = var.source_image_reference[var.source_image].sku
    version   = var.source_image_reference[var.source_image].version
  }
  computer_name  = trimsuffix(local.prefix, "-")
  admin_username = var.admin_username
  admin_password = var.admin_password
  boot_diagnostics {
    storage_account_uri = null
  }
  disable_password_authentication = false

  lifecycle {
    /*ignore_changes = [
      identity,
      secure_boot_enabled,
      tags,
    ]*/
  }
  timeouts {
    create = "60m"
  }
  depends_on = [time_sleep.this]
}

resource "azurerm_virtual_machine_extension" "this" {
  count                = var.use_vm_extension ? 1 : 0
  name                 = trimsuffix(local.prefix, "-")
  virtual_machine_id   = azurerm_linux_virtual_machine.this.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
{
  "script": "${var.custom_data}"
}
SETTINGS
}

resource "azurerm_private_dns_a_record" "this" {
  count               = var.private_dns_zone_name == "" || var.dns_host == "" ? 0 : 1
  resource_group_name = var.resource_group
  name                = lower("${var.dns_host}")
  zone_name           = var.private_dns_zone_name
  ttl                 = 300
  records             = [azurerm_linux_virtual_machine.this.private_ip_address]
}

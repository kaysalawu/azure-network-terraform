
locals {
  name = var.prefix == "" ? "${var.name}" : format("%s%s-", var.prefix, var.name)
  cleanup_commands = [
    "az vm extension delete -g ${var.resource_group} --vm-name ${local.name}-vm --name ${local.name}-vm-${random_id.this.hex} --no-wait",
  ]
}

# random
#----------------------------

resource "random_id" "this" {
  byte_length = 4
}

# public ip
#----------------------------

resource "azurerm_public_ip" "this" {
  count               = var.enable_public_ip == true ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.name}pip"
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
  tags                = var.tags
}

# interface
#----------------------------

resource "azurerm_network_interface" "this" {
  resource_group_name  = var.resource_group
  name                 = "${local.name}nic"
  location             = var.location
  dns_servers          = var.dns_servers
  tags                 = var.tags
  enable_ip_forwarding = var.enable_ip_forwarding
  ip_configuration {
    name                          = "ip-config"
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
#----------------------------

resource "time_sleep" "this" {
  depends_on = [
    azurerm_network_interface.this
  ]
  create_duration = var.delay_creation
}

# vm
#----------------------------

resource "azurerm_linux_virtual_machine" "this" {
  resource_group_name = var.resource_group
  name                = trimsuffix(local.name, "-")
  location            = var.location
  zone                = var.zone
  size                = var.vm_size
  tags                = var.tags
  custom_data         = var.use_vm_extension ? null : var.custom_data
  network_interface_ids = [
    azurerm_network_interface.this.id
  ]
  os_disk {
    name                 = "${local.name}os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = var.source_image_reference[var.source_image].publisher
    offer     = var.source_image_reference[var.source_image].offer
    sku       = var.source_image_reference[var.source_image].sku
    version   = var.source_image_reference[var.source_image].version
  }
  computer_name  = trimsuffix(local.name, "-")
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
  name                 = "${local.name}vm-${random_id.this.hex}"
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

# dns
#----------------------------

resource "azurerm_private_dns_a_record" "this" {
  count               = var.private_dns_zone_name == "" ? 0 : 1
  resource_group_name = var.resource_group
  name                = lower("${var.name}")
  zone_name           = var.private_dns_zone_name
  ttl                 = 300
  records             = [azurerm_linux_virtual_machine.this.private_ip_address]
}

# cleanup
#----------------------------

resource "null_resource" "cleanup_commands" {
  count = var.use_vm_extension ? length(local.cleanup_commands) : 0
  triggers = {
    create = ":"
    delete = local.cleanup_commands[count.index]
  }
  provisioner "local-exec" {
    command = self.triggers.create
  }
  provisioner "local-exec" {
    when    = destroy
    command = self.triggers.delete
  }
  depends_on = [
    azurerm_virtual_machine_extension.this
  ]
}


locals {
  name = var.prefix == "" ? "${var.name}" : format("%s-%s", var.prefix, var.name)
  cleanup_commands = [
    "az vm extension delete -g ${var.resource_group} --vm-name ${local.name}-vm --name ${local.name}-vm-${random_id.this.hex} --no-wait",
  ]
}

####################################################
# random
####################################################

resource "random_id" "this" {
  byte_length = 4
}

####################################################
# public ip
####################################################

resource "azurerm_public_ip" "this" {
  for_each            = { for i in var.interfaces : i.name => i if i.create_public_ip == true }
  resource_group_name = var.resource_group
  name                = "${each.value.name}-pip"
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
  zones               = [1, 2, 3]
  tags                = var.tags
}

####################################################
# interfaces
####################################################

resource "azurerm_network_interface" "this" {
  for_each             = { for i in var.interfaces : i.name => i }
  resource_group_name  = var.resource_group
  name                 = each.value.name
  location             = var.location
  dns_servers          = var.dns_servers
  tags                 = var.tags
  enable_ip_forwarding = var.enable_ip_forwarding

  ip_configuration {
    name                          = each.value.name
    subnet_id                     = each.value.subnet_id
    private_ip_address_allocation = try(each.value.private_ip_address, null) != null ? "Static" : "Dynamic"
    private_ip_address            = try(each.value.private_ip_address, null) != null ? each.value.private_ip_address : null
    public_ip_address_id = (
      try(each.value.create_public_ip, false) ? azurerm_public_ip.this[each.key].id :
      try(each.value.public_ip_address_id, null) != null ? each.value.public_ip_address_id :
      null
    )
  }

  lifecycle {
    ignore_changes = [
      ip_configuration.0.subnet_id,
    ]
  }

  depends_on = [
    azurerm_public_ip.this,
  ]
  timeouts {
    create = "60m"
  }
}

####################################################
# virtual machine
####################################################

resource "azurerm_linux_virtual_machine" "this" {
  resource_group_name = var.resource_group
  name                = local.name
  location            = var.location
  zone                = var.zone
  size                = var.vm_size
  tags                = var.tags
  custom_data         = var.use_vm_extension ? null : var.custom_data

  network_interface_ids = [
    for i in var.interfaces : azurerm_network_interface.this[i.name].id
  ]

  os_disk {
    name                 = "${local.name}-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = var.source_image_publisher
    offer     = var.source_image_offer
    sku       = var.source_image_sku
    version   = var.source_image_version
  }
  dynamic "plan" {
    for_each = var.enable_plan ? [1] : []
    content {
      publisher = var.source_image_publisher
      product   = var.source_image_offer
      name      = var.source_image_sku
    }
  }
  computer_name  = var.computer_name == "" ? local.name : replace(var.computer_name, "_", "-")
  admin_username = var.admin_username
  admin_password = var.admin_password
  boot_diagnostics {
    storage_account_uri = null
  }
  disable_password_authentication = false

  dynamic "identity" {
    for_each = length(var.user_assigned_ids) > 0 ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = var.user_assigned_ids
    }
  }

  dynamic "identity" {
    for_each = length(var.user_assigned_ids) == 0 ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  lifecycle {
    #ignore_changes = all
    # ignore_changes = [
    #   identity,
    #   secure_boot_enabled,
    #   tags,
    # ]
  }
  timeouts {
    create = "60m"
  }
}

####################################################
# virtual machine extension
####################################################

resource "azurerm_virtual_machine_extension" "this" {
  count                      = var.use_vm_extension ? 1 : 0
  name                       = local.name
  virtual_machine_id         = azurerm_linux_virtual_machine.this.id
  publisher                  = var.vm_extension_publisher
  type                       = var.vm_extension_type
  type_handler_version       = var.vm_extension_type_handler_version
  settings                   = var.vm_extension_settings
  auto_upgrade_minor_version = var.vm_extension_auto_upgrade_minor_version
}

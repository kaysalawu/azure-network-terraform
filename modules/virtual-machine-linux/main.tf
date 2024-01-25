
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
      try(each.value.public_ip_id, null) != null ? each.value.public_ip_id :
      null
    )
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
  custom_data         = var.custom_data

  network_interface_ids = [
    for i in var.interfaces : azurerm_network_interface.this[i.name].id
  ]

  os_disk {
    name                 = "${local.name}-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = var.source_image_reference[var.source_image].publisher
    offer     = var.source_image_reference[var.source_image].offer
    sku       = var.source_image_reference[var.source_image].sku
    version   = var.source_image_reference[var.source_image].version
  }
  dynamic "plan" {
    for_each = length(regexall("cisco", var.source_image)) > 0 ? [var.source_image_reference[var.source_image]] : []
    content {
      publisher = plan.value.publisher
      product   = plan.value.offer
      name      = plan.value.sku
    }
  }
  computer_name  = var.computer_name == "" ? local.name : var.computer_name
  admin_username = var.admin_username
  admin_password = var.admin_password
  boot_diagnostics {
    storage_account_uri = null
  }
  disable_password_authentication = false

  dynamic "identity" {
    for_each = var.identity_ids != null ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = var.identity_ids
    }
  }

  lifecycle {
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



locals {
  prefix = var.prefix == "" ? "${var.name}" : format("%s-%s-", var.prefix, var.name)
  params_opnsense = {
    ShellScriptName               = var.shell_script_name
    OpnScriptURI                  = var.opn_script_uri
    OpnVersion                    = var.opn_version
    WALinuxVersion                = var.walinux_version
    OpnType                       = var.opn_type
    TrustedSubnetAddressPrefix    = var.trusted_subnet_address_prefix
    WindowsVmSubnetAddressPrefix  = var.deploy_windows_mgmt ? var.mgmt_subnet_address_prefix : "1.1.1.1/32"
    publicIPAddress               = azurerm_public_ip.this.ip_address
    opnSenseSecondarytrustedNicIP = var.scenario_option == "Active-Active" ? "SOME" : ""
  }
  settings_opnsense = templatefile("${path.module}/settings.tpl", local.params_opnsense)
}

resource "local_file" "params_opnsense" {
  filename = "settings.json"
  content  = local.settings_opnsense
}

####################################################
# public ip
####################################################

resource "azurerm_public_ip" "this" {
  resource_group_name = var.resource_group
  name                = "${local.prefix}pip"
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
  zones               = [1, 2, 3]
  timeouts {
    create = "60m"
  }
  tags = var.tags
}

# ####################################################
# interface
# ####################################################

resource "azurerm_network_interface" "untrust" {
  resource_group_name  = var.resource_group
  name                 = "${local.prefix}nic-untrust"
  location             = var.location
  dns_servers          = var.dns_servers
  tags                 = var.tags
  enable_ip_forwarding = var.enable_ip_forwarding

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = var.untrust_subnet_id
    private_ip_address_allocation = var.private_ip_untrust == null ? "Dynamic" : "Static"
    private_ip_address            = var.private_ip_untrust == null ? null : var.private_ip_untrust
    public_ip_address_id          = var.public_ip_address_id == null ? azurerm_public_ip.this.id : var.public_ip_address_id
  }
}

resource "azurerm_network_interface" "trust" {
  resource_group_name  = var.resource_group
  name                 = "${local.prefix}nic-trust"
  location             = var.location
  dns_servers          = var.dns_servers
  tags                 = var.tags
  enable_ip_forwarding = var.enable_ip_forwarding

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = var.trust_subnet_id
    private_ip_address_allocation = var.private_ip_trust == null ? "Dynamic" : "Static"
    private_ip_address            = var.private_ip_trust == null ? null : var.private_ip_trust
  }
}

# vm

resource "azurerm_linux_virtual_machine" "this" {
  resource_group_name = var.resource_group
  name                = trimsuffix(local.prefix, "-")
  location            = var.location
  zone                = var.zone
  size                = var.vm_size
  tags                = var.tags
  network_interface_ids = [
    azurerm_network_interface.untrust.id,
    azurerm_network_interface.trust.id
  ]
  os_disk {
    name                 = "${local.prefix}vm-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }
  plan {
    publisher = var.image_publisher
    product   = var.image_offer
    name      = var.image_sku
  }
  computer_name  = var.name
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

resource "azurerm_virtual_machine_extension" "this" {
  name                       = trimsuffix(local.prefix, "-")
  virtual_machine_id         = azurerm_linux_virtual_machine.this.id
  publisher                  = "Microsoft.OSTCExtensions"
  type                       = "CustomScriptForLinux"
  type_handler_version       = "1.5"
  auto_upgrade_minor_version = false
  settings                   = local.settings_opnsense
}

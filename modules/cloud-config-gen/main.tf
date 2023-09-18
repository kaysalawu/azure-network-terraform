
locals {
  cloud_config = templatefile(local.template, merge(var.config_variables, {
    packages          = var.packages
    boot_commands     = var.boot_commands
    container_args    = var.container_args
    container_image   = var.container_image
    container_name    = var.container_name
    container_volumes = var.container_volumes
    docker_args       = var.docker_args
    files             = local.files
    run_commands      = var.run_commands
    users             = var.users
  }))
  files = {
    for path, attrs in var.files : path => {
      content = attrs.content,
      owner   = attrs.owner == null ? var.file_defaults.owner : attrs.owner,
      permissions = (
        attrs.permissions == null
        ? var.file_defaults.permissions
        : attrs.permissions
      )
    }
  }
  template = (
    var.cloud_config == null
    ? "${path.module}/cloud-config.yaml"
    : var.cloud_config
  )
}

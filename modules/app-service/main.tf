
locals {
  name = var.prefix == "" ? "${var.name}" : format("%s%s", var.prefix, var.name)
}

# Service Plan

resource "azurerm_service_plan" "this" {
  resource_group_name = var.resource_group
  name                = "${local.name}-asp"
  location            = var.location
  os_type             = "Linux"
  sku_name            = "P1v2"
}

# Httpbin App Service

resource "azurerm_linux_web_app" "this" {
  resource_group_name       = var.resource_group
  name                      = local.name
  location                  = var.location
  service_plan_id           = azurerm_service_plan.this.id
  virtual_network_subnet_id = var.subnet_id

  ftp_publish_basic_authentication_enabled = true

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
  }

  logs {
    detailed_error_messages = true
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
    application_logs {
      file_system_level = "Verbose"
    }
  }

  site_config {
    always_on = true

    application_stack {
      docker_image_name   = var.docker_image_name
      docker_registry_url = var.docker_registry_url
    }
  }
}

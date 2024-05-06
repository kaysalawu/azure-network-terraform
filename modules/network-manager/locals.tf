
locals {
  prefix = var.prefix == "" ? "" : format("%s-", var.prefix)

  default_rules_high_risk = {
    "tcp-high-risk" = {
      description = "tcp-high-risk"
      action      = "Deny"
      direction   = "Inbound"
      priority    = 1
      protocol    = "Tcp"
      destination_port_ranges = [
        "20", "21", "23", "111", "119", "135", "161", "162", "445", "512", "514", "593", "873", "2049", "5800", "5900", "11211",
      ]
      source = [
        { address_prefix_type = "IPPrefix", address_prefix = "*" }
      ]
      destinations = [
        { address_prefix_type = "IPPrefix", address_prefix = "*" }
      ]
    },
    "udp-high-risk" = {
      description = "udp-high-risk"
      action      = "Deny"
      direction   = "Inbound"
      priority    = 2
      protocol    = "Udp"
      destination_port_ranges = [
        "111", "135", "162", "593", "2049",
      ]
      source = [
        { address_prefix_type = "IPPrefix", address_prefix = "*" }
      ]
      destinations = [
        { address_prefix_type = "IPPrefix", address_prefix = "*" }
      ]
    }
  }
}


locals {
  vhub1_vpngw_pip0  = tolist(azurerm_vpn_gateway.vhub1.bgp_settings[0].instance_0_bgp_peering_address[0].tunnel_ips)[1]
  vhub1_vpngw_pip1  = tolist(azurerm_vpn_gateway.vhub1.bgp_settings[0].instance_1_bgp_peering_address[0].tunnel_ips)[1]
  vhub1_vpngw_bgp0  = tolist(azurerm_vpn_gateway.vhub1.bgp_settings[0].instance_0_bgp_peering_address[0].default_ips)[0]
  vhub1_vpngw_bgp1  = tolist(azurerm_vpn_gateway.vhub1.bgp_settings[0].instance_1_bgp_peering_address[0].default_ips)[0]
  vhub1_router_bgp0 = azurerm_virtual_hub.vhub1.virtual_router_ips[1]
  vhub1_router_bgp1 = azurerm_virtual_hub.vhub1.virtual_router_ips[0]
}

# hub
#----------------------------

resource "azurerm_virtual_hub" "vhub1" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.vhub1_prefix}hub"
  location            = local.vhub1_location
  virtual_wan_id      = azurerm_virtual_wan.vwan.id
  address_prefix      = local.vhub1_address_prefix
}

# vpngw
#----------------------------

# s2s

resource "azurerm_vpn_gateway" "vhub1" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.vhub1_prefix}vpngw"
  location            = local.vhub1_location
  virtual_hub_id      = azurerm_virtual_hub.vhub1.id
  bgp_settings {
    asn         = local.vhub1_bgp_asn
    peer_weight = 0
    instance_0_bgp_peering_address {
      custom_ips = [local.vhub1_vpngw_bgp_apipa_0]
    }
    instance_1_bgp_peering_address {
      custom_ips = [local.vhub1_vpngw_bgp_apipa_1]
    }
  }
}

# p2s

/*resource "azurerm_vpn_server_configuration" "vhub1_vpn_server_config" {
  resource_group_name      = azurerm_resource_group.rg.name
  name                     = "${local.vhub1_prefix}vpn-server-config"
  location                 = local.vhub1_location
  vpn_authentication_types = ["Certificate"]

  client_root_certificate {
    name             = "${local.vhub1_prefix}rootps"
    public_cert_data = <<EOF
MIIC5zCCAc+gAwIBAgIQKEOwUXK/gr5L3RKpnpHL+jANBgkqhkiG9w0BAQsFADAW
MRQwEgYDVQQDDAtQMlNSb290Q2VydDAeFw0yMjEyMTQxNDMxNThaFw0yMzEyMTQx
NDUxNThaMBYxFDASBgNVBAMMC1AyU1Jvb3RDZXJ0MIIBIjANBgkqhkiG9w0BAQEF
AAOCAQ8AMIIBCgKCAQEAsC61dKiSh1/a1vVWoDBuOdtN/9rRwYEGNQR4PgMyL2PJ
TQm9FHnZCCoYKunReWyK7peaXzEWnxDDIpV5HwgW8KXTL1C9HoCUOxsYbCBqB0qg
85gdg2rEDlES7uWuxDIBkiVtYNKoHdUWq75M3rrxXAlphGgMCnbeCztuLuIbMWed
1lyX0ft/zLVAE0uB96AsT2wvuo0ZF/el3ivXpx7ilrDe88qePC9Dm16tpDA61+JG
TucDT4c6TgzzZcxmIEk74UHuypEfu3zmp0xKV2GsW6L0Xud0tQChGp3+QxQLlRZG
nNdhMotTp7AqxGq2NODGG3zFeefqsNY83CLo7cHdmQIDAQABozEwLzAOBgNVHQ8B
Af8EBAMCAgQwHQYDVR0OBBYEFGezzmJ72SthYqOfmQx7w3Io2QHdMA0GCSqGSIb3
DQEBCwUAA4IBAQBsrf1iQ8XOekzXYLJuW0d3+yoNZwWKBG1/PnlflSGegtRKz2Vq
/VDOxAYHG+tu40uNz0qGpH2FiZqDzsHSWlTw7j4Yq0Puqo4n17lW0dfzxcQn+VH+
/PeJxCREvU+gbG0EA/DeydnYs6dkwShdX+yRdQH9kf0+1ZtpuMP2VCh2eSsXdqUc
XK3AUGsO2ecXVfXOVZr3IzRBD8F6q228PmacVoqD067YJ1IO70TZc7ISU+HbkR4k
kX9M7TDfO8NBO45VODAK5yDUOf9y1ndyd5akuYXsfAhzeHPTqSMMiNCRfLFi5OeF
0EhBfWStHZbZoYDSSl4f66euLv8nWd0f+bgB
EOF
  }
}*/

/*resource "azurerm_point_to_site_vpn_gateway" "vhub1" {
  resource_group_name         = azurerm_resource_group.rg.name
  name                        = "${local.vhub1_prefix}vpngw"
  location                    = local.vhub1_location
  virtual_hub_id              = azurerm_virtual_hub.vhub1.id
  vpn_server_configuration_id = azurerm_vpn_server_configuration.vhub1_vpn_server_config.id
  scale_unit                  = 1

  connection_configuration {
    name = "blue"
    vpn_client_address_pool {
      address_prefixes = ["192.168.10.0/24", ]
    }
    #route {
    #  associated_route_table_id = azurerm_virtual_hub.vhub1.default_route_table_id
    #  propagated_route_table {
    #    labels = [
    #      "default",
    #      "blue",
    #      "red",
    #    ]
    #    ids = [
    #      #azurerm_virtual_hub.vhub1.default_route_table_id,
    #      #azurerm_virtual_hub_route_table.vhub1_rt_blue.id,
    #      #azurerm_virtual_hub_route_table.vhub1_rt_red.id,
    #    ]
    #  }
    #}
  }
}*/

# vpn-site
#----------------------------

# branch1

resource "azurerm_vpn_site" "vhub1_site_branch1" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.vhub1_prefix}site-branch1"
  location            = local.vhub1_location
  virtual_wan_id      = azurerm_virtual_wan.vwan.id
  device_model        = "Azure"
  device_vendor       = "Microsoft"
  link {
    name          = "${local.vhub1_prefix}site-branch1-link-0"
    provider_name = "Microsoft"
    ip_address    = azurerm_public_ip.branch1_nva_pip.ip_address
    speed_in_mbps = 50
    bgp {
      asn             = local.branch1_nva_asn
      peering_address = local.branch1_nva_loopback0
    }
  }
}

/*# ergw
#----------------------------

resource "azurerm_express_route_gateway" "vhub1" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.vhub1_prefix}ergw"
  location            = local.vhub1_location
  virtual_hub_id      = azurerm_virtual_hub.vhub1.id
  scale_units         = 1
}*/

# route tables
#----------------------------

# blue

resource "azurerm_virtual_hub_route_table" "vhub1_rt_blue" {
  name           = "${local.vhub1_prefix}rt-blue"
  virtual_hub_id = azurerm_virtual_hub.vhub1.id
  labels         = ["blue", ]
}

# red

resource "azurerm_virtual_hub_route_table" "vhub1_rt_red" {
  name           = "${local.vhub1_prefix}rt-red"
  virtual_hub_id = azurerm_virtual_hub.vhub1.id
  labels         = ["red", ]
}


####################################################
# vnet
####################################################

# base
#----------------------------

module "branch3" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.branch3_prefix, "-")
  location        = local.branch3_location
  storage_account = module.common.storage_accounts["region2"]
  tags            = local.branch1_tags

  nsg_subnet_map = {
    "MainSubnet"        = module.common.nsg_main["region2"].id
    "NvaInternalSubnet" = module.common.nsg_main["region2"].id
    "NvaExternalSubnet" = module.common.nsg_nva["region2"].id
    "DnsServerSubnet"   = module.common.nsg_main["region2"].id
  }

  vnet_config = [
    {
      address_space = local.branch3_address_space
      subnets       = local.branch3_subnets
      #nat_gateway_subnet_names = ["${local.branch3_prefix}main", ]
    }
  ]

  depends_on = [
    module.common,
  ]
}

####################################################
# dns
####################################################

module "branch3_dns" {
  source           = "../../modules/linux"
  resource_group   = azurerm_resource_group.rg.name
  prefix           = local.branch3_prefix
  name             = "dns"
  location         = local.branch3_location
  subnet           = module.branch3.subnets["MainSubnet"].id
  private_ip       = local.branch3_dns_addr
  enable_public_ip = true
  source_image     = "ubuntu-20"
  custom_data      = base64encode(local.branch_unbound_startup)
  storage_account  = module.common.storage_accounts["region2"]
  tags             = local.branch3_tags
}

####################################################
# nva
####################################################

locals {
  branch3_network       = cidrhost(local.branch3_subnets["MainSubnet"].address_prefixes[0], 0)
  branch3_mask          = cidrnetmask(local.branch3_subnets["MainSubnet"].address_prefixes[0])
  branch3_inverse_mask_ = [for octet in split(".", local.branch3_mask) : 255 - tonumber(octet)]
  branch3_inverse_mask  = join(".", local.branch3_inverse_mask_)
}

# nva
#----------------------------

locals {
  branch3_nva_route_map_onprem = "ONPREM"
  branch3_nva_route_map_azure  = "AZURE"
  branch3_nva_init = templatefile("../../scripts/cisco-branch.sh", {
    LOCAL_ASN = local.branch3_nva_asn
    LOOPBACK0 = local.branch3_nva_loopback0
    LOOPBACKS = {}
    EXT_ADDR  = local.branch3_nva_ext_addr
    VPN_PSK   = local.psk

    NAT_ACL_PREFIXES = [
      { network = local.branch3_network, inverse_mask = local.branch3_inverse_mask }
    ]

    ROUTE_MAPS = [
      {
        name   = local.branch3_nva_route_map_onprem
        action = "permit"
        rule   = 100
        commands = [
          "match ip address prefix-list all",
          "set as-path prepend ${local.branch3_nva_asn} ${local.branch3_nva_asn} ${local.branch3_nva_asn}"
        ]
      },
      {
        name   = local.branch3_nva_route_map_azure
        action = "permit"
        rule   = 110
        commands = [
          "match ip address prefix-list all",
        ]
      }
    ]

    TUNNELS = [
      {
        ike = {
          name    = "Tunnel0"
          address = cidrhost(local.branch3_nva_tun_range0, 1)
          mask    = cidrnetmask(local.branch3_nva_tun_range0)
          source  = local.branch3_nva_ext_addr
          dest    = module.hub2.vpngw_public_ip0
        },
        ipsec = {
          peer_ip = module.hub2.vpngw_public_ip0
          psk     = local.psk
        }
      },
      {
        ike = {
          name    = "Tunnel1"
          address = cidrhost(local.branch3_nva_tun_range1, 1)
          mask    = cidrnetmask(local.branch3_nva_tun_range1)
          source  = local.branch3_nva_ext_addr
          dest    = module.hub2.vpngw_public_ip1
        },
        ipsec = {
          peer_ip = module.hub2.vpngw_public_ip1
          psk     = local.psk
        }
      },
      {
        ike = {
          name    = "Tunnel2"
          address = cidrhost(local.branch3_nva_tun_range2, 1)
          mask    = cidrnetmask(local.branch3_nva_tun_range2)
          source  = local.branch3_nva_ext_addr
          dest    = local.branch1_nva_ext_addr
        },
        ipsec = {
          peer_ip = local.branch1_nva_ext_addr
          psk     = local.psk
        }
      },
    ]

    STATIC_ROUTES = [
      { network = "0.0.0.0", mask = "0.0.0.0", next_hop = local.branch3_ext_default_gw },
      { network = module.hub2.vpngw_bgp_ip0, mask = "255.255.255.255", next_hop = "Tunnel0" },
      { network = module.hub2.vpngw_bgp_ip1, mask = "255.255.255.255", next_hop = "Tunnel1" },
      { network = local.branch1_nva_loopback0, mask = "255.255.255.255", next_hop = "Tunnel2" },
      {
        network  = local.branch3_network
        mask     = local.branch3_mask
        next_hop = local.branch3_int_default_gw
      },
    ]

    BGP_SESSIONS = [
      {
        peer_asn        = module.hub2.vpngw_bgp_asn,
        peer_ip         = module.hub2.vpngw_bgp_ip0,
        source_loopback = true
        ebgp_multihop   = true
        route_maps = [
          { direction = "out", name = local.branch3_nva_route_map_azure }
        ]
      },
      {
        peer_asn        = module.hub2.vpngw_bgp_asn
        peer_ip         = module.hub2.vpngw_bgp_ip1
        source_loopback = true
        ebgp_multihop   = true
        route_maps = [
          { direction = "out", name = local.branch3_nva_route_map_azure }
        ]
      },
      {
        peer_asn        = local.branch1_nva_asn
        peer_ip         = local.branch1_nva_loopback0
        source_loopback = true
        ebgp_multihop   = true
        route_maps = [
          { direction = "out", name = local.branch3_nva_route_map_onprem }
        ]
      },
    ]

    BGP_ADVERTISED_NETWORKS = [
      {
        network = cidrhost(local.branch3_subnets["MainSubnet"].address_prefixes[0], 0)
        mask    = cidrnetmask(local.branch3_subnets["MainSubnet"].address_prefixes[0])
      },
    ]
  })
}

module "branch3_nva" {
  source               = "../../modules/csr-branch"
  resource_group       = azurerm_resource_group.rg.name
  name                 = "${local.branch3_prefix}nva"
  location             = local.branch3_location
  enable_ip_forwarding = true
  enable_public_ip     = true
  subnet_ext           = module.branch3.subnets["NvaExternalSubnet"].id
  subnet_int           = module.branch3.subnets["NvaInternalSubnet"].id
  private_ip_ext       = local.branch3_nva_ext_addr
  private_ip_int       = local.branch3_nva_int_addr
  public_ip            = azurerm_public_ip.branch3_nva_pip.id
  storage_account      = module.common.storage_accounts["region2"]
  admin_username       = local.username
  admin_password       = local.password
  custom_data          = base64encode(local.branch3_nva_init)
}

####################################################
# workload
####################################################

module "branch3_vm" {
  source           = "../../modules/linux"
  resource_group   = azurerm_resource_group.rg.name
  prefix           = local.branch3_prefix
  name             = "vm"
  location         = local.branch3_location
  subnet           = module.branch3.subnets["MainSubnet"].id
  private_ip       = local.branch3_vm_addr
  enable_public_ip = true
  source_image     = "ubuntu-20"
  custom_data      = base64encode(local.vm_startup)
  dns_servers      = [local.branch3_dns_addr, ]
  storage_account  = module.common.storage_accounts["region2"]
  delay_creation   = "120s"
  tags             = local.branch3_tags
  depends_on = [
    module.branch3,
    module.branch3_dns,
    module.branch3_nva,
  ]
}

####################################################
# udr
####################################################

# main

module "branch3_udr_main" {
  source                        = "../../modules/udr"
  resource_group                = azurerm_resource_group.rg.name
  prefix                        = "${local.branch3_prefix}main"
  location                      = local.branch3_location
  subnet_id                     = module.branch3.subnets["MainSubnet"].id
  next_hop_type                 = "VirtualAppliance"
  next_hop_in_ip_address        = local.branch3_nva_int_addr
  destinations                  = local.private_prefixes_map
  delay_creation                = "90s"
  disable_bgp_route_propagation = true
  depends_on = [
    module.branch3,
    module.branch3_nva,
    module.branch3_dns,
  ]
}

####################################################
# output files
####################################################

locals {
  branch3_files = {
    "output/branch3-nva.sh" = local.branch3_nva_init
  }
}

resource "local_file" "branch3_files" {
  for_each = local.branch3_files
  filename = each.key
  content  = each.value
}

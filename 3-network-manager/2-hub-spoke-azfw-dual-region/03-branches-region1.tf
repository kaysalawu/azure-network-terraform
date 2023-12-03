
####################################################
# vnet
####################################################

# base
#----------------------------

module "branch1" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.branch1_prefix, "-")
  location        = local.branch1_location
  storage_account = module.common.storage_accounts["region1"]
  tags            = local.branch1_tags

  nsg_subnet_map = {
    "MainSubnet"      = module.common.nsg_main["region1"].id
    "TrustSubnet"     = module.common.nsg_main["region1"].id
    "UntrustSubnet"   = module.common.nsg_nva["region1"].id
    "DnsServerSubnet" = module.common.nsg_main["region1"].id
  }

  vnet_config = [
    {
      address_space = local.branch1_address_space
      subnets       = local.branch1_subnets
      #nat_gateway_subnet_names = ["${local.branch1_prefix}main", ]
    }
  ]

  depends_on = [
    module.common,
  ]
}

####################################################
# dns
####################################################

module "branch1_dns" {
  source           = "../../modules/linux"
  resource_group   = azurerm_resource_group.rg.name
  prefix           = local.branch1_prefix
  name             = "dns"
  location         = local.branch1_location
  subnet           = module.branch1.subnets["MainSubnet"].id
  private_ip       = local.branch1_dns_addr
  enable_public_ip = true
  source_image     = "ubuntu-20"
  custom_data      = base64encode(local.branch_unbound_startup)
  storage_account  = module.common.storage_accounts["region1"]
  tags             = local.branch1_tags
}

####################################################
# nva
####################################################

locals {
  branch1_network       = cidrhost(local.branch1_subnets["MainSubnet"].address_prefixes[0], 0)
  branch1_mask          = cidrnetmask(local.branch1_subnets["MainSubnet"].address_prefixes[0])
  branch1_inverse_mask_ = [for octet in split(".", local.branch1_mask) : 255 - tonumber(octet)]
  branch1_inverse_mask  = join(".", local.branch1_inverse_mask_)
}

# nva
#----------------------------

locals {
  branch1_nva_route_map_onprem = "ONPREM"
  branch1_nva_route_map_azure  = "AZURE"
  branch1_nva_init = templatefile("../../scripts/cisco-branch.sh", {
    LOCAL_ASN   = local.branch1_nva_asn
    LOOPBACK0   = local.branch1_nva_loopback0
    LOOPBACKS   = {}
    CRYPTO_ADDR = local.branch1_nva_untrust_addr
    VPN_PSK     = local.psk

    NAT_ACL_PREFIXES = [
      { network = local.branch1_network, inverse_mask = local.branch1_inverse_mask }
    ]

    ROUTE_MAPS = [
      {
        name   = local.branch1_nva_route_map_onprem
        action = "permit"
        rule   = 100
        commands = [
          "match ip address prefix-list all",
          "set as-path prepend ${local.branch1_nva_asn} ${local.branch1_nva_asn} ${local.branch1_nva_asn}"
        ]
      },
      {
        name   = local.branch1_nva_route_map_azure
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
          address = cidrhost(local.branch1_nva_tun_range0, 1)
          mask    = cidrnetmask(local.branch1_nva_tun_range0)
          source  = local.branch1_nva_untrust_addr
          dest    = module.hub1.vpngw_public_ip0
        },
        ipsec = {
          peer_ip = module.hub1.vpngw_public_ip0
          psk     = local.psk
        }
      },
      {
        ike = {
          name    = "Tunnel1"
          address = cidrhost(local.branch1_nva_tun_range1, 1)
          mask    = cidrnetmask(local.branch1_nva_tun_range1)
          source  = local.branch1_nva_untrust_addr
          dest    = module.hub1.vpngw_public_ip1
        },
        ipsec = {
          peer_ip = module.hub1.vpngw_public_ip1
          psk     = local.psk
        }
      },
      {
        ike = {
          name    = "Tunnel2"
          address = cidrhost(local.branch1_nva_tun_range2, 1)
          mask    = cidrnetmask(local.branch1_nva_tun_range2)
          source  = local.branch1_nva_untrust_addr
          dest    = local.branch3_nva_untrust_addr
        },
        ipsec = {
          peer_ip = local.branch3_nva_untrust_addr
          psk     = local.psk
        }
      },
    ]

    STATIC_ROUTES = [
      { network = "0.0.0.0", mask = "0.0.0.0", next_hop = local.branch1_untrust_default_gw },
      { network = module.hub1.vpngw_bgp_ip0, mask = "255.255.255.255", next_hop = "Tunnel0" },
      { network = module.hub1.vpngw_bgp_ip1, mask = "255.255.255.255", next_hop = "Tunnel1" },
      { network = local.branch3_nva_loopback0, mask = "255.255.255.255", next_hop = "Tunnel2" },
      {
        network  = local.branch1_network
        mask     = local.branch1_mask
        next_hop = local.branch1_trust_default_gw
      },
    ]

    BGP_SESSIONS = [
      {
        peer_asn        = module.hub1.vpngw_bgp_asn,
        peer_ip         = module.hub1.vpngw_bgp_ip0,
        source_loopback = true
        ebgp_multihop   = true
        route_maps = [
          { direction = "out", name = local.branch1_nva_route_map_azure }
        ]
      },
      {
        peer_asn        = module.hub1.vpngw_bgp_asn
        peer_ip         = module.hub1.vpngw_bgp_ip1
        source_loopback = true
        ebgp_multihop   = true
        route_maps = [
          { direction = "out", name = local.branch1_nva_route_map_azure }
        ]
      },
      {
        peer_asn        = local.branch3_nva_asn
        peer_ip         = local.branch3_nva_loopback0
        source_loopback = true
        ebgp_multihop   = true
        route_maps = [
          { direction = "out", name = local.branch1_nva_route_map_onprem }
        ]
      },
    ]

    BGP_ADVERTISED_NETWORKS = [
      {
        network = cidrhost(local.branch1_subnets["MainSubnet"].address_prefixes[0], 0)
        mask    = cidrnetmask(local.branch1_subnets["MainSubnet"].address_prefixes[0])
      },
    ]
  })
}

module "branch1_nva" {
  source               = "../../modules/csr-branch"
  resource_group       = azurerm_resource_group.rg.name
  name                 = "${local.branch1_prefix}nva"
  location             = local.branch1_location
  enable_ip_forwarding = true
  enable_public_ip     = true
  subnet_ext           = module.branch1.subnets["UntrustSubnet"].id
  subnet_int           = module.branch1.subnets["TrustSubnet"].id
  private_ip_ext       = local.branch1_nva_untrust_addr
  private_ip_int       = local.branch1_nva_trust_addr
  public_ip            = azurerm_public_ip.branch1_nva_pip.id
  storage_account      = module.common.storage_accounts["region1"]
  admin_username       = local.username
  admin_password       = local.password
  custom_data          = base64encode(local.branch1_nva_init)
}

####################################################
# workload
####################################################

locals {
  branch1_vm_init = templatefile("../../scripts/server.sh", {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = local.vm_script_targets
    TARGETS_HEAVY_TRAFFIC_GEN = [for target in local.vm_script_targets : target.dns if try(target.probe, false)]
    ENABLE_TRAFFIC_GEN        = true
  })
}

module "branch1_vm" {
  source           = "../../modules/linux"
  resource_group   = azurerm_resource_group.rg.name
  prefix           = local.branch1_prefix
  name             = "vm"
  location         = local.branch1_location
  subnet           = module.branch1.subnets["MainSubnet"].id
  private_ip       = local.branch1_vm_addr
  enable_public_ip = true
  source_image     = "ubuntu-20"
  dns_servers      = [local.branch1_dns_addr, ]
  custom_data      = base64encode(local.branch1_vm_init)
  storage_account  = module.common.storage_accounts["region1"]
  delay_creation   = "60s"
  tags             = local.branch1_tags

  depends_on = [
    module.branch1,
    module.branch1_dns,
    module.branch1_nva,
  ]
}

####################################################
# udr
####################################################

# main

module "branch1_udr_main" {
  source                        = "../../modules/udr"
  resource_group                = azurerm_resource_group.rg.name
  prefix                        = "${local.branch1_prefix}main"
  location                      = local.branch1_location
  subnet_id                     = module.branch1.subnets["MainSubnet"].id
  next_hop_type                 = "VirtualAppliance"
  next_hop_in_ip_address        = local.branch1_nva_trust_addr
  destinations                  = local.private_prefixes_map
  delay_creation                = "90s"
  disable_bgp_route_propagation = true
  depends_on = [
    module.branch1,
    module.branch1_nva,
    module.branch1_dns,
  ]
}

####################################################
# output files
####################################################

locals {
  branch1_files = {
    "output/branch1-nva.sh" = local.branch1_nva_init
    "output/branch1-vm.sh"  = local.branch1_vm_init
  }
}

resource "local_file" "branch1_files" {
  for_each = local.branch1_files
  filename = each.key
  content  = each.value
}

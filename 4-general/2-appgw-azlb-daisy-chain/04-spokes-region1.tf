
locals {
  spoke1_cert_name_app1   = "cert"
  spoke1_cert_output_path = "certs/spoke1"
  spoke1_common_name      = "*.az.corp"
  spoke1_host_app1        = "app1.we.az.corp"
  spoke1_host_app2        = "app2.we.az.corp"
  spoke1_host_all         = "*.az.corp"
}

####################################################
# spoke1
####################################################

# base

module "spoke1" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.spoke1_prefix, "-")
  env             = "prod"
  location        = local.spoke1_location
  storage_account = module.common.storage_accounts["region1"]
  tags = {
    "nodeType" = "spoke"
    "env"      = "prod"
  }

  create_private_dns_zone = true
  private_dns_zone_name   = local.spoke1_dns_zone
  private_dns_zone_linked_external_vnets = {
    "hub1" = module.hub1.vnet.id
  }

  nsg_subnet_map = {
    "MainSubnet"               = module.common.nsg_main["region1"].id
    "UntrustSubnet"            = module.common.nsg_open["region1"].id
    "TrustSubnet"              = module.common.nsg_main["region1"].id
    "ManagementSubnet"         = module.common.nsg_main["region1"].id
    "AppGatewaySubnet"         = module.common.nsg_lb["region1"].id
    "LoadBalancerSubnet"       = module.common.nsg_default["region1"].id
    "PrivateLinkServiceSubnet" = module.common.nsg_default["region1"].id
    "PrivateEndpointSubnet"    = module.common.nsg_default["region1"].id
    "AppServiceSubnet"         = module.common.nsg_default["region1"].id
  }

  config_vnet = {
    address_space = local.spoke1_address_space
    subnets       = local.spoke1_subnets
  }
}

# workload

locals {
  spoke1_vm_init = templatefile("../../scripts/server.sh", {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = local.vm_script_targets
    TARGETS_HEAVY_TRAFFIC_GEN = [for target in local.vm_script_targets : target.dns if try(target.probe, false)]
    ENABLE_TRAFFIC_GEN        = true
  })
}

module "spoke1_vm" {
  source                = "../../modules/linux"
  resource_group        = azurerm_resource_group.rg.name
  prefix                = local.spoke1_prefix
  name                  = "vm"
  location              = local.spoke1_location
  subnet                = module.spoke1.subnets["MainSubnet"].id
  private_ip            = local.spoke1_vm_addr
  enable_public_ip      = true
  custom_data           = base64encode(local.spoke1_vm_init)
  storage_account       = module.common.storage_accounts["region1"]
  private_dns_zone_name = local.spoke1_dns_zone
  delay_creation        = "1m"
  tags                  = local.spoke1_tags
  depends_on            = [module.spoke1]
}

####################################################
# backends
####################################################

locals {
  spoke1_be_dir = "/var/lib/spoke"
  spoke1_be_vars = {
    INIT_DIR = local.spoke1_be_dir
  }
}

module "spoke1_web_http_backend_init" {
  source = "../../modules/cloud-config-gen"
  files = {
    "${local.spoke1_be_dir}/docker-compose.yml"    = { owner = "root", permissions = "0744", content = templatefile("../../scripts/containers/web-http/docker-compose.yml", local.spoke1_be_vars) }
    "${local.spoke1_be_dir}/service.sh"            = { owner = "root", permissions = "0744", content = templatefile("../../scripts/containers/web-http/service.sh", local.spoke1_be_vars) }
    "${local.spoke1_be_dir}/start.sh"              = { owner = "root", permissions = "0744", content = templatefile("../../scripts/containers/web-http/start.sh", local.spoke1_be_vars) }
    "${local.spoke1_be_dir}/stop.sh"               = { owner = "root", permissions = "0744", content = templatefile("../../scripts/containers/web-http/stop.sh", local.spoke1_be_vars) }
    "${local.spoke1_be_dir}/app1/Dockerfile"       = { owner = "root", permissions = "0744", content = templatefile("../../scripts/containers/web-http/app1/Dockerfile", local.spoke1_be_vars) }
    "${local.spoke1_be_dir}/app1/dockerignore"     = { owner = "root", permissions = "0744", content = templatefile("../../scripts/containers/web-http/app1/dockerignore", local.spoke1_be_vars) }
    "${local.spoke1_be_dir}/app1/app.py"           = { owner = "root", permissions = "0744", content = templatefile("../../scripts/containers/web-http/app1/app.py", local.spoke1_be_vars) }
    "${local.spoke1_be_dir}/app1/requirements.txt" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/containers/web-http/app1/requirements.txt", local.spoke1_be_vars) }
    "${local.spoke1_be_dir}/app2/Dockerfile"       = { owner = "root", permissions = "0744", content = templatefile("../../scripts/containers/web-http/app2/Dockerfile", local.spoke1_be_vars) }
    "${local.spoke1_be_dir}/app2/dockerignore"     = { owner = "root", permissions = "0744", content = templatefile("../../scripts/containers/web-http/app2/dockerignore", local.spoke1_be_vars) }
    "${local.spoke1_be_dir}/app2/app.py"           = { owner = "root", permissions = "0744", content = templatefile("../../scripts/containers/web-http/app2/app.py", local.spoke1_be_vars) }
    "${local.spoke1_be_dir}/app2/requirements.txt" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/containers/web-http/app2/requirements.txt", local.spoke1_be_vars) }
    "/etc/ssl/app/cert.pem"                        = { owner = "root", permissions = "0400", content = join("\n", [module.spoke1_appgw_app1_cert.cert_pem, tls_self_signed_cert.root_ca.cert_pem]) }
    "/etc/ssl/app/cert.key"                        = { owner = "root", permissions = "0400", content = module.spoke1_appgw_app1_cert.private_key_pem }
  }
  run_commands = [
    ". ${local.spoke1_be_dir}/service.sh",
  ]
}

module "spoke1_be1" {
  source                = "../../modules/linux"
  resource_group        = azurerm_resource_group.rg.name
  prefix                = local.spoke1_prefix
  name                  = "be1"
  location              = local.spoke1_location
  subnet                = module.spoke1.subnets["MainSubnet"].id
  private_ip            = local.spoke1_be1_addr
  enable_public_ip      = true
  custom_data           = base64encode(module.spoke1_web_http_backend_init.cloud_config)
  storage_account       = module.common.storage_accounts["region1"]
  source_image          = "ubuntu-22"
  private_dns_zone_name = local.spoke1_dns_zone
  tags                  = local.spoke1_tags
}

module "spoke1_be2" {
  source                = "../../modules/linux"
  resource_group        = azurerm_resource_group.rg.name
  prefix                = local.spoke1_prefix
  name                  = "be2"
  location              = local.spoke1_location
  subnet                = module.spoke1.subnets["MainSubnet"].id
  private_ip            = local.spoke1_be2_addr
  enable_public_ip      = true
  custom_data           = base64encode(module.spoke1_web_http_backend_init.cloud_config)
  storage_account       = module.common.storage_accounts["region1"]
  source_image          = "ubuntu-22"
  private_dns_zone_name = local.spoke1_dns_zone
  tags                  = local.spoke1_tags
}

####################################################
# client cert
####################################################

module "spoke1_appgw_app1_cert" {
  source   = "../../modules/self-signed-cert"
  name     = local.spoke1_cert_name_app1
  rsa_bits = 2048
  subject = {
    common_name         = local.spoke1_host_all
    organization        = "app1 demo"
    organizational_unit = "app1 network team"
    street_address      = "99 mpls chicken road, network avenue"
    locality            = "London"
    province            = "England"
    country             = "UK"
  }
  dns_names = [
    local.spoke1_host_all,
  ]
  ca_private_key_pem = tls_private_key.root_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.root_ca.cert_pem
  cert_output_path   = local.spoke1_cert_output_path
}

####################################################
# output files
####################################################

locals {
  spoke1_files = {
    "output/spoke1-be-init"    = module.spoke1_web_http_backend_init.cloud_config
    "certs/spoke1/root-ca.pem" = tls_self_signed_cert.root_ca.cert_pem
    "certs/spoke1/cert.key"    = module.spoke1_appgw_app1_cert.private_key_pem
    "certs/spoke1/cert.pem"    = join("\n", [module.spoke1_appgw_app1_cert.cert_pem, tls_self_signed_cert.root_ca.cert_pem])
  }
}

resource "local_file" "spoke1_files" {
  for_each = local.spoke1_files
  filename = each.key
  content  = each.value
}

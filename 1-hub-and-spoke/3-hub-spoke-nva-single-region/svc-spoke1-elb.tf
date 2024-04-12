
###################################################
# external load balancer
###################################################

module "azure_lb_dual_stack" {
  source              = "../../modules/azure-load-balancer"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.spoke1_location
  prefix              = trimsuffix(local.spoke1_prefix, "-")
  name                = "dualStack"
  type                = "public"
  lb_sku              = "Standard"
  enable_dual_stack   = true

  log_analytics_workspace_name = module.common.log_analytics_workspaces["region1"].name

  frontend_ip_configuration = [
    {
      name              = "be1-app-v4"
      subnet_id         = module.spoke1.subnets["LoadBalancerSubnet"].id
      domain_name_label = "be1appv4"
    },
    # {
    #   name              = "vm-app-v4"
    #   subnet_id         = module.spoke1.subnets["LoadBalancerSubnet"].id
    #   domain_name_label = "vmappv4"
    # },
    {
      name                      = "vm-app-v6"
      subnet_id                 = module.spoke1.subnets["LoadBalancerSubnet"].id
      public_ip_address_version = "IPv6"
      domain_name_label         = "vmappv6"
    }
    # {
    #   name               = "fe-snat4"
    #   subnet_id          = module.spoke1.subnets["LoadBalancerSubnet"].id
    #   private_ip_address = local.spoke1_ilb_addr
    # },
    # {
    #   name                       = "fe-snat6"
    #   subnet_id                  = module.spoke1.subnets["LoadBalancerSubnet"].id
    #   private_ip_address_version = "IPv6"
    #   public_ip_address_version  = "IPv6"
    # },
  ]

  probes = [
    # { name = "http-8080", protocol = "Http", port = "8080", request_path = "/healthz" },
    { name = "tcp-8080", protocol = "Tcp", port = "8080" },
  ]

  backend_pools = [
    {
      name = "be1-app-v4"
      interfaces = [
        {
          ip_configuration_name = module.spoke1_be1.interface_name
          network_interface_id  = module.spoke1_be1.interface_id
        },
      ]
    },
    # {
    #   name = "vm-app-v4"
    #   addresses = [
    #     {
    #       name               = "spoke1vm-v4"
    #       virtual_network_id = module.spoke1.vnet.id
    #       ip_address         = module.spoke1_vm.private_ipv6_address
    #     },
    #   ]
    # },
    {
      name = "vm-app-v6"
      addresses = [
        {
          name               = "spoke1vm-v6"
          virtual_network_id = module.spoke1.vnet.id
          ip_address         = module.spoke1_vm.private_ipv6_address
        },
      ]
    },
    # {
    #   name = "snat4"
    #   interfaces = [
    #     {
    #       ip_configuration_name = module.spoke1_be1.interface_name
    #       network_interface_id  = module.spoke1_be1.interface_id
    #     },
    #   ]
    # },
    # {
    #   name = "snat6"
    #   addresses = [
    #     {
    #       name               = "snat6"
    #       virtual_network_id = module.spoke1.vnet.id
    #       ip_address         = module.spoke1_be1.private_ipv6_address
    #     },
    #   ]
    # },
  ]

  lb_rules = [
    {
      name                           = "be1-app-v4"
      protocol                       = "Tcp"
      frontend_port                  = "80"
      backend_port                   = "8080"
      frontend_ip_configuration_name = "be1-app-v4"
      backend_address_pool_name      = ["be1-app-v4", ]
      probe_name                     = "tcp-8080"
    },
    # {
    #   name                           = "vm-app-v4"
    #   protocol                       = "Tcp"
    #   frontend_port                  = "80"
    #   backend_port                   = "8080"
    #   frontend_ip_configuration_name = "vm-app-v4"
    #   backend_address_pool_name      = ["vm-app-v4", ]
    #   probe_name                     = "tcp-8080"
    # },
    {
      name                           = "vm-app-v6"
      protocol                       = "Tcp"
      frontend_port                  = "80"
      backend_port                   = "8080"
      frontend_ip_configuration_name = "vm-app-v6"
      backend_address_pool_name      = ["vm-app-v6", ]
      probe_name                     = "tcp-8080"
    }
  ]

  outbound_rules = [
    # {
    #   name                           = "snat4"
    #   frontend_ip_configuration_name = "fe-snat4"
    #   backend_address_pool_name      = "snat4"
    #   protocol                       = "All"
    #   allocated_outbound_ports       = 1024
    #   idle_timeout_in_minutes        = 4
    # },
    # {
    #   name                           = "snat6"
    #   frontend_ip_configuration_name = "fe-snat6"
    #   backend_address_pool_name      = "snat6"
    #   protocol                       = "All"
    #   allocated_outbound_ports       = 1024
    #   idle_timeout_in_minutes        = 4
    # },
  ]
}

###################################################
# backends
###################################################

locals {
  spoke1_be1_init_vars = {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []
  }
  spoke1_be1_init_files = {
    "${local.init_dir}/fastapi/docker-compose-app1-80.yml"   = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/docker-compose-app1-80.yml", {}) }
    "${local.init_dir}/fastapi/docker-compose-app2-8080.yml" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/docker-compose-app2-8080.yml", {}) }
    "${local.init_dir}/fastapi/app/app/Dockerfile"           = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/app/app/Dockerfile", {}) }
    "${local.init_dir}/fastapi/app/app/_app.py"              = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/app/app/_app.py", {}) }
    "${local.init_dir}/fastapi/app/app/main.py"              = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/app/app/main.py", {}) }
    "${local.init_dir}/fastapi/app/app/requirements.txt"     = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/app/app/requirements.txt", {}) }
    "${local.init_dir}/init/start.sh"                        = { owner = "root", permissions = "0744", content = templatefile("../../scripts/startup.sh", local.spoke1_be1_init_vars) }
  }
}

module "spoke1_be1_cloud_init" {
  source = "../../modules/cloud-config-gen"
  files  = local.spoke1_be1_init_files
  packages = [
    "docker.io", "docker-compose", "npm",
  ]
  run_commands = [
    "systemctl enable docker",
    "systemctl start docker",
    "bash ${local.init_dir}/init/start.sh",
    "docker-compose -f ${local.init_dir}/fastapi/docker-compose-app1-80.yml up -d",
    "docker-compose -f ${local.init_dir}/fastapi/docker-compose-app2-8080.yml up -d",
  ]
}

module "spoke1_be1" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-spoke1Be1"
  computer_name   = "spoke1Be1"
  location        = local.spoke1_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.spoke1_be1_cloud_init.cloud_config)
  tags            = local.spoke1_tags

  enable_ipv6 = false
  interfaces = [
    {
      name      = "${local.spoke1_prefix}be1-test-nic"
      subnet_id = module.spoke1.subnets["TestSubnet"].id
    },
  ]
  depends_on = [
    time_sleep.spoke1,
  ]
}

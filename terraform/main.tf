terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.71.0"
    }
  }
}

provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {
  }
}
data "azurerm_client_config" "current" {
}

resource "azurerm_resource_group" "mgmt_rg" {
  name     = var.mgmt_resource_group_name
  location = var.location
  tags     = var.tags
}

module "log_analytics_workspace" {
  source                           = "./modules/log_analytics"
  name                             = var.log_analytics_workspace_name
  location                         = var.location
  resource_group_name              = azurerm_resource_group.mgmt_rg.name
  solution_plan_map                = var.solution_plan_map
}

module "mgmt_network" {
  source                       = "./modules/virtual_network"
  resource_group_name          = azurerm_resource_group.mgmt_rg.name
  location                     = var.location
  vnet_name                    = var.mgmt_vnet_name
  address_space                = var.mgmt_address_space
  tags                         = var.tags
  log_analytics_workspace_id   = module.log_analytics_workspace.id
  log_analytics_retention_days = var.log_analytics_retention_days

  subnets = [
    {
      name : "serverSubnet"
      address_prefixes : var.mgmt_bastion_subnet_address_prefix
      enforce_private_link_endpoint_network_policies : true
      enforce_private_link_service_network_policies : false
    },
    {
      name : var.cluster_subnet_name
      address_prefixes : var.cluster_subnet_address_prefix
      enforce_private_link_endpoint_network_policies : true
      enforce_private_link_service_network_policies : false
    }
  ]
  depends_on                   = [module.log_analytics_workspace]
}

module "aks_cluster" {
  source                                   = "./modules/aks"
  name                                     = var.aks_cluster_name
  location                                 = var.location
  resource_group_name                      = azurerm_resource_group.mgmt_rg.name
  dns_prefix                               = lower(var.aks_cluster_name)
  private_cluster_enabled                  = true
  sku_tier                                 = var.sku_tier
  vnet_subnet_id                           = module.mgmt_network.subnet_ids[var.cluster_subnet_name]
  default_node_pool_node_taints            = var.default_node_pool_node_taints
  default_node_pool_enable_host_encryption = false
  default_node_pool_min_count              = 1
  default_node_pool_node_count             = 1
  tags                                     = var.tags
  log_analytics_workspace_id               = module.log_analytics_workspace.id
  tenant_id                                = data.azurerm_client_config.current.tenant_id
  admin_group_object_ids                   = var.admin_group_object_ids
  admin_username                           = var.admin_username
  ssh_public_key                           = file(var.ssh_public_key)
  ingress_application_gateway              = {enabled      = false           
                                              gateway_id   = null
                                              gateway_name = null
                                              subnet_cidr  = var.aks_app_gateway_subnet 
                                              subnet_id    = null}
  depends_on                               = [module.mgmt_network, module.log_analytics_workspace]

}
# Jumpbox
module "virtual_machine" {
  source                              = "./modules/virtual_machine"
  name                                = var.jumpbox_vm_name
  size                                = var.jumpbox_vm_size
  location                            = var.location
  public_ip                           = false
  vm_user                             = var.admin_username
  admin_ssh_public_key                = file(var.ssh_public_key)
  os_disk_image                       = var.jumpbox_vm_os_disk_image
  domain_name_label                   = var.domain_name_label
  resource_group_name                 = azurerm_resource_group.mgmt_rg.name
  vnet_id                             = module.mgmt_network.vnet_id
  subnet_id                           = module.mgmt_network.subnet_ids["serverSubnet"]
  os_disk_storage_account_type        = var.jumpbox_vm_os_disk_storage_account_type
  depends_on                          = [module.mgmt_network]
}
# Peer to Hub VNET
module "vnet_peering" {
  source                    = "./modules/virtual_network_peering"
  hub_vnet_name             = "hubnet-vnet"
  hub_vnet_id               = "/subscriptions/b464152a-a78e-48f5-85af-268bd1a50744/resourceGroups/hubnet/providers/Microsoft.Network/virtualNetworks/hubnet-vnet"
  hub_vnet_rg               = "hubnet"
  spoke_vnet_name            = var.mgmt_vnet_name
  spoke_vnet_id              = module.mgmt_network.vnet_id
  spoke_vnet_rg              = azurerm_resource_group.mgmt_rg.name
  peering_name_hub_to_spoke = "hubTo${var.mgmt_vnet_name}"
  peering_name_spoke_to_hub = "${var.mgmt_vnet_name}ToHub"
  depends_on                = [module.mgmt_network]
}

module "diagnostic_settings" {
    source                        = "./modules/diagnostic_settings"
    depends_on                    = [module.aks_cluster, module.mgmt_network]
    log_analytics_workspace_id    = module.log_analytics_workspace.id
    vnet_id                       = module.mgmt_network.vnet_id
    aks_cluster_id                = module.aks_cluster.id
    log_analytics_retention_days  = var.log_analytics_retention_days
    acr_id                        = module.container_registry.id
}
# Route spokes through hub vnet
module "routetable" {
  source               = "./modules/route_table"
  depends_on           = [module.mgmt_network]
  resource_group_name  = azurerm_resource_group.mgmt_rg.name
  location             = var.location
  route_table_name     = "hub-nva-routes"
  nva_private_ip       = "192.168.24.132"
  subnets_to_associate = {
    (var.cluster_subnet_name) = {
      subscription_id      = data.azurerm_client_config.current.subscription_id
      resource_group_name  = azurerm_resource_group.mgmt_rg.name
      virtual_network_name = module.mgmt_network.name
    },
    "serverSubnet" = {
      subscription_id      = data.azurerm_client_config.current.subscription_id
      resource_group_name  = azurerm_resource_group.mgmt_rg.name
      virtual_network_name = module.mgmt_network.name
    },
    "ClusterSubnet" = {
      subscription_id      = data.azurerm_client_config.current.subscription_id
      resource_group_name  = "gitops-demo-app"
      virtual_network_name = "appVnet"
    },
    "endpointSubnet" = {
      subscription_id      = data.azurerm_client_config.current.subscription_id
      resource_group_name  = "gitops-demo-app"
      virtual_network_name = "appVnet"
    }
  }
}
# ACR, Private Endpoint, Private DNS zone
module "container_registry" {
  source                        = "./modules/container_registry"
  name                          = var.acr_name
  resource_group_name           = azurerm_resource_group.mgmt_rg.name
  location                      = var.location
  sku                           = var.acr_sku
  admin_enabled                 = var.acr_admin_enabled
  georeplication_locations      = var.acr_georeplication_locations
  public_network_access_enabled = false
}

module "acr_private_endpoint" {
  source                         = "./modules/private_endpoint"
  name                           = "${module.container_registry.name}PrivateEndpoint"
  location                       = var.location
  resource_group_name            = azurerm_resource_group.mgmt_rg.name
  subnet_id                      = module.mgmt_network.subnet_ids["serverSubnet"]
  tags                           = var.tags
  private_connection_resource_id = module.container_registry.id
  is_manual_connection           = false
  subresource_name               = "registry"
  private_dns_zone_group_name    = "AcrPrivateDnsZoneGroup"
  private_dns_zone_group_ids     = [module.acr_private_dns_zone.id]
}

module "acr_private_dns_zone" {
  source                       = "./modules/private_dns_zone"
  name                         = "privatelink.azurecr.io"
  resource_group_name          = azurerm_resource_group.mgmt_rg.name
  virtual_networks_to_link     = {
    (module.mgmt_network.name) = {
      subscription_id = data.azurerm_client_config.current.subscription_id
      resource_group_name = azurerm_resource_group.mgmt_rg.name
    },
    "appVnet" = {
      subscription_id = data.azurerm_client_config.current.subscription_id
      resource_group_name = "gitops-demo-app"
    }
  }
}
# If using AGIC and specifying a subnet cidr, the cluster identity will
# need contributor access to the cluster vnet to add the subnet
resource "azurerm_role_assignment" "agic_vnet_contributor" {
  count                = module.aks_cluster.ingress_identity_id != null ? 1 : 0
  scope                = module.mgmt_network.vnet_id         
  role_definition_name = "Contributor"
  principal_id         = module.aks_cluster.ingress_identity_id
}

# Add ACR role assignments
resource "azurerm_role_assignment" "aks_acr" {
  scope                = module.container_registry.id
  role_definition_name = "AcrPull"
  principal_id         = module.aks_cluster.kubelet_identity
}

resource "azurerm_role_assignment" "aks_acr_push" {
  scope                = module.container_registry.id
  role_definition_name = "AcrPush"
  principal_id         = module.aks_cluster.kubelet_identity
}

module "vote_app_cluster" {
  source                       = "./modules/app_cluster"
  log_analytics_workspace_id   = module.log_analytics_workspace.id
  mgmt_vnet_name               = "hubnet-vnet"
  mgmt_vnet_id                 = "/subscriptions/b464152a-a78e-48f5-85af-268bd1a50744/resourceGroups/hubnet/providers/Microsoft.Network/virtualNetworks/hubnet-vnet"
  mgmt_vnet_rg                 = "hubnet"
  acr_private_dns_zone_id      = module.acr_private_dns_zone.id
  ssh_public_key               = file(var.ssh_public_key)
}
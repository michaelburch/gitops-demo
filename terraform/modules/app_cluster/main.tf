
data "azurerm_client_config" "current" {
}

resource "azurerm_resource_group" "app_rg" {
  name     = var.app_rg_name
  location = var.location
  tags     = var.tags
}

module "app_vnet" {
  source                       = "../virtual_network"
  resource_group_name          = azurerm_resource_group.app_rg.name
  location                     = var.location
  vnet_name                    = var.app_vnet_name
  address_space                = var.app_address_space
  tags                         = var.tags
  log_analytics_workspace_id   = var.log_analytics_workspace_id
  log_analytics_retention_days = var.log_analytics_retention_days

  subnets = [
    {
      name : "endpointSubnet"
      address_prefixes : var.endpoint_subnet_address_prefix
      enforce_private_link_endpoint_network_policies : true
      enforce_private_link_service_network_policies : false
    },
    {
      name : var.app_cluster_subnet_name
      address_prefixes : var.app_cluster_subnet_address_prefix
      enforce_private_link_endpoint_network_policies : true
      enforce_private_link_service_network_policies : false
    }
  ]
}

module "app_aks_cluster" {
  source                                   = "../aks"
  name                                     = var.app_aks_cluster_name
  location                                 = var.location
  resource_group_name                      = azurerm_resource_group.app_rg.name
  dns_prefix                               = lower(var.app_aks_cluster_name)
  private_cluster_enabled                  = true
  sku_tier                                 = var.sku_tier
  vnet_subnet_id                           = module.app_vnet.subnet_ids[var.app_cluster_subnet_name]
  default_node_pool_node_taints            = var.default_node_pool_node_taints
  default_node_pool_enable_host_encryption = false
  default_node_pool_min_count              = 1
  default_node_pool_node_count             = 1
  tags                                     = var.tags
  log_analytics_workspace_id               = var.log_analytics_workspace_id
  tenant_id                                = data.azurerm_client_config.current.tenant_id
  admin_group_object_ids                   = var.app_admin_group_object_ids
  admin_username                           = var.app_admin_username
  ssh_public_key                           = var.ssh_public_key
  ingress_application_gateway              = {enabled      = var.aks_app_gateway_enabled           
                                              gateway_id   = null
                                              gateway_name = null
                                              subnet_cidr  = var.aks_app_gateway_subnet 
                                              subnet_id    = null}
  depends_on                               = [module.app_vnet]

}

# Peer to MGMT VNET
module "vnet_peering" {
  source                     = "../virtual_network_peering"
  hub_vnet_name              = var.mgmt_vnet_name
  hub_vnet_id                = var.mgmt_vnet_id
  hub_vnet_rg                = var.mgmt_vnet_rg
  spoke_vnet_name            = var.app_vnet_name
  spoke_vnet_id              = module.app_vnet.vnet_id
  spoke_vnet_rg              = azurerm_resource_group.app_rg.name
  peering_name_hub_to_spoke  = "mgmtTo${var.app_vnet_name}"
  peering_name_spoke_to_hub  = "${var.app_vnet_name}ToMgmt"
  depends_on                 = [module.app_vnet]
}

module "diagnostic_settings" {
    source                        = "../diagnostic_settings"
    depends_on                    = [module.app_aks_cluster, module.app_vnet]
    log_analytics_workspace_id    = var.log_analytics_workspace_id
    vnet_id                       = module.app_vnet.vnet_id
    aks_cluster_id                = module.app_aks_cluster.id
    log_analytics_retention_days  = var.log_analytics_retention_days
    acr_id                        = module.container_registry.id
}

# ACR, Private Endpoint, Private DNS zone
module "container_registry" {
  source                        = "../container_registry"
  name                          = var.acr_name
  resource_group_name           = azurerm_resource_group.app_rg.name
  location                      = var.location
  sku                           = var.acr_sku
  admin_enabled                 = var.acr_admin_enabled
  georeplication_locations      = var.acr_georeplication_locations
  public_network_access_enabled = false
}

module "acr_private_endpoint" {
  source                         = "../private_endpoint"
  name                           = "${module.container_registry.name}PrivateEndpoint"
  location                       = var.location
  resource_group_name            = azurerm_resource_group.app_rg.name
  subnet_id                      = module.app_vnet.subnet_ids["endpointSubnet"]
  tags                           = var.tags
  private_connection_resource_id = module.container_registry.id
  is_manual_connection           = false
  subresource_name               = "registry"
  private_dns_zone_group_name    = "AcrPrivateDnsZoneGroup"
  private_dns_zone_group_ids     = [var.acr_private_dns_zone_id]
}


# If using AGIC and specifying a subnet cidr, the cluster identity will
# need contributor access to the cluster vnet to add the subnet
resource "azurerm_role_assignment" "agic_vnet_contributor" {
  count                = var.aks_app_gateway_enabled && var.aks_app_gateway_subnet != null ? 1 : 0
  scope                = module.app_vnet.vnet_id         
  role_definition_name = "Contributor"
  principal_id         = module.app_aks_cluster.ingress_identity_id
}

# Add ACR role assignments
resource "azurerm_role_assignment" "aks_acr" {
  scope                = module.container_registry.id
  role_definition_name = "AcrPull"
  principal_id         = module.app_aks_cluster.kubelet_identity
}

resource "azurerm_role_assignment" "aks_acr_push" {
  scope                = module.container_registry.id
  role_definition_name = "AcrPush"
  principal_id         = module.app_aks_cluster.kubelet_identity
}
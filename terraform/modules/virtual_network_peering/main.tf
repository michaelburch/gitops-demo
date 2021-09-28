terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.71.0"
    }
  }

  required_version = ">= 0.14.9"
}

resource "azurerm_virtual_network_peering" "hub_peering" {
  name                      = var.peering_name_hub_to_spoke
  resource_group_name       = var.hub_vnet_rg
  virtual_network_name      = var.hub_vnet_name
  remote_virtual_network_id = var.spoke_vnet_id
}

resource "azurerm_virtual_network_peering" "spoke_peering" {
  name                      = var.peering_name_spoke_to_hub
  resource_group_name       = var.spoke_vnet_rg
  virtual_network_name      = var.spoke_vnet_name
  remote_virtual_network_id = var.hub_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}
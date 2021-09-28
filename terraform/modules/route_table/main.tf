terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }

  required_version = ">= 0.14.9"
}

data "azurerm_client_config" "current" {
}

resource "azurerm_route_table" "spoke_rt" {
  name                = var.route_table_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  route = [{
    name                   = "vpn-remote-office"
    address_prefix         = "192.168.16.0/21"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.nva_private_ip
  },
  {
    name                   = "spokes"
    address_prefix         = "192.168.24.0/22"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.nva_private_ip
  }]

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_subnet_route_table_association" "subnet_association" {
  for_each = var.subnets_to_associate

  subnet_id      = "/subscriptions/${each.value.subscription_id}/resourceGroups/${each.value.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${each.value.virtual_network_name}/subnets/${each.key}"
  route_table_id = azurerm_route_table.spoke_rt.id
}
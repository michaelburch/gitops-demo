variable "hub_vnet_name" {
  description = "Specifies the name of the first virtual network"
  type        = string
}

variable "hub_vnet_id" {
  description = "Specifies the resource id of the first virtual network"
  type        = string
}

variable "hub_vnet_rg" {
  description = "Specifies the resource group name of the first virtual network"
  type        = string
}

variable "spoke_vnet_name" {
  description = "Specifies the name of the second virtual network"
  type        = string
}

variable "spoke_vnet_id" {
  description = "Specifies the resource id of the second virtual network"
  type        = string
}

variable "spoke_vnet_rg" {
  description = "Specifies the resource group name of the second virtual network"
  type        = string
}

variable "peering_name_hub_to_spoke" {
  description = "(Optional) Specifies the name of the first to second virtual network peering"
  type        = string
  default     = "hub_to_spoke"
}

variable "peering_name_spoke_to_hub" {
  description = "(Optional) Specifies the name of the second to first virtual network peering"
  type        = string
  default     = "spoke_to_hub"
}
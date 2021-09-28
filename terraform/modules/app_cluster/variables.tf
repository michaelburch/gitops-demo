variable "location" {
  description = "Specifies the location for the resource group and all the resources"
  default     = "southcentralus"
  type        = string
}
variable "app_rg_name" {
  description = "Specifies the resource group name"
  default     = "gitops-demo-app"
  type        = string
}

variable "app_vnet_name" {
  description = "Specifies the name of the app virtual virtual network"
  default     = "appVnet"
  type        = string
}

variable "mgmt_vnet_name" {
  description = "Specifies the name of the mgmt virtual virtual network"
  default     = "mgmtVnet"
  type        = string
}
variable "mgmt_vnet_id" {
  description = "Specifies the id of the mgmt virtual network"
  default     = null
  type        = string
}
variable "mgmt_vnet_rg" {
  description = "Specifies the name of the resource group containing the mgmt virtual network"
  default     = "gitops-demo-mgmt"
  type        = string
}

variable "app_address_space" {
  description = "Specifies the address space of the mgmt virtual virtual network"
  default     = ["192.168.26.0/24"]
  type        = list(string)
}
variable "log_analytics_workspace_id" {
  description = "Specifies the id of the log analytics workspace"
  default     = null
  type        = string
}
variable "log_analytics_retention_days" {
  description = "Specifies the number of days of the retention policy"
  type        = number
  default     = 30
}
variable "solution_plan_map" {
  description = "Specifies solutions to deploy to log analytics workspace"
  default     = {
    ContainerInsights= {
      product   = "OMSGallery/ContainerInsights"
      publisher = "Microsoft"
    }
  }
  type = map(any)
}
variable "endpoint_subnet_address_prefix" {
  description = "Specifies the address prefix of the endpoint subnet"
  default     = ["192.168.26.0/26"]
  type        = list(string)
}

variable "app_cluster_subnet_name" {
  description = "Specifies the name of the cluster subnet"
  default     = "ClusterSubnet"
  type        = string
}

variable "app_cluster_subnet_address_prefix" {
  description = "Specifies the address prefix of the cluster subnet"
  default     = ["192.168.26.128/25"]
  type        = list(string)
}
variable "tags" {
  description = "(Optional) Specifies tags for all the resources"
  default     = {
    createdWith = "Terraform"
  }
}
variable "app_aks_cluster_name" {
  description = "(Required) Specifies the name of the AKS cluster."
  default     = "appAks"
  type        = string
}
variable "sku_tier" {
  description = "(Optional) The SKU Tier that should be used for this Kubernetes Cluster. Possible values are Free and Paid (which includes the Uptime SLA). Defaults to Free."
  default     = "Free"
  type        = string

  validation {
    condition = contains( ["Free", "Paid"], var.sku_tier)
    error_message = "The sku tier is invalid."
  }
}
variable "app_admin_group_object_ids" {
  description = "(Optional) A list of Object IDs of Azure Active Directory Groups which should have Admin Role on the Cluster."
  default     = ["eea3c5e4-7768-4274-a881-e0bf2e6cd464"]
  type        = list(string)
}
variable "app_admin_username" {
  description = "(Required) Specifies the admin username of the AKS worker nodes."
  type        = string
  default     = "azadmin"
}
variable "ssh_public_key" {
  description = "(Required) Specifies the SSH public key for the AKS worker nodes."
  type        = string
  default     = "id_rsa.pub"
}

variable "default_node_pool_node_taints" {
  description = "(Optional) A map of Kubernetes labels which should be applied to nodes in this Node Pool. Changing this forces a new resource to be created."
  type          = list(string)
  default       = []
} 

variable "acr_name" {
  description = "Specifies the name of the container registry"
  type        = string
  default     = "appAcr50744"
}

variable "acr_sku" {
  description = "Specifies the name of the container registry"
  type        = string
  default     = "Premium"

  validation {
    condition = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "The container registry sku is invalid."
  }
}

variable "acr_admin_enabled" {
  description = "Specifies whether admin is enabled for the container registry"
  type        = bool
  default     = true
}

variable "acr_georeplication_locations" {
  description = "(Optional) A list of Azure locations where the container registry should be geo-replicated."
  type        = list(string)
  default     = []
}
variable "aks_app_gateway_enabled" {
  description = "Specifies whether AGIC is enabled"
  type        = bool
  default     = true
}
variable "aks_app_gateway_subnet" {
  description = "Specifies subnet for AGIC"
  type        = string
  default     = "192.168.26.64/26"
}

variable "acr_private_dns_zone_id" {
  description = "Specifies the id of the private DNS zone to link to ACR"
  type        = string
  default     = null
}

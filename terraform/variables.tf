variable "location" {
  description = "Specifies the location for the resource group and all the resources"
  default     = "southcentralus"
  type        = string
}
variable "mgmt_resource_group_name" {
  description = "Specifies the resource group name"
  default     = "gitops-demo-mgmt"
  type        = string
}

variable "mgmt_vnet_name" {
  description = "Specifies the name of the mgmt virtual virtual network"
  default     = "mgmtVnet"
  type        = string
}

variable "mgmt_address_space" {
  description = "Specifies the address space of the mgmt virtual virtual network"
  default     = ["192.168.25.0/24"]
  type        = list(string)
}
variable "log_analytics_workspace_name" {
  description = "Specifies the name of the log analytics workspace"
  default     = "mgmtWorkspace"
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
variable "mgmt_bastion_subnet_address_prefix" {
  description = "Specifies the address prefix of the bastion subnet"
  default     = ["192.168.25.0/26"]
  type        = list(string)
}

variable "cluster_subnet_name" {
  description = "Specifies the name of the cluster subnet"
  default     = "ClusterSubnet"
  type        = string
}

variable "cluster_subnet_address_prefix" {
  description = "Specifies the address prefix of the cluster subnet"
  default     = ["192.168.25.128/25"]
  type        = list(string)
}
variable "tags" {
  description = "(Optional) Specifies tags for all the resources"
  default     = {
    createdWith = "Terraform"
  }
}
variable "aks_cluster_name" {
  description = "(Required) Specifies the name of the AKS cluster."
  default     = "mgmtAks"
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
variable "admin_group_object_ids" {
  description = "(Optional) A list of Object IDs of Azure Active Directory Groups which should have Admin Role on the Cluster."
  default     = ["eea3c5e4-7768-4274-a881-e0bf2e6cd464"]
  type        = list(string)
}
variable "admin_username" {
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
variable "jumpbox_vm_name" {
  description = "Specifies the name of the jumpbox virtual machine"
  default     = "demoVm"
  type        = string
}

variable "jumpbox_vm_size" {
  description = "Specifies the size of the jumpbox virtual machine"
  default     = "Standard_B2ms"
  type        = string
}

variable "jumpbox_vm_os_disk_storage_account_type" {
  description = "Specifies the storage account type of the os disk of the jumpbox virtual machine"
  default     = "Premium_LRS"
  type        = string

  validation {
    condition = contains(["Premium_LRS", "Premium_ZRS", "StandardSSD_LRS", "StandardSSD_ZRS",  "Standard_LRS"], var.jumpbox_vm_os_disk_storage_account_type)
    error_message = "The storage account type of the OS disk is invalid."
  }
}

variable "jumpbox_vm_os_disk_image" {
  type        = map(string)
  description = "Specifies the os disk image of the virtual machine"
  default     = {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS" 
    version   = "latest"
  }
}
variable "domain_name_label" {
  description = "Specifies the domain name for the jumbox virtual machine"
  default     = "gitopsdemovm"
  type        = string
}
variable "acr_name" {
  description = "Specifies the name of the container registry"
  type        = string
  default     = "demoAcr50744"
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
  default     = "192.168.25.64/26"
}
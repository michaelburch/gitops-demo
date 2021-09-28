variable "log_analytics_workspace_id" {
  description = "(Optional) The ID of the Log Analytics Workspace that diagnostic settings will target"
  type        = string
}
variable vnet_id {
  description = "(Required) Specifies the resource id of the virtual network to enable diagnostics settings"
  type        = string
}
variable aks_cluster_id {
  description = "(Required) Specifies the resource id of the AKS Cluster to enable diagnostic settings"
  type        = string
}
variable "log_analytics_retention_days" {
  description = "Specifies the number of days of the retention policy"
  type        = number
  default     = 7
}
variable acr_id {
  description = "(Required) Specifies the resource id of the ACR to enable diagnostics settings"
  type        = string
}
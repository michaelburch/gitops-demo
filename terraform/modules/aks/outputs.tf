output "id" {
  value       = azurerm_kubernetes_cluster.aks_cluster.id
  description = "Specifies the resource id of the AKS cluster."
}

output "ingress_identity_id" {

  value       = var.var.ingress_application_gateway.enabled == false ? null : flatten(azurerm_kubernetes_cluster.aks_cluster.addon_profile[*].ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id)[0]
  description = "Specifies the resource id of the AKS cluster."
}

output "kubelet_identity" {
  value       = azurerm_kubernetes_cluster.aks_cluster.kubelet_identity[0].object_id
  description = "Specifies the kubelet identity of the AKS cluster."
}


resource "azurerm_monitor_diagnostic_setting" "settings" {
  name                       = "DiagnosticsSettings"
  target_resource_id         = var.aks_cluster_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  log {
    category = "kube-apiserver"
    enabled  = false

    retention_policy {
      enabled = true  
      days    = var.log_analytics_retention_days
    }
  }

  log {
    category = "kube-audit"
    enabled  = false

    retention_policy {
      enabled = true
      days    = var.log_analytics_retention_days
    }
  }

  log {
    category = "kube-audit-admin"
    enabled  = true

    retention_policy {
      enabled = true
      days    = var.log_analytics_retention_days
    }
  }

  log {
    category = "kube-controller-manager"
    enabled  = false

    retention_policy {
      enabled = true
      days    = var.log_analytics_retention_days
    }
  }

  log {
    category = "kube-scheduler"
    enabled  = false

    retention_policy {
      enabled = true
      days    = var.log_analytics_retention_days
    }
  }

  log {
    category = "cluster-autoscaler"
    enabled  = false

    retention_policy {
      enabled = true
      days    = var.log_analytics_retention_days
    }
  }

  log {
    category = "guard"
    enabled  = true

    retention_policy {
      enabled = true
      days    = var.log_analytics_retention_days
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
      days    = var.log_analytics_retention_days
    }
  }
}
resource "azurerm_monitor_diagnostic_setting" "vnetSettings" {
  name                       = "vnetDiagnosticsSettings"
  target_resource_id         = var.vnet_id
  #depends_on               = [module.log_analytics_workspace, module.mgmt_network]
  log_analytics_workspace_id = var.log_analytics_workspace_id

  log {
    category = "VMProtectionAlerts"
    enabled  = true

    retention_policy {
      enabled = true
      days    = var.log_analytics_retention_days
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
      days    = var.log_analytics_retention_days
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "acrSettings" {
  name                       = "ACRDiagnosticsSettings"
  target_resource_id         = var.acr_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  log {
    category = "ContainerRegistryRepositoryEvents"
    enabled  = true

    retention_policy {
      enabled = true
      days    = var.log_analytics_retention_days
    }
  }

  log {
    category = "ContainerRegistryLoginEvents"
    enabled  = true

    retention_policy {
      enabled = true
      days    = var.log_analytics_retention_days
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
      days    = var.log_analytics_retention_days
    }
  }
}
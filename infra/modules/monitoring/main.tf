locals {
  app_http_error_kql = <<-KQL
ContainerLogV2
| where KubernetesNamespace == "${var.app_namespace}"
| where LogMessage has " 404 " or LogMessage has " 500 " or LogMessage matches regex @"\\b(404|500)\\b"
| project TimeGenerated, KubernetesNamespace, KubernetesPodName, ContainerName, LogMessage
| order by TimeGenerated desc
KQL
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "law-${replace(var.aks_name, "aks-", "")}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "diag-${var.aks_name}"
  target_resource_id         = var.aks_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_action_group" "ops" {
  count               = var.alert_email_receiver == null ? 0 : 1
  name                = "ag-${var.aks_name}-ops"
  resource_group_name = var.resource_group_name
  short_name          = "aksops"
  tags                = var.tags

  email_receiver {
    name          = "platform"
    email_address = var.alert_email_receiver
  }
}

resource "azurerm_monitor_metric_alert" "aks_node_cpu_high" {
  name                = "ma-${var.aks_name}-node-cpu-high"
  resource_group_name = var.resource_group_name
  scopes              = [var.aks_id]
  description         = "Alert when AKS node CPU usage is above threshold"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.cpu_threshold_percent
  }

  dynamic "action" {
    for_each = var.alert_email_receiver == null ? [] : [1]
    content {
      action_group_id = azurerm_monitor_action_group.ops[0].id
    }
  }
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.this.id
}

output "log_analytics_workspace_name" {
  value = azurerm_log_analytics_workspace.this.name
}

output "aks_cpu_alert_id" {
  value = azurerm_monitor_metric_alert.aks_node_cpu_high.id
}

output "app_http_error_alert_id" {
  value = azurerm_monitor_scheduled_query_rules_alert_v2.app_http_errors.id
}

output "app_http_error_kql" {
  value = local.app_http_error_kql
}

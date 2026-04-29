output "resource_group_name" {
  value       = azurerm_resource_group.platform.name
  description = "Platform resource group"
}

output "acr_name" {
  value       = module.acr.name
  description = "Azure Container Registry name"
}

output "acr_login_server" {
  value       = module.acr.login_server
  description = "ACR login server"
}

output "aks_name" {
  value       = module.aks.name
  description = "AKS cluster name"
}

output "infra_client_id" {
  value       = azurerm_user_assigned_identity.gha_infra.client_id
  description = "Client ID for infra GitHub Actions identity"
}

output "app_client_id" {
  value       = azurerm_user_assigned_identity.gha_app.client_id
  description = "Client ID for app GitHub Actions identity"
}

output "subscription_id" {
  value       = data.azurerm_client_config.current.subscription_id
  description = "Subscription ID"
}

output "tenant_id" {
  value       = data.azurerm_client_config.current.tenant_id
  description = "Tenant ID"
}

output "log_analytics_workspace_name" {
  value       = module.monitoring.log_analytics_workspace_name
  description = "Log Analytics workspace name"
}

output "aks_cpu_alert_id" {
  value       = module.monitoring.aks_cpu_alert_id
  description = "Metric alert resource ID for AKS node CPU"
}

output "app_http_error_kql" {
  value       = module.monitoring.app_http_error_kql
  description = "KQL query for 404/500 app container logs"
}

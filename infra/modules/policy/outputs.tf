output "deny_public_ip_assignment_id" {
  value = azurerm_resource_group_policy_assignment.deny_public_ip.id
}

output "deny_public_access_core_assignment_id" {
  value = azurerm_resource_group_policy_assignment.deny_public_access_core.id
}

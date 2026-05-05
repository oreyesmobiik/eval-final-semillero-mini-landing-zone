output "id" {
  value = azurerm_key_vault.this.id
}

output "name" {
  value = azurerm_key_vault.this.name
}

output "miniapp_secret_name" {
  value = var.create_bootstrap_secret ? azurerm_key_vault_secret.miniapp_config[0].name : "miniapp-config"
}
